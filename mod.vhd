----------------------------------------------------------------------------------
-- Engineers: Matt Kenney and Jake Epstein
-- 
-- Create Date: 05/26/2019 
-- Design Name: 
-- Module Name: modulus - Behavioral
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

entity modulus is

	GENERIC( data_size  : integer := 8); -- set for test key
	
	-- Computes a / b = q remainder r.
    PORT (clk 		: 	in STD_LOGIC;
          a_in 		: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0); -- a should be >= b
		  b_in  	: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  new_data	: 	in STD_LOGIC;
		  ---------------------------------------------------------
		  done 		: 	out STD_LOGIC;
		  q_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  r_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0));
		
END modulus;


ARCHITECTURE Behavioral of modulus is

type state_type is (nop,compute,output);
signal current_state, next_state : state_type := nop;
signal load_en, compute_en, output_en, compute_finshed: STD_LOGIC := '0';
signal a, b, q : UNSIGNED(data_size -1 downto 0) := (others => '0');


BEGIN

	next_state_logic: process(current_state, new_data, compute_finshed)
	begin

		next_state <= current_state;
		load_en <= '0';
		compute_en <= '0';
		output_en <= '0';

		case (current_state) is

			when nop =>

				if new_data = '1' then
					load_en <= '1';
					next_state <= compute;
				end if;

			when compute =>

				if compute_finshed = '0' then
					compute_en <= '1';
				else
					next_state <= output;
				end if;
		
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


	data_path: process(clk)
	begin
		if rising_edge(clk) then 
			
			compute_finshed <= '0';
			done <= '0';

			if load_en = '1' then
				a <= UNSIGNED(a_in);
				b <= UNSIGNED(b_in);
				q <= (others => '0'); -- reset quotient
				done <= '0';
			end if;
	
			if compute_en = '1' then
				if a < b then
					compute_finshed <= '1';
				else
					q <= q + 1; -- increment quotient
					a <= a - b;
				end if;
	
			end if;
	
			if output_en = '1' then
				done <= '1';
				r_out <= STD_LOGIC_VECTOR(a); -- what's left of a is the remainder
				q_out <= STD_LOGIC_VECTOR(q); 
	
			end if;
		end if;
	end process data_path;

END Behavioral;
