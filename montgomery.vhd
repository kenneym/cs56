library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity montgomery is
    generic (
    num_bits_ab : integer := 8;
    num_bits_n :integer := 8
    );
    Port (mclk    :     in STD_LOGIC;
          a       :     in STD_LOGIC_VECTOR(num_bits_ab-1 downto 0);
          b       :     in STD_LOGIC_VECTOR(num_bits_ab-1 downto 0);
          n       :     in STD_LOGIC_VECTOR(num_bits_n-1 downto 0);
          toggle  :     in STD_LOGIC;
          modmult  :     out STD_LOGIC_VECTOR(num_bits_n-1 downto 0));
end montgomery;

architecture Behavioral of montgomery is

signal a_c, b_c : unsigned(num_bits_ab-1 downto 0) := (others => '0');
signal n_c, m, o_reg, m_temp   : unsigned(num_bits_n-1 downto 0) := (others => '0');
signal l_en, m_en, o_en, count_en, m2_en, mn2_en, mn_en   : std_logic := '0';
signal counts   :   unsigned(num_bits_ab-1 downto 0) := (others => '0');
signal count    :   integer := 0;

type state_type is (nop, multiply, check, mn);
signal current_state, next_state : state_type := nop;


begin 

nextStateLogic: process(current_state, toggle, b_c, M_temp, count)
begin
    
    next_state <= current_state;
    
    l_en <= '0';
    m_en <= '0';
    o_en <= '0';
    count_en <= '0';
    m2_en <= '0';
    mn2_en <= '0';
    mn_en <= '0';
    
    case (current_state) is
    
    when nop =>
    
        if toggle = '1' then
                next_state <= multiply;
                l_en <= '1';
        end if;
        
        m <= (others => '0');

    
     when multiply =>
        count_en <= '1';
        if count = a_c'left then
            o_en <= '1';
            next_state <= nop;
        else
            if (b_c(count) = '1') then
                m_en <= '1';
            end if;
            next_state <= check;
        end if;
     
     when check =>
        if (M_temp(0) = '1') then
           m2_en <= '1';
           next_state <= multiply;
        else
            mn_en <= '1';
            next_state <= mn;
        end if;
     
     when mn =>
        mn2_en <= '1';
        next_state <= multiply;
     end case;
     
     
end process nextStateLogic;

stateUpdate: process(mclk)
begin
    if rising_edge(mclk) then
        
        current_state <= next_state;
        
        if count_en = '1' then
            count <= count + 1;
         end if; 
         
         if l_en = '1' then
            a_c <= UNSIGNED(a);
            b_c <= UNSIGNED(b); 
            n_c <= UNSIGNED(n);
         end if;
         
         if m_en = '1' then
            --M <= M + a_c;  
         end if;
         
         if m2_en = '1' then
            M <= unsigned(shift_right(M, 1));
             --M <= '0' & M(M'left downto 1);
         end if;
         if mn_en = '1' then
            M_temp <= unsigned(M + n_c);
         end if;
         if mn2_en = '1' then
            M <= unsigned(shift_right((M_temp), 1));
           -- M <= '0' & (M(m'left downto 1) + n_c(n_c'left downto 1));
         end if; 
         
         if o_en = '1' then
            o_reg <= m;
         end if;
         
     end if;
     
end process stateUpdate;

modmult <= STD_LOGIC_VECTOR(o_reg);

end behavioral;