library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity led_interface is
    port(
        -- Output to LEDs
        led_out : out std_logic_vector(15 downto 0);
        
        -- Bus signals
        addr_write : in std_logic_vector(11 downto 0);
        data_write : in std_logic_vector(31 downto 0);
        
        cs : in std_logic;
        clk_bus : in std_logic;
        reset : in std_logic
    );
end led_interface;

architecture rtl of led_interface is
    signal data_reg : std_logic_vector(31 downto 0);
    
    signal data_reg_en : std_logic;
begin
    data_reg_process : process(clk_bus, reset)
    begin
        if (rising_edge(clk_bus)) then
            if (reset = '1') then
                data_reg <= (others => '0');
            elsif (data_reg_en = '1') then
                data_reg <= data_write;
            end if;
        end if;
    end process;
    
    data_reg_en <= '1' when addr_write = X"000" else '0';
                   
    led_out <= data_reg(15 downto 0);

end rtl;
