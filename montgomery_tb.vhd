----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/25/2019 06:42:42 PM
-- Design Name: 
-- Module Name: montgomery_tb - Behavioral
-- Project Name: 
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
use IEEE.NUMERIC_STD.ALL;

entity montgomery_tb is
end montgomery_tb;

architecture testbench of montgomery_tb is

component montgomery is
generic (
    num_bits_ab : integer := 8;
    num_bits_n :integer := 8
    );
    Port (mclk    :     in STD_LOGIC;
          a       :     in STD_LOGIC_VECTOR(num_bits_ab-1 downto 0);
          b       :     in STD_LOGIC_VECTOR(num_bits_ab-1 downto 0);
          n       :     in STD_LOGIC_VECTOR(num_bits_n-1 downto 0);
          toggle  :     in STD_LOGIC;
          modmult  :     out STD_LOGIC_VECTOR(num_bits_n-1 downto 0));
 end component;
 
 constant c_num_bits_ab :   integer := 4;
 constant c_num_bits_n  :   integer := 8;
 constant c_period      :   time := 20 ns; 
 
 signal mclk             :  STD_LOGIC := '0';
 signal a                :  STD_LOGIC_VECTOR(c_num_bits_ab-1 downto 0);
 signal b                :  STD_LOGIC_VECTOR(c_num_bits_ab-1 downto 0);
 signal n                :  STD_LOGIC_VECTOR(c_num_bits_n-1 downto 0);
 signal toggle           :  STD_LOGIC := '0';
 signal modmult          :  STD_LOGIC_VECTOR(c_num_bits_n-1 downto 0);

begin

uut : montgomery GENERIC MAP (
num_bits_ab => c_num_bits_ab,
num_bits_n => C_num_bits_n)
PORT MAP (
           mclk => mclk,
           a => a,
           b => b,
           n => n,
           toggle => toggle,
           modmult => modmult);
           
clk_proc : process
BEGIN
    mclk <= '0';
    wait for c_period/2;
    mclk <= '1';
    wait for c_period/2;
end process clk_proc;

stim_proc : process
BEGIn
    
    wait for 20 ns;
    
    a <= "0100";
    wait for 20 ns;
    b <= "1000";
    wait for 20 ns;
    n <= "00001010";
    wait for 20 ns;
    toggle <= '1';
    wait for 40 ns;
    toggle <= '0';
    
    wait;

end process stim_proc;
    
end testbench;
