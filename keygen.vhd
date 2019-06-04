library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY keygen is
	
	GENERIC(key_size	: integer := 16);

	PORT (  clk			:	in STD_LOGIC;
			en			:	in STD_LOGIC;
			seed_1		: 	in STD_LOGIC_VECTOR(key_size -1 downto 0);
			seed_2		: 	in STD_LOGIC_VECTOR(key_size/2 -1 downto 0);
			----------------------------------------------------------
			done 		: 	out STD_LOGIC;
			n_out 		: 	out STD_LOGIC_VECTOR(key_size -1 downto 0);
			e_out 		:	out STD_LOGIC_VECTOR(key_size -1 downto 0);
			d_out		:	out STD_LOGIC_VECTOR(key_size -1 downto 0));
end keygen;


ARCHITECTURE Behavioral of keygen is
	
	component pqgen is
    	Generic(num_bits    :   integer := (key_size / 2));
    	Port ( clk          : in STD_LOGIC;
    	       en           : in STD_LOGIC;
			   seed_dad 	: in STD_LOGIC_VECTOR(num_bits -1 downto 0);
    	       ---------------------------------------------------------
    	       p            : out STD_LOGIC_VECTOR(num_bits-1 downto 0);
    	       q            : out STD_LOGIC_VECTOR(num_bits-1 downto 0);
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

	component LFSR
		GENERIC( num_bits : integer := key_size);
		PORT( clk 		: in STD_LOGIC;
			  enable 	: in STD_LOGIC;
			  seed 		: in STD_LOGIC_VECTOR(num_bits -1 downto 0);
			  seed_en 	: in STD_LOGIC;
			  data 		: out STD_LOGIC_VECTOR(num_bits -1 downto 0);
			  data_done : out STD_LOGIC);
	end component;



-- Interface with pqgen component
signal pqgen_en, pqgen_done, new_e_en, not_compute : STD_LOGIC := '0';
signal p, q, pq_seed : STD_LOGIC_VECTOR((key_size / 2) -1 downto 0);
--signal test_p : STD_LOGIC_VECTOR((key_size / 2) -1 downto 0) := "10001001"; -- 137
--signal test_q : STD_LOGIC_VECTOR((key_size / 2) -1 downto 0) := "10111111"; -- 191


-- Interface with extgcd components
signal extgcd_en, extgcd_done : STD_LOGIC := '0';
signal phi_n, e, gcd, y : STD_LOGIC_VECTOR(key_size - 1 downto 0);
signal signed_y : SIGNED(key_size - 1 downto 0);
signal adjusted_y : STD_LOGIC_VECTOR(key_size -1 downto 0);


-- Interface with mod
signal mod_en, mod_done, try_again : STD_LOGIC := '0';
signal d : STD_LOGIC_VECTOR(key_size -1 downto 0);
signal d_final : STD_LOGIC_VECTOR(key_size -1 downto 0); -- in case of negative y values (-num mod phi_n)



-- Interface with LSFR Random number generator
signal rand_en, seed_en, rand_done: STD_LOGIC := '0';
signal rand_seed : STD_LOGIC_VECTOR(key_size - 1 downto 0);
signal rand_seed_u : UNSIGNED(key_size - 1 downto 0);


-- Additional signals
signal n : STD_LOGIC_VECTOR(key_size - 1 downto 0);
signal p_unsigned, q_unsigned : UNSIGNED((key_size / 2) -1 downto 0);
signal one : UNSIGNED((key_size / 2) -1 downto 0) :=  (0 => '1', others => '0'); 		-- represent the number 1
signal big_one : STD_LOGIC_VECTOR(key_size -1 downto 0) :=  (0 => '1', others => '0'); 		-- represent the number 1
signal signed_zero: SIGNED(key_size -1 downto 0) := (others => '0');
signal neg_1: UNSIGNED(key_size-1 downto 0) := (0 => '1', others => '0');
signal reverse_y: UNSIGNED(key_size-1 downto 0) := (others => '0');
signal all_1: STD_LOGIC_VECTOR(key_size-1 downto 0) := (others => '1');
-- FSM:
-- hold is a generic state to wait for modules to complete
type state_type is (nop, gen_pq, hold, compute_n, try_e, test_e, check_y_sign, mod_n, compute_d, output);
signal current_state, next_state : state_type := nop;
signal load_en, compute_n_en, output_en, check_y_sign_en, compute_d_en, en_pqgen, en_rand, en_seed, en_extgcd, en_mod, new_e_disable: STD_LOGIC := '0'; -- enable signals 
signal reset_seed : STD_LOGIC := '1'; 			-- misc. internal control signals
signal new_e, rand_res : STD_LOGIC := '0';



-- Interface
begin

	pq_generator : pqgen 
	generic map(
	    num_bits => (key_size / 2))
	port map(
		clk => clk,
		en => pqgen_en,
		seed_dad => pq_seed,
		p => p,
		q => q,
		done => pqgen_done);


	rand_generator : LFSR
	generic map(
	    num_bits => key_size)
	port map(
		clk => clk,
		enable => rand_en,
		seed => rand_seed,
		seed_en => seed_en,
		data => e,					-- random generated number becomes e if verified coprime with phi_n 
		data_done => rand_done);


	extgcd_find_d : extgcd 
	generic map(
	    data_size => key_size)	
	port map(
		clk => clk,
		new_data => extgcd_en,
		a_in => phi_n,
		b_in => e, 					-- try random values of e until one is coprime with phi_n.
		done => extgcd_done,
		g_out => gcd,
		x_out => open,
		y_out => y);				-- Once we find a coprime e, 
									-- extgcd algorithm produces linear map (x,y) such that x(phi_n) + y(e) = gcd(phi_n,e) = 1
									-- We can use y to compute the "multiplicative inverse mod n" of 'e': the secret key 'd'

	-- to compute y mod phi of n
	mod_component : modulus 
	generic map(
	    data_size => key_size)	
	port map(
		clk => clk,
		a_in => adjusted_y,
		b_in => phi_n,
		new_data => mod_en,
		done => mod_done,
		q_out => open,
		r_out => d); 				-- y produced from extgcd algorithm produces secret key when moded by phi_n
        

	next_state_logic: process(current_state, load_en, pqgen_done, e, new_e, extgcd_done, mod_done, en, reset_seed, phi_n, big_one, gcd, extgcd_en, seed_en, rand_en, mod_en, pqgen_en, try_again, adjusted_y)
	begin

		next_state <= current_state;

		load_en <= '0';
		compute_n_en <= '0';
		check_y_sign_en <= '0';
		compute_d_en <= '0';
		output_en <= '0';


		-- to components
		en_pqgen <= '0';
		en_mod <= '0';
		en_rand <= '0';
		en_seed <= '0';
		en_extgcd <= '0';
		new_e_disable <= '0';
		not_compute <= '0';
        rand_res <= '0';

		case(current_state) is

			when nop =>
				if en = '1' then
					load_en <= '1';
					next_state <= gen_pq;
				end if;

			when gen_pq => 
				en_pqgen <= '1';            ---
				next_state <= hold;
			
			-- generic hold state
			when hold =>

				if pqgen_done = '1' then
					next_state <= compute_n;

				elsif extgcd_done = '1' then
					next_state <= test_e;

				elsif mod_done = '1' then
					next_state <= compute_d;

				end if;
				

			when compute_n => 
				compute_n_en <= '1';
				next_state <= try_e;

			when try_e =>
				en_rand  <= '1';
				if reset_seed = '1' then
					en_seed <= '1'; --
				end if;

				next_state <= test_e;

			when test_e =>
			
			    -- wait for one clock cycle to collect random number
			    if rand_en = '0' then

				    -- if e has yet to be tested
				    if new_e = '1' then
				        new_e_disable <= '1';

					   -- enforce range
					   if (e < phi_n) and (e > big_one) then
						  en_extgcd <= '1'; --
						  next_state <= hold;
					   else
						  next_state <= try_e;
					   end if;

				    -- if we've already found gcd(e, phi_n), test it
				    else 
					   if gcd = big_one then
						  next_state <= check_y_sign;
						  check_y_sign_en <= '1';
					   else
						  next_state <= try_e;
					   end if;
				    end if;
				
				end if;

			when check_y_sign =>
				--check_y_sign_en <= '1';
				if try_again = '1' then
				    next_state <= try_e;
				else
				    next_state <= mod_n;
                end if;
			when mod_n => 
			    if (phi_n > adjusted_y) then
--			         next_state <= try_e;
			         rand_res <= '1';
			         next_state <= try_e;
			    else
				    en_mod <= '1';
				    next_state <= hold;
                end if;
			when compute_d =>
				compute_d_en <= '1';
				next_state <= output;
			
			when output =>
				output_en <= '1';
				next_state <= nop;
							

		end case;

	end process next_state_logic;


	state_update: process(clk)
	begin
		if rising_edge(clk) then
	        current_state <= next_state;
		end if;
	end process state_update;


	datapath : process(clk)
	begin
		if rising_edge(clk) then

			p_unsigned <= UNSIGNED(p);
			q_unsigned <= UNSIGNED(q);
			signed_y <= SIGNED(y);
			--reverse_y <= (UNSIGNED(all_1 XOR y) + neg_1);
			
			-- Enables to components:
		    pqgen_en <= '0';
		    mod_en <= '0';
		    rand_en <= '0';
		    seed_en <= '0';
		    extgcd_en <= '0';
		    try_again <= '0';

			-- monopulse done signal
			done <= '0';

			-- capture monopulse done signals for later (more convenient for this code)
			if rand_done = '1' then
				reset_seed <= '1';
				rand_seed <= STD_LOGIC_VECTOR(UNSIGNED(rand_seed) + UNSIGNED(e)); -- add current random number to past seed to get a new seed
			end if;
			
			if rand_res = '1' then
				reset_seed <= '1';
				rand_seed <= STD_LOGIC_VECTOR(UNSIGNED(rand_seed) + UNSIGNED(e)); -- add current random number to past seed to get a new seed
			end if;
			
			if seed_en = '1' then
			    reset_seed <= '0';
			end if;

		    -- enables interfacing with components
		    if en_pqgen = '1' then
		        pqgen_en <= '1';
		    end if;
		    
		    if not_compute = '1' then
		      d_final <= y;
		    end if;
		    
		    if en_mod = '1' then
		        mod_en <= '1';
		    end if;
		    
		    if en_rand = '1' then
		        new_e <= '1';
		        rand_en <= '1';
		    end if;
		    
		    if new_e_disable = '1' then
		        new_e <= '0';
		    end if;
		    
		    if en_seed = '1' then
		        seed_en <= '1';
		    end if;
		    
		    if en_extgcd = '1' then
		        extgcd_en <= '1';
		    end if;
		
		
		
		
			if load_en = '1' then
				n_out <= (others => '0');
				e_out <= (others => '0');
				d_out <= (others => '0');
				rand_seed <= seed_1;
				pq_seed <= seed_2;
				reset_seed <= '1';  -- reset the seed each time the keygen module is used
			end if;

			if compute_n_en = '1' then
				n <= STD_LOGIC_VECTOR(p_unsigned * q_unsigned);
				phi_n <= STD_LOGIC_VECTOR((p_unsigned - one) * (q_unsigned - one));
			end if;
			

			if check_y_sign_en = '1' then
                
				if signed_y < signed_zero then
--					adjusted_y <= STD_LOGIC_VECTOR(-signed(y));
--					adjusted_y <= STD_LOGIC_VECTOR(reverse_y);
					try_again <= '1';
				else
					adjusted_y <= y;
				end if;
			end if;


			if compute_d_en = '1' then

				d_final <= d;

				-- If y was negative, corect the value of d to account for negative mod operation
				if signed_y < signed_zero then
					d_final <= STD_LOGIC_VECTOR(UNSIGNED(phi_n) - UNSIGNED(d));
				end if;

			end if;

			if output_en = '1' then
				n_out <= n;
				e_out <= e;
				d_out <= d_final;
				done <= '1';
			end if;


		end if;
	end process datapath;


end Behavioral;



