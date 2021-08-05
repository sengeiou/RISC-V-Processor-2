library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.axi_interface_signal_groups.all;

entity cpu is
    port(
        clk_cpu : in std_logic;
        reset_cpu : in std_logic
    );
end cpu;

architecture structural of cpu is
    signal master_to_interface_1 : work.axi_interface_signal_groups.ToMasterFromInterface; 
    signal master_from_interface_1 : work.axi_interface_signal_groups.FromMasterToInterface; 
    
    signal slave_to_interface_1 : work.axi_interface_signal_groups.FromSlave;
    signal slave_from_interface_1 : work.axi_interface_signal_groups.ToSlave;
begin
    -- AXI Interconnect
    axi_interconnect : entity work.axi_interconnect(rtl)
                       port map(master_to_interface_1 => master_to_interface_1,
                                master_from_interface_1 => master_from_interface_1,
                                
                                slave_to_interface_1 => slave_to_interface_1,
                                slave_from_interface_1 => slave_from_interface_1,
                                
                                clk => clk_cpu,
                                reset => reset_cpu)

    core_1 : entity work.core(structural)
             port map(instruction_debug => ,
                      clk_cpu => clk_cpu,
                      reset_cpu => reset_cpu)

end structural;
