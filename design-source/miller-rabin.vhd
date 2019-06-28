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
			prime_out 	: 	out STD_LOGIC;
			done 		: 	out STD_LOGIC);

end prime_test;

architecture Behavioral of prime_test is

type state_type is (nop, hold_rand, half, trial, hold_modmult, hold_modmult2, v_test, output);
signal current_state, next_state : state_type := nop;
signal s, num, v, t, i: UNSIGNED(data_size -1 downto 0) :=  (others => '0'); 	-- set all values to num_bits for simplicity
																					-- in performing operations

signal one : UNSIGNED(data_size -1 downto 0) :=  (0 => '1', others => '0') ; 		-- represent the number 1
signal two : UNSIGNED(data_size -1 downto 0) :=  (0 => '0', 1 => '1', others => '0') ; 		-- represent the number 2


signal v_vec, x_vec, y_vec, mod_vec : STD_LOGIC_VECTOR(data_size -1 downto 0) := (others => '0');

-- To hold random numbers needed for this operation:
type array_type is array(0 to num_tries - 1) of STD_LOGIC_VECTOR(data_size -1 downto 0);
signal rand_array : array_type := (others => (others => '0')); -- init with all 0s
signal try_num : integer := 0;	-- array index


-- Enable and other signals
signal load_en, fetch_rands, fetch_modexp, half_en, outer_loop_en, inner_loop_en, output_en, not_prime_en: STD_LOGIC := '0';
signal s_odd, v_ready : STD_LOGIC := '0';
signal prime : STD_LOGIC := '1';


-- Interface with modulus component
signal modexp_en, modexp_done: STD_LOGIC := '0';


-- Interface with LSFR component
signal rand_en, rand_en_en, seed_en, seed_en_en : STD_LOGIC := '0';
signal rand_num : STD_LOGIC_VECTOR(data_size -1 downto 0) := (others => '0');


-- computes x^y mod p
component modexp2
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


component LFSR
	GENERIC( num_bits : integer := data_size);
	PORT( clk 		: in STD_LOGIC;
		  enable 	: in STD_LOGIC;
		  seed 		: in STD_LOGIC_VECTOR(data_size -1 downto 0);
		  seed_en 	: in STD_LOGIC;
		  data 		: out STD_LOGIC_VECTOR(data_size -1 downto 0);
		  data_done : out STD_LOGIC);
end component;


begin

modexp_component: modexp2 
generic map(
    num_bits => data_size)
port map(
	clk => clk,
	en => modexp_en,
	x => x_vec,
	y => y_vec,
	p => mod_vec,
	mod_exp => v_vec,
	done => modexp_done);


random_generator: LFSR
generic map(
    num_bits => data_size)
port map(
	clk => clk,
	enable => rand_en,
	seed => seed,
	seed_en => seed_en,
	data => rand_num,
	data_done => open); -- unnessesary, since we will only ever be grabbing 7 values
						-- and thus won't ever run out for one given seed



nextStateLogic: process(current_state, en, try_num, s_odd, v_ready, v, one, num, i, t)
begin
    
    next_state <= current_state;
	load_en <= '0';
	fetch_rands <= '0';
	half_en <= '0';
	outer_loop_en <= '0';
	inner_loop_en <= '0';
	output_en <= '0';
	not_prime_en <= '0';
	
	seed_en_en <= '0';
	
	case (current_state) is

		when nop =>

			if en = '1' then
				load_en <= '1';
				rand_en_en <= '1'; -- set up random number generator
				seed_en_en <= '1';
				next_state <= hold_rand;
			end if;

		when hold_rand =>

			if  try_num < num_tries then
				fetch_rands <= '1';
			else
			    rand_en_en <= '0';
				next_state <= half; 	-- NOTE this is not the correct next state. used for testing only
			end if;

		when half =>

			if s_odd = '0' then
				half_en <= '1';
			else
				next_state <= trial;
			end if;

		when trial =>

			if try_num < num_tries then
				next_state <= hold_modmult;
				outer_loop_en <= '1';
			else
				next_state <= output;
			end if;

		when hold_modmult =>

			if v_ready = '1' then
				if v > one then
					next_state <= v_test;
				else
					next_state <= trial;
				end if;
			end if;


		when v_test => 

			if v /= (num - 1) then
			
			    if i = t - 1 then 
			        not_prime_en <= '1';
				    next_state <= output;
				else
					inner_loop_en <= '1';
				    next_state <= hold_modmult2;
				end if;
			
			else 
				next_state <= trial;

			end if;

		when hold_modmult2 =>

			if v_ready = '1' then
				next_state <= v_test;
			end if;

		when output => 
			output_en <= '1';
			next_state <= nop;


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

		-- defaults:
		modexp_en <= '0';
		v_ready <= '0';
		done <= '0';
		seed_en <= '0';
		
		if rand_en_en = '1' then
		   rand_en <= '1';
		else
		   rand_en <= '0';
		end if;
		
		if seed_en_en = '1' then
		   seed_en <= '1';
		end if;
		
		-- allows for one clock cycle delay, for v to be updated
		if modexp_done = '1' then
		   v_ready <= '1';
		end if;

		if load_en = '1' then
			-- set defaults
			num <= UNSIGNED(num_in);
			s <=  UNSIGNED(num_in) - 1;
			t <= (others => '0');
			try_num <= 0;
			s_odd <= '0';
			prime <= '1';
			done <= '0';

		end if;

		if fetch_rands = '1' then
			if (unsigned(rand_num) > one) and (unsigned(rand_num) < num) then
				rand_array(try_num) <= rand_num;
				try_num <= try_num + 1;
			end if;
		end if;

		if half_en = '1' then

			try_num <= 0; --reset count for the outer loop

			if s(0) = '0' then
				s <= '0' & s(s'left downto 1); -- divide by 2
				t <= t + 1;	-- increment t
			else
				s_odd <= '1';
			end if;
		end if;

		if outer_loop_en = '1' then

		    x_vec <= rand_array(try_num); -- a
			y_vec <= STD_LOGIC_VECTOR(s); -- s
			mod_vec <= STD_LOGIC_VECTOR(num); -- n

			modexp_en <= '1';       -- compute a^s mod num

			try_num <= try_num + 1;
			i <= (others => '0'); -- reset i after each loop

		end if;

		if inner_loop_en = '1' then
			
--			if i = t - 1 then
--				prime <= '0';
--			else

				i <= i + 1;

				-- perform v = v^2 mod num
				x_vec <= v_vec;
				y_vec <= STD_LOGIC_VECTOR(two);
				mod_vec <= STD_LOGIC_VECTOR(num);
				modexp_en <= '1';

--			end if;
		end if;
		
		if not_prime_en = '1' then
		   prime <= '0';
		end if;

		if output_en = '1' then
			prime_out <= prime;
			done <= '1';
		end if;
		
	end if;
end process datapath;

v <= UNSIGNED(v_vec);



end Behavioral;
