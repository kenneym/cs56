library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LSFR_tb is
end LSFR_tb;

architecture testbench of LSFR_tb is

component LFSR is
 generic (num_bits : integer := 8);
 port ( clk : in STD_LOGIC;
        enable : in STD_LOGIC;
        seed : in STD_LOGIC_VECTOR(num_bits - 1 downto 0);
        seed_en : in STD_LOGIC;
        data : out STD_LOGIC_VECTOR(num_bits -1 downto 0);
        data_done : out STD_LOGIC
        );
end component;

constant c_num_bits :       integer := 4;
constant c_period   :       time    := 40ns;

signal clk          :       STD_LOGIC := '0';
signal enable       :       STD_LOGIC := '0';
signal seed         :       STD_LOGIC_VECTOR(c_num_bits-1 downto 0);
signal seed_en      :       STD_LOGIC  := '0';
signal data         :       STD_LOGIC_VECTOR(c_num_bits-1 downto 0);
signal data_done    :       STD_LOGIC := '0';


begin


uut : LFSR GENERIC MAP (
num_bits => c_num_bits)
PORT MAP(
    clk => clk,
    enable => enable,
    seed => seed,
    seed_en => seed_en,
    data => data,
    data_done => data_done);

clk_proc : process
BEGIN
    clk <= '0';
    wait for c_period/2;
    clk <= '1';
    wait for c_period/2;
end process clk_proc;

stim_proc : process
begin
    wait for 10ns;
    enable <= '1';
    seed_en <= '1';
    seed <= "10011011";
    wait for c_period;
     seed_en <= '0';
    
    wait for 20ns;
    wait;
end process stim_proc;

end testbench;