library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.axi_interface_signal_groups.all;

entity axi_read_decoder_simple is
    port(
        address_bus : in std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
        
        read_slave_sel : 
    );
end axi_read_decoder_simple;

architecture rtl of axi_read_decoder_simple is

begin


end rtl;
