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
    type test1 is array (2 downto 0) of ToMaster;
    type test2 is array (2 downto 0) of ToSlave;

    signal test1S : test1;
    signal test2S : test2;

    signal master_to_interface_1 : FromMaster; 
    signal master_from_interface_1 : ToMaster; 
    
    signal slave_from_interface_1 : FromSlave;
    signal slave_to_interface_1 : ToSlave;
    
    signal reset_inv : std_logic;
begin
    -- AXI Interconnect
    axi_interconnect : entity work.axi_interconnect_simple(rtl)
                       generic map(NUM_MASTERS => 2,
                                   NUM_SLAVES => 2)
                       port map(to_masters(0) => master_from_interface_1,
                                to_masters(1) => test1S(0),
                                to_masters(2) => test1S(1),
                                to_masters(3) => test1S(2),
                       
                                from_masters(0) => master_to_interface_1,
                                from_masters(1) => FROM_MASTER_CLEAR,       -- Indicates that no device is connected to the corresponding input
                                from_masters(2) => FROM_MASTER_CLEAR,
                                from_masters(3) => FROM_MASTER_CLEAR,

                                to_slaves(0) => slave_to_interface_1,
                                to_slaves(1) => test2S(0),
                                to_slaves(2) => test2S(1),
                                to_slaves(3) => test2S(2),
                                
                                from_slaves(0) => slave_from_interface_1,
                                from_slaves(1) => FROM_SLAVE_CLEAR,
                                from_slaves(2) => FROM_SLAVE_CLEAR,
                                from_slaves(3) => FROM_SLAVE_CLEAR,
                                
                                clk => clk_cpu,
                                reset => reset_inv);

    -- AXI Masters
    core_1 : entity work.core(structural)
             port map(
                      from_master => master_to_interface_1,
                      to_master => master_from_interface_1,
             
                      clk_cpu => clk_cpu,
                      reset_cpu => reset_cpu);

    -- AXI Slaves
--    led_device : entity work.led_interface(rtl)
--                 port map(data_write => slave_from_interface_1.data_write,
--                          addr_write => slave_from_interface_1.addr_write,
                          
--                          led_out => led_out_debug,
                          
--                          clk_bus => clk_cpu,
--                          reset => reset_cpu);
                          
    rom_memory : entity work.rom_memory_2(structural)
                 port map(data_bus => slave_from_interface_1.data_read,
                          addr_bus => slave_to_interface_1.addr_read(11 downto 2),
                          
                          clk => clk_cpu);
                          
    reset_inv <= not reset_cpu;                          

end structural;
