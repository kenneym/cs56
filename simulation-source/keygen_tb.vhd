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

entity keygen_tb is
	GENERIC(key_size	: integer := 32);
end keygen_tb;

architecture testbench of keygen_tb is

component keygen is
	GENERIC(key_size	: integer := key_size);

	PORT (  clk			:	in STD_LOGIC;
			en			:	in STD_LOGIC;
			seed_1		: 	in STD_LOGIC_VECTOR(key_size -1 downto 0);
			seed_2		: 	in STD_LOGIC_VECTOR(key_size/2 -1 downto 0);
			----------------------------------------------------------
			done 		: 	out STD_LOGIC;
			n_out 		: 	out STD_LOGIC_VECTOR(key_size -1 downto 0);
			e_out 		:	out STD_LOGIC_VECTOR(key_size -1 downto 0);
			d_out		:	out STD_LOGIC_VECTOR(key_size -1 downto 0));
end component;

signal clk, en, done: STD_LOGIC := '0';
signal seed_1, n_out, e_out, d_out: STD_LOGIC_VECTOR(key_size - 1 downto 0) := (others => '0');
signal seed_2 : STD_LOGIC_VECTOR(key_size/2 -1 downto 0) := (others => '0');
signal clk_period : time := 10 ns;


begin

uut: keygen 
GENERIC MAP ( key_size => key_size)
PORT MAP(
     clk => clk,
     en => en,
     seed_1 => seed_1,
     seed_2 => seed_2,
     done => done,
	 n_out => n_out,
	 e_out => e_out,
	 d_out => d_out);

clk_proc : process
BEGIN
    clk <= '0';
    wait for 5 ns;
    
    clk <= '1';
    wait for 5 ns;
end process clk_proc;

stim_proc : process
begin


    
    seed_1 <= "10011011001010111001101100101011";
    seed_2 <= "1001100110011001";       
    en <= '1';
    wait for clk_period;
    en <= '0';
    wait for clk_period * 20;


    wait;


end process stim_proc;

end testbench;
