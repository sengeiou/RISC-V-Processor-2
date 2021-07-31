--package axi_signals is new work.axi_interface_signal_groups;
--    generic map (AXI_DATA_BUS_WIDTH => 5);

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.axi_interface_signal_groups.all;

entity axi_interconnect is
    port(
        -- Master 1 port
        master_read_1 : out work.axi_interface_signal_groups.ToMaster;
        master_write_1 : in work.axi_interface_signal_groups.FromMaster;
        master_handshake_to_slave_1 : in work.axi_interface_signal_groups.HandshakeMasterSrc;
        master_handshake_from_slave_1 : out work.axi_interface_signal_groups.HandshakeSlaveSrc;
        
        -- Slave 1 port 
        slave_read_1 : in work.axi_interface_signal_groups.ToMaster;
        slave_write_1 : out work.axi_interface_signal_groups.FromMaster;
        slave_handshake_to_master_1 : in work.axi_interface_signal_groups.HandshakeSlaveSrc;
        slave_handshake_from_master_1 : out work.axi_interface_signal_groups.HandshakeMasterSrc
    );
end axi_interconnect;

architecture rtl of axi_interconnect is
    signal to_master_1 : work.axi_interface_signal_groups.ToMaster;
    signal from_master : work.axi_interface_signal_groups.FromMaster;
    signal handshake_master_src_1 : work.axi_interface_signal_groups.HandshakeMasterSrc;
    signal handshake_slave_src_1 : work.axi_interface_signal_groups.HandshakeSlaveSrc;
begin
    to_master_1 <= slave_read_1;
    master_read_1 <= to_master_1;
    
    from_master <= master_write_1;
    slave_write_1 <= from_master;
    
    handshake_master_src_1 <= master_handshake_to_slave_1;
    slave_handshake_from_master_1 <= handshake_master_src_1;
    
    handshake_slave_src_1 <= slave_handshake_to_master_1;
    master_handshake_from_slave_1 <= handshake_slave_src_1;
end rtl;
