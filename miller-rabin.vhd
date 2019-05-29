
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Employs miller rabin test for primality based on the suggested implementation in the 
-- handbook of applied cryptography, a resource leveraged by legitamate RSA codes such as those
-- found in the openssl and openssh libraries. Number of tries as input to the miller rabin 
-- function is 7, since 7 tries can deterministically determine primality for any number below 2^52
-- and determines primality with very high probabilty for numbers above 7.

-- NOTE: For the sake of simplicity we use 7 tries for all case. For actual RSA keysizes, you can use
-- a smaller number of tries (since primes are sparser at higher bit counts). Use the following number of tries for actual RSA:

-- 1024-bit key (512 bit p & q) -> tries = 6
-- 2048-bit key -> tries = 6
-- 3072 or 4096-bit key -> tries = 4

-- These entries are based on code from OpenSSL and The Federal Information Processing Standards Publication
-- on Digital Signature Standard (DSS) issued July 2013
-- OpenSSL: https://github.com/openssl/openssl
-- DSS: https://nvlpubs.nist.gov/nistpubs/fips/nist.fips.186-4.pdf


entity prime_test is
	
	GENERIC(data_size 	: integer := 8;
		    num_tries	: integer := 7); -- set for test key
	PORT (	clk 		:   in STD_LOGIC;
			en 		 	:   in STD_LOGIC;
			num_in 		:   in STD_LOGIC_VECTOR(data_size - 1 downto 0);  -- num to check for primality
			seed 		: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0);  -- seed for random number generation
			-----------------------------------------------------------
			prime 		: 	out STD_LOGIC;
			done 		: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0));

end prime_test;

architecture Behavioral of prime_test is

type state_type is (nop, hold);
signal current_state, next_state : state_type := nop;
signal a, s, num, v, t, i: UNSIGNED(data_size -1 downto 0) :=  (others => '0'); 	-- set all values to num_bits for simplicity
																					-- in performing operations

signal v_vec, a_vec, s_vec, num_vec : STD_LOGIC_VECTOR(data_size -1 downto 0) := (others => '0');

-- to hold random numbers needed for this operation:
type array_type is array(0 to num_tries -1) of STD_LOGIC_VECTOR(data_size -1 downto 0);
signal rand_array : array_type := (others => (others => '0')); -- init with all 0s
signal rands_count :  integer := 0;													-- array index



signal load_en, fetch_rands, fetch_modexp : STD_LOGIC := '0';						-- Enable Signals
    

-- Interface with modulus component
signal modexp_en, modexp_done: STD_LOGIC := '0';


-- Interface with LSFR component
signal rand_en, seed_en : STD_LOGIC := '0';
signal rand_num : STD_LOGIC_VECTOR(data_size -1 downto 0) := (others => '1');


-- computes x^y mod p
component modexp
	GENERIC( num_bits : integer := data_size); -- set for test key
    PORT (clk		: 	in STD_LOGIC;
          en 		: 	in STD_LOGIC; -- a should be >= b
		  x  		: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  y 		: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  p 		: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  ----------------------------------------------------------
		  mod_exp 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  done 		: 	out STD_LOGIC);
end component;


component LSFR
	GENERIC( num_bits : integer := data_size);
	PORT( clk 		: in STD_LOGIC;
		  enable 	: in STD_LOGIC;
		  seed 		: in STD_LOGIC_VECTOR(data_size -1 downto 0);
		  seed_en 	: in STD_LOGIC;
		  data 		: out STD_LOGIC_VECTOR(data_size -1 downto 0);
		  data_done : out STD_LOGIC);
end component;


begin

modexp_component: modexp port map(
	clk => clk,
	en => modexp_en,
	x => a_vec,
	y => s_vec,
	p => num_vec,
	mod_exp => v_vec,
	done => modexp_done);


random_generator: LSFR port map(
	clk => clk,
	enable => rand_en,
	seed => seed,
	seed_en => seed_en,
	data => rand_num,
	data_done => open); -- unnessesary, since we will only ever be grabbing 7 values
						-- and thus won't ever run out for one given seed



nextStateLogic: process(current_state, new_data, mod_finished)
begin
    
    next_state <= current_state;
	load_en <= '0';
	fetch_rands <= '0';
	
	case (current_state) is

		when nop =>

			if en = '1' then
				load_en <= '1';
				next_state <= hold;
			end if;

		when hold =>

			if rands_fetched = '0' then
				fetch_rands <= '1';
			else
				next_state <= nop; 	-- NOTE this is not the correct next state. used for testing only
			end if;

    end case;

end process nextStateLogic;
    
state_update: process(clk)
begin
	if rising_edge(clk) then
        current_state <= next_state;
	end if;
end process state_update;


datapath: process(clk)
begin
	if rising_edge(clk) then

		rand_en <= '0';
		seed_en <= '0';

		if load_en = '1' then

			-- set defaults
			num <= UNSIGNED(num_in);
			s <=  UNSIGNED(num_in) - 1;
			t <= (others => '0');

			rand_en <= '1'; -- start up random number generator
			seed_en <= '1';

		end if;

		if fetch_rands = '1'
			rand_array(rands_count) <= rand_num;


			
			
				


		
	end if;
end process datapath;

end Behavioral;
