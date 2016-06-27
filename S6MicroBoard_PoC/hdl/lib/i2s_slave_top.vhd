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

use work.iobus_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2s_slave_top is
	generic ( base_addr 	: std_logic_vector (31 downto 0) := x"C0080000";
		  addr_mask	: std_logic_vector (31 downto 0) := x"FFFF0000";
		  i2s_data_width: integer := 16;
		  frame_sync_early : std_logic := '1'
	);
	port (
		-- System clock
		clk      	: in std_logic;

		-- System Reset
		reset		: in std_logic;

		-- IO BUS signals
		iobus_in 	: in IOBUS_MOSI;
		iobus_out	: out IOBUS_MISO;

		-- I2S signals
		bclk		: in std_logic;
		lrclk		: in std_logic;
		d_out		: out std_logic;
		d_in		: in std_logic
	);
end i2s_slave_top;

architecture Behavioral of i2s_slave_top is
	component i2s_slave is
	generic (DATA_WIDTH: integer;
		 FRAME_SYNC_EARLY: std_logic
		 );
	port (BCLK : in std_logic;
	      FRCLK: in std_logic;
	      I2S_DATA_OUT: out std_logic;
	      I2S_DATA_IN : in std_logic;
	      DATA_OUT_R: out std_logic_vector(DATA_WIDTH-1 downto 0);
	      DATA_OUT_L: out std_logic_vector(DATA_WIDTH-1 downto 0);
	      DATA_OUT_VALID: out std_logic;
	      DATA_IN_R: in std_logic_vector(DATA_WIDTH-1 downto 0);
	      DATA_IN_L: in std_logic_vector(DATA_WIDTH-1 downto 0)
	);
	end component;

	-- Connections to lower level module
	signal dataTxR : std_logic_vector(i2s_data_width-1 downto 0) := (others => '0');
	signal dataTxL : std_logic_vector(i2s_data_width-1 downto 0) := (others => '0');
	signal dataRxR : std_logic_vector(i2s_data_width-1 downto 0) := (others => '0');
	signal dataRxL : std_logic_vector(i2s_data_width-1 downto 0) := (others => '0');
	signal dataRxVal : std_logic := '0';

	-- Synchronizer for data valid strobe from lower level module to iobus clock domain
	signal dataValdel : std_logic_vector (2 downto 0) := (others => '0');
	signal dataValEdge : std_logic := '0';
	signal dataValLatch: std_logic := '0';
	signal dataValAck : std_logic := '0';

	attribute shreg_extract : string;
	attribute shreg_extract of dataValdel : signal is "NO";

	attribute async_reg : string;
	attribute async_reg of dataValdel : signal is "TRUE";

	attribute optimize : string;
	attribute optimize of dataValdel : signal is "OFF";

	-- Registers accessible from IO bus
	signal regTxR : std_logic_vector(31 downto 0) := (others => '0');
	signal regTxL : std_logic_vector(31 downto 0) := (others => '0');
	signal regRxR : std_logic_vector(31 downto 0) := (others => '0');
	signal regRxL : std_logic_vector(31 downto 0) := (others => '0');
	signal regStatus : std_logic_vector(31 downto 0) := (others => '0');

	signal loc_addr : std_logic_vector(2 downto 0) := (others => '0');
	signal base_addr_match : std_logic := '0';
	signal masked_addr : std_logic_vector (31 downto 0) := (others => '0');

begin

	i2s_slave_phy: i2s_slave
	generic map (DATA_WIDTH => i2s_data_width,
		     FRAME_SYNC_EARLY => frame_sync_early)
	port map (BCLK => bclk,
	      FRCLK => lrclk,
	      I2S_DATA_OUT => d_out,
	      I2S_DATA_IN => d_in,
	      DATA_OUT_R => dataRxR,
	      DATA_OUT_L => dataRxL,
	      DATA_OUT_VALID => dataRxVal,
	      DATA_IN_R => dataTxR,
	      DATA_IN_L => dataTxL
	);

	-- map tx regs directly to sub-module (uP must make sure to avoid SU/H violations)
	dataTxR <= regTxR(i2s_data_width-1 downto 0);
	dataTxL <= regTxL(i2s_data_width-1 downto 0);

	-- use FFs to synchronize data valid signal from bclk domain
	valid_synch: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				dataValDel <= (others => '0');
			else
				dataValDel <= dataValDel(1 downto 0) & dataRxVal;
			end if;
		end if;
	end process;

	dataValEdge <= dataValDel(1) and (not dataValDel(2));

	-- latch data valid until acknowledged by processor
	dataValidLatch: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				dataValLatch <= '0';
			elsif dataValEdge = '1' then
				dataValLatch <= '1';
			elsif dataValAck = '1' then
				dataValLatch <= '0';
			else
				dataValLatch <= dataValLatch;
			end if;
		end if;
	end process;


	-- capture data received on edge of data valid
	rxRegs: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				regRxR <= (others => '0');
				regRxL <= (others => '0');
			elsif dataValEdge = '1' then
				for i in 31 downto 0 loop
					if i < i2s_data_width then
						regRxR(i) <= dataRxR(i);
						regRxL(i) <= dataRxL(i);
					else
						regRxR(i) <= '0';
						regRxL(i) <= '0';
					end if;
				end loop;
			else
				regRxR <= regRxR;
				regRxL <= regRxL;
			end if;
		end if;
	end process;

	-- Base address matches when full address masked with addr mask is equal base address generic
	maskInputAddress: process (iobus_in.Address)
	begin
		for i in 0 to iobus_in.Address'length-1 loop
			masked_addr(i) <= iobus_in.Address(i) and addr_mask(i);
		end loop;
	end process;
	base_addr_match <= '1' when masked_addr = base_addr else
			   '0';

	loc_addr <= iobus_in.Address (4 downto 2);

	-- IOBus write
	iobus_write: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				regTxR <= (others => '0');
				regTxL <= (others => '0');
				dataValAck <= '0';
			elsif iobus_in.Addr_Strobe = '1' and iobus_in.Write_Strobe = '1' and base_addr_match = '1' then
				-- 0th byte
				if iobus_in.Byte_Enable(0) = '1' then
					case loc_addr is
						when "000" =>
							regTxR (7 downto 0) <= regTxR (7 downto 0);
							regTxL (7 downto 0) <= regTxL (7 downto 0);
							dataValAck <= iobus_in.Write_Data (0);
							regStatus (7 downto 1) <= iobus_in.Write_Data (7 downto 1);
						when "001" =>
							regTxR (7 downto 0) <= iobus_in.Write_Data(7 downto 0);
							regTxL (7 downto 0) <= regTxL (7 downto 0);
							dataValAck <= dataValAck;
							regStatus (7 downto 1) <= regStatus(7 downto 1);
						when "010" =>
							regTxR (7 downto 0) <= regTxR (7 downto 0);
							regTxL (7 downto 0) <= iobus_in.Write_Data(7 downto 0);
							dataValAck <= dataValAck;
							regStatus (7 downto 1) <= regStatus(7 downto 1);
						when others =>
					end case;
				end if;
				-- 1st byte
				if iobus_in.Byte_Enable(1) = '1' then
					case loc_addr is
						when "000" =>
							regTxR (15 downto 8) <= regTxR (15 downto 8);
							regTxL (15 downto 8) <= regTxL (15 downto 8);
							regStatus (15 downto 8) <= iobus_in.Write_Data (15 downto 8);
						when "001" =>
							regTxR (15 downto 8) <= iobus_in.Write_Data(15 downto 8);
							regTxL (15 downto 8) <= regTxL (15 downto 8);
							regStatus (15 downto 8) <= regStatus(15 downto 8);
						when "010" =>
							regTxR (15 downto 8) <= regTxR (15 downto 8);
							regTxL (15 downto 8) <= iobus_in.Write_Data(15 downto 8);
							regStatus (15 downto 8) <= regStatus(15 downto 8);
						when others =>
					end case;
				end if;
				-- 2nd byte
				if iobus_in.Byte_Enable(2) = '1' then
					case loc_addr is
						when "000" =>
							regTxR (23 downto 16) <= regTxR (23 downto 16);
							regTxL (23 downto 16) <= regTxL (23 downto 16);
							regStatus (23 downto 16) <= iobus_in.Write_Data (23 downto 16);
						when "001" =>
							regTxR (23 downto 16) <= iobus_in.Write_Data(23 downto 16);
							regTxL (23 downto 16) <= regTxL (23 downto 16);
							regStatus (23 downto 16) <= regStatus(23 downto 16);
						when "010" =>
							regTxR (23 downto 16) <= regTxR (23 downto 16);
							regTxL (23 downto 16) <= iobus_in.Write_Data(23 downto 16);
							regStatus (23 downto 16) <= regStatus(23 downto 16);
						when others =>
					end case;
				end if;
				-- 3rd byte
				if iobus_in.Byte_Enable(3) = '1' then
					case loc_addr is
						when "000" =>
							regTxR (31 downto 24) <= regTxR (31 downto 24);
							regTxL (31 downto 24) <= regTxL (31 downto 24);
							regStatus (31 downto 24) <= iobus_in.Write_Data (31 downto 24);
						when "001" =>
							regTxR (31 downto 24) <= iobus_in.Write_Data(31 downto 24);
							regTxL (31 downto 24) <= regTxL (31 downto 24);
							regStatus (31 downto 24) <= regStatus(31 downto 24);
						when "010" =>
							regTxR (31 downto 24) <= regTxR (31 downto 24);
							regTxL (31 downto 24) <= iobus_in.Write_Data(31 downto 24);
							regStatus (31 downto 24) <= regStatus(31 downto 24);
						when others =>
					end case;
				end if;
			elsif dataValAck = '1' then -- Reset ack
				dataValAck <= '0';
				regTxR <= regTxR;
				regTxL <= regTxL;
				regStatus <= regStatus;
			end if;
		end if;
	end process;


	iobus_ready: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				iobus_out.Ready <= '0';
			elsif iobus_in.Addr_Strobe = '1' and base_addr_match = '1' then
				iobus_out.Ready <= '1';
			else
				iobus_out.Ready <= '0';
			end if;
		end if;
	end process;

	-- iobus read proc
	iobus_read: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				iobus_out.Read_Data <= (others => '0');
			elsif iobus_in.Addr_Strobe = '1' and iobus_in.Read_Strobe = '1' and base_addr_match = '1' then
				case loc_addr is
					when "000" => iobus_out.Read_Data <= regStatus(31 downto 1) & dataValLatch;
					when "001" => iobus_out.Read_Data <= regTxR;
					when "010" => iobus_out.Read_Data <= regTxL;
					when "011" => iobus_out.Read_Data <= regRxR;
					when "100" => iobus_out.Read_Data <= regRxL;
					when others => iobus_out.Read_Data <= (others => '0');
				end case;
			else
				iobus_out.Read_Data <= (others => '0');
			end if;
		end if;
	end process;


end Behavioral;
