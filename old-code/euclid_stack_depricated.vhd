----------------------------------------------------------------------------------
-- Author: 			Matt Kenney
-- Create Date: 	May 6, 2019
-- Assignment: 		HW6
-- Class			COSC056 - Digital Electronics
--
-- Program: 		euclid_stack.vhd
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Set the generic 'stack_size' to one of the follwing, depending on key length:
-- 16-bit test key: 12
-- 64-bit key: 46
-- 128-bit key: 92
-- 256-bit key: 369

-- Set the generic 'data_size' to the key bit-length over 2 (i.e the maximum 
-- size of public key e)
-- 16 bit test key: 8
-- 64-bit key: 32
-- 128-bit key: 64
-- 256-bit key: 128

ENTITY stack is
	
	GENERIC( stack_size : integer := 12;
		   	 data_size  : integer := 8); -- set for test key

	PORT  (	clk : in STD_LOGIC;
			push : in STD_LOGIC;
			pop : in STD_LOGIC;
			clear : in STD_LOGIC;
			data_in: in STD_LOGIC_VECTOR(data_size - 1 downto 0);
			----------------------------------------------
			full: out STD_LOGIC := '0';
			empty: out STD_LOGIC := '1';
			data_out : out STD_LOGIC_VECTOR(data_size -1  downto 0) );
END stack;	

ARCHITECTURE behavior of stack is

type stackreg_type is array(0 to stack_size -1) of STD_LOGIC_VECTOR(data_size -1 downto 0);
signal stackreg : stackreg_type := (others => (others => '0')); -- init with all 0s
signal front: integer := 0; -- write to front, read from front -1

signal push_done : STD_LOGIC := '0'; 	-- used to update front after push is completed
signal pop_done : STD_LOGIC := '0';
signal reset_front : STD_LOGIC := '0';

BEGIN
	
	-- Update front after push/ pop operations occur
	update_front: process(push_done, pop_done, clear)
	begin
            
		-- updates occur syncronously in case of push & async in case of pop
		    if (reset_front = '1') then
		        front <= 0;
			elsif (push_done = '1') then -- push_done only occurs when not full
				front <= front + 1;
			elsif (pop_done = '1') then
				front <= front - 1;
			end if;

	end process update_front;

	-- Update attributes empty & full after update_front process takes place
	attribute_update: process(front)
	begin
        empty <= '0';
        full <= '0';
		
        if front = 0 then 
			empty <= '1';
        elsif front = stack_size then		-- invalid index for writing 
			full <= '1'; 
        end if;
        
	end process attribute_update;

	-- Writes to stackreg (write and clear)
	write_process: process(clk)
	begin
		if rising_edge(clk) then
			push_done <= '0'; -- default
			
		    --  clear
		    if (clear = '1') then
		       reset_front <= '1';
               stackreg   <= (others => (others => '0')); -- set all bits to 0
               
            -- write
			elsif (push = '1') and (front < stack_size)  then
				stackreg(front) <= data_in;
				push_done <= '1';
			end if;

		end if;
	end process;
	
	-- Asynchronous read
	read_process: process(pop)
	begin
		pop_done <= '0';
		if (pop = '1') and (front > 0) then
			data_out <= stackreg(front - 1);
			pop_done <= '1';
		end if;
	end process read_process;


END behavior;
