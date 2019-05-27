library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity extgcd is

	GENERIC( data_size  : integer := 8); -- set for test key

    PORT (mclk    :     in STD_LOGIC;
          phi_n    :     in STD_LOGIC_VECTOR(data_size - 1 downto 0); -- a should be >= b
          e    :     in STD_LOGIC_VECTOR(data_size -1 downto 0);
          toggle  :     in STD_LOGIC;
		  -----------------------------------------------------------
          g_out	  :     out STD_LOGIC_VECTOR(data_size -1 downto 0);
		  d 	  : 	out STD_LOGIC_VECTOR(data_size -1 downto 0)); -- private key d

end extgcd;

architecture Behavioral of extgcd is

type state_type is (nop, check, greater, less);
signal current_state, next_state : state_type := nop;

signal a, b, g : UNSIGNED(data_size -1 downto 0) :=  (others => '0'); 		  -- To compute gcd
signal x1, y0 : SIGNED(data_size -1 downto 0) :=  (others => '0');  		  -- Extended portion
signal x0, y1 : SIGNED(data_size -1 downto 0) :=  (0 => '1', others => '0');  -- Extended portion
signal l_en, g_en, load_en, output_en, reset_q  : STD_LOGIC := '0';			  -- Enable signals


signal a_greater, b_greater: STD_LOGIC := '0'; 								  -- Track of magnitude flips

signal push, pop, clear, full, empty : STD_LOGIC := '0';					  -- Stack interface
signal  q : SIGNED(data_size -1 downto 0) :=  (0 => '1', others => '0') ;     -- q register
signal q_in, q_out: STD_LOGIC_VECTOR(data_size -1 downto 0) := (others => '0');



begin

-- Stack to store values of q on each recursion, for later computation of x & y

nextStateLogic: process(current_state, toggle, a, b)
begin
    
    next_state <= current_state;
    
    load_en <= '0';
    l_en <= '0';
    g_en <= '0';
	reset_q <= '0';

    case (current_state) is
        when nop =>
        
        if toggle = '1' then
                load_en <= '1';
                next_state <= check;
        end if;
        
        when check =>
        
            if (a = b) then
                next_state <= nop;
                output_en <= '1';
            else
				if (a > b) then
					a_greater <= '1';
					b_greater <= '0';

					if b_greater =  '1' then
						reset_q <= '1';
					end if;

                    next_state <= greater;

				else
					a_greater <= '0';
					b_greater <= '1';

					if a_greater =  '1' then
						reset_q <= '1';
					end if;

                    next_state <= less;
                end if;
            end if;
            
        when greater =>
       		
            g_en <= '1';
            next_state <= check;
            
        when less =>

            l_en <= '1';
            next_state <= check;
        
     end case;
end process nextStateLogic;
    
state_update: process(mclk)
begin
	if rising_edge(mclk) then
        current_state <= next_state;
	end if;
end process state_update;


gcd_datapath: process(mclk)
begin
	if rising_edge(mclk) then

		-- Reset monopulse stack operations:
		push <= '0';
		pop <= '0';
		clear <= '0';

        if g_en = '1' then
            a <= a - b;
			q <= q + 1; -- increment quotient of b into a
        end if;
		
        if l_en = '1' then
            b <= b - a;
			q <= q + 1; -- increment quotient of b into a
        end if;

		if reset_q = '1' then
			x0 <= x1;
			y0 <= y1;
			x1 <= x0 - (q * x1);
			y1 <= y0 - (q * y1);
			q <= (0 => '1', others => '0') ;  -- reset q to 1
		end if;
			
		if load_en = '1' then
            a <= UNSIGNED(phi_n);
            b <= UNSIGNED(e);
			q <= (0 => '1', others => '0') ;  -- reset q to 1
			x1 <= (others => '0');  		  -- reset x & y values
			y0 <= (others => '0');
			x0 <= (0 => '1', others => '0');
			y1 <= (0 => '1', others => '0');
        end if;

        if output_en = '1' then
            g <= a;
			-- d <= y mod a -- (y mod phi of n gives secret key d)
        end if;
    
    end if;

end process gcd_datapath;

g_out <= STD_LOGIC_VECTOR(g);            

end Behavioral;
