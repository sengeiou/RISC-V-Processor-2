library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity led_interface is
    port(
        -- Output to LEDs
        led_out : out std_logic_vector(15 downto 0);
        
        -- Bus signals
        addr_write : in std_logic_vector(11 downto 0);
        data_write : in std_logic_vector(31 downto 0);
        
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
    
    data_reg_en <= (not addr_write(11)) and
                   (not addr_write(10)) and
                   (not addr_write(9)) and
                   (not addr_write(8)) and
                   (not addr_write(7)) and
                   (not addr_write(6)) and
                   (not addr_write(5)) and
                   (not addr_write(4)) and
                   (not addr_write(3)) and
                   (not addr_write(2)) and
                   (not addr_write(1)) and
                   (not addr_write(0));
                   
    led_out <= data_reg(15 downto 0);

end rtl;
