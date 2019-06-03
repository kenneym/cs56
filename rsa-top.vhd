----------------------------------------------------------------------------------
-- Course:	 		 Engs 31 16S
-- 
-- Create Date:      15:44:25 07/25/2009 
-- Design Name: 
-- Module Name:      rsatop - Behavioral 
-- Project Name:	 Lab 5 
-- Target Devices:   Spartan 6 / Nexys 3
-- Tool versions:    ISE 14.4
-- Description:      Top Level Shell for RSA Encryption Project
--
-- Dependencies:     SerialRx.vhd (eventually, SerialTx.vhd)
--
-- Revision: 
-- Revision 0.01 - File Created
--		Revised (EWH) 7.19.2014 for Nexys3 board and updated lab flow
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library UNISIM;					-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

entity rsatop is
	Generic ( key_size : integer := 32);
    Port ( Clk : in  STD_LOGIC;					-- 100 MHz board clock
           
		   RsRx  : in  STD_LOGIC;				-- Rx input
		   RsTx  : out  STD_LOGIC;

		   gen_key : in STD_LOGIC; 				-- push-button mp signal to generate a key
		   key_ready : out STD_LOGIC := '1';
		   encrypt_start : out STD_LOGIC := '0';
		   decrypt_start : out STD_LOGIC := '0';
		   
		   nop_state, generate_key_state, encrypt_state, decrypt_state, hold_state, encrypt_out_state, decrypt_out_state : out STD_LOGIC := '0';
		   

		   -- Seven segment display (one digit)
           seg : out STD_LOGIC_VECTOR (0 to 6);
		   dp : out std_logic;
           an : out std_logic_vector(3 downto 0)
		   );				-- Tx output
end rsatop;

architecture Structural of rsatop is

-- Signals for the 100 MHz to 10 MHz clock divider
constant CLOCK_DIVIDER_VALUE: integer := 5;
signal clkdiv: integer := 0;			-- the clock divider counter
signal clk_en, clk_en2: std_logic := '0';		-- terminal count
signal clk10, clk2: std_logic;				-- 10 MHz clock signal, and 50MHz signal

-- Other signals
signal rx_data : std_logic_vector(7 downto 0);
signal rx_done_tick, rx_done_sync : std_logic := '0';
signal tick_cnt : UNSIGNED(2 downto 0) := (others => '0');

-- Component declarations
COMPONENT SerialRx
	PORT(
		Clk : IN std_logic;
		RsRx : IN std_logic;   
--		rx_shift : out std_logic;		-- for testing      
		rx_data :  out std_logic_vector(7 downto 0);
		rx_done_tick : out std_logic  );
	END COMPONENT;

-- Add declarations for SerialTx and Mux7seg here
COMPONENT SerialTx is
    Port ( Clk : in  STD_LOGIC;
           tx_data : in  STD_LOGIC_VECTOR (7 downto 0);
           tx_start : in  STD_LOGIC;
           tx : out  STD_LOGIC;					    -- to RS-232 interface
           tx_done_tick : out  STD_LOGIC);
end Component;

COMPONENT keygen is
	GENERIC(key_size	: integer := 16);

	PORT (  clk			:	in STD_LOGIC;
			en			:	in STD_LOGIC;
			seed_1		: 	in STD_LOGIC_VECTOR(key_size -1 downto 0);
			seed_2		: 	in STD_LOGIC_VECTOR(key_size/2 -1 downto 0);
			----------------------------------------------------------
			done 		: 	out STD_LOGIC;
			n_out 		: 	out STD_LOGIC_VECTOR(key_size -1 downto 0);
			e_out 		:	out STD_LOGIC_VECTOR(key_size -1 downto 0);
			d_out		:	out STD_LOGIC_VECTOR(key_size -1 downto 0));
end COMPONENT;

component modexp2 is
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
end component;

component mux7seg is
    Port ( clk : in  STD_LOGIC;									-- runs on a fast (100 MHz or so) clock
           y0, y1, y2, y3 : in  STD_LOGIC_VECTOR (3 downto 0);	-- digits
           dp_set : in std_logic_vector(3 downto 0);            -- decimal points
           seg : out  STD_LOGIC_VECTOR(0 to 6);				    -- segments (a...g)
           dp : out std_logic;
           an : out  STD_LOGIC_VECTOR (3 downto 0) );			-- anodes
end component;



-- FSM Declaration
type state_type is (nop, generate_key, encrypt, decrypt, hold, encrypt_out, decrypt_out);
signal current_state, next_state : state_type := nop;
signal keygen_start, create_key, key_finished, encrypt_en, decrypt_en, out_en, load_msg_out, reset_en: STD_LOGIC := '0'; -- enable signals

signal encrypting: STD_LOGIC := '1'; -- enable signals

signal started: STD_LOGIC := '0'; -- information signals back to FSM


signal num_letters : UNSIGNED(2 downto 0) := (others => '0'); -- count 4 letters before encrypting
signal num_letters_mux : STD_LOGIC_VECTOR(3 downto 0) := (others => '0'); -- count 4 letters before encrypting
signal letters_sent : UNSIGNED(2 downto 0) := (others => '0'); -- count 4 letters before sending
signal four : UNSIGNED(2 downto 0) := "100"; -- count 4 letters before encrypting
signal msg : STD_LOGIC_VECTOR(key_size - 1 downto 0) := (others => '0'); -- (read in via rx data)

-- interface with keygen:
signal keygen_en, keygen_done: STD_LOGIC := '0';
signal seed_1, n_out, e_out, d_out: STD_LOGIC_VECTOR(key_size - 1 downto 0) := (others => '0');
signal seed_2 : STD_LOGIC_VECTOR(key_size/2 -1 downto 0) := (others => '0');
signal n, e, d : STD_LOGIC_VECTOR(key_size - 1 downto 0) := (others => '0');


-- interface with modexp:
signal key, operated_msg, msg_out: STD_LOGIC_VECTOR(key_size -1 downto 0) := (others => '0');
signal modexp_en, mod_exp_done : STD_LOGIC := '0';

-- interface with reciever and transmitter:
signal tx_data : STD_LOGIC_VECTOR(7 downto 0);
signal tx_start, tx_done_tick: STD_LOGIC;


-- Count how many times new data comes in via SerialRx
-------------------------
begin


-- Clock buffer for 10 MHz clock
-- The BUFG component puts the slow clock onto the FPGA clocking network
Slow_clock_buffer: BUFG
      port map (I => clk_en,
                O => clk10 );
                
Slow_clock_buffer2: BUFG
      port map (I => clk_en2,
                O => clk2 );

-- Divide the 100 MHz clock down to 20 MHz, then toggling the 
-- clk_en signal at 20 MHz gives a 10 MHz clock with 50% duty cycle
Clock_divider: process(clk)
begin
	if rising_edge(clk) then
	   	if clkdiv = CLOCK_DIVIDER_VALUE-1 then 
	   		clk_en <= NOT(clk_en);		
			clkdiv <= 0;
		else
			clkdiv <= clkdiv + 1;
		end if;
	end if;
end process Clock_divider;
------------------------------

Clock_divider2: process(clk)
begin
	if rising_edge(clk) then
	   	clk_en2 <= NOT(clk_en2);
	end if;		
end process Clock_divider2;





-- Map testing signals to toplevel ports
--clk10_p <= clk_en;
--RsRx_p <= RsRx;				
--rx_done_tick_p <= rx_done_tick;



-- display first 12 bits of public key component n & the SerialTx counter
display: mux7seg port map(
			clk=>clk,			-- has its own clock divider built-in

			y0=>n(31 downto 28), 
			y1=>n(27 downto 24), 
			y2=> n(23 downto 20), 
			y3=> num_letters_mux, 
			dp_set=>"0000",
			seg=>seg, dp=>dp, an=>an);


Receiver: SerialRx PORT MAP(
		Clk => clk10,				-- receiver is clocked with 10 MHz clock
		RsRx => RsRx,
--		rx_shift => rx_shift_p,		-- testing port
		rx_data => rx_data,
		rx_done_tick => rx_done_tick  );



-- Add declarations for SerialTx and Mux7seg here
Transmitter: SerialTx PORT MAP(
		Clk => clk10,
		tx_data => tx_data,
		tx_start => tx_start,
		tx => RsTx,
		tx_done_tick => tx_done_tick);

keygenerator : keygen 
GENERIC MAP(
		key_size => key_size)
PORT MAP(
        clk => clk10,
--		clk => clk2,
		en => keygen_en,
		seed_1 => seed_1,
		seed_2 => seed_2,
		done => keygen_done,
		n_out => n_out,
		e_out => e_out,
		d_out => d_out);


enc_dec_module: modexp2
generic map(
	num_bits => key_size)
port map(
--		clk => clk2,
        clk => clk10,
		en => modexp_en,
		x => msg, -- encrypt the message
		y => key,
		p => n,
		mod_exp => operated_msg,
		done => mod_exp_done);
		
		
--sync_rxdone : process(clk2)
--begin
--    if rising_edge(clk2) then
--        rx_done_sync <= '0';
        
--        if rx_done_tick = '1' then
--            tick_cnt <= tick_cnt + 1;
--        end if;
        
--        if tick_cnt = "010" then -- if we have 5 in a row (4 plus the current one)
--            tick_cnt <= "000";
--            rx_done_sync <= '1';
--        end if;
--    end if;
--end process;
        

-- NOTE  self: convert keygen's dbne signal to an mp for this module
--type state_type is (nop, generate_key, encrypt, hold, output);
--signal current_state, next_state : state_type := nop;
--signal keygen_start, create_key: STD_LOGIC := '0'; -- enable signals

next_state_logic: process(current_state, keygen_start, keygen_done, num_letters, mod_exp_done, encrypting, letters_sent, four, tx_done_tick)
begin

	next_state <= current_state;

	-- Defaults
	create_key <= '0';
	key_finished <= '0';
	encrypt_en <= '0';
	decrypt_en <= '0';
	out_en <= '0';
	load_msg_out <= '0';
	reset_en <= '0';
	
	nop_state <= '0';
	generate_key_state <= '0';
	encrypt_state<= '0';
	decrypt_state<= '0';
	hold_state<= '0';
	encrypt_out_state <= '0';
	decrypt_out_state <= '0';

	case(current_state) is

		when nop =>

			started <= '0';
			nop_state <= '1';

			if keygen_start = '1' then
				started <= '1';
				next_state <= generate_key;
			end if;

			if num_letters =  four then
				next_state <= encrypt;
			end if;


		when generate_key =>
		    generate_key_state <= '0';
			create_key <= '1';
			next_state <= hold;

		when hold =>
		    hold_state <= '1';

			if keygen_done = '1' then
				started <= '0';
				key_finished <= '1';
				next_state <= nop;

			elsif mod_exp_done = '1' then
				if encrypting = '1' then
					load_msg_out <= '1';
					next_state <= encrypt_out;
				else
					load_msg_out <= '1';
					next_state <= decrypt_out;
				end if;

			elsif tx_done_tick = '1' then
				if encrypting = '1' then
					next_state <= encrypt_out;
				else
					next_state <= decrypt_out;
				end if;

			end if;


		when encrypt =>
		    encrypt_state <= '1';
			encrypt_en <= '1';
			next_state <= hold;

		when encrypt_out =>
		    encrypt_out_state <= '1';

			if letters_sent = four then
				next_state <= decrypt;
			else
				out_en <= '1';
				next_state <= hold;
			end if;

		when decrypt =>
		    decrypt_state <= '1';
			decrypt_en <= '1';
			next_state <= hold;

		when decrypt_out =>
		    decrypt_out_state <= '1';
			if letters_sent = four then
				next_state <= nop;
				reset_en <= '1';
			else 
				out_en <= '1';
				next_state <= hold;
			end if;

		
	end case;



end process next_state_logic;



state_update: process(clk10)
begin
	if rising_edge(clk10) then
        current_state <= next_state;
	end if;
end process state_update;




datapath: process(clk10)
begin

	if rising_edge(clk10) then

		keygen_start <= '0';
		keygen_en <= '0';
		modexp_en <= '0';
		tx_start <= '0';

		-- testing
		num_letters_mux <= '0' & STD_LOGIC_VECTOR(num_letters);

		-- convert gen_key button to mp
		if gen_key = '1' and started = '0' then
			keygen_start <= '1';
		end if;

		if create_key = '1' then
		    key_ready <= '0';
			keygen_en <= '1';
			-- seeds are set internally for now:
			seed_1 <= "10011011001010111001101100101011";
			seed_2 <= "1001100110011001";
		end if;

		if key_finished = '1' then
			key_ready <= '1';
			n <= n_out;
			e <= e_out;
			d <= d_out;
		end if;

		-- Count how many times new data comes in via SerialRx
		if rx_done_tick = '1' then
			num_letters <= num_letters + 1;
			msg <= rx_data & msg(msg'left downto 8); -- right shift the new data in 		
		end if;

		if load_msg_out = '1' then
			msg_out <= operated_msg; 	-- load the ciphertext after encryption & message after decryption
		end if;

		if encrypt_en = '1' then
			encrypt_start <= '1';
			letters_sent <= (others => '0');
			encrypting <= '1'; -- notify fsm we are encrypting
			key <= e;		   -- public key 'e' as exponent
			modexp_en <= '1';
		end if;

		if out_en = '1' then
			letters_sent <= letters_sent + 1;
			tx_data <= msg_out(msg_out'left downto msg_out'left - 7); -- left shift msg_out into tx_data
			msg_out <= msg_out(msg_out'left - 8 downto 0) & "00000000";
			tx_start <= '1';
		end if;

		if decrypt_en = '1' then
			decrypt_start <= '1';
			letters_sent <= (others => '0');
			msg <= operated_msg;	-- result of encryption now input to modexp as the ciphertext
			encrypting <= '0'; 		-- notify we are now decrypting
			key <= d;		   		-- private key 'd' as exponent
			modexp_en <= '1';
		end if;

		if reset_en = '1' then
			letters_sent <= (others => '0');
			msg_out <= (others => '0');
			tx_data <= (others => '0');
			num_letters <= (others => '0');
			msg <= (others => '0');
			encrypt_start <= '0';
			decrypt_start <= '0';
		end if;

	end if;
end process datapath;

end Structural;
