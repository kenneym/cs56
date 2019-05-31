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

entity prime_test_tb is
	GENERIC(data_size 	: integer := 8;
		    num_tries	: integer := 7); -- set for test key

end prime_test_tb;

architecture testbench of prime_test_tb is

component prime_test is
	
	GENERIC(data_size 	: integer := data_size;
		    num_tries	: integer := num_tries); -- set for test key
	PORT (	clk 		:   in STD_LOGIC;
			en 		 	:   in STD_LOGIC;
			num_in 		:   in STD_LOGIC_VECTOR(data_size - 1 downto 0);  -- num to check for primality
			seed 		: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0);  -- seed for random number generation
			-----------------------------------------------------------
			prime_out 		: 	out STD_LOGIC;
			done 		: 	out STD_LOGIC);

end component;

signal clk, en, prime_out, done: STD_LOGIC := '0';
signal num_in, seed : STD_LOGIC_VECTOR(data_size - 1 downto 0) := (others => '0');
signal clk_period : time := 10 ns;


begin

uut: prime_test PORT MAP(
     clk => clk,
     en => en,
     num_in => num_in,
     seed => seed,
	 prime_out => prime_out,
     done => done);

clk_proc : process
BEGIN
    clk <= '0';
    wait for 5 ns;
    
    clk <= '1';
    wait for 5 ns;
end process clk_proc;

stim_proc : process
begin


--  num_in <= "10100011";       -- 163 (an 8 bit prime
--    seed <= "00101011";         -- set seed
--    en <= '1';
--    wait for clk_period;
--    en <= '0';
--    wait for clk_period * 20;

--    num_in <= "10111111";       -- 191 (an 8 bit prime)
--    seed <= "00101011";         -- set seed
--    en <= '1';
--    wait for clk_period;
--    en <= '0';
--    wait for clk_period * 20;


    num_in <= "10111011";       -- 187 (an 8 bit composite number)
    seed <= "00101011";         -- set seed
    en <= '1';
    wait for clk_period;
    en <= '0';
    wait for clk_period * 20;
    
--    num_in <= "00000011";       -- 1 (an 8 bit prime number)
--    seed <= "00101011";         -- set seed
--    en <= '1';
--    wait for clk_period;
--    en <= '0';
--    wait for clk_period * 20;


    wait;


end process stim_proc;

end testbench;
