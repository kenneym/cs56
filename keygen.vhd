library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY keygen is
	
	GENERIC(key_size	: integer := 16);

	PORT (  clk			:	in STD_LOGIC;
			en			:	in STD_LOGIC;
			seed_in		: 	in STD_LOGIC_VECTOR(key_size -1 downto 0);
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
signal pqgen_en, pqgen_done : STD_LOGIC := '0';
signal p, q : STD_LOGIC_VECTOR((key_size / 2) -1 downto 0);
--signal test_p : STD_LOGIC_VECTOR((key_size / 2) -1 downto 0) := "10001001"; -- 137
--signal test_q : STD_LOGIC_VECTOR((key_size / 2) -1 downto 0) := "10111111"; -- 191


-- Interface with extgcd components
signal extgcd_en, extgcd_done : STD_LOGIC := '0';
signal phi_n, e, gcd, y : STD_LOGIC_VECTOR(key_size - 1 downto 0);


-- Interface with mod
signal mod_en, mod_done : STD_LOGIC := '0';
signal d : STD_LOGIC_VECTOR(key_size -1 downto 0);


-- Interface with LSFR Random number generator
signal rand_en, seed_en, rand_done: STD_LOGIC := '0';
signal seed : STD_LOGIC_VECTOR(key_size - 1 downto 0);


-- FSM:
-- hold is a generic state to wait for modules to complete
type state_type is (nop, gen_pq, hold, compute_n, try_e, test_e);
signal current_state, next_state : state_type := nop;
signal load_en, compute_n_en: STD_LOGIC := '0'; -- enable signals 
signal reset_seed : STD_LOGIC := '1'; 			-- misc. internal control signals



-- Interface
begin
	pq_generator : pqgen 
	generic map(
	    num_bits => (key_size / 2))
	port map(
		clk => clk,
		en => pqgen_en,
		p => p,
		q => q,
		done => pqgen_done);


	rand_generator : LFSR
	generic map(
	    num_bits => key_size)
	port map(
		clk => clk,
		enable => rand_en,
		seed => seed,
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
		a_in => y,
		b_in => phi_n,
		new_data => mod_en,
		done => mod_done,
		q_out => open,
		r_out => d); 				-- y produced from extgcd algorithm produces secret key when moded by phi_n


	next_state_logic: process(current_state, load_en, pqgen_done)
	begin

		next_state <= current_state;

		pqgen_en <= '0';
		rand_en <= '0';
		seed_en <= '0';
		compute_n_en <= '0';

		case(current_state) is

			when nop =>
				if en = '1' then
					load_en <= '1';
					next_state <= gen_pq;
				end if;

			when gen_pq => 
				pqgen_en <= '1';
				next_state <= hold;

			when hold =>
				if pqgen_done = '1' then
					next_state <= compute_n;
				end if;

			when compute_n => 
				compute_n_en <= '1';
				next_state <= try_e;

			when try_e =>
				rand_en <= '1';
				if reset_seed = '1' then
					seed_en <= '1';
				end if;

				next_state <= test_e;

			when test_e =>


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

			-- capture monopulse done signal for later (more convenient for this code)
			if rand_done = '1' then
				reset_seed <= '1';
				seed <= STD_LOGIC_VECTOR(UNSIGNED(seed) + UNSIGNED(e)); -- add current random number to past seed to get a new seed
			end if;
			
			if seed_en = '1' then
			    reset_seed <= '0';
			end if;

			if load_en = '1' then
				seed <= seed_in;
				reset_seed <= '1'; -- reset the seed each time the keygen module is used
			end if;

		end if;
	end process datapath;


end Behavioral;
















