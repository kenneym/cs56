----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/29/2019 01:26:42 PM
-- Design Name: 
-- Module Name: pqgen - Behavioral
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

entity pqgen is
    Generic(num_bits    :   integer := 8);
    Port ( clk          : in STD_LOGIC;
           en           : in STD_LOGIC;
          -- seed_dad     : in STD_LOGIC_VECTOR(num_bits-1 downto 0);
           ---------------------------------------------------------
           p            : out STD_LOGIC_VECTOR (num_bits-1 downto 0);
           q            : out STD_LOGIC_VECTOR (num_bits-1 downto 0);
           done         : out STD_LOGIC                            );
end pqgen;

architecture Behavioral of pqgen is

-- component declarations
component LFSR
    GENERIC( num_bits : integer := num_bits);
    PORT(clk          : in STD_LOGIC;
         enable       : in STD_LOGIC;
         seed         : in STD_LOGIC_VECTOR(num_bits-1 downto 0);
         seed_en      : in STD_LOGIC;
         data         : out STD_LOGIC_VECTOR(num_bits-1 downto 0);
         data_done    : out STD_LOGIC);
 end component;
 
 component prime_test is
    GENERIC(data_size   : integer := num_bits;
            num_tries   : integer := 7);
    PORT(clk            : in STD_LOGIC;
         en             : in STD_LOGIC;
         num_in         : in STD_LOGIC_VECTOR(data_size-1 downto 0);
         seed           : in STD_LOGIC_VECTOR(data_size-1 downto 0);
         -----------------------------------------------------------
         prime_out      : out   STD_LOGIC;
         done           : out   STD_LOGIC);
end component;

-- Interface with LSFR component
signal rand_en, rand_seed_en, rand_done : STD_LOGIC := '0';
signal rand_num, rand_seed : STD_LOGIC_VECTOR(num_bits -1 downto 0) := (others => '0');

-- Interface with the prime test component
signal prime_en, prime_done, prime_outs :   STD_LOGIC := '0';
signal prime_num_in, prime_seed        :   STD_LOGIC_VECTOR(num_bits-1 downto 0) := (others => '0');

type state_type is (START, LS, LS_wait, LS_check, prime, prime_wait);
signal current_state, next_state : state_type := START;

-- enable bits
signal seed_en_en, seed_s_en, rand_en_en, r_l_en, num_in_en, pr_en, pout_en, qout_en, count_en, donez, count_r, d, seed_init : STD_LOGIC := '0';

-- registers
signal rand_reg, pout, qout : STD_LOGIC_VECTOR(num_bits-1 downto 0) := (others => '0');

--count
signal count : integer := 0;

-- seed intermediates
signal rand_seed_temp, prime_seed_temp : STD_LOGIC_VECTOR(num_bits-1 downto 0);

signal zero : STD_LOGIC_VECTOR(num_bits-1 downto 1) := (others => '0');
signal one : STD_LOGIC_VECTOR(num_bits -1 downto 0) :=  (0 => '1', others => '0') ; 		-- represent the number 1
signal three : UNSIGNED(num_bits -1 downto 0) :=  (0 => '1', 1 => '1', others => '0') ; 		-- represent the number 1

begin

random_generator: LFSR
generic map(
    num_bits => num_bits)
port map(
	clk => clk,
	enable => rand_en,
	seed => rand_seed,
	seed_en => rand_seed_en,
	data => rand_num,
	data_done => rand_done);

prime_tester : prime_test
generic map(
    data_size => num_bits)
port map(
    clk => clk,
    en => prime_en,
    num_in => prime_num_in,
    seed => prime_seed,
    prime_out => prime_outs,
    done => prime_done);

nextStateLogic: process(current_state, rand_done, en, rand_reg, prime_done, prime_outs, count)
begin
    next_state <= current_state;
    seed_en_en <= '0';
    seed_s_en <= '0';
    rand_en_en <= '0';
    r_l_en <= '0';
    num_in_en <= '0';
    pr_en <= '0';
    pout_en <= '0';
    qout_en <= '0';
    count_en <= '0';
    count_r <= '0';
    seed_init <= '0';
    
    case (current_state) is
        when START =>
        if en = '1' then
            next_state <= LS;
            seed_init <= '1';
        end if;
        
        when LS =>
            if rand_done = '1' then
                seed_en_en <= '1';
                seed_s_en <= '1';
            end if;
            rand_en_en <= '1';
            next_state <= LS_wait;
       
        when LS_wait =>
            next_state <= LS_check;
            r_l_en <= '1';
            
        when LS_check =>
            if (rand_reg = one) then
                next_state <= LS;
            elsif (rand_reg(0) = '1') then
                if(rand_reg(rand_reg'left) = '1') then
                    next_state <= prime;
                else
                    next_state <= LS;
                end if;
            else
                next_state <= LS;
            end if;
            
        when prime =>
            num_in_en <= '1';
            pr_en <= '1';
            next_state <= prime_wait;
            
        when prime_wait =>
            if prime_done = '1' then
                if prime_outs = '1' then
                    count_en <= '1';
                    if count = 0 then
                        pout_en <= '1';
                        next_state <= LS;
                    else
                        qout_en <= '1';
                        donez <= '1';
                        count_r <= '1';
                        next_state <= START;
                    end if;
                else
                    next_state <= LS;
                end if;
            end if;
        
    end case;    
end process nextStateLogic;

state_update: process(clk)
begin
	if rising_edge(clk) then
        current_state <= next_state;
	end if;
end process state_update;

datapath : process(clk)
begin
    if rising_edge(clk) then
        rand_en <= '0';
        rand_seed_en <= '0';
        prime_en <= '0';
        d <= '0';
        
        
        
        if seed_init = '1' then
            --prime_seed <=  STD_LOGIC_VECTOR(UNSIGNED(seed_dad) + UNSIGNED(three));
             --rand_seed <= seed_dad;
            --prime_seed_temp <= STD_LOGIC_VECTOR(UNSIGNED(seed_dad) + UNSIGNED(three));
            --rand_seed_temp <= seed_dad;
            prime_seed <= "11000100";
            rand_seed <= "01010001";
            prime_seed_temp <= "11000100";
            rand_seed_temp <= "01010001";
            rand_seed_en <= '1';
            rand_en <= '1';
        end if;
        
        if seed_en_en = '1' then
            rand_seed_en <= '1';
        end if;
        
        if seed_s_en = '1' then
            rand_seed <= STD_LOGIC_VECTOR(UNSIGNED(rand_seed_temp) + UNSIGNED(rand_reg)); 
        end if;
        
        if rand_en_en = '1' then
            rand_en <= '1';
        end if;
        
        if r_l_en = '1' then
            rand_reg <= rand_num;
           
        end if;
        
        if pr_en = '1' then
            prime_en <= '1';
        end if;
        
        if num_in_en = '1' then
            prime_num_in <= rand_reg;
        end if;
        
        if pout_en = '1' then
            pout <= rand_reg;
        end if;
        
        if qout_en = '1' then
            qout <= rand_reg;
            d <= '1';
        end if;    
        
        if count_en = '1' then
            count <= count + 1;
        end if;
        
        if count_r = '1' then
            count <= 0;
        end if;
      
     end if;
end process datapath;
    q <= qout;
    p <= pout;
    done <= d;
end Behavioral;
