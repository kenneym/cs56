--------------------------------------------------------------------------------
-- Course:	 		Engs 31 16S
--
-- Create Date:   17:11:39 07/25/2009
-- Design Name:   
-- Module Name:   SerialRx_tb.vhd
-- Project Name:  Lab5
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: SerialRx
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:

--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;
 
ENTITY SerialRx_tb IS
END SerialRx_tb;
 
ARCHITECTURE behavior OF SerialRx_tb IS 
 
COMPONENT SerialRx
	PORT(
		Clk : IN std_logic;
		RsRx : IN std_logic;   
		rx_shift : out std_logic;		-- for testing      
		rx_data :  out std_logic_vector(7 downto 0);
		rx_done_tick : out std_logic  );
	END COMPONENT;
   

   --Inputs
   signal clk : std_logic := '0';
   signal RsRx : std_logic := '1';

 	--Outputs
   signal rx_shift : std_logic;
   signal rx_data : std_logic_vector(7 downto 0);
   signal rx_done_tick : std_logic;

   -- Clock period definitions
   constant clk_period : time := 100 ns;		-- 10 MHz clock
	
	-- Data definitions
--	constant bit_time : time := 104us;		-- 9600 baud
	constant bit_time : time := 8.68 us;		-- 115,200 baud
	constant TxData : std_logic_vector(7 downto 0) := "01101001";
	
BEGIN 
	-- Instantiate the Unit Under Test (UUT)
   uut: SerialRx PORT MAP (
          clk => clk,
          RsRx => RsRx,
          rx_shift => rx_shift,
          rx_data => rx_data,
          rx_done_tick => rx_done_tick
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
		wait for 100 us;
		wait for 10.25*clk_period;		
		
		RsRx <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			RsRx <= TxData(bitcount);
			wait for bit_time;
		end loop;
		
		RsRx <= '1';		-- Stop bit
		wait for 200 us;
		
		RsRx <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			RsRx <= not( TxData(bitcount) );
			wait for bit_time;
		end loop;
		
		RsRx <= '1';		-- Stop bit
		
		wait;
   end process;
END;
