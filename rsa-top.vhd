
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


		   rx_test_data : in STD_LOGIC_VECTOR(7 downto 0);
		   rx_test_done_tick : in STD_LOGIC;
	       tx_test_data : out STD_LOGIC_VECTOR(24 downto 0);

		
		   gen_key : in STD_LOGIC; 				-- push-button mp signal to generate a key
		   enc_dec : in STD_LOGIC;				-- switch: enc = '1', dec = '0'
		   key_ready : out STD_LOGIC;
		   RsTx  : out  STD_LOGIC);				-- Tx output
end rsatop;

architecture Structural of rsatop is

-- Signals for the 100 MHz to 10 MHz clock divider
constant CLOCK_DIVIDER_VALUE: integer := 5;
signal clkdiv: integer := 0;			-- the clock divider counter
signal clk_en: std_logic := '0';		-- terminal count
signal clk10: std_logic;				-- 10 MHz clock signal

-- Other signals
signal rx_data : std_logic_vector(7 downto 0);
signal rx_done_tick : std_logic;

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



type state_type is (nop, generate_key, encrypt, decrypt, hold, output);
signal current_state, next_state : state_type := nop;
signal keygen_start, create_key, key_finished, encrypt_en, decrypt_en, output_en: STD_LOGIC := '0'; -- enable signals
signal started: STD_LOGIC := '0'; -- information signals back to FSM

signal num_letters : UNSIGNED(2 downto 0) := (others => '0'); -- count 7 letters before encrypting
signal three : UNSIGNED(2 downto 0) := "011"; -- count 7 letters before encrypting
signal msg : STD_LOGIC_VECTOR(key_size - 9 downto 0) := (others => '0'); -- the message to be sent (read in via rx data)
signal oversized_msg : STD_LOGIC_VECTOR(key_size - 1 downto 0) := (others => '0'); -- the message to be sent (read in via rx data)

-- interface with keygen:
signal keygen_en, keygen_done: STD_LOGIC := '0';
signal seed_1, n_out, e_out, d_out: STD_LOGIC_VECTOR(key_size - 1 downto 0) := (others => '0');
signal seed_2 : STD_LOGIC_VECTOR(key_size/2 -1 downto 0) := (others => '0');
signal n, e, d : STD_LOGIC_VECTOR(key_size - 1 downto 0) := (others => '0');


-- interface with modexp:
signal key, mod_exp: STD_LOGIC_VECTOR(key_size -1 downto 0) := (others => '0');
signal modexp_en, mod_exp_done : STD_LOGIC := '0';


-------------------------
begin


-- Clock buffer for 10 MHz clock
-- The BUFG component puts the slow clock onto the FPGA clocking network
Slow_clock_buffer: BUFG
      port map (I => clk_en,
                O => clk10 );

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

-- Map testing signals to toplevel ports
--clk10_p <= clk_en;
--RsRx_p <= RsRx;				
--rx_done_tick_p <= rx_done_tick;

Receiver: SerialRx PORT MAP(
		Clk => clk10,				-- receiver is clocked with 10 MHz clock
		RsRx => RsRx,
--		rx_shift => rx_shift_p,		-- testing port
		rx_data => rx_data,
		rx_done_tick => rx_done_tick  );



-- Add declarations for SerialTx and Mux7seg here
Transmitter: SerialTx PORT MAP(
		Clk => clk10,
		tx_data => rx_data, -- loopback
		tx_start => rx_done_tick,
		tx => RsTx,
		tx_done_tick => open);


keygenerator : keygen 
GENERIC MAP(
		key_size => key_size)
PORT MAP(
		clk => clk,
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
		clk => clk,
		en => modexp_en,
		x => oversized_msg, -- encrypt the message
		y => key,
		p => n,
		mod_exp => mod_exp,
		done => mod_exp_done);

-- NOTE  self: convert keygen's dbne signal to an mp for this module
--type state_type is (nop, generate_key, encrypt, hold, output);
--signal current_state, next_state : state_type := nop;
--signal keygen_start, create_key: STD_LOGIC := '0'; -- enable signals

next_state_logic: process(current_state, keygen_start, keygen_done, rx_test_done_tick, mod_exp_done)
begin

	next_state <= current_state;

	-- Defaults
	create_key <= '0';
	key_finished <= '0';
	encrypt_en <= '0';
	decrypt_en <= '0';
	output_en <= '0';

	case(current_state) is

		when nop =>

			started <= '0';
			if keygen_start = '1' then
				started <= '1';
				next_state <= generate_key;
			end if;

			if num_letters =  three then
				if enc_dec = '1' then
					next_state <= encrypt;
				else
					next_state <= decrypt;
				end if;
			end if;


		when generate_key =>
			create_key <= '1';
			next_state <= hold;

		when hold =>
			if keygen_done = '1' then
				started <= '0';
				key_finished <= '1';
				next_state <= nop;
			end if;

			if mod_exp_done = '1' then
				next_state <= output;
			end if;

		when encrypt =>
			encrypt_en <= '1';
			next_state <= hold;

		when decrypt =>
			decrypt_en <= '1';
			next_state <= hold;

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


datapath: process(clk)
begin

	if rising_edge(clk) then

		keygen_start <= '0';
		keygen_en <= '0';
		modexp_en <= '0';

		oversized_msg <= "00000000" & msg;

		-- convert gen_key button to mp
		if gen_key = '1' and started = '0' then
			keygen_start <= '1';
		end if;

		if create_key = '1' then

			keygen_en <= '1';
			-- seeds are internally generated for now:
			seed_1 <= "10011011001010111001101100101011";
			seed_2 <= "1001100110011001";

		end if;

		if key_finished = '1' then
			key_ready <= '1';
			n <= n_out;
			e <= e_out;
			d <= d_out;

		-- could possibly add functionality to send key back to user via serial
		end if;


		if rx_test_done_tick = '1' then
			num_letters <= num_letters + 1;
			msg <= rx_test_data & msg(msg'left downto 8); -- right shift the new data in (leaving 8 trailing zeros at 8 Most sig. bits)
		end if;

		if encrypt_en = '1' then
			key <= e;
			modexp_en <= '1';
		end if;

		if decrypt_en = '1' then
			key <= d;
			modexp_en <= '1';
		end if;


		if output_en = '1' then
			tx_test_data <= mod_exp(24 downto 0);
			num_letters <= (others => '0');
			msg <= (others => '0');

		end if;


	end if;
end process datapath;


end Structural;

