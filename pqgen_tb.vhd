library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pqgen_tb is
end pqgen_tb;

architecture testbench of pqgen_tb is

component pqgen is
 Generic(num_bits    :   integer := 8);
    Port ( clk          : in STD_LOGIC;
           en           : in STD_LOGIC;
           seed_dad     : in STD_LOGIC_VECTOR(num_bits-1 downto 0);
           ---------------------------------------------------------
           p            : out STD_LOGIC_VECTOR (num_bits-1 downto 0);
           q            : out STD_LOGIC_VECTOR (num_bits-1 downto 0);
           done         : out STD_LOGIC                            );
end component;

constant c_num_bits :           integer := 8;
constant c_period   :           time    := 10ns;

signal clk          :           STD_LOGIC := '0';
signal en           :           STD_LOGIC := '0';
signal seed_dad     :           STD_LOGIC_VECTOR(c_num_bits-1 downto 0);
signal p            :           STD_LOGIC_VECTOR(c_num_bits-1 downto 0);
signal q            :           STD_LOGIC_VECTOR(c_num_bits-1 downto 0);
signal done         :           STD_LOGIC := '0';

begin

uut: pqgen GENERIC MAP ( num_bits => c_num_bits)
    PORT MAP(
    clk => clk,
    en => en,
    seed_dad => seed_dad,
    p => p,
    q => q,
    done => done);
    
    
clk_proc : process
BEGIN

    clk <= '0';
    wait for c_period/2;
    
    clk <= '1';
    wait for c_period/2;
end process clk_proc;

stim_proc : process
BEGIN
    wait for c_period;
    seed_dad <= "00001001";
    en <= '1';
    wait for c_period;
    
    en <= '0';
    wait;

end process stim_proc;
    
end testbench;