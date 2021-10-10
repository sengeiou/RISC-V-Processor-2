library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.axi_interface_signal_groups.all;

entity axi_decoder is
    port(
        axi_master_0_out : in MasterBusInterfaceOut;
        axi_master_0_master_hndshk : in HandshakeMasterSrc;
        axi_master_0_slave_hndshk : out HandshakeMasterSrc;
        
        axi_slave_0_in : out MasterBusInterfaceOut;
        axi_slave_0_master_hndshk : out HandshakeMasterSrc;
        axi_slave_0_slave_hndshk : in HandshakeSlaveSrc;
        
        axi_slave_1_in : out MasterBusInterfaceOut;
        axi_slave_1_master_hndshk : out HandshakeMasterSrc;
        axi_slave_1_slave_hndshk : in HandshakeSlaveSrc
    );
end axi_decoder;

architecture rtl of axi_decoder is

begin
    decoder_proc : process()
    begin
        if (axi_master_0_out.
    end process;

end rtl;
