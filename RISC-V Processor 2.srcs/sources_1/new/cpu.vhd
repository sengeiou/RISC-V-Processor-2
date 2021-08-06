library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.axi_interface_signal_groups.all;

entity cpu is
    port(
        led_out_debug : out std_logic_vector(15 downto 0);
    
        clk_cpu : in std_logic;
        reset_cpu : in std_logic
    );
end cpu;

architecture structural of cpu is
    signal master_to_interface_1 : work.axi_interface_signal_groups.FromMaster; 
    signal master_from_interface_1 : work.axi_interface_signal_groups.ToMaster; 
    
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
                                reset => reset_cpu);

    -- AXI Masters
    core_1 : entity work.core(structural)
             port map(--instruction_debug => master_from_interface_1.data_read,
                      from_master => master_to_interface_1,
                      to_master => master_from_interface_1,
             
                      clk_cpu => clk_cpu,
                      reset_cpu => reset_cpu);

    -- AXI Slaves
    led_device : entity work.led_interface(rtl)
                 port map(data_write => slave_from_interface_1.data_write,
                          addr_write => slave_from_interface_1.addr_write,
                          
                          led_out => led_out_debug,
                          
                          clk_bus => clk_cpu,
                          reset => reset_cpu);
                          
    slave_to_interface_1.data_read <= (others => '1');

end structural;
