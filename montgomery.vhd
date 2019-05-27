library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity montgomery is
    Port (mclk    :     in STD_LOGIC;
          a       :     in STD_LOGIC_VECTOR(7 downto 0);
          b       :     in STD_LOGIC_VECTOR(7 downto 0);
          e       :     in STD_LOGIC_VECTOR(7 downto 0);
          n       :     in STD_LOGIC_VECTOR(7 downto 0);
          toggle  :     in STD_LOGIC;
          modexp  :     out STD_LOGIC_VECTOR(7 downto 0));
end montgomery;

architecture Behavioral of montgomery is

begin

findR: process(n, toggle, a, b, 