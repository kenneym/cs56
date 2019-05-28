
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


-- Set the generic 'data_size' to the key bit-length over 2 (i.e the maximum 
-- size of public key e)
-- 16 bit test key: 8
-- 64-bit key: 32
-- 128-bit key: 64
-- 256-bit key: 128

entity extgcd is

	GENERIC( data_size  : integer := 8); -- set for test key

    PORT (mclk    :     in STD_LOGIC;
          a_in    :     in STD_LOGIC_VECTOR(data_size - 1 downto 0);
          b_in    :     in STD_LOGIC_VECTOR(data_size -1 downto 0);
          toggle  :     in STD_LOGIC;
		  -----------------------------------------------------------
          g_out	  :     out STD_LOGIC_VECTOR(data_size -1 downto 0);
		  x_out	  : 	out STD_LOGIC_VECTOR(data_size -1 downto 0);
		  y_out	  : 	out STD_LOGIC_VECTOR(data_size -1 downto 0);
	  	  err	  : 	out STD_LOGIC);

end extgcd;

architecture Behavioral of extgcd is

-- Set the bit length neccessary for the stack using the generic outputs contained in that file
component stack is
	PORT  (	clk : in STD_LOGIC;
			push : in STD_LOGIC;
			pop : in STD_LOGIC;
			clear : in STD_LOGIC;
			data_in: in STD_LOGIC_VECTOR(data_size -1 downto 0);
			----------------------------------------------
			full: out STD_LOGIC := '0';
			empty: out STD_LOGIC := '1';
			data_out : out STD_LOGIC_VECTOR(data_size -1 downto 0) );
end component stack;

type state_type is (nop, check, greater, less);
signal current_state, next_state : state_type := nop;

signal a, b, g : UNSIGNED(data_size -1 downto 0) :=  (others => '0'); 		-- To compute gcd
signal  x, y : UNSIGNED(data_size -1 downto 0) :=  (others => '0'); 		-- Extended portion
signal l_en, g_en, load_en, output_en, reset_q  : STD_LOGIC := '0';			-- Enable signals


signal a_greater, b_greater: STD_LOGIC := '0'; 								-- Track of magnitude flips

signal push, pop, clear, full, empty : STD_LOGIC := '0';					-- Stack interface
signal  q : UNSIGNED(data_size -1 downto 0) :=  (0 => '1', others => '0') ; -- q register
signal q_in, q_out: STD_LOGIC_VECTOR(data_size -1 downto 0) := (others => '0');



begin

-- Stack to store values of q on each recursion, for later computation of x & y
q_stack : stack port map(
	clk => mclk,
	push => push,
	pop => pop,
	clear => clear,
	data_in => q_in,
	data_out => q_out);


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
			q_out <= STD_LOGIC_VECTOR(q);
			q <=  (0 => '1', others => '0') ; -- reset q to 1: since we stop subtracted a from b when a = b 
											  -- (and not when a = 0), we need to add 1 to the quotient.
			
			if full = '0' then
				push <= '1'; -- push quotient into stack memory
			else
				err <= '1';
			end if;

		end if;
			
		if load_en = '1' then
            a <= UNSIGNED(a_in);
            b <= UNSIGNED(b_in);
			clear <= '1';	-- clear the quotient stack in prepartion for new computation
			q <= (0 => '1', others => '0') ;  -- reset q to 1
        end if;

        if output_en = '1' then
            g <= a;
        end if;
    
    end if;

end process gcd_datapath;



g_out <= STD_LOGIC_VECTOR(g);            

end Behavioral;
