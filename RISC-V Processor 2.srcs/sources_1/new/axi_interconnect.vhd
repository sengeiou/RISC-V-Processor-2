--package axi_signals is new work.axi_interface_signal_groups;
--    generic map (AXI_DATA_BUS_WIDTH => 5);

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.axi_interface_signal_groups.all;

entity axi_interconnect is
    port(
        -- Master 1 port
        master_to_interface_1 : in work.axi_interface_signal_groups.FromMaster; 
        master_from_interface_1 : out work.axi_interface_signal_groups.ToMaster; 
        
        -- Slave 1 port 
        slave_to_interface_1 : in work.axi_interface_signal_groups.FromSlave;
        slave_from_interface_1 : out work.axi_interface_signal_groups.ToSlave;
        
        -- Control signals
        clk : in std_logic;
        reset : in std_logic
    );
end axi_interconnect;

architecture rtl of axi_interconnect is
    signal read_bus_1 : work.axi_interface_signal_groups.ToMasterInterface;
    signal write_bus_1 : work.axi_interface_signal_groups.FromMasterInterface;
    signal handshake_master_src_1 : work.axi_interface_signal_groups.HandshakeMasterSrc;
    signal handshake_slave_src_1 : work.axi_interface_signal_groups.HandshakeSlaveSrc;
    
    signal axi_reset : std_logic;
begin
    axi_master_1 : entity work.axi_master_interface(rtl)
                   port map(-- Interconnect side signals
                            to_master => read_bus_1,
                            from_master => write_bus_1,
                            master_handshake => handshake_master_src_1,
                            slave_handshake => handshake_slave_src_1,
                            
                            -- Device side signals
                            interface_to_master => master_from_interface_1,
                            master_to_interface => master_to_interface_1,
                            
                            clk => clk,
                            reset => axi_reset);
                            
    axi_slave_1 : entity work.axi_slave_interface(rtl)
                  port map(-- Interconnect side signals
                           to_master_interface => read_bus_1,
                           from_master_interface => write_bus_1,
                           master_handshake => handshake_master_src_1,
                           slave_handshake => handshake_slave_src_1,
                           
                           -- Device side signals
                           from_slave => slave_to_interface_1,
                           to_slave => slave_from_interface_1,
                           
                           clk => clk,
                           reset => axi_reset);
                           
    axi_reset <= not reset;

end rtl;