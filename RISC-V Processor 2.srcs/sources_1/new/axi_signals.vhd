library ieee;
use ieee.std_logic_1164.all;

package axi_interface_signal_groups is
    generic(
        AXI_DATA_BUS_WIDTH : integer range 3 to 10
    );
    
    type integer_bus_width is range 3 to 10;
    
    type WriteAddressChannel is record
        len : std_logic_vector(7 downto 0);     -- Burst length
        size : std_logic_vector(2 downto 0);    -- Num of bytes to transfer    
        burst : std_logic_vector(1 downto 0);   -- Burst type    
    end record WriteAddressChannel;
    
    type WriteDataChannel is record
        -- DATA
        data : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);
        -- CONTROL
        strb : std_logic_vector((2 ** AXI_DATA_BUS_WIDTH / 8) - 1 downto 0);
    end record WriteDataChannel;
    
    type WriteResponseChannel is record
        resp : std_logic_vector(1 downto 0);    -- Response vector
    end record WriteResponseChannel;
    
    type ReadAddressChannel is record
        len : std_logic_vector(7 downto 0);     -- Burst length
        size : std_logic_vector(2 downto 0);    -- Num of bytes to transfer
        burst : std_logic_vector(1 downto 0);   -- Burst type
    end record ReadAddressChannel;
    
    type ReadDataChannel is record
        resp : std_logic_vector(1 downto 0);    -- Response vector
    end record ReadDataChannel;
    
    type HandshakeMasterSrc is record
        awvalid : std_logic;
        wvalid : std_logic;
        arvalid : std_logic;
        
        bready : std_logic;
        rready : std_logic;
    end record HandshakeMasterSrc;
    
    type HandshakeSlaveSrc is record
        bvalid : std_logic;
        rvalid : std_logic;
        
        arready : std_logic;
        awready : std_logic;
        wready : std_logic;
    end record HandshakeSlaveSrc;
    
    type WriteChannels is record
        write_addr_ch : WriteAddressChannel;
        write_data_ch : WriteDataChannel;
        write_resp_ch : WriteResponseChannel;
    end record WriteChannels;
    
    type ReadChannels is record
        read_addr_ch : ReadAddressChannel;
        read_data_ch : ReadDataChannel;
    end record ReadChannels;
end axi_interface_signal_groups;

package body axi_interface_signal_groups is

end axi_interface_signal_groups;