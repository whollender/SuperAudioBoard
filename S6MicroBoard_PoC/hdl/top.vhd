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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
	port ( 	USER_RESET : in std_logic; -- RESET (active high)
		CLOCK_Y3 :  in std_logic; -- 100MHz clock
		GPIO_LED1 : out std_logic;
		GPIO_LED2 : out std_logic;
		GPIO_LED3 : out std_logic;
		GPIO_LED4 : out std_logic;
		PMOD1_P1 : in std_logic; -- BCLK
		PMOD1_P2 : out std_logic; -- I2S_OUT
		PMOD1_P3 : out std_logic; -- Codec reset
		PMOD1_P4 : inout std_logic; -- SCL
		--SCL : inout std_logic; -- SCL
		PMOD1_P7 : in std_logic; -- LRCLK
		PMOD1_P8 : in std_logic; -- I2S_IN
		--SDA : inout std_logic; -- SDA
		PMOD1_P10 : inout std_logic; -- SDA
		USB_RS232_RXD : in std_logic;
		USB_RS232_TXD : out std_logic
	     );
end top;

architecture Behavioral of top is
	constant periph_addr_mask : std_logic_vector (31 downto 0) := x"FFFF0000";
	constant i2c_base_addr : std_logic_vector (31 downto 0) := x"C0040000";
	constant i2s_base_addr : std_logic_vector (31 downto 0) := x"C0080000";
	constant i2s_data_width : integer := 32;
	constant i2s_fse : std_logic := '1';

COMPONENT microblaze_mcs_v1_4_0
  PORT (
    Clk : IN STD_LOGIC;
    Reset : IN STD_LOGIC;
    IO_Addr_Strobe : OUT STD_LOGIC;
    IO_Read_Strobe : OUT STD_LOGIC;
    IO_Write_Strobe : OUT STD_LOGIC;
    IO_Address : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    IO_Byte_Enable : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    IO_Write_Data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    IO_Read_Data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    IO_Ready : IN STD_LOGIC;
    UART_Rx : IN STD_LOGIC;
    UART_Tx : OUT STD_LOGIC;
    PIT1_Toggle : OUT STD_LOGIC;
    GPO1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

signal UART_Rx : std_logic := '0';
signal UART_Tx : std_logic := '0';
signal PIT1_Toggle : std_logic := '0';
signal GPO1 : std_logic_vector (31 downto 0);

signal iobus_master_out : iobus_mosi;
signal iobus_master_in : iobus_miso;

component i2c_top is
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
end component;
signal iobus_i2c_out : iobus_miso;
signal SDA_RD : std_logic := '1';
signal SDA_EN : std_logic := '0';
signal SCL_RD : std_logic := '1';
signal SCL_EN : std_logic := '0';

component i2s_slave_top is
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
end component;
signal iobus_i2s_out : iobus_miso;
signal bclk : std_logic := '0';
signal lrclk : std_logic := '0';
signal d_out : std_logic := '0';
signal d_in : std_logic := '0';

-- signals for iobus master in mux
signal masked_addr : std_logic_vector (31 downto 0);
signal latched_masked_addr : std_logic_vector (31 downto 0);
signal iobus_miso_dummy : iobus_miso;

begin

-- Microblaze instance and unique IOs
mcs_0 : microblaze_mcs_v1_4_0
  PORT MAP (
    Clk => CLOCK_Y3,
    Reset => USER_RESET,
    IO_Addr_Strobe => iobus_master_out.Addr_Strobe,
    IO_Read_Strobe => iobus_master_out.Read_Strobe,
    IO_Write_Strobe => iobus_master_out.Write_Strobe,
    IO_Address => iobus_master_out.Address,
    IO_Byte_Enable => iobus_master_out.Byte_Enable,
    IO_Write_Data => iobus_master_out.Write_Data,
    IO_Read_Data => iobus_master_in.Read_Data,
    IO_Ready => iobus_master_in.Ready,
    UART_Rx => UART_Rx,
    UART_Tx => UART_Tx,
    PIT1_Toggle => PIT1_Toggle,
    GPO1 => GPO1
  );

  UART_Rx <= USB_RS232_RXD;
  USB_RS232_TXD <= UART_Tx;
  PMOD1_P3 <= GPO1(0);
  GPIO_LED1 <= GPO1(1);
  GPIO_LED2 <= GPO1(2);
  GPIO_LED3 <= GPO1(3);
  GPIO_LED4 <= GPO1(4);

-- Microblaze unique stuff


  
-- I2C specific stuff
i2c_periph: i2c_top
	generic map (
		base_addr => i2c_base_addr,
		addr_mask => periph_addr_mask
	)
	port map (
		-- System clock
		clk => CLOCK_Y3,

		-- System Reset
		reset => USER_RESET,

		-- IO BUS signals
		iobus_in => iobus_master_out,
		iobus_out => iobus_i2c_out,

		-- I2C signals (setup as tri-state at top level)
	      	SDA_RD => SDA_RD,
	        SDA_EN => SDA_EN,
	        SCL_RD => SCL_RD,
	        SCL_EN => SCL_EN
	);

	PMOD1_P10 <= '0' when SDA_EN  = '1' else 'Z';
	--SDA <= '0' when SDA_EN  = '1' else 'Z';
	SDA_RD <= PMOD1_P10;
	--SDA_RD <= SDA;
	PMOD1_P4 <= '0' when SCL_EN  = '1' else 'Z';
	--SCL <= '0' when SCL_EN  = '1' else 'Z';
	SCL_RD <= PMOD1_P4;
	--SCL_RD <= SCL;

-- I2C specific stuff

-- I2S specific stuff
i2s_slave_periph: i2s_slave_top
	generic map ( 
		base_addr => i2s_base_addr,
		addr_mask => periph_addr_mask,
		i2s_data_width => i2s_data_width,
		frame_sync_early => i2s_fse
	)
	port map (
		-- System clock
		clk => CLOCK_Y3,

		-- System Reset
		reset => USER_RESET,

		-- IO BUS signals
		iobus_in => iobus_master_out,
		iobus_out => iobus_i2s_out,

		-- I2S signals
		bclk => bclk,
		lrclk => lrclk,
		d_out => d_out,
		d_in => d_in
	);

	bclk <= PMOD1_P1;
	lrclk <= PMOD1_P7;
	PMOD1_P2 <= d_out;
	d_in <= PMOD1_P8;

-- I2S specific stuff


-- Last thing needed is something to mux the two iobus slave outputs into a single master input


	-- Latch masked address on address strobe
	addr_latch : process (CLOCK_Y3)
	begin
		if rising_edge(CLOCK_Y3) then
			if USER_RESET = '1' then
				latched_masked_addr <= (others => '0');
			elsif iobus_master_out.Addr_Strobe = '1' then
				latched_masked_addr <= masked_addr;
			else
				latched_masked_addr <= latched_masked_addr;
			end if;
		end if;
	end process;

	-- Mask address
	addr_mask : process (iobus_master_out.Address)
	begin
		for i in 31 downto 0 loop
			masked_addr(i) <= iobus_master_out.Address(i) and periph_addr_mask(i);
		end loop;
	end process;

	-- Finally mux the two inputs
	iobus_miso_mux : process (latched_masked_addr,iobus_i2c_out,iobus_i2s_out,iobus_miso_dummy)
	begin
		case latched_masked_addr is
			when i2c_base_addr => iobus_master_in <= iobus_i2c_out;
			when i2s_base_addr => iobus_master_in <= iobus_i2s_out;
			when others => iobus_master_in <= iobus_miso_dummy;
		end case;
	end process;

	-- Generate dummy MISO so that microblaze doesn't hang if it tries to access bad address
	iobus_dummy : process (CLOCK_Y3)
	begin
		if rising_edge(CLOCK_Y3) then
			if iobus_master_out.Addr_Strobe = '1' then
				iobus_miso_dummy.Ready <= '1';
			else
				iobus_miso_dummy.Ready <= '0';
			end if;
		end if;
	end process;
	iobus_miso_dummy.Read_Data <= (others => '0');

end Behavioral;
