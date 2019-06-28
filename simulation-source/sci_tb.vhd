----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/23/2019 09:06:23 PM
-- Design Name: 
-- Module Name: sci_tb - Behavioral
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

entity sci_tb is
--  Port ( );
end sci_tb;

architecture testbench of sci_tb is

component sci is
PORT(       mclk    :       in STD_LOGIC;                       --the master clock
            RsRx     :      in STD_LOGIC;                       --serial data in
            rx_data  :      out STD_LOGIC_VECTOR(7 downto 0);   --parallel data out
            rx_done_tick :  out STD_LOGIC);
end component;

signal mclk : STD_LOGIC := '0';
signal RsRX : STD_LOGIC := '0';
signal rx_data : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
signal rx_done_tick : STD_LOGIC := '0';

begin

uut : sci PORT MAP(
      mclk => mclk,
      RsRX => RsRx,
      rx_data => rx_data,
      rx_done_tick => rx_done_tick);

clk_proc :process
BEGIN
    mclk <= '0';
    wait for 5 ns;
    mclk <= '1';
    wait for 5 ns;
end process clk_proc;

stim_proc: process
begin
RsRx <= '0';
wait for 20 ns;

wait;
end process stim_proc;
end testbench;

