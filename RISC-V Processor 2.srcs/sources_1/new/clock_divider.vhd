library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_divider is
    port(
        divider : in std_logic_vector(15 downto 0);
    
        clk_src : in std_logic;
        clk_div : out std_logic;
        
        reset : in std_logic
    );
end clock_divider;

architecture rtl of clock_divider is
    signal divider_reg : std_logic_vector(15 downto 0);
    signal divider_changed : std_logic;

    signal counter_reg : std_logic_vector(15 downto 0);
    signal counter_reg_next : std_logic_vector(15 downto 0);
    
    signal clk_div_ff_posedge : std_logic;
    signal ff_posedge_en : std_logic;
    
    signal clk_div_ff_negedge : std_logic;
    signal ff_negedge_en : std_logic;
    
    signal clk_div_ff_even : std_logic;
    signal ff_even_en : std_logic;
    
    signal counter_divider_equal : std_logic;
begin
    divider_reg_process : process(clk_src)
    begin
        if (rising_edge(clk_src)) then
            divider_reg <= divider;
        end if;
    end process;

    divider_changed <= '0' when divider_reg = divider else
                       '1';

    counter_reg_process : process(clk_src)
    begin
        if (rising_edge(clk_src)) then
            if (counter_divider_equal = '1' or reset = '1' or divider_changed = '1') then
                counter_reg <= (others => '0');
            else
                counter_reg <= counter_reg_next;
            end if;
        end if;
    end process;
    
    counter_reg_next <= std_logic_vector(unsigned(counter_reg) + 1);
    
    detect_equality : process(counter_reg, divider)
    begin
        if (counter_reg = std_logic_vector(unsigned(divider) - 1)) then
            counter_divider_equal <= '1';
        else
            counter_divider_equal <= '0';
        end if;
    end process;
    
    ff_posedge_process : process(clk_src)
    begin
        if (rising_edge(clk_src)) then
            if (reset = '1') then
                clk_div_ff_posedge <= '0';
            elsif (ff_posedge_en = '1') then
                clk_div_ff_posedge <= not clk_div_ff_posedge;
            end if;
        end if;
    end process;

    ff_negedge_process : process(clk_src)
    begin
        if (falling_edge(clk_src)) then
            if (reset = '1') then
                clk_div_ff_negedge <= '0';
            elsif (ff_negedge_en = '1') then
                clk_div_ff_negedge <= not clk_div_ff_negedge;
            end if;
        end if;
    end process;   
    
    ff_even_process : process(clk_src)
    begin
        if (rising_edge(clk_src)) then
            if (reset = '1') then
                clk_div_ff_even <= '0';
            elsif (ff_even_en = '1') then
                clk_div_ff_even <= not clk_div_ff_even;
            end if;
        end if;
    end process;   
    
    process(counter_reg, divider)
    begin
        ff_posedge_en <= '0';
        ff_negedge_en <= '0';
        ff_even_en <= '0';
        
        if (counter_reg = X"0000") then
            ff_posedge_en <= '1';
            ff_even_en <= '1';
        end if;
        
        if (counter_reg = std_logic_vector(shift_right(unsigned(divider) + 1, 1))) then
            ff_negedge_en <= '1';
        end if;
        
        if (counter_reg = std_logic_vector(shift_right(unsigned(divider), 1))) then
            ff_even_en <= '1';
        end if;
    end process;
    
    process(divider, clk_div_ff_negedge, clk_div_ff_posedge, clk_div_ff_even)
    begin
        if (divider(0) = '1') then
            clk_div <= clk_div_ff_negedge xor clk_div_ff_posedge;
        else
            clk_div <= clk_div_ff_even;
        end if;
    end process;


end rtl;












