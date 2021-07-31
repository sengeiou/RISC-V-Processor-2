package axi_signals is new work.axi_interface_signal_groups
    generic map (AXI_DATA_BUS_WIDTH => 5);

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_interconnect is
    port(
        master_read_1 : out work.axi_signals.ReadSignals;
        master_write_1 : in work.axi_signals.WriteSignals;
    );
end axi_interconnect;

architecture rtl of axi_interconnect is

begin


end rtl;
