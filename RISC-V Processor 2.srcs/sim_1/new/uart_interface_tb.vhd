library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_interface_tb is

end uart_interface_tb;

architecture Behavioral of uart_interface_tb is
    signal clk, reset, cs : std_logic;
    signal tx_line, rx_line : std_logic;
    
    signal data_read_bus, data_write_bus : std_logic_vector(7 downto 0);
    signal addr_bus : std_logic_vector(2 downto 0);
    
    constant T : time := 20ns;
begin
    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    reset <= '1', '0' after T * 2;
    
    uut : entity work.uart_interface(rtl)
          port map(addr_bus => addr_bus,
                   data_read_bus => data_read_bus,
                   data_write_bus => data_write_bus,
                   tx_line => tx_line,
                   rx_line => rx_line,
                   cs => cs,
                   reset => reset,
                   clk => clk);
                   
    process
    begin
        wait for T * 5;
        cs <= '1';
        addr_bus <= "001";
        data_write_bus <= X"BA";
        wait for T;
        cs <= '0';
        data_write_bus <= X"00";
        addr_bus <= "000";
    end process;

end Behavioral;
