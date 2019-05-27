----------------------------------------------------------------------------------
-- Engineers: Matt Kenney and Jake Epstein
-- 
-- Create Date: 05/26/2019 
-- Design Name: 
-- Module Name: mod_tb - Behavioral
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

entity mod_tb is
end mod_tb;

architecture testbench of mod_tb is

component modulus is 
	GENERIC( data_size  : integer := 8); -- set for test key
	PORT (clk 		: 	in STD_LOGIC;
          a_in 		: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0); -- a should be >= b
		  b_in  	: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  new_data	: 	in STD_LOGIC;
		  ---------------------------------------------------------
		  q_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  r_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0));
end component;

signal clk : STD_LOGIC := '0';
signal new_data : STD_LOGIC := '0';
signal a_in, b_in, q_out, r_out : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');


begin

uut: modulus PORT MAP(
     clk => clk,
     a_in => a_in,
     b_in => b_in,
     new_data => new_data,
     q_out => q_out,
 	 r_out => r_out);

clk_proc : process
BEGIN
    clk <= '0';
    wait for 5 ns;
    
    clk <= '1';
    wait for 5 ns;
end process clk_proc;

stim_proc : process
begin

    wait for 10 ns;
    a_in <= "00000111"; -- 7
    b_in <= "00000011"; -- 3
    wait for 10 ns;
    new_data <= '1';
    wait for 10 ns;
    new_data <= '0';
    wait;
end process stim_proc;

end testbench;
