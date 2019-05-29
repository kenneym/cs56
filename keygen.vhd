library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY keygen is
	
	GENERIC(key_size	: integer := 16);

	PORT (  clk			:	in STD_LOGIC;
			new_data	:	in STD_LOGIC;
			prime_p		:	in STD_LOGIC_VECTOR((key_size / 2) downto 0);
			prime_q		:	in STD_LOGIC_VECTOR((key_size / 2) downto 0);
			n 			: 	out STD_LOGIC_VECTOR(key_size downto 0);
			e 			:	out STD_LOGIC_VECTOR(key_size downto 0);
			d 			:	out STD_LOGIC_VECTOR(key_size downto 0));
end keygen;


ARCHITECTURE behavioral of keygen is


begin


end behavioral;
