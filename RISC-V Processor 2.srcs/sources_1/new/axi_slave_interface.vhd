----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/31/2021 11:02:55 AM
-- Design Name: 
-- Module Name: axi_slave_interface - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_slave_interface is
    port(
        -- CHANNEL SIGNALS
        write_address_channel : in work.axi_signals.WriteAddressChannel;
        write_data_channel : in work.axi_signals.WriteDataChannel;
        write_response_channel : in work.axi_signals.WriteResponseChannel;
        read_address_channel : out work.axi_signals.ReadAddressChannel;
        read_data_channel : out work.axi_signals.ReadDataChannel;
        
        -- HANDSHAKE SIGNALS
        awvalid : in std_logic;
        awready : out std_logic;
        
        wvalid : in std_logic;
        wready : out std_logic;
        
        bvalid : out std_logic;
        bready : in std_logic;
        
        arvalid : in std_logic;
        arready : out std_logic;
        
        rvalid : out std_logic;
        rready : in std_logic
    );
end axi_slave_interface;

architecture rtl of axi_slave_interface is

begin


end rtl;











