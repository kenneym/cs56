library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity modexp2_tb is
end modexp2_tb;

architecture testbench of modexp2_tb is

component modexp2 is
    GENERIC(num_bits :integer := 8);
     Port (clk      :     in  STD_LOGIC;
          en        :     in  STD_LOGIC;
          x         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          y         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          p         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          ----------------------------------------------------------
          mod_exp   :     out STD_LOGIC_VECTOR(num_bits-1 downto 0);
          done      :     out STD_LOGIC);
end component;


constant c_num_bits   : integer := 4;
signal clk, done, en : STD_LOGIC := '0';
signal x, y, p , mod_exp : STD_LOGIC_VECTOR(c_num_bits-1 downto 0) := (others => '0'); 
   

begin

uut : modexp2 GENERIC MAP (
      num_bits => c_num_bits) 
      PORT MAP(
      clk => clk,
      en => en,
      x => x,
      y => y,
      p => p,
      mod_exp => mod_exp,
      done => done);
      
clk_proc : process
BEGIN
    clk <= '0';
    wait for 5ns;
    clk <= '1';
    wait for 5ns;
end process clk_proc;

stim_proc : process
begin
    wait for 10 ns;
    x <= "0101";
    y <= "0111";
    p <= "1101";
    wait for 20 ns;
    en <= '1';
    wait for 20 ns;
    en <= '0'; 
    
    wait;
end process stim_proc; 
    


end testbench;
