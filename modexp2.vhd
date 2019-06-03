----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/28/2019 10:08:22 PM
-- Design Name: 
-- Module Name: modexp2 - Behavioral
-- Project Name: 
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


entity modexp2 is
    generic (
    num_bits    :   integer := 8);
    
    Port (clk      :     in  STD_LOGIC;
          en        :     in  STD_LOGIC;
          x         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          y         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          p         :     in  STD_LOGIC_VECTOR(num_bits-1 downto 0);
          ----------------------------------------------------------
          mod_exp   :     out STD_LOGIC_VECTOR(num_bits-1 downto 0);
          done      :     out STD_LOGIC);
end modexp2;

architecture Behavioral of modexp2 is

type state_type is (load, modx_load, modx_go, modx, whiles, resx, modres_load, modres_go, modres, shift, modxx_load, modxx_go, modxx);
signal current_state, next_state : state_type := load;

signal x_c, y_c, p_c, y_c_zero,res, res_out      :       UNSIGNED(num_bits-1 downto 0) := (others => '0');
signal res_temp, x_temp                          :       UNSIGNED(2*num_bits-1 downto 0) := (others => '0');
    

-- Interface with modulus component
signal mod_data, mod_finished: STD_LOGIC;
signal b_mod, r_out : STD_LOGIC_VECTOR(2*num_bits-1 downto 0);
signal a_mod               : STD_LOGIC_VECTOR(2*num_bits-1 downto 0);
signal a_mod_temp          : UNSIGNED(2*num_bits-1 downto 0);
signal r_intermed          : STD_LOGIC_VECTOR(2*num_bits -1 downto 0);


-- Computes a / b = q remainder r.
component modulus
	GENERIC(data_size  : integer := 2 * num_bits); -- set for test key
    PORT (clk 		: 	in STD_LOGIC;
          a_in 		: 	in STD_LOGIC_VECTOR(data_size -1  downto 0); -- a should be >= b
		  b_in  	: 	in STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  new_data	: 	in STD_LOGIC;
		  ---------------------------------------------------------
		  done 		: 	out STD_LOGIC;
		  q_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0);
		  r_out 	: 	out STD_LOGIC_VECTOR(data_size - 1 downto 0));
end component;

signal l_en, modx_en, resx_en, modrex_en, output_en, y_shift_en, x_multi_en, modxx_en, modx_load_en, modres_load_en, modxx_load_en, x_load, res_load : STD_LOGIC := '0';

begin

mod_component: modulus
generic map(
    data_size => 2 * num_bits)
port map(
	clk => clk,
	a_in => a_mod,
	b_in => b_mod,
	new_data => mod_data,
	done => mod_finished,
	q_out => open,
	r_out => r_out);
	
nextStateLogic: process(current_state, en, mod_finished, y_c(0), y_c_zero)
begin

next_state <= current_state;

l_en <= '0';
modx_en <= '0';
resx_en <= '0';
modrex_en <= '0';
output_en <= '0';
y_shift_en <= '0';
x_multi_en <= '0';
modxx_en <= '0';
modx_load_en <= '0';
modres_load_en <= '0';
modxx_load_en <= '0';
x_load <= '0';
res_load <= '0';

case(current_state) is
    when load =>
        if en = '1' then
            l_en <= '1';
            next_state <= modx_load;
        end if;
        
    when modx_load =>
        modx_load_en <= '1';
        next_state <= modx_go;
        
    when modx_go =>
        modx_en <= '1';
        next_state <= modx;
    
    when modx =>
        --modx_en <= '1';
        if mod_finished = '1' then
            x_load <= '1';
            next_state <= whiles;
        end if;
        
    when whiles =>
        if (y_c > y_c_zero) then
            if(y_c(0) = '1') then
                next_state <= resx;
            else
                next_state <= shift;
            end if;
        else
            next_state <= load;
            output_en <= '1';
        end if;
        
    when resx =>
        resx_en <= '1';
        next_state <= modres_load;
        
    when modres_load =>
        modres_load_en <= '1'; 
        next_state <= modres_go;
        
    when modres_go =>
        modrex_en <= '1';
        next_state <= modres;
               
    when modres =>
       -- modrex_en <= '1';
        if mod_finished = '1' then
            res_load <= '1';
            next_state <= shift;
        end if;
         
    when shift =>
        y_shift_en <= '1';
        x_multi_en <= '1';
        next_state <= modxx_load;
        
    when modxx_load =>
        modxx_load_en <= '1';   
        next_state <= modxx_go;
        
    when modxx_go =>
        modxx_en <= '1';
        next_state <= modxx;
        
    when modxx =>
        --modxx_en <= '1';
        if mod_finished = '1' then
            x_load <= '1';
            next_state <= whiles;
        end if;
end case; 

end process nextStateLogic; 

stateUpdate : process(clk)
begin
    if rising_edge(clk) then
        current_state <= next_state;
    end if;
end process stateUpdate;

modexpDataPath : process(clk)
begin
    if rising_edge(clk) then
        mod_data <= '0';
        done <= '0';
                
        if (l_en = '1' ) then
            x_c <= UNSIGNED(x);
            y_c <= UNSIGNED(y);
            p_c <= UNSIGNED(p);
            res <= (0 => '1', others => '0') ;
        end if;
        
        if modx_load_en = '1' then
            a_mod <= STD_LOGIC_VECTOR(y_c_zero & x_c);
            b_mod <= STD_LOGIC_VECTOR(y_c_zero & p_c);
        end if;
        
        if modx_en = '1' then
            mod_data <= '1';
        end if;
        
        if x_load = '1' then
            x_c <= UNSIGNED(r_intermed(num_bits-1 downto 0));
        end if;
        
        if resx_en = '1' then
            res_temp <= res * x_c;
        end if;
            
        if modres_load_en = '1' then
            a_mod <= STD_LOGIC_VECTOR(res_temp);
            b_mod <= STD_LOGIC_VECTOR(y_c_zero & p_c);
        end if;
        
        if modrex_en = '1' then
            mod_data <= '1';    
        end if;
        
        if res_load = '1' then
            res <= UNSIGNED(r_intermed(num_bits-1 downto 0));
        end if;
        
        if output_en = '1' then
            res_out <= res;
            done <= '1';
        end if;
        
        if y_shift_en = '1' then
            y_c <= '0' & y_c(num_bits-1 downto 1);
        end if;
        
        if x_multi_en = '1'  then
            x_temp <= x_c*x_c;
        end if;
        
        if modxx_load_en = '1' then 
            a_mod <= STD_LOGIC_VECTOR(X_temp);
            b_mod <= STD_LOGIC_VECTOR(y_c_zero & p_c);
        end if;
        
        if modxx_en = '1' then
            mod_data <= '1';
        end if;    
        
    end if;
end process modexpDataPath;

r_intermed <= r_out;

mod_exp <= STD_LOGIC_VECTOR(res_out);

end Behavioral;
