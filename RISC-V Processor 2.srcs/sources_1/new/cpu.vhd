library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.axi_interface_signal_groups.all;

entity cpu is
    port(
        led_out_debug : out std_logic_vector(15 downto 0);
    
        clk_cpu : in std_logic;
        clk_dbg : in std_logic;
        
        reset_cpu : in std_logic
    );
end cpu;

architecture structural of cpu is
    COMPONENT axi_led_ila

    PORT (
        clk : IN STD_LOGIC;
    
    
    
        probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
    END COMPONENT  ;

    type test1 is array (2 downto 0) of ToMaster;
    type test2 is array (2 downto 0) of ToSlave;

    signal test1S : test1;
    signal test2S : test2;

    signal from_master_1 : FromMaster; 
    signal to_master_1 : ToMaster; 
    
    signal from_slave_1 : FromSlave;
    signal to_slave_1 : ToSlave;
    
    signal from_slave_2 : FromSlave;
    signal to_slave_2 : ToSlave;
    
    signal reset_inv : std_logic;
    
    signal led_temp : std_logic_vector(15 downto 0);
begin
    -- AXI Interconnect
    axi_interconnect : entity work.axi_interconnect_simple(rtl)
                       generic map(NUM_MASTERS => 2,
                                   NUM_SLAVES => 2)
                       port map(to_masters(0) => to_master_1,
                                to_masters(1) => test1S(0),
                                to_masters(2) => test1S(1),
                                to_masters(3) => test1S(2),
                       
                                from_masters(0) => from_master_1,
                                from_masters(1) => FROM_MASTER_CLEAR,       -- Indicates that no device is connected to the corresponding input
                                from_masters(2) => FROM_MASTER_CLEAR,
                                from_masters(3) => FROM_MASTER_CLEAR,

                                to_slaves(0) => to_slave_1,
                                to_slaves(1) => to_slave_2,
                                to_slaves(2) => test2S(1),
                                to_slaves(3) => test2S(2),
                                
                                from_slaves(0) => from_slave_1,
                                from_slaves(1) => from_slave_2,
                                from_slaves(2) => FROM_SLAVE_CLEAR,
                                from_slaves(3) => FROM_SLAVE_CLEAR,
                                
                                clk => clk_cpu,
                                reset => reset_inv);

    -- AXI Masters
    core_1 : entity work.core(structural)
             port map(
                      from_master => from_master_1,
                      to_master => to_master_1,
             
                      clk_cpu => clk_cpu,
                      clk_dbg => clk_dbg,
                      
                      reset_cpu => reset_cpu);

    -- AXI Slaves
    led_device : entity work.led_interface(rtl)
                 port map(data_write => to_slave_2.data_write,
                          addr_write => to_slave_2.addr_write(11 downto 0),
                          
                          led_out => led_temp,
                          
                          clk_bus => clk_cpu,
                          reset => reset_cpu);
                          
    rom_memory : entity work.rom_memory_2(structural)
                 port map(data_bus => from_slave_1.data_read,
                          addr_bus => to_slave_1.addr_read(11 downto 2),
                          
                          data_ready => from_slave_1.data_ready,
                          
                          clk => clk_cpu);
                          
    uart_controller : entity work.uart_interface(rtl)
                      port map(data_read_bus => from_slave_3.data_read,
                               data_write_bus => to_slave_3.data_write,
                               
                               addr_bus => to_slave_3.addr_)
                          
    reset_inv <= not reset_cpu;     
    led_out_debug <= led_temp;                     


end structural;
