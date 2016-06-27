-- Copyright (c) 2016 RF William Hollender
--
-- Permission is hereby granted, free of charge,
-- to any person obtaining a copy of this software
-- and associated documentation files (the "Software"),
-- to deal in the Software without restriction,
-- including without limitation the rights to use,
-- copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit
-- persons to whom the Software is furnished to do so,
-- subject to the following conditions:
--
-- The above copyright notice and this permission
-- notice shall be included in all copies or
-- substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
-- OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
-- NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
-- BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_2wire is
	port ( clk    : in STD_LOGIC;
	       rst    : in std_logic;

	        -- Comms to top module
	       data_in : in std_logic_vector (7 downto 0);
	       data_out : out std_logic_vector (7 downto 0);
	       data_in_str : in std_logic;
	       data_out_val : out std_logic;
	       start_str : in std_logic;
	       stop_str : in std_logic;
	       recv_byte_str : in std_logic;
	       busy : out std_logic;
	       divide_ratio : in std_logic_vector (7 downto 0);

	       send_ack : in std_logic;
	       send_ack_str : in std_logic;
	       recv_ack_str : in std_logic;
	       ack_rcvd : out std_logic;
		
		-- I2C phy
	       SDA_RD : in STD_LOGIC;
	       SCL_RD : in STD_LOGIC;
	       SDA_EN : out STD_LOGIC;
	       SCL_EN : out STD_LOGIC
	);
end i2c_2wire;

architecture Behavioral of i2c_2wire is
	type state_type is (	bus_idle, -- bus idle is normal state (no transaction, not driving any data)
				start_a, -- start condition
				start_b,
				start_c,
				start_d,
				repStart_a,
				repStart_b,
				bus_hold, -- bus hold waiting to start sending byte, start receiving byte, or send stop condition
				out_a, -- output bit
				out_b,
				out_c,
				out_d,
				in_a, -- input bit
				in_b,
				in_c,
				in_d,
				txAck_a,
				txAck_b,
				txAck_c,
				txAck_d,
				rxAck_a,
				rxAck_b,
				rxAck_c,
				rxAck_d,
				stop_a, -- stop condition
				stop_b,
				stop_c,
				stop_d);

	signal curr_state, next_state : state_type := bus_idle;
				
	component i2c_clock_divider is
	port(	clk		: in std_logic;
		rst		: in std_logic;
		div_rat 	: in std_logic_vector (7 downto 0);
		clk_strobe	: out std_logic
	);
	end component;

	-- clock divider connections
	signal clock_divider_rst : std_logic := '0';
	signal clk_div_str : std_logic := '0';

	-- input and output shift registers
	signal output_shift_reg : std_logic_vector (7 downto 0) := (others => '0');
	signal input_shift_reg : std_logic_vector (7 downto 0) := (others => '0');
	signal output_shift_en : std_logic := '0';
	signal output_shift_load : std_logic := '0';
	signal input_shift_en : std_logic := '0';

	-- synchronizer shift reg
	signal sda_synch : std_logic_vector (2 downto 0) := (others => '1');
	signal scl_synch : std_logic_vector (2 downto 0) := (others => '1');

	-- synchronizer attributes
	attribute shreg_extract : string;
	attribute shreg_extract of sda_synch : signal is "NO";
	attribute shreg_extract of scl_synch : signal is "NO";

	attribute async_reg : string;
	attribute async_reg of sda_synch : signal is "TRUE";
	attribute async_reg of scl_synch : signal is "TRUE";

	attribute optimize : string;
	attribute optimize of sda_synch : signal is "OFF";
	attribute optimize of scl_synch : signal is "OFF";

	-- glitch filtering shift regs
	signal sda_filt : std_logic_vector (4 downto 0) := (others => '1');
	signal scl_filt : std_logic_vector (4 downto 0) := (others => '1');

	-- internally usable (synchronized and filtered) i2c bus inputs
	signal sda_rd_int : std_logic;
	signal scl_rd_int : std_logic;

	-- I2C output driver enables (active high pulls lines low)
	signal sda_drv_en : std_logic := '0';
	signal scl_drv_en : std_logic := '0';

	signal bit_counter : unsigned (2 downto 0) := "000";
	signal bit_count_en : std_logic := '0';
	signal bit_count_rst : std_logic := '0';

	signal rx_ack_latch : std_logic := '0';
	signal rx_ack_latch_en : std_logic := '0';

	signal data_out_reg : std_logic_vector (7 downto 0) := (others => '0');

	signal send_ack_latch : std_logic := '0';

begin

	SDA_EN <= sda_drv_en;
	SCL_EN <= scl_drv_en;

	-- input synchronizers
	-- 3FF synch for best metastability protection
	synch: process (clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				sda_synch <= (others => '1');
				scl_synch <= (others => '1');
			else
				sda_synch <= sda_synch(1 downto 0) & SDA_RD;
				scl_synch <= scl_synch(1 downto 0) & SCL_RD;
			end if;
		end if;
	end process;

	-- input shift regs for filtering
	-- (could combine with synch shift reg)
	filt: process (clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				sda_filt <= (others => '1');
				scl_filt <= (others => '1');
			else
				sda_filt <= sda_filt(3 downto 0) & sda_synch(2);
				scl_filt <= scl_filt(3 downto 0) & scl_synch(2);
			end if;
		end if;
	end process;

	-- input filtering comb. logic
	-- I think that the glitches are only during high states, so use
	-- a nor gate for now, but probably need to revisit.
	sda_rd_int <= '0' when sda_filt = "00000" else
		      '1';
	scl_rd_int <= '0' when scl_filt = "00000" else
		      '1';

	clkdivider: i2c_clock_divider
	port map (	clk => clk,
			rst => clock_divider_rst,
			div_rat => divide_ratio,
			clk_strobe => clk_div_str
	);

	-- Input shift register
	-- Note: need to assert enable one state before capture transition
	-- so that both the enable and clock strobe are at the right time
	InputShiftReg: process (clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				input_shift_reg <= (others => '0');
			else
				if (input_shift_en = '1') and (clk_div_str = '1') then
					input_shift_reg <= input_shift_reg (6 downto 0) & sda_rd_int;
				else
					input_shift_reg <= input_shift_reg;
				end if;
			end if;
		end if;
	end process;

	data_out <= data_out_reg;
	DataOutReg: process (clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				data_out_reg <= (others => '0');
				data_out_val <= '0';
			elsif (input_shift_en = '1') and (clk_div_str = '1') and (bit_counter = "111") then
				data_out_reg <= input_shift_reg (6 downto 0) & sda_rd_int;
				data_out_val <= '1';
			else
				data_out_reg <= data_out_reg;
				data_out_val <= '0';
			end if;
		end if;
	end process;

	-- Output shift register
	-- shift register with enable and load
	output_shift_load <= data_in_str;
	OutputShiftReg: process (clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				output_shift_reg <= (others => '0');
			else
				if output_shift_load = '1' then
					output_shift_reg <= data_in;
				elsif (output_shift_en = '1') and (clk_div_str = '1') then
					output_shift_reg <= output_shift_reg (6 downto 0) & '0';
				else
					output_shift_reg <= output_shift_reg;
				end if;
			end if;
		end if;
	end process;

	-- Bit counter
	BitCount: process (clk)
	begin
		if rising_edge(clk) then
			if bit_count_rst = '1' then
				bit_counter <= "000";
			elsif (bit_count_en = '1') and (clk_div_str = '1') then
				bit_counter <= bit_counter + 1;
			else
				bit_counter <= bit_counter;
			end if;
		end if;
	end process;

	ack_rcvd <= rx_ack_latch;
	RxAckLatch: process (clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				rx_ack_latch <= '0';
			elsif rx_ack_latch_en = '1' then
				rx_ack_latch <= not sda_rd_int;
			else
				rx_ack_latch <= rx_ack_latch;
			end if;
		end if;
	end process;

	SendAckLatch: process (clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				send_ack_latch <= '0';
			elsif send_ack_str = '1' then
				send_ack_latch <= send_ack;
			else
				send_ack_latch <= send_ack_latch;
			end if;
		end if;
	end process;


	-- State register
	state_reg: process (clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				curr_state <= bus_idle;
			else
				curr_state <= next_state;
			end if;
		end if;
	end process;

	-- Next state logic
	-- Need to make sure that ALL inputs are given in sensitivity list
	-- so that there aren't any latches generated.
	next_state_logic: process(curr_state, start_str, clk_div_str, data_in_str, recv_byte_str, stop_str, send_ack_str, recv_ack_str, bit_counter)
	begin
		if curr_state = bus_idle then
			if start_str = '1' then
				next_state <= start_a;
			else
				next_state <= bus_idle;
			end if;
		elsif curr_state = bus_hold then
			if start_str = '1' then
				next_state <= repStart_a;
			elsif stop_str = '1' then
				next_state <= stop_a;
			elsif data_in_str = '1' then
				next_state <= out_a;
			elsif recv_byte_str = '1' then
				next_state <= in_a;
			elsif send_ack_str = '1' then
				next_state <= txAck_a;
			elsif recv_ack_str = '1' then
				next_state <= rxAck_a;
			else
				next_state <= curr_state;
			end if;
		elsif clk_div_str = '1' then
			case curr_state is 
				when	repStart_a =>	next_state <= repStart_b;

				when	repStart_b =>	next_state <= start_a;

				when 	start_a => 	next_state <= start_b;

				when	start_b => 	next_state <= start_c;

				when	start_c => 	next_state <= start_d;

				when	start_d => 	next_state <= bus_hold;

				when	out_a => 	next_state <= out_b;

				when	out_b => 	next_state <= out_c;

				when	out_c => 	next_state <= out_d;

				when	out_d => 	if bit_counter = "111" then
								next_state <= bus_hold;
							else
								next_state <= out_a;
							end if;

				when	in_a => 	next_state <= in_b;

				when	in_b => 	next_state <= in_c;

				when	in_c => 	next_state <= in_d;

				when	in_d => 	if bit_counter = "111" then
								next_state <= bus_hold;
							else
								next_state <= in_a;
							end if;

				when	txAck_a => 	next_state <= txAck_b;

				when	txAck_b => 	next_state <= txAck_c;

				when	txAck_c => 	next_state <= txAck_d;

				when	txAck_d => 	next_state <= bus_hold;

				when	rxAck_a => 	next_state <= rxAck_b;

				when	rxAck_b => 	next_state <= rxAck_c;

				when	rxAck_c => 	next_state <= rxAck_d;

				when	rxAck_d => 	next_state <= bus_hold;

				when	stop_a => 	next_state <= stop_b;

				when	stop_b => 	next_state <= stop_c;

				when	stop_c => 	next_state <= stop_d;

				when	stop_d => 	next_state <= bus_idle;

				when	others => 	next_state <= bus_idle;
			end case;
		else
			next_state <= curr_state;
		end if;
	end process;

	-- Output logic
	output_logic: process(curr_state, output_shift_reg(7), send_ack_latch)
	begin
		case curr_state is 
			when 	bus_idle => 	sda_drv_en <= '0';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '0';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '1';

			when 	start_a => 	sda_drv_en <= '0';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	start_b => 	sda_drv_en <= '1';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	start_c => 	sda_drv_en <= '1';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	start_d => 	sda_drv_en <= '1';
						scl_drv_en <= '1';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	repStart_a => 	sda_drv_en <= '0';
						scl_drv_en <= '1';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	repStart_b => 	sda_drv_en <= '0';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	bus_hold => 	sda_drv_en <= '0';
						scl_drv_en <= '1';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '1';
						busy <= '0';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '1';

			when	out_a => 	sda_drv_en <= not output_shift_reg(7);
						scl_drv_en <= '1';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	out_b => 	sda_drv_en <= not output_shift_reg(7);
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	out_c => 	sda_drv_en <= not output_shift_reg(7);
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	out_d => 	sda_drv_en <= not output_shift_reg(7);
						scl_drv_en <= '1';
						output_shift_en <= '1';
						input_shift_en <= '0';
						bit_count_en <= '1';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	in_a => 	sda_drv_en <= '0';
						scl_drv_en <= '1';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	in_b => 	sda_drv_en <= '0';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '1';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	in_c => 	sda_drv_en <= '0';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	in_d => 	sda_drv_en <= '0';
						scl_drv_en <= '1';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '1';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	txAck_a => 	sda_drv_en <= send_ack_latch;
						scl_drv_en <= '1';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	txAck_b => 	sda_drv_en <= send_ack_latch;
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	txAck_c => 	sda_drv_en <= send_ack_latch;
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	txAck_d => 	sda_drv_en <= send_ack_latch;
						scl_drv_en <= '1';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	rxAck_a => 	sda_drv_en <= '0';
						scl_drv_en <= '1';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	rxAck_b => 	sda_drv_en <= '0';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '1';
						clock_divider_rst <= '0';

			when	rxAck_c => 	sda_drv_en <= '0';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	rxAck_d => 	sda_drv_en <= '0';
						scl_drv_en <= '1';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	stop_a => 	sda_drv_en <= '1';
						scl_drv_en <= '1';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	stop_b => 	sda_drv_en <= '1';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	stop_c => 	sda_drv_en <= '1';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	stop_d => 	sda_drv_en <= '0';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '1';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '0';

			when	others => 	sda_drv_en <= '0';
						scl_drv_en <= '0';
						output_shift_en <= '0';
						input_shift_en <= '0';
						bit_count_en <= '0';
						bit_count_rst <= '0';
						busy <= '0';
						rx_ack_latch_en <= '0';
						clock_divider_rst <= '1';
		end case;
	end process;

end Behavioral;
