----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/28/2019 02:11:30 PM
-- Design Name: 
-- Module Name: modexp_tb - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity modexp_tb is
end modexp_tb;

architecture testbench of modexp_tb is

component modexp is
    GENERIC(num_bits :integer := 8);
     Port (mclk      :     in  STD_LOGIC;
          en        :     in  STD_LOGIC;
          x         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          y         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          p         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          ----------------------------------------------------------
          mod_exp   :     out STD_LOGIC_VECTOR(num_bits-1 downto 0);
          done      :     out STD_LOGIC);
end component;


constant c_num_bits   : integer := 4;
signal mclk, done, en : STD_LOGIC := '0';
signal x, y, p , mod_exp : STD_LOGIC_VECTOR(c_num_bits-1 downto 0) := (others => '0'); 
   

begin

uut : modexp GENERIC MAP (
      num_bits => c_num_bits) 
      PORT MAP(
      mclk => mclk,
      en => en,
      x => x,
      y => y,
      p => p,
      mod_exp => mod_exp,
      done => done);
      
clk_proc : process
BEGIN
    mclk <= '0';
    wait for 5ns;
    mclk <= '1';
    wait for 5ns;
end process clk_proc;

stim_proc : process
begin
    wait for 10 ns;
    x <= "0111";
    y <= "0110";
    p <= "1000";
    wait for 20 ns;
    en <= '1';
    wait for 20 ns;
    en <= '0'; 
    
    wait;
end process stim_proc; 
    


end testbench;
