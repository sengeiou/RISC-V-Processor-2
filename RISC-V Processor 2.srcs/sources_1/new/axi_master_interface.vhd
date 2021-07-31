library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_master_interface is
    port(
        -- CHANNEL SIGNALS
--        write_address_channel : out work.axi_signals.WriteAddressChannel;
--        write_data_channel : out work.axi_signals.WriteDataChannel;
--        write_response_channel : out work.axi_signals.WriteResponseChannel;
--        read_address_channel : in work.axi_signals.ReadAddressChannel;
--        read_data_channel : in work.axi_signals.ReadDataChannel;
        write_channels : out work.axi_signals.WriteChannels;
        read_channels : in work.axi_signals.ReadChannels;
        
        -- HANDSHAKE SIGNALS
        master_handshake : out work.axi_signals.HandshakeMasterSrc;
        slave_handshake : in work.axi_signals.HandshakeSlaveSrc
--        awvalid : out std_logic;
--        awready : in std_logic;
        
--        wvalid : out std_logic;
--        wready : in std_logic;
        
--        bvalid : in std_logic;
--        bready : out std_logic;
        
--        arvalid : out std_logic;
--        arready : in std_logic;
        
--        rvalid : in std_logic;
--        rready : out std_logic
    );
end axi_master_interface;

architecture rtl of axi_master_interface is

begin


end rtl;
