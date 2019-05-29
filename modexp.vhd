----------------------------------------------------------------------------------
-- Engineers: Matt Kenney and Jake Epstein
-- 
-- Create Date: 05/26/2019 
-- Design Name: 
-- Module Name: modular exponentiation - Behavioral
-- Project Name: CS56 Final Project
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity modexp is
    generic (
    num_bits    :   integer := 8);
    
    Port (mclk      :     in  STD_LOGIC;
          en        :     in  STD_LOGIC;
          x         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          y         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          p         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          ----------------------------------------------------------
          mod_exp   :     out STD_LOGIC_VECTOR(num_bits-1 downto 0);
          done      :     out STD_LOGIC);
end modexp;

architecture Behavioral of modexp is

type state_type is (nop, check, shift, modu, hold);
signal current_state, next_state : state_type := nop;

signal x_c, y_c, p_c, y_c_zero, res, res_out      :       UNSIGNED(num_bits-1 downto 0) := (others => '0');

signal mod_en, load_en, output_en, iterate_en, fetch_en, res_en, sh_en, mul_en, h_load, o_done, res2res, res_set, x2x, x_set: STD_LOGIC := '0';			-- Enable signals
    

-- Interface with modulus component
signal mod_data, mod_finished: STD_LOGIC;

signal b_mod, q_out, r_out, b_mod_temp, r_out_temp : STD_LOGIC_VECTOR(2*num_bits -1 downto 0);
signal a_mod                           : STD_LOGIC_VECTOR(2*num_bits-1 downto 0);

signal a_mod_temp : UNSIGNED(2*num_bits-1 downto 0);


-- Computes a / b = q remainder r.
component modulus
	GENERIC(data_size  : integer := 2*num_bits); -- set for test key
    PORT (clk 		: 	in STD_LOGIC;
          a_in 		: 	in STD_LOGIC_VECTOR(2*num_bits -1  downto 0); -- a should be >= b
		  b_in  	: 	in STD_LOGIC_VECTOR(2*num_bits - 1 downto 0);
		  new_data	: 	in STD_LOGIC;
		  ---------------------------------------------------------
		  done 		: 	out STD_LOGIC;
		  q_out 	: 	out STD_LOGIC_VECTOR(2*num_bits - 1 downto 0);
		  r_out 	: 	out STD_LOGIC_VECTOR(2*num_bits - 1 downto 0));
end component;

begin

mod_component: modulus port map(
	clk => mclk,
	a_in => a_mod,
	b_in => b_mod,
	new_data => mod_data,
	done => mod_finished,
	q_out => q_out,
	r_out => r_out);
	
nextStateLogic: process(current_state, en, mod_finished, res2res, x2x, o_done, y_c, y_c_zero)
begin

next_state <= current_state;
load_en <= '0';
mod_en <= '0';
fetch_en <= '0';
res_en <= '0';
sh_en <= '0';
mul_en <= '0';
h_load <= '0';
output_en <= '0';
res_set <= '0';
x_set <= '0';

case(current_state) is
    when nop =>
    if en ='1' then
        load_en <= '1';
        next_state <= hold;
        x2x <= '1';
    end if;
        
    when modu =>
        mod_en <= '1';
        if (mod_finished = '1') then
            fetch_en <= '1';
            if res2res = '1' then
                res_set <= '1';
            end if;
            if x2x = '1' then
                x_set <= '1';
            end if;
            next_state <= check;
        end if;
        
  when check =>
    --while y > 0
    res2res <= '0';
    x2x <= '0';
  if o_done = '0' then
    if y_c > y_c_zero then
        -- if y is odd
        if (y_c(0) = '1') then
            res_en <= '1';
            res2res <= '1';
            next_state <= hold;
            o_done <= '1';
        end if;
        next_state <= shift;
   end if;
     next_state <= nop; 
    else
        output_en <= '1';
        next_state <= nop;
    end if;
    
    when shift =>
        --shift y (y=y/2)
        sh_en <= '1';
        mul_en <= '1';
        x2x <= '1';
        o_done <= '0';
        next_state <= hold;
        
    when hold =>
        h_load <= '1';
        next_state <= modu;
        
end case;
end process nextStateLogic;
	
stateUpdate : process(mclk)
begin
    if rising_edge(mclk) then
        current_state <= next_state;
    end if;
end process stateUpdate;

modexpDataPath : process(mclk)
begin
    if rising_edge(mclk) then
        if h_load = '1' then
            a_mod <= STD_LOGIC_VECTOR(a_mod_temp);
            b_mod <= STD_LOGIC_VECTOR(y_c_zero & p_c);
        end if;
        if sh_en = '1' then
            y_c <= '0' & y_c(y_c'left downto 1);
        end if;
        if mul_en = '1' then
            a_mod_temp <= x_c * x_c;
           -- x2x <= '1';
        end if;
        if load_en = '1' then
            y_c <= UNSIGNED(y);
            x_c <= UNSIGNED(x);
            p_c <= UNSIGNED(p);
            a_mod_temp <= UNSIGNED(y_c_zero) & UNSIGNED(x);
        end if;
        if fetch_en = '1' then
            r_out_temp <= r_out;
        end if;
        if res_en = '1' then
            a_mod_temp <= res * x_c;
        end if;
        if mod_en = '1' then
            mod_data <= '1';
        end if;
        if res_set = '1' then
            res <= unsigned(r_out(num_bits-1 downto 0));
            res2res <= '0';
        end if;
        if x_set = '1' then
            x_c <= unsigned(r_out(num_bits-1 downto 0));
            res2res <= '0';
        end if;
        if output_en = '1' then
            res_out <= res;
            done <= '1';
        end if;   
    end if;
end process modexpDataPath;
mod_exp <= STD_LOGIC_VECTOR(res);
end Behavioral;