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
signal o_reg, n_c  : unsigned(num_bits_n-1 downto 0) := (others => '0');
signal m, q, pad      : unsigned(num_bits_n downto 0) := (others => '0');
signal temp    : unsigned(2*num_bits_n downto 0) := (others => '0');
signal m_temp   : unsigned(2*num_bits_n+1 downto 0) := (others => '0'); 
signal l_en, m_en, o_en, count_en, m2_en, mn2_en, mn_en, m3_en, qc_en  : std_logic := '0';
signal counts   :   unsigned(num_bits_ab-1 downto 0) := (others => '0');
signal count    :   integer := 0;

type state_type is (nop, add, compute, check);
signal current_state, next_state : state_type := nop;


begin 

nextStateLogic: process(current_state, toggle, b_c, count, a_c)
begin
    
    next_state <= current_state;
    
    l_en <= '0';
    m_en <= '0';
    o_en <= '0';
    count_en <= '0';
    m2_en <= '0';
    mn2_en <= '0';
    mn_en <= '0';
    m3_en <= '0';
    qc_en <= '0';
    case (current_state) is
    
    when nop =>
    
        if toggle = '1' then
                next_state <= add;
                l_en <= '1';
        end if;

    
     when add =>
     
        count_en <= '1';
        if count = a_c'left then
            o_en <= '1';
            next_state <= nop;
        else
            if (b_c(count) = '1') then
                m_en <= '1';
            else
                mn2_en <= '1';
            end if;
            next_state <= compute;
        end if;
        
     when compute =>
        qc_en <= '1';
        next_state <= check;
        
     when check =>
     if (b_c(count) = '1') then
           m2_en <= '1';
     else
            m3_en <= '1';
     end if;
           next_state <= add;
     end case;
     
     
end process nextStateLogic;

stateUpdate: process(mclk)
begin
    if rising_edge(mclk) then
        
        current_state <= next_state;
        
        M <= '0' & M_temp(M'left downto 1);
        M <= '0' & M_temp(M'left downto 1);
        
        if count_en = '1' then
            count <= count + 1;
         end if; 
         
         if l_en = '1' then
            a_c <= UNSIGNED(a);
            b_c <= UNSIGNED(b); 
            n_c <= UNSIGNED(n);
         end if;
         
         if m_en = '1' then
            q <= (M + A_C) mod 2;  
         end if;
         
         if mn2_en = '1' then
            q <= (M) mod 2;
         end if;
         
         if qc_en = '1' then
            temp <= q*n_c;
            --temp <= "00000000001";
         end if;
         
         if m2_en = '1' then
            M_temp <= (pad & M) + (pad & '0' & A_C) + temp;
         end if;
         
         if m3_en = '1' then
            M_temp <= (pad & M) + temp;
         end if;
         
         if o_en = '1' then
            if unsigned(M) >= unsigned(N) then
                o_reg <= m(m'left -1 downto 0) - unsigned(n);
            else
                o_reg <= m(m'left -1 downto 0);
            end if;
         end if;
         
     end if;
     
end process stateUpdate;

modmult <= STD_LOGIC_VECTOR(o_reg);

end behavioral;