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

use work.IOBUS_PKG.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_top is
	generic ( base_addr 	: std_logic_vector (31 downto 0) := x"C0040000";
		  addr_mask	: std_logic_vector (31 downto 0) := x"FFFF0000"
	);
	port (
		-- System clock
		clk      	: in std_logic;

		-- System Reset
		reset		: in std_logic;

		-- IO BUS signals
		iobus_in 	: in IOBUS_MOSI;
		iobus_out	: out IOBUS_MISO;

		-- I2C signals (setup as tri-state at top level)
	      	SDA_RD 		: in std_logic;
	        SDA_EN 		: out std_logic;
	        SCL_RD 		: in std_logic;
	        SCL_EN 		: out std_logic
	);
end i2c_top;

architecture Behavioral of i2c_top is
	component i2c_2wire is
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
	end component;

	signal read_reg : std_logic_vector (31 downto 0) := (others => '0');
	signal ready_str_reg : std_logic := '0';
	signal loc_addr : std_logic_vector (1 downto 0) := (others => '0');
	signal base_addr_match : std_logic := '0';
	signal masked_addr : std_logic_vector (31 downto 0) := (others => '0');

	-- Registers
	-- Status and control
	signal regSC : std_logic_vector(31 downto 0) := (others => '0');

	-- Divide Ratio
	signal regDR : std_logic_vector(31 downto 0) := (others => '0');
	
	-- Data output
	signal regDataOut : std_logic_vector (31 downto 0) := (others => '0');

	-- Data input
	signal regDataIn : std_logic_vector (31 downto 0) := (others => '0');
	-- end registers


	-- Connections to 2-wire module
	signal rst    : std_logic := '1';
	signal rstDly : std_logic := '1';

	signal data_in : std_logic_vector (7 downto 0) := (others => '0');
	signal data_out : std_logic_vector (7 downto 0) := (others => '0');
	signal data_in_str : std_logic := '0';
	signal data_out_val : std_logic := '0';
	signal start_str : std_logic := '0';
	signal stop_str : std_logic := '0';
	signal recv_byte_str : std_logic := '0';
	signal busy : std_logic := '0';
	signal divide_ratio : std_logic_vector (7 downto 0) := (others => '1');

	signal send_ack : std_logic := '0';
	signal send_ack_str : std_logic := '0';
	signal recv_ack_str : std_logic := '0';
	signal ack_rcvd : std_logic := '0';
	-- end connections to 2-wire module

begin

	DUT: i2c_2wire
		port map ( clk => clk,
		       rst => rst,

			-- Comms to top module
		       data_in => data_in,
		       data_out => data_out,
		       data_in_str => data_in_str,
		       data_out_val => data_out_val,
		       start_str => start_str,
		       stop_str => stop_str,
		       recv_byte_str => recv_byte_str,
		       busy => busy,
		       divide_ratio => divide_ratio,

		       send_ack => send_ack,
		       send_ack_str => send_ack_str,
		       recv_ack_str => recv_ack_str,
		       ack_rcvd => ack_rcvd,
			
			-- I2C phy
		       SDA_RD => SDA_RD,
		       SCL_RD => SCL_RD,
		       SDA_EN => SDA_EN,
		       SCL_EN => SCL_EN
		);

		
	-- Local register address decode is last 2 bits (only 4 regs)
	-- before sub-word address bits
	loc_addr <= iobus_in.Address (3 downto 2);

	-- Base address matches when full address masked with addr mask is equal base address generic
	maskInputAddress: process (iobus_in.Address)
	begin
		for i in 0 to iobus_in.Address'length-1 loop
			masked_addr(i) <= iobus_in.Address(i) and addr_mask(i);
		end loop;
	end process;
	base_addr_match <= '1' when masked_addr = base_addr else
			   '0';

	Regs: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				regSC <= (others => '0');
				regDR <= (others => '0');
				regDataOut <= (others => '0');
			elsif iobus_in.Addr_Strobe = '1' and iobus_in.Write_Strobe = '1' and base_addr_match = '1' then
				if iobus_in.Byte_Enable(0) = '1' then
					case loc_addr is
						when "00" => 	regSC (7 downto 0) <= iobus_in.Write_Data (7 downto 0);
								regDR (7 downto 0) <= regDR (7 downto 0);
								regDataOut (7 downto 0) <= regDataOut (7 downto 0);

						when "01" => 	regSC (7 downto 0) <= regSC (7 downto 0);
								regDR (7 downto 0) <= iobus_in.Write_Data (7 downto 0);
								regDataOut (7 downto 0) <= regDataOut (7 downto 0);

						when "10" => 	regSC (7 downto 0) <= regSC (7 downto 0);
								regDR (7 downto 0) <= regDR (7 downto 0);
								regDataOut (7 downto 0) <= iobus_in.Write_Data (7 downto 0);

						when others => 	regSC (7 downto 0) <= regSC (7 downto 0);
								regDR (7 downto 0) <= regDR (7 downto 0);
								regDataOut (7 downto 0) <= regDataOut (7 downto 0);
					end case;

				else
					regSC (7 downto 0) <= regSC (7 downto 0);
					regDR (7 downto 0) <= regDR (7 downto 0);
					regDataOut (7 downto 0) <= regDataOut (7 downto 0);
				end if;

				if iobus_in.Byte_Enable(1) = '1' then
					case loc_addr is
						when "00" => 	regSC (15 downto 8) <= iobus_in.Write_Data (15 downto 8);
								regDR (15 downto 8) <= regDR (15 downto 8);
								regDataOut (15 downto 8) <= regDataOut (15 downto 8);

						when "01" => 	regSC (15 downto 8) <= regSC (15 downto 8);
								regDR (15 downto 8) <= iobus_in.Write_Data (15 downto 8);
								regDataOut (15 downto 8) <= regDataOut (15 downto 8);

						when "10" => 	regSC (15 downto 8) <= regSC (15 downto 8);
								regDR (15 downto 8) <= regDR (15 downto 8);
								regDataOut (15 downto 8) <= iobus_in.Write_Data (15 downto 8);

						when others => 	regSC (15 downto 8) <= regSC (15 downto 8);
								regDR (15 downto 8) <= regDR (15 downto 8);
								regDataOut (15 downto 8) <= regDataOut (15 downto 8);
					end case;

				else
					regSC (15 downto 8) <= regSC (15 downto 8);
					regDR (15 downto 8) <= regDR (15 downto 8);
					regDataOut (15 downto 8) <= regDataOut (15 downto 8);
				end if;

				if iobus_in.Byte_Enable(2) = '1' then
					case loc_addr is
						when "00" => 	regSC (23 downto 16) <= iobus_in.Write_Data (23 downto 16);
								regDR (23 downto 16) <= regDR (23 downto 16);
								regDataOut (23 downto 16) <= regDataOut (23 downto 16);

						when "01" => 	regSC (23 downto 16) <= regSC (23 downto 16);
								regDR (23 downto 16) <= iobus_in.Write_Data (23 downto 16);
								regDataOut (23 downto 16) <= regDataOut (23 downto 16);

						when "10" => 	regSC (23 downto 16) <= regSC (23 downto 16);
								regDR (23 downto 16) <= regDR (23 downto 16);
								regDataOut (23 downto 16) <= iobus_in.Write_Data (23 downto 16);

						when others => 	regSC (23 downto 16) <= regSC (23 downto 16);
								regDR (23 downto 16) <= regDR (23 downto 16);
								regDataOut (23 downto 16) <= regDataOut (23 downto 16);
					end case;

				else
					regSC (23 downto 16) <= regSC (23 downto 16);
					regDR (23 downto 16) <= regDR (23 downto 16);
					regDataOut (23 downto 16) <= regDataOut (23 downto 16);
				end if;

				if iobus_in.Byte_Enable(3) = '1' then
					case loc_addr is
						when "00" => 	regSC (31 downto 24) <= iobus_in.Write_Data (31 downto 24);
								regDR (31 downto 24) <= regDR (31 downto 24);
								regDataOut (31 downto 24) <= regDataOut (31 downto 24);

						when "01" => 	regSC (31 downto 24) <= regSC (31 downto 24);
								regDR (31 downto 24) <= iobus_in.Write_Data (31 downto 24);
								regDataOut (31 downto 24) <= regDataOut (31 downto 24);

						when "10" => 	regSC (31 downto 24) <= regSC (31 downto 24);
								regDR (31 downto 24) <= regDR (31 downto 24);
								regDataOut (31 downto 24) <= iobus_in.Write_Data (31 downto 24);

						when others => 	regSC (31 downto 24) <= regSC (31 downto 24);
								regDR (31 downto 24) <= regDR (31 downto 24);
								regDataOut (31 downto 24) <= regDataOut (31 downto 24);
					end case;

				else
					regSC (31 downto 24) <= regSC (31 downto 24);
					regDR (31 downto 24) <= regDR (31 downto 24);
					regDataOut (31 downto 24) <= regDataOut (31 downto 24);
				end if;


				-- Read-only bits are always over-written with internal signals
				regSC(1) <= busy;
				regSC(9) <= ack_rcvd;

			elsif regSC(2) = '1' then -- reset start strobe
				regSC (31 downto 3) <= regSC (31 downto 3);
				regSC(2) <= '0';
				regSC (1 downto 0) <= regSC (1 downto 0);

				regDR <= regDR;
				regDataOut <= regDataOut;

			elsif regSC(3) = '1' then -- reset stop strobe
				regSC (31 downto 4) <= regSC (31 downto 4);
				regSC(3) <= '0';
				regSC (2 downto 0) <= regSC (2 downto 0);

				regDR <= regDR;
				regDataOut <= regDataOut;

			elsif regSC(4) = '1' then -- reset data strobe
				regSC (31 downto 5) <= regSC (31 downto 5);
				regSC(4) <= '0';
				regSC (3 downto 0) <= regSC (3 downto 0);

				regDR <= regDR;
				regDataOut <= regDataOut;

			elsif regSC(5) = '1' then -- reset recv strobe
				regSC (31 downto 6) <= regSC (31 downto 6);
				regSC(5) <= '0';
				regSC (4 downto 0) <= regSC (4 downto 0);

				regDR <= regDR;
				regDataOut <= regDataOut;

			elsif regSC(6) = '1' then -- reset send ack strobe
				regSC (31 downto 7) <= regSC (31 downto 7);
				regSC(6) <= '0';
				regSC (5 downto 0) <= regSC (5 downto 0);

				regDR <= regDR;
				regDataOut <= regDataOut;

			elsif regSC(8) = '1' then -- reset send ack strobe
				regSC (31 downto 9) <= regSC (31 downto 9);
				regSC(8) <= '0';
				regSC (7 downto 0) <= regSC (7 downto 0);

				regDR <= regDR;
				regDataOut <= regDataOut;
			else
				regSC(0) <= regSC(0);
				regSC(1) <= busy;
				regSC (8 downto 2) <= regSC (8 downto 2);
				regSC (9) <= ack_rcvd;
				regSC (31 downto 10) <= regSC (31 downto 10);
				regDR <= regDR;
				regDataOut <= regDataOut;
			end if;
		end if;
	end process;

	-- assign regs to lower level signals
	-- Status and control reg
	rst <= not regSC(0); -- Enable
        -- Busy drives bit 1, so it must be in the register process
	start_str <= regSC(2);
	stop_str <= regSC(3);
	data_in_str <= regSC(4);
	recv_byte_str <= regSC(5);
	send_ack_str <= regSC(6);
	send_ack <= regSC(7);
	recv_ack_str <= regSC(8);
	-- ack_recvd drives bit 9

	-- data out reg
	data_in <= regDataOut (7 downto 0);

	-- Input data register
	inpDataReg: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				regDataIn <= (others => '0');
			elsif data_out_val = '1' then
				regDataIn (7 downto 0) <= data_out;
				regDataIn (31 downto 8) <= (others => '0');
			else
				regDataIn <= regDataIn;
			end if;
		end if;
	end process;

	rstDelay: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				rstDly <= '1';
			else
				rstDly <= rst;
			end if;
		end if;
	end process;

	-- Divide reg latch
	-- Latch divide reg on rising edge of enable (falling edge of reset)
	divLatch: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				divide_ratio <= (others => '1');
			elsif rst = '0' and rstDly = '1' then
				divide_ratio <= regDR (7 downto 0);
			else
				divide_ratio <= divide_ratio;
			end if;
		end if;
	end process;

	-- Read register
	readReg: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				read_reg <= (others => '0');
			elsif iobus_in.Addr_Strobe = '1' and iobus_in.Read_Strobe = '1' and base_addr_match = '1' then
				case loc_addr is
					when "00" => read_reg <= regSC;
					when "01" => read_reg <= regDR;
					when "10" => read_reg <= regDataOut;
					when "11" => read_reg <= regDataIn;
					when others => read_reg <= (others => '0');
				end case;
			else
				read_reg <= read_reg;
			end if;
		end if;
	end process;
	iobus_out.Read_Data <= read_reg;

	-- Ready strobe gen
	readyStr: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				ready_str_reg <= '0';
			elsif iobus_in.Addr_Strobe = '1' then
				ready_str_reg <= '1';
			else
				ready_str_reg <= '0';
			end if;
		end if;
	end process;
	iobus_out.Ready <= ready_str_reg;

end Behavioral;
