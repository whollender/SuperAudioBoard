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
use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;

entity i2s_slave is
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
end i2s_slave;

architecture Behavioral of i2s_slave is
	signal fs_counter : std_logic_vector(5 downto 0) := (others => '0');
	signal fs_norm : std_logic := '0';
	signal fs_early : std_logic := '0';
	signal frclk_re : std_logic := '0';
	signal frclk_d : std_logic := '0';
	signal frclk_dd : std_logic := '0';
	signal fs_str : std_logic := '0';
	signal shiftreg_out : std_logic_vector(DATA_WIDTH*2-1 downto 0) := (others => '0');
	signal shiftreg_in : std_logic_vector(DATA_WIDTH*2-1 downto 0) := (others => '0');
	signal data_reg_out : std_logic_vector(DATA_WIDTH*2-1 downto 0) := (others => '0');
	signal data_reg_in : std_logic_vector(DATA_WIDTH*2-1 downto 0) := (others => '0');
	signal data_valid_str : std_logic := '0';
begin

	I2S_DATA_OUT <= shiftreg_out(shiftreg_out'high);
	DATA_OUT_VALID <= data_valid_str;

	data_cap: process (BCLK)
	begin
		if rising_edge(BCLK) then
			if fs_str = '1' then
				data_reg_in <= shiftreg_in;
			end if;
		end if;
	end process;

	data_val_strobe: process (BCLK)
	begin
		if rising_edge(BCLK) then
			if fs_str = '1' then
				data_valid_str <= '1';
			else
				data_valid_str <= '0';
			end if;
		end if;
	end process;

-- Shift reg processes
	shift_in: process (BCLK)
	begin
		if rising_edge(BCLK) then
			shiftreg_in <= shiftreg_in(shiftreg_in'high-1 downto 0) & I2S_DATA_IN;
		end if;
	end process;

	shift_out: process (BCLK)
	begin
		if falling_edge(BCLK) then
			if fs_str = '1' then
				shiftreg_out <= data_reg_out;
			else
				shiftreg_out <= shiftreg_out(shiftreg_out'high-1 downto 0) & '0';
			end if;
		end if;
	end process;

	-- delayed FRCLK for finding edges
	frclk_del: process(BCLK)
	begin
		if rising_edge(BCLK) then
			frclk_d <= FRCLK;
			frclk_dd <= frclk_d;
		end if;
	end process;

	frclk_re <= frclk_d AND (NOT frclk_dd);

	-- Counter for generating early frame sync
	fs_proc: process(BCLK)
	begin
		if rising_edge(BCLK) then
			if frclk_re = '1' then
				fs_counter <= (others => '0');
			else
				fs_counter <= std_logic_vector(unsigned(fs_counter) + 1);
			end if;
		end if;
	end process;
	
	-- Generate FS and FS early
	fs_norm <= frclk_re;

	fs_early <= '1' when fs_counter = std_logic_vector(to_unsigned(DATA_WIDTH*2-2, fs_counter'length)) else
		    '0';

	-- Decide which strobe to use
	fs_str <= fs_norm when FRAME_SYNC_EARLY = '0' else
		  fs_early;

	-- Data reg to IOs
	DATA_OUT_R <= data_reg_in(DATA_WIDTH*2-1 downto DATA_WIDTH);
	DATA_OUT_L <= data_reg_in(DATA_WIDTH-1 downto 0);

	data_reg_out(DATA_WIDTH*2-1 downto DATA_WIDTH) <= DATA_IN_R;
	data_reg_out(DATA_WIDTH-1 downto 0) <= DATA_IN_L;


end Behavioral;
