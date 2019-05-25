----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/25/2019 02:27:26 PM
-- Design Name: 
-- Module Name: euclid_tb - Behavioral
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


entity euclid is
    Port (mclk    :     in STD_LOGIC;
          a       :     in STD_LOGIC_VECTOR(7 downto 0);
          b       :     in STD_LOGIC_VECTOR(7 downto 0);
          toggle  :     in STD_LOGIC;
          gcd     :     out STD_LOGIC_VECTOR(7 downto 0));
end euclid;

architecture Behavioral of euclid is

type state_type is (nop, check, greater, less);
signal current_state, next_state : state_type := nop;

signal a_c, b_c, outs : UNSIGNED(7 downto 0) :=  (others => '0');
signal l_en, g_en, d_en, o_en : STD_LOGIC := '0';

begin

nextStateLogic: process(current_state, toggle, a, b)
begin
    
    next_state <= current_state;
    
    d_en <= '0';
    l_en <= '0';
    g_en <= '0';
    d_en <= '0';
    case (current_state) is
        when nop =>
        
        if toggle = '1' then
                d_en <= '1';
                next_state <= check;
        end if;
        
        when check =>
        
            if (a_c = b_c) then
                next_state <= nop;
                o_en <= '1'; 
            else
                if (a_c > b_c) then
                    next_state <= greater;
                else
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
    
stateUpdate: process(mclk)
begin
    if rising_edge(mclk) then
        current_state <= next_state;
        if g_en = '1' then
            a_c <= a_c - b_c;
        end if;
        if l_en = '1' then
            b_c <= b_c - a_c;
        end if;
        if d_en = '1' then
            a_c <= UNSIGNED(a);
            b_c <= UNSIGNED(b);
        end if;
        if o_en = '1' then
            outs <= a_c;
        end if;
    
    end if;
end process stateUpdate;

gcd <= STD_LOGIC_VECTOR(outs);            

end Behavioral;
