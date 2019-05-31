----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/23/2019 03:00:33 PM
-- Design Name: 
-- Module Name: sci - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SerialRx is
    Port (  clk    :       in STD_LOGIC;                       --the master clock
            RsRx     :      in STD_LOGIC;                       --serial data in
            rx_data  :      out STD_LOGIC_VECTOR(7 downto 0);   --parallel data out
            rx_done_tick :  out STD_LOGIC);                     --data ready (done tick)
end SerialRx;

architecture Behavioral of SerialRx is

type state_type is (waits, shifts, writes);
signal current_state, next_state : state_type := waits;
signal c_count :integer := 0;
signal s_count : unsigned(3 downto 0) := "0000";
signal c_count_en, s_count_en, rx_done_en, out_en, first, c_count_r, s_count_r: STD_LOGIC := '0';
signal rsrx_ff, rsrx_s : STD_LOGIC;
constant baud : integer := 115200;
constant clk_freq : integer := 10000000;
constant n : integer := clk_freq/baud;
constant n_half : integer := n/2;
signal shift_reg : STD_LOGIC_VECTOR(9 downto 0) := "0000000000";
signal out_reg : STD_LOGIC_VECTOR(7 downto 0) := "00000000";

begin
    nextStateLogic: process(current_state, RsRx, RsRx_S, c_count, s_count, first)
    begin
        next_state <= current_state;
        c_count_en <= '0';
        s_count_en <= '0';
        out_en <= '0';
        rx_done_en <= '0';
        c_count_r <= '0';
        s_count_r <= '0';
        case (current_state) is
            when waits =>
                c_count_r <= '1';
                s_count_r <= '1';
                first <= '0';
                if RsRx_S = '0' then
                    next_state <= shifts;
                end if;
            when shifts =>
                c_count_en <= '1';
                if c_count = n_half then
                    if first = '0' then
                        s_count_en <= '1';
                        first <= '1';
                    end if;
                elsif c_count = n then
                    s_count_en <= '1';
                    c_count_r <= '1';
                end if;
                if s_count = "1010" then
                    next_state <= writes;
                end if;
            when writes =>
                out_en <= '1';
                rx_done_en <= '1';
                next_state <= waits;
         end case; 
    end process nextStateLogic;
    
    
    synchronize:process(clk, RsRx_FF, RsRx_S)
    begin
        if rising_edge(clk) then
            RsRx_FF <= RsRx;
            RsRx_S <= RsRx_FF;
        end if;
    end process synchronize;
    
    stateUpdate: process(clk)
    begin
        if rising_edge(clk) then
            current_state <= next_state;

			rx_done_tick <= '0';

            if c_count_en = '1' then
                c_count <= c_count + 1;
            end if;
            if s_count_en = '1' then
                s_count <= s_count + 1;
                shift_reg <= RsRx_s & shift_reg(9 downto 1);
            end if;
            if out_en = '1' then
                out_reg <= shift_reg(7 downto 0);
            end if;
            if rx_done_en = '1' then
                rx_done_tick <= '1';
            end if;
            if c_count_r = '1' then
                c_count <= 0;
            end if;
            if s_count_r = '1' then
                s_count <= "0000";
            end if;
        end if;
     end process stateUpdate;
     rx_data <= out_reg;
end Behavioral;
