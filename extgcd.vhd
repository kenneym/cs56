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

type state_type is (nop, divide, hold, check, update_xy);
signal current_state, next_state : state_type := nop;

signal a, b, r, pad : UNSIGNED(data_size -1 downto 0) :=  (others => '0');  		-- To compute gcd
signal x : SIGNED(data_size * 2 -1 downto 0) :=  (others => '0');               	-- Extended portion
signal y : SIGNED(data_size * 2 -1 downto 0) :=  (0 => '1', others => '0');    		-- Extended portion
signal prev_x : SIGNED(data_size * 2 -1 downto 0) :=  (0 => '1', others => '0');    -- Extended portion
signal prev_y : SIGNED(data_size * 2 -1 downto 0) :=  (others => '0');              -- Extended portion
signal mult_x : SIGNED((data_size * 4) -1 downto 0) := (others => '0');     		-- large bit signals
signal mult_y : SIGNED((data_size * 4) -1 downto 0) := (0 => '1', others => '0');   -- large bit signals

signal q : UNSIGNED(data_size * 2 -1 downto 0) :=  (others => '0');

                                                                            		-- used for multiplication

signal mod_en, load_en, output_en, iterate_en, fetch_en, update_en: STD_LOGIC := '0';			-- Enable signals
    

-- Interface with modulus component
signal mod_data, mod_finished: STD_LOGIC;
signal a_mod, b_mod, q_out, r_out : STD_LOGIC_VECTOR(data_size -1 downto 0);





-- Computes a / b = q remainder r.
component modulus
	GENERIC( data_size  : integer := data_size); -- set for test key
    PORT (clk 		: 	in STD_LOGIC;
          a_in 		: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0); -- a should be >= b
		  b_in  	: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  new_data	: 	in STD_LOGIC;
		  done 		: 	out STD_LOGIC;
		  q_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  r_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0));
end component;

begin

mod_component: modulus
generic map(
    data_size => data_size)
port map(
	clk => clk,
	a_in => a_mod,
	b_in => b_mod,
	new_data => mod_data,
	done => mod_finished,
	q_out => q_out,
	r_out => r_out);

nextStateLogic: process(current_state, new_data, mod_finished, r)
begin
    
    next_state <= current_state;
	
	load_en <= '0';
	mod_en <= '0';
	output_en <= '0';
	iterate_en <= '0';
	fetch_en <= '0';
	update_en <= '0';

	
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
				next_state <= update_xy;
			end if;
			
		when update_xy =>
		    update_en <= '1';
		    next_state <= divide;

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
		done <= '0';
--		y <= mult_y(mult_y'left) & mult_y(y'left - 1 downto 0);
        
        if update_en = '1' then
		    x <= resize(mult_x, data_size * 2);
		    y <= resize(mult_y, data_size * 2);
		end if;
		
		if load_en = '1' then
			done <= '0';
			a <= UNSIGNED(a_in);
			b <= UNSIGNED(b_in);

			x <= (others => '0');  		  -- reset x & y values
			prev_x <= (0 => '1', others => '0');
			mult_x <= (others => '0');

			y <= (0 => '1', others => '0');
			prev_y <= (others => '0');
			mult_y <= (0 => '1', others => '0');

        end if;

		if mod_en = '1' then

			-- load data into mod_component
			a_mod <= STD_LOGIC_VECTOR(a);
			b_mod <= STD_LOGIC_VECTOR(b);
			mod_data <= '1';

		end if;

		if fetch_en = '1' then

			q <= pad & UNSIGNED(q_out);
			r <= UNSIGNED(r_out);

		end if;

		if iterate_en = '1' then

			-- find gcd(b,r) recursively until gcd is reached
			a <= b;
			b <= r;

			-- Continue euclid's extended algorithm to find x & y
			prev_x <= x;
			prev_y <= y;
			mult_x <= prev_x - (SIGNED(q) * x);
			mult_y <= prev_y - (SIGNED(q) * y);

		end if;
			

		if output_en = '1' then

			g_out <= STD_LOGIC_VECTOR(b); -- a if finally divisiable by b, thus b is the gcd
			x_out <= STD_LOGIC_VECTOR(RESIZE(x, data_size));
			y_out <= STD_LOGIC_VECTOR(RESIZE(y, data_size));


			done <= '1';
			-- NOTE: (y mod phi of n gives secret key d)

		end if;
	end if;

end process gcd_datapath;


end Behavioral;
