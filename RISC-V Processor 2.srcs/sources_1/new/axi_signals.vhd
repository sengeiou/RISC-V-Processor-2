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
        burst_type : std_logic_vector(1 downto 0);   -- Burst type    
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
        burst_type : std_logic_vector(1 downto 0);   -- Burst type
    end record ReadAddressChannel;
    
    type ReadDataChannel is record
        data : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);
        resp : std_logic_vector(1 downto 0);    -- Response vector
        last : std_logic;
    end record ReadDataChannel;
    
    type HandshakeWriteMaster is record
        awvalid : std_logic;
        wvalid : std_logic;
        
        bready : std_logic;
    end record HandshakeWriteMaster;
    
    type HandshakeReadMaster is record
        arvalid : std_logic;
        
        rready : std_logic;
    end record HandshakeReadMaster;
    
    type HandshakeWriteSlave is record
        awready : std_logic;
        wready : std_logic;
        
        bvalid : std_logic;
    end record HandshakeWriteSlave;
    
    type HandshakeReadSlave is record
        arready : std_logic;
        
        rvalid : std_logic;
    end record HandshakeReadSlave;
    
    type FromMaster is record
        -- Data signals
        data_write : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);
        
        -- Address signals
        addr_write : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
        addr_read : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
        
        -- Control signals
        burst_len : std_logic_vector(7 downto 0);
        burst_size : std_logic_vector(2 downto 0);
        burst_type : std_logic_vector(1 downto 0);
        
        execute_read : std_logic;
        execute_write : std_logic;
    end record FromMaster;
    
    type ToMaster is record
        -- Data signals
        data_read : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);
        
        -- Control signals
        done_read : std_logic;
        done_write : std_logic;
    end record ToMaster;
    
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
    
    -- ========== CONSTANTS ==========
    constant BURST_FIXED : std_logic_vector(1 downto 0) := "00";
    constant BURST_INCR : std_logic_vector(1 downto 0) := "01";
    constant BURST_WRAP : std_logic_vector(1 downto 0) := "10";
    
    constant RESP_OKAY : std_logic_vector(1 downto 0) := "00";
    constant RESP_EXOKAY : std_logic_vector(1 downto 0) := "01";
    constant RESP_SLVERR : std_logic_vector(1 downto 0) := "10";
    constant RESP_DECERR : std_logic_vector(1 downto 0) := "11";
end axi_interface_signal_groups;

package body axi_interface_signal_groups is

end axi_interface_signal_groups;









