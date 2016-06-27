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

entity i2c_clock_divider is
	port(	clk		: in std_logic;
		rst		: in std_logic;
		div_rat 	: in std_logic_vector (7 downto 0);
		clk_strobe	: out std_logic
	);
end i2c_clock_divider;

architecture Behavioral of i2c_clock_divider is
	signal count : unsigned (7 downto 0);
	signal clk_str : std_logic := '0';
begin

	clk_strobe <= clk_str;

	counter: process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				count <= (others => '0');
				clk_str <= '0';
			else
				if count = unsigned(div_rat) then
					count <= (others => '0');
					clk_str <= '1';
				else
					count <= count + 1;
					clk_str <= '0';
				end if;
			end if;
		end if;
	end process;

end Behavioral;
