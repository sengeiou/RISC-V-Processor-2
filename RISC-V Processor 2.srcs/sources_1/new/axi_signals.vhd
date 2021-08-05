library ieee;
use ieee.std_logic_1164.all;

package axi_interface_signal_groups is
--    generic(
--        AXI_DATA_BUS_WIDTH : integer range 3 to 10 := 5
--    );
    
    constant AXI_DATA_BUS_WIDTH : integer range 3 to 10 := 5;
    constant AXI_ADDR_BUS_WIDTH : integer range 3 to 10 := 5;
    
    type integer_bus_width is range 3 to 10;
    
    type WriteAddressChannel is record
        addr : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
        len : std_logic_vector(7 downto 0);     -- Burst length
        size : std_logic_vector(2 downto 0);    -- Num of bytes to transfer    
        burst : std_logic_vector(1 downto 0);   -- Burst type    
    end record WriteAddressChannel;
    
    type WriteDataChannel is record
        -- DATA
        data : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);
        -- CONTROL
        strb : std_logic_vector((2 ** AXI_DATA_BUS_WIDTH / 8) - 1 downto 0);
        last : std_logic;
    end record WriteDataChannel;
    
    type WriteResponseChannel is record
        resp : std_logic_vector(1 downto 0);    -- Response vector
    end record WriteResponseChannel;
    
    type ReadAddressChannel is record
        addr : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
        len : std_logic_vector(7 downto 0);     -- Burst length
        size : std_logic_vector(2 downto 0);    -- Num of bytes to transfer
        burst : std_logic_vector(1 downto 0);   -- Burst type
    end record ReadAddressChannel;
    
    type ReadDataChannel is record
        data : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);
        resp : std_logic_vector(1 downto 0);    -- Response vector
        last : std_logic;
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
    
    type FromMaster is record
        write_addr_ch : WriteAddressChannel;
        write_data_ch : WriteDataChannel;
        read_addr_ch : ReadAddressChannel;
    end record FromMaster;
    
    type ToMaster is record
        read_data_ch : ReadDataChannel;
        write_resp_ch : WriteResponseChannel;
    end record ToMaster;
    
    type ToMasterFromInterface is record
        -- Data signals
        data_write : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);
        
        -- Address signals
        addr_write : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
        
        -- Control signals
        execute_read : std_logic;
        execute_write : std_logic;
    end record ToMasterFromInterface;
    
    type FromMasterToInterface is record
        -- Data signals
        data_read : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);
        
        -- Address signals
        addr_read : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    end record FromMasterToInterface;
    
    type FromSlave is record
        -- Data signals
        data_read : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);
        
        -- Address signals
    end record FromSlave;

    type ToSlave is record
        -- Data signals
        data_write : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);
        
        -- Address signals
        addr_read : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
        addr_write : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    end record ToSlave;
end axi_interface_signal_groups;

package body axi_interface_signal_groups is

end axi_interface_signal_groups;









