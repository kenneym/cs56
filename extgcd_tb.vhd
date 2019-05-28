----------------------------------------------------------------------------------
-- Engineers: Matt Kenney and Jake Epstein
-- 
-- Create Date7/2019
-- Design Name: 
-- Module Name: extgcd_tb - Behavioral
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

entity extgcd_tb is
end extgcd_tb;

architecture testbench of extgcd_tb is

component extgcd is 
	GENERIC( data_size  : integer := 8); -- set for test key
    PORT (clk     	:   in STD_LOGIC;
          new_data  :   in STD_LOGIC;
          a_in    	:   in STD_LOGIC_VECTOR(data_size - 1 downto 0);  --  phi of n
          b_in    	:   in STD_LOGIC_VECTOR(data_size - 1 downto 0);  --  public key 'e'
		  -----------------------------------------------------------
		  done 		: 	out STD_LOGIC;
          g_out	  	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  x_out	  	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
	  	  y_out		: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0));
end component;

signal clk, new_data, done : STD_LOGIC := '0';
signal a_in, b_in, g_out, x_out, y_out : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal clk_period : time := 10 ns;


begin

uut: extgcd PORT MAP(
     clk => clk,
     new_data => new_data,
     a_in => a_in,
     b_in => b_in,
	 done => done,
     g_out => g_out,
     x_out => x_out,
 	 y_out => y_out);

clk_proc : process
BEGIN
    clk <= '0';
    wait for 5 ns;
    
    clk <= '1';
    wait for 5 ns;
end process clk_proc;

stim_proc : process
begin


	-- Should give gcd of 2, x = -1, y = 3
    a_in <= "00010000"; -- 16
    b_in <= "00000110"; -- 6
    new_data <= '1';
    wait for clk_period;
    new_data <= '0';
    wait for clk_period * 20;

--	  -- 18 remainder 2
--	  a_in <= "10000000"; -- 128
--    b_in <= "00000111"; -- 7
--    new_data <= '1';
--    wait for clk_period;
--    new_data <= '0';


    wait;


end process stim_proc;

end testbench;
