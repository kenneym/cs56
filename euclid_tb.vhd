----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/25/2019 02:27:26 PM
-- Design Name: 
-- Module Name: euclid_tb - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity euclid_tb is
end euclid_tb;

architecture testbench of euclid_tb is

component euclid is
PORT(   mclk    :     in STD_LOGIC;
        a       :     in STD_LOGIC_VECTOR(7 downto 0);
        b       :     in STD_LOGIC_VECTOR(7 downto 0);
        toggle  :     in STD_LOGIC;
        gcd     :     out STD_LOGIC_VECTOR(7 downto 0));
end component;

signal mclk     :   STD_LOGIC := '0';
signal a        :   STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal b        :   STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal toggle   :   STD_LOGIC := '0';
signal gcd      :   STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

begin

uut: euclid PORT MAP(
     mclk => mclk,
     a => a,
     b => b,
     toggle => toggle,
     gcd => gcd);

clk_proc : process
BEGIN
    mclk <= '0';
    wait for 5ns;
    
    mclk <= '1';
    wait for 5ns;
end process clk_proc;

stim_proc : process
begin

    wait for 10ns;
    a <= "00001000";
    b <= "00001100";
    wait for 10ns;
    toggle <= '1';
    wait for 10ns;
    toggle <= '0';
    wait;
end process stim_proc;

end testbench;
