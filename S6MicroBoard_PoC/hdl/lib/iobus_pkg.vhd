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

package IOBUS_PKG is

	constant READY_TIMEOUT : natural := 20; -- number of cycles to wait for ready from slave

	type IOBUS_MOSI is record
		Addr_Strobe : std_logic;
		Read_Strobe : std_logic;
		Write_Strobe : std_logic;
		Address : std_logic_vector (31 downto 0);
		Byte_Enable : std_logic_vector (3 downto 0);
		Write_Data : std_logic_vector (31 downto 0);
	end record;

	type IOBUS_MISO is record
		Read_Data : std_logic_vector (31 downto 0);
		Ready : std_logic;
	end record;

	procedure iobus_wait_rdy (
		signal clk : in std_logic;
		signal iobus_out : out IOBUS_MOSI;
		signal iobus_in : in IOBUS_MISO
	);

	procedure iobus_write32 (
		variable address : in std_logic_vector (31 downto 0);
		variable data : in std_logic_vector (31 downto 0);
		signal clk : in std_logic;
		signal iobus_out : out IOBUS_MOSI;
		signal iobus_in : in IOBUS_MISO
	);

	procedure iobus_read32 (
		variable address : in std_logic_vector (31 downto 0);
		variable data : out std_logic_vector (31 downto 0);
		signal clk : in std_logic;
		signal iobus_out : out IOBUS_MOSI;
		signal iobus_in : in IOBUS_MISO
	);

end IOBUS_PKG;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package body IOBUS_PKG is

	procedure iobus_wait_rdy (
		signal clk : in std_logic;
		signal iobus_out : out IOBUS_MOSI;
		signal iobus_in : in IOBUS_MISO
	) is
		variable count : natural := 0;
	begin
		RDY_LOOP: loop
			wait until rising_edge(clk);

			-- Clear all outputs
			iobus_out.Addr_Strobe <= '0';
			iobus_out.Read_Strobe <= '0';
			iobus_out.Write_Strobe <= '0';
			iobus_out.Address <= (others => '0');
			iobus_out.Byte_Enable <= (others => '0');
			iobus_out.Write_Data <= (others => '0');

			count := count + 1;
			if iobus_in.Ready = '1' then
				exit;
			elsif count > READY_TIMEOUT then
				report "IO BUS error: timeout exceeded waiting for slave ready signal" severity error;
				exit;
			end if;
		end loop;

	end;

	procedure iobus_write32 (
		variable address : in std_logic_vector (31 downto 0);
		variable data : in std_logic_vector (31 downto 0);
		signal clk : in std_logic;
		signal iobus_out : out IOBUS_MOSI;
		signal iobus_in : in IOBUS_MISO
	) is
	begin
		-- Start cycle
		wait until rising_edge(clk);
		iobus_out.Addr_Strobe <= '1';
		iobus_out.Read_Strobe <= '0';
		iobus_out.Write_Strobe <= '1';
		iobus_out.Address <= address;
		iobus_out.Byte_Enable <= x"F";
		iobus_out.Write_Data <= data;
		
		-- Wait for ready to end cycle
		iobus_wait_rdy(clk, iobus_out, iobus_in);
	end;

	procedure iobus_read32 (
		variable address : in std_logic_vector (31 downto 0);
		variable data : out std_logic_vector (31 downto 0);
		signal clk : in std_logic;
		signal iobus_out : out IOBUS_MOSI;
		signal iobus_in : in IOBUS_MISO
	) is
	begin
		-- Start cycle
		wait until rising_edge(clk);
		iobus_out.Addr_Strobe <= '1';
		iobus_out.Read_Strobe <= '1';
		iobus_out.Write_Strobe <= '0';
		iobus_out.Address <= address;
		iobus_out.Byte_Enable <= x"F";
		iobus_out.Write_Data <= (others => '0');
		
		-- Wait for ready to end cycle
		iobus_wait_rdy(clk, iobus_out, iobus_in);
		data := iobus_in.Read_Data;
	end;

end IOBUS_PKG;
