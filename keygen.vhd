library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY keygen is
	
	GENERIC(key_size	: integer := 16);

	PORT (  clk			:	in STD_LOGIC;
			new_data	:	in STD_LOGIC;
			n 			: 	out STD_LOGIC_VECTOR(key_size downto 0);
			e 			:	out STD_LOGIC_VECTOR(key_size downto 0);
			d 			:	out STD_LOGIC_VECTOR(key_size downto 0));
end keygen;


ARCHITECTURE behavioral of keygen is
	
	component pqgen is
    	Generic(num_bits    :   integer := (key_size / 2));
    	Port ( clk          : in STD_LOGIC;
    	       en           : in STD_LOGIC;
    	       ---------------------------------------------------------
    	       p            : out STD_LOGIC_VECTOR (num_bits-1 downto 0);
    	       q            : out STD_LOGIC_VECTOR (num_bits-1 downto 0);
    	       done         : out STD_LOGIC);
	end component;


	component extgcd is
		GENERIC( data_size  : integer := key_size); -- set for test key
		PORT (	clk 		:   in STD_LOGIC;
				new_data 	:   in STD_LOGIC;
				a_in 		:   in STD_LOGIC_VECTOR(data_size - 1 downto 0);  --  phi of n
				b_in 		:   in STD_LOGIC_VECTOR(data_size - 1 downto 0);  --  public key 'e'
				-----------------------------------------------------------
				done 		: 	out STD_LOGIC;
				g_out 		: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
				x_out 		: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
				y_out 		: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0));
	end component;


	component modulus is

		GENERIC(data_size  : integer := key_size); -- set for test key
		
		-- Computes a / b = q remainder r.
    	PORT (clk 		: 	in STD_LOGIC;
    	      a_in 		: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0); -- a should be >= b
			  b_in  	: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0);
			  new_data	: 	in STD_LOGIC;
			  ---------------------------------------------------------
			  done 		: 	out STD_LOGIC;
			  q_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
			  r_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0));
			
	end component;


-- Interface with pqgen component
signal pqgen_en, pqgen_done : STD_LOGIC := '0';
signal p, q : STD_LOGIC_VECTOR((key_size / 2) -1 downto 0);
signal test_p : STD_LOGIC_VECTOR((key_size / 2) -1 downto 0) := "10001001"; -- 137
signal test_q : STD_LOGIC_VECTOR((key_size / 2) -1 downto 0) := "10111111"; -- 191


-- Interface with extgcd
signal extgcd_en, extgcd_en, 

-- Interface
begin
	
	pqgenerator : pqgen port map(
		clk => clk,
		en => pqgen_en,
		p => p,
		q => q,
		done => done);


	extgcd : extgcd port map(
		clk => clk,





end behavioral;
