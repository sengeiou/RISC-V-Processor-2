library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_bus_tb is
    
end axi_bus_tb;

architecture Behavioral of axi_bus_tb is
    signal read_channels : work.axi_interface_signal_groups.ReadChannels;
    signal write_channels : work.axi_interface_signal_groups.WriteChannels;
    signal handshake_master_src : work.axi_interface_signal_groups.HandshakeMasterSrc;
    signal handshake_slave_src : work.axi_interface_signal_groups.HandshakeSlaveSrc;
    
    signal addr_write, addr_read, data_write : std_logic_vector(31 downto 0);
    signal data_in_slave : std_logic_vector(31 downto 0);
    
    
    signal clk, reset, execute_w, execute_r : std_logic;
    
    constant T : time := 20ns;
begin
    clock : process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    reset <= '0', '1' after 20ns;

    axi_master_1 : entity work.axi_master_interface(rtl)
                   port map(read_channels => read_channels,
                            write_channels => write_channels,
                            master_handshake => handshake_master_src,
                            slave_handshake => handshake_slave_src,
                            
                            data_write => data_write,
                            addr_write => addr_write,
                            execute_write => execute_w,
                            execute_read => execute_r,
                            
                            addr_read => addr_read,
                            
                            clk => clk,
                            reset => reset);
                            
    axi_slave_1 : entity work.axi_slave_interface(rtl)
                  port map(read_channels => read_channels,
                           write_channels => write_channels,
                           master_handshake => handshake_master_src,
                           slave_handshake => handshake_slave_src,
                           
                           data_in => data_in_slave,
                           
                           clk => clk,
                           reset => reset);
                           
    tb : process
    begin
        execute_w <= '0';
        execute_r <= '0';
        wait for 100ns;
        data_write <= X"F0F0_F0F0";
        addr_write <= X"0F0F_0F0F";
        execute_w <= '1';
        
        wait for 20ns;
        execute_w <= '0';
        wait for T * 10;
        data_write <= X"AAAA_AAAA";
        addr_write <= X"BBBB_BBBB";
        execute_w <= '1';
        
        wait for 20ns;
        execute_w <= '0';
        wait for T * 20;
        addr_read <= X"CCCC_CCCC";
        data_in_slave <= X"ABCD_ABCD";
        execute_r <= '1';
        wait for 20ns;
        execute_r <= '0';
        wait for T * 10;
    end process;

end Behavioral;






