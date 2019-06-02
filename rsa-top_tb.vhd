
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

entity rsatop_tb is
	GENERIC(key_size	: integer := 32);
end rsatop_tb;

architecture testbench of rsatop_tb is

component rsatop is
	Generic ( key_size : integer := 32);
	 Port ( Clk : in  STD_LOGIC;					-- 100 MHz board clock
           
		   RsRx  : in  STD_LOGIC;				-- Rx input
		   RsTx  : out  STD_LOGIC;

		   gen_key : in STD_LOGIC; 				-- push-button mp signal to generate a key
		   key_ready : out STD_LOGIC;
		   encrypt_start : out STD_LOGIC := '0';
		   decrypt_start : out STD_LOGIC := '0';

		   -- Seven segment display (one digit)
           seg : out STD_LOGIC_VECTOR (0 to 6);
		   dp : out std_logic;
           an : out std_logic_vector(3 downto 0)
		   );				-- Tx output
end component;

signal clk, RsRx, RsTx, gen_key, key_ready, encrypt_start, decrypt_start : STD_LOGIC := '0';
signal clk_period : time := 10 ns;


begin

uut: rsatop
GENERIC MAP ( key_size => key_size)
PORT MAP( clk => clk,
		  RsRx => RsRx,
		  RsTx => RsTx,

		  -- Test variables
		  gen_key => gen_key,
		  key_ready => key_ready,
		  encrypt_start => encrypt_start,
		  decrypt_start => decrypt_start,
		  seg => open,
		  dp => open,
		  an => open);

clk_proc : process
BEGIN
    clk <= '0';
    wait for 5 ns;
    
    clk <= '1';
    wait for 5 ns;
end process clk_proc;

stim_proc : process
begin

    RsRx <= '1';
	gen_key <= '1';
	wait for clk_period * 3;
	gen_key <= '0';

	wait for 100 ms;

    wait;


end process stim_proc;

end testbench;
