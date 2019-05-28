library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity extgcd is
	
	GENERIC( data_size  : integer := 8); -- set for test key
	PORT (	clk 		:   in STD_LOGIC;
			new_data 	:   in STD_LOGIC;
			a_in 		:   in STD_LOGIC_VECTOR(data_size - 1 downto 0);  --  phi of n
			b_in 		:   in STD_LOGIC_VECTOR(data_size - 1 downto 0);  --  public key 'e'
			-----------------------------------------------------------
			done 		: 	out STD_LOGIC;
			g_out 		: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
			x_out 		: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
			y_out 		: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0));

end extgcd;

architecture Behavioral of extgcd is

type state_type is (nop, divide, hold, check);
signal current_state, next_state : state_type := nop;

signal a, b, g, r, q: UNSIGNED(data_size -1 downto 0) :=  (others => '0');  		-- To compute gcd
signal y : SIGNED(data_size -1 downto 0) :=  (others => '0');               		-- Extended portion
signal x : SIGNED(data_size -1 downto 0) :=  (0 => '1', others => '0');    			-- Extended portion
signal mult_y : SIGNED((data_size * 2) -1 downto 0) := (others => '0'); 	-- large bit signal
                                                                            		-- used for multiplication

signal mod_en, load_en, output_en, iterate_en, fetch_en : STD_LOGIC := '0';			-- Enable signals
    

-- Interface with modulus component
signal mod_data, mod_finished: STD_LOGIC;
signal a_mod, b_mod, q_out, r_out : STD_LOGIC_VECTOR(data_size -1 downto 0);


-- Computes a / b = q remainder r.
component modulus
	GENERIC( data_size  : integer := 8); -- set for test key
    PORT (clk 		: 	in STD_LOGIC;
          a_in 		: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0); -- a should be >= b
		  b_in  	: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  new_data	: 	in STD_LOGIC;
		  done 		: 	out STD_LOGIC;
		  q_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  r_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0));
end component;

begin

mod_component: modulus port map(
	clk => clk,
	a_in => a_mod,
	b_in => b_mod,
	new_data => mod_data,
	done => mod_finished,
	q_out => q_out,
	r_out => r_out);

nextStateLogic: process(current_state, new_data, mod_finished)
begin
    
    next_state <= current_state;
	
	load_en <= '0';
	mod_en <= '0';
	output_en <= '0';
	iterate_en <= '0';
	fetch_en <= '0';

	
	case (current_state) is
		
		when nop =>
			
			if new_data = '1' then
				load_en <= '1';
				next_state <= divide;
			end if;
	
		when divide =>

			mod_en <= '1';
			next_state <= hold;

		when hold =>

			if mod_finished = '1' then
				fetch_en <= '1';
				next_state <= check;
			end if;

        
        when check =>

			if r = 0 then
				output_en <= '1';
				next_state <= nop;
			else
				iterate_en <= '1';
				next_state <= divide;
			end if;

     end case;

end process nextStateLogic;
    
state_update: process(clk)
begin
	if rising_edge(clk) then
        current_state <= next_state;
	end if;
end process state_update;


gcd_datapath: process(clk)
begin
	if rising_edge(clk) then
		
		-- Reset monopulse mod operations:
		mod_data <= '0';
		y <= mult_y(7 downto 0);
		
		if load_en = '1' then
			done <= '0';
			a <= UNSIGNED(a_in);
			b <= UNSIGNED(b_in);
			y <= (others => '0');  		  -- reset x & y values
			x <= (0 => '1', others => '0');

        end if;

		if mod_en = '1' then

			-- load data into mod_component
			a_mod <= STD_LOGIC_VECTOR(a);
			b_mod <= STD_LOGIC_VECTOR(b);
			mod_data <= '1';

		end if;

		if fetch_en = '1' then

			q <= UNSIGNED(q_out);
			r <= UNSIGNED(r_out);

		end if;

		if iterate_en = '1' then

			-- find gcd(b,r) recursively until gcd is reached
			a <= b;
			b <= r;

			-- Continue euclid's extended algorithm to find x & y
			x <= y;
			mult_y <= x - (SIGNED(q) * y);

		end if;
			

		if output_en = '1' then
			-- compute x and y one more time:
			x <= y;
			mult_y <= x - (SIGNED(q) * y);
			g <= b; -- a if finally divisiable by b, thus b is the gcd
			done <= '1';
			-- NOTE: (y mod phi of n gives secret key d)
		end if;
	end if;

end process gcd_datapath;

g_out <= STD_LOGIC_VECTOR(g);
x_out <= STD_LOGIC_VECTOR(x);
y_out <= STD_LOGIC_VECTOR(y);

end Behavioral;
