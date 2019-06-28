----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/26/2019 04:30:55 PM
-- Design Name: 
-- Module Name: LFSR - Behavioral
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


entity LFSR is
    generic (
    num_bits : integer := 32
    );
    
    Port ( clk : in STD_LOGIC;
           enable : in STD_LOGIC;
           seed : in STD_LOGIC_VECTOR(num_bits - 1 downto 0);
           seed_en : in STD_LOGIC;
           data : out STD_LOGIC_VECTOR(num_bits -1 downto 0);
           data_done : out STD_LOGIC);
end LFSR;

architecture Behavioral of LFSR is

signal r_LFSR : std_logic_vector(num_bits downto 1) := (others => '0');
signal XNORS, start  : std_logic;


begin

-- Load up LFSR with Seed if seed_en is detected or just run LFSR when enabled

p_LFSR : process(clk) is
begin
    if rising_edge(clk) then 
        if enable = '1' then
            if seed_en = '1' then
                r_LFSR <= seed; 
                start <= '1';
            else
                r_LFSR <= r_LFSR(r_LFSR'left -1 downto 1) & XNORS;  -- left most value of r_LFSR, the upper bound conc. with XNORS
                start <= '0';
            end if;
        end if;
     end if;
end process p_LFSR;

-- Create the needed polynomials for any needed 

poly_3 : if num_bits = 3 generate
    XNORS <= r_LFSR(3) xnor r_LFSR(2);
end generate poly_3;

poly_4 : if num_Bits = 4 generate
    XNORS <= r_LFSR(4) xnor r_LFSR(3);
end generate poly_4;
 
 poly_5 : if num_Bits = 5 generate
    XNORS <= r_LFSR(5) xnor r_LFSR(3);
end generate poly_5;
 
  poly_6 : if Num_Bits = 6 generate
   XNORS <= r_LFSR(6) xnor r_LFSR(5);
  end generate poly_6;
 
  poly_7 : if Num_Bits = 7 generate
    XNORS <= r_LFSR(7) xnor r_LFSR(6);
  end generate poly_7;
 
  poly_8 : if Num_Bits = 8 generate
    XNORS <= r_LFSR(8) xnor r_LFSR(6) xnor r_LFSR(5) xnor r_LFSR(4);
  end generate poly_8;
 
  poly_9 : if Num_Bits = 9 generate
    XNORS <= r_LFSR(9) xnor r_LFSR(5);
  end generate poly_9;
 
  poly_10 : if Num_Bits = 10 generate
    XNORS <= r_LFSR(10) xnor r_LFSR(7);
  end generate poly_10;
 
  poly_11 : if Num_Bits = 11 generate
    XNORS <= r_LFSR(11) xnor r_LFSR(9);
  end generate poly_11;
 
  poly_12 : if Num_Bits = 12 generate
    XNORS <= r_LFSR(12) xnor r_LFSR(6) xnor r_LFSR(4) xnor r_LFSR(1);
  end generate poly_12;
 
  poly_13 : if Num_Bits = 13 generate
    XNORS <= r_LFSR(13) xnor r_LFSR(4) xnor r_LFSR(3) xnor r_LFSR(1);
  end generate poly_13;
 
  poly_14 : if Num_Bits = 14 generate
    XNORS <= r_LFSR(14) xnor r_LFSR(5) xnor r_LFSR(3) xnor r_LFSR(1);
  end generate poly_14;
 
  poly_15 : if Num_Bits = 15 generate
    XNORS <= r_LFSR(15) xnor r_LFSR(14);
  end generate poly_15;
 
  poly_16 : if Num_Bits = 16 generate
    XNORS <= r_LFSR(16) xnor r_LFSR(15) xnor r_LFSR(13) xnor r_LFSR(4);
  end generate poly_16;
 
  poly_17 : if Num_Bits = 17 generate
    XNORS <= r_LFSR(17) xnor r_LFSR(14);
  end generate poly_17;
 
  poly_18 : if Num_Bits = 18 generate
    XNORS <= r_LFSR(18) xnor r_LFSR(11);
  end generate poly_18;
 
  poly_19 : if Num_Bits = 19 generate
    XNORS <= r_LFSR(19) xnor r_LFSR(6) xnor r_LFSR(2) xnor r_LFSR(1);
  end generate poly_19;
 
  poly_20 : if Num_Bits = 20 generate
    XNORS <= r_LFSR(20) xnor r_LFSR(17);
  end generate poly_20;
 
  poly_21 : if Num_Bits = 21 generate
    XNORS <= r_LFSR(21) xnor r_LFSR(19);
  end generate poly_21;
 
  poly_22 : if Num_Bits = 22 generate
    XNORS <= r_LFSR(22) xnor r_LFSR(21);
  end generate poly_22;
 
  poly_23 : if Num_Bits = 23 generate
    XNORS <= r_LFSR(23) xnor r_LFSR(18);
  end generate poly_23;
 
  poly_24 : if Num_Bits = 24 generate
    XNORS <= r_LFSR(24) xnor r_LFSR(23) xnor r_LFSR(22) xnor r_LFSR(17);
  end generate poly_24;
 
  poly_25 : if Num_Bits = 25 generate
    XNORS <= r_LFSR(25) xnor r_LFSR(22);
  end generate poly_25;
 
  poly_26 : if Num_Bits = 26 generate
    XNORS <= r_LFSR(26) xnor r_LFSR(6) xnor r_LFSR(2) xnor r_LFSR(1);
  end generate poly_26;
 
  poly_27 : if Num_Bits = 27 generate
    XNORS <= r_LFSR(27) xnor r_LFSR(5) xnor r_LFSR(2) xnor r_LFSR(1);
  end generate poly_27;
 
  poly_28 : if Num_Bits = 28 generate
    XNORS <= r_LFSR(28) xnor r_LFSR(25);
  end generate poly_28;
 
  poly_29 : if Num_Bits = 29 generate
    XNORS <= r_LFSR(29) xnor r_LFSR(27);
  end generate poly_29;
 
  poly_30 : if Num_Bits = 30 generate
    XNORS <= r_LFSR(30) xnor r_LFSR(6) xnor r_LFSR(4) xnor r_LFSR(1);
  end generate poly_30;
 
  poly_31 : if Num_Bits = 31 generate
    XNORS <= r_LFSR(31) xnor r_LFSR(28);
  end generate poly_31;
 
  poly_32 : if Num_Bits = 32 generate
    XNORS <= r_LFSR(32) xnor r_LFSR(22) xnor r_LFSR(2) xnor r_LFSR(1);
  end generate poly_32;
  
  poly_33 : if num_bits = 33 generate
    XNORS <= r_LFSR(33) xnor r_LFSR(20);
end generate poly_33;

poly_34 : if num_Bits = 34 generate
    XNORS <= r_LFSR(34) xnor r_LFSR(27) xnor r_LFSR(2) xnor r_LFSR(1);
end generate poly_34;
 
 poly_35 : if num_Bits = 35 generate
    XNORS <= r_LFSR(35) xnor r_LFSR(33);
end generate poly_35;
 
  poly_36 : if Num_Bits = 36 generate
   XNORS <= r_LFSR(36) xnor r_LFSR(25);
  end generate poly_36;
 
  poly_37 : if Num_Bits = 37 generate
    XNORS <= r_LFSR(37) xnor r_LFSR(5) xnor r_LFSR(4) xnor r_LFSR(3) xnor r_LFSR(2) xnor r_LFSR(1);
  end generate poly_37;
 
  poly_38 : if Num_Bits = 38 generate
    XNORS <= r_LFSR(38) xnor r_LFSR(6) xnor r_LFSR(5) xnor r_LFSR(1);
  end generate poly_38;
 
  poly_39 : if Num_Bits = 39 generate
    XNORS <= r_LFSR(39) xnor r_LFSR(35);
  end generate poly_39;
 
  poly_40 : if Num_Bits = 40 generate
    XNORS <= r_LFSR(40) xnor r_LFSR(38) xnor r_LFSR(21) xnor r_LFSR(19);
  end generate poly_40;
 
  poly_41 : if Num_Bits = 41 generate
    XNORS <= r_LFSR(41) xnor r_LFSR(38);
  end generate poly_41;
 
  poly_42 : if Num_Bits = 42 generate
    XNORS <= r_LFSR(42) xnor r_LFSR(41) xnor r_LFSR(20) xnor r_LFSR(19);
  end generate poly_42;
 
  poly_43 : if Num_Bits = 43 generate
    XNORS <= r_LFSR(43) xnor r_LFSR(42) xnor r_LFSR(38) xnor r_LFSR(37);
  end generate poly_43;
 
  poly_44 : if Num_Bits = 44 generate
    XNORS <= r_LFSR(44) xnor r_LFSR(43) xnor r_LFSR(18) xnor r_LFSR(17);
  end generate poly_44;
 
  poly_45 : if Num_Bits = 45 generate
    XNORS <= r_LFSR(45) xnor r_LFSR(44) xnor r_LFSR(42) xnor r_LFSR(41);
  end generate poly_45;
 
  poly_46 : if Num_Bits = 46 generate
    XNORS <= r_LFSR(46) xnor r_LFSR(45) xnor r_LFSR(26) xnor r_LFSR(25);
  end generate poly_46;
 
  poly_47 : if Num_Bits = 47 generate
    XNORS <= r_LFSR(47) xnor r_LFSR(42);
  end generate poly_47;
 
  poly_48 : if Num_Bits = 48 generate
    XNORS <= r_LFSR(48) xnor r_LFSR(47) xnor r_LFSR(21) xnor r_LFSR(20);
  end generate poly_48;
 
  poly_49 : if Num_Bits = 49 generate
    XNORS <= r_LFSR(49) xnor r_LFSR(40);
  end generate poly_49;
 
  poly_50 : if Num_Bits = 50 generate
    XNORS <= r_LFSR(20) xnor r_LFSR(17);
  end generate poly_50;
 
  poly_51 : if Num_Bits = 51 generate
    XNORS <= r_LFSR(50) xnor r_LFSR(49) xnor r_LFSR(24) xnor r_LFSR(23);
  end generate poly_51;
 
  poly_52 : if Num_Bits = 52 generate
    XNORS <= r_LFSR(52) xnor r_LFSR(49);
  end generate poly_52;
 
  poly_53 : if Num_Bits = 53 generate
    XNORS <= r_LFSR(53) xnor r_LFSR(52) xnor r_LFSR(38) xnor r_LFSR(37);
  end generate poly_53;
 
  poly_54 : if Num_Bits = 54 generate
    XNORS <= r_LFSR(54) xnor r_LFSR(53) xnor r_LFSR(18) xnor r_LFSR(17);
  end generate poly_54;
 
  poly_55 : if Num_Bits = 55 generate
    XNORS <= r_LFSR(55) xnor r_LFSR(31);
  end generate poly_55;
 
  poly_56 : if Num_Bits = 56 generate
    XNORS <= r_LFSR(56) xnor r_LFSR(55) xnor r_LFSR(35) xnor r_LFSR(34);
  end generate poly_56;
 
  poly_57 : if Num_Bits = 57 generate
    XNORS <= r_LFSR(57) xnor r_LFSR(50);
  end generate poly_57;
 
  poly_58 : if Num_Bits = 58 generate
    XNORS <= r_LFSR(58) xnor r_LFSR(39);
  end generate poly_58;
 
  poly_59 : if Num_Bits = 59 generate
    XNORS <= r_LFSR(59) xnor r_LFSR(58) xnor r_LFSR(38) xnor r_LFSR(37);
  end generate poly_59;
 
  poly_60 : if Num_Bits = 60 generate
    XNORS <= r_LFSR(60) xnor r_LFSR(59);
  end generate poly_60;
 
  poly_61 : if Num_Bits = 61 generate
    XNORS <= r_LFSR(61) xnor r_LFSR(60) xnor r_LFSR(46) xnor r_LFSR(45);
  end generate poly_61;
 
  poly_62 : if Num_Bits = 62 generate
    XNORS <= r_LFSR(63) xnor r_LFSR(62);
  end generate poly_62;
  
   poly_63 : if Num_Bits = 63 generate
    XNORS <= r_LFSR(63) xnor r_LFSR(62);
  end generate poly_63;
 
  poly_64 : if Num_Bits = 64 generate
    XNORS <= r_LFSR(64) xnor r_LFSR(63) xnor r_LFSR(61) xnor r_LFSR(60);
  end generate poly_64;

data <= r_LFSR(r_LFSR'left downto 1);
data_done <= '1' when ((r_LFSR(r_LFSR'left downto 1) = seed) AND  NOT(start = '1')) else '0';

end Behavioral;
