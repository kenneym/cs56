-- Engineers: Matt Kenney and Jake Epstein
-- 
-- Create Date 05/29/2019
-- Design Name: 
-- Module Name: miller-rabin_tb - Behavioral
-- Project Name: CS56 Final Project
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rsatop_tb is
	GENERIC(key_size	: integer := 32);
end rsatop_tb;

architecture testbench of rsatop_tb is

component rsatop is
	Generic ( key_size : integer := 32);
    Port ( Clk : in  STD_LOGIC;					-- 100 MHz board clock
           RsRx  : in  STD_LOGIC;				-- Rx input

		   rx_test_data : in STD_LOGIC_VECTOR(7 downto 0);
		   rx_test_done_tick : in STD_LOGIC;
	       tx_test_data : out STD_LOGIC_VECTOR(24 downto 0);

		   gen_key : in STD_LOGIC; 				-- push-button mp signal to generate a key
		   enc_dec : in STD_LOGIC;				-- switch: enc = '1', dec = '0'
		   key_ready : out STD_LOGIC;
		   RsTx  : out  STD_LOGIC);				-- Tx output
end component;

signal clk, RsRx, gen_key, enc_dec, key_ready, RsTx : STD_LOGIC := '0';
signal clk_period : time := 10 ns;
signal rx_test_data: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal tx_test_data : STD_LOGIC_VECTOR(24 downto 0) := (others => '0');
signal rx_test_done_tick : STD_LOGIC := '0';


begin

uut: rsatop
GENERIC MAP ( key_size => key_size)
PORT MAP( clk => clk,
		  RsRx => RsRx,

		  -- Test variables
		  rx_test_data => rx_test_data,
		  rx_test_done_tick => rx_test_done_tick,
		  tx_test_data => tx_test_data,

		  gen_key => gen_key,
		  enc_dec => enc_dec,
		  key_ready => key_ready,
		  RsTx => RsTx);

clk_proc : process
BEGIN
    clk <= '0';
    wait for 5 ns;
    
    clk <= '1';
    wait for 5 ns;
end process clk_proc;

stim_proc : process
begin

	gen_key <= '1';
	wait for clk_period * 3;
	gen_key <= '0';

	wait for 100 ms;

	enc_dec <= '1';
	rx_test_data <= "01000001"; --a
	rx_test_done_tick <= '1';
	wait for clk_period;
	rx_test_done_tick <= '0';
	wait for clk_period;

	rx_test_data <= "01000010"; --b
	rx_test_done_tick <= '1';
	wait for clk_period;
	rx_test_done_tick <= '0';
	wait for clk_period;

	rx_test_data <= "01000011"; --c
	rx_test_done_tick <= '1';
	wait for clk_period;
	rx_test_done_tick <= '0';
	wait for clk_period;

--	rx_test_data <= "01000100"; --d
--	rx_test_done_tick <= '1';
--	wait for clk_period;
--	rx_test_done_tick <= '0';
--
--	rx_test_data <= "01100101"; --e
--	rx_test_done_tick <= '1';
--	wait for clk_period;
--	rx_test_done_tick <= '0';
--
--	rx_test_data <= "01100110"; --f
--	rx_test_done_tick <= '1';
--	wait for clk_period;
--	rx_test_done_tick <= '0';
--
--	rx_test_data <= "01100111"; --g
--	rx_test_done_tick <= '1';
--	wait for clk_period;
--	rx_test_done_tick <= '0';


    wait;


end process stim_proc;

end testbench;
