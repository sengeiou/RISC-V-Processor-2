library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use WORK.PKG_AXI.ALL;

entity cpu is
    port(
        led_out_debug : out std_logic_vector(15 downto 0);
        
        uart_rx : in std_logic;
        uart_tx : out std_logic;
        uart_cts : out std_logic;
        uart_rts : in std_logic;
    
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
    
COMPONENT blk_mem_gen_0
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

    type test1 is array (2 downto 0) of FromMasterInterface;
    type test2 is array (2 downto 0) of FromSlaveInterface;

    signal test1S : test1;
    signal test2S : test2;

    signal from_master_1 : ToMasterInterface; 
    signal to_master_1 : FromMasterInterface; 
    
    signal from_slave_1 : ToSlaveInterface;
    signal to_slave_1 : FromSlaveInterface;
    
    signal from_slave_2 : ToSlaveInterface;
    signal to_slave_2 : FromSlaveInterface;
    
    signal from_slave_3 : ToSlaveInterface;
    signal to_slave_3 : FromSlaveInterface;
    
    signal resetn : std_logic;
    signal ram_en : std_logic;
    signal ram_read_valid_1 : std_logic;
    signal ram_read_valid_2 : std_logic;
    
    signal led_temp : std_logic_vector(15 downto 0);
begin
    -- AXI Interconnect
    axi_interconnect : entity work.axi_interconnect_simple(rtl)
                       generic map(NUM_MASTERS => 4,
                                   NUM_SLAVES => 4)
                       port map(to_masters(0) => to_master_1,
                                to_masters(1) => test1S(0),
                                to_masters(2) => test1S(1),
                                to_masters(3) => test1S(2),
                       
                                from_masters(0) => from_master_1,
                                from_masters(1) => TO_MASTER_CLEAR,       -- Indicates that no device is connected to the corresponding input
                                from_masters(2) => TO_MASTER_CLEAR,
                                from_masters(3) => TO_MASTER_CLEAR,

                                to_slaves(0) => to_slave_1,
                                to_slaves(1) => to_slave_2,
                                to_slaves(2) => to_slave_3,
                                to_slaves(3) => test2S(2),
                                
                                from_slaves(0) => from_slave_1,
                                from_slaves(1) => from_slave_2,
                                from_slaves(2) => from_slave_3,
                                from_slaves(3) => FROM_SLAVE_CLEAR,
                                
                                clk => clk_cpu,
                                reset => resetn);

    -- AXI Masters
    core_1 : entity work.core(structural)
             port map(
                      from_master_1 => from_master_1,
                      to_master_1 => to_master_1,
             
                      clk => clk_cpu,
                      clk_dbg => clk_dbg,
                      
                      reset => reset_cpu);

    -- AXI Slaves
    led_device : entity work.led_interface(rtl)
                 port map(data_write => to_slave_2.data_write,
                          addr_write => to_slave_2.addr_write(11 downto 0),
                          
                          led_out => led_temp,
                          
                          clk_bus => clk_cpu,
                          reset => reset_cpu);
                          
--    rom_memory : entity work.rom_memory_2(structural)
--                 port map(data_bus => from_slave_1.data,
--                          addr_bus => to_slave_1.addr_read(11 downto 2),
                          
--                          data_ready => from_slave_1.data_valid,
                          
--                          clk => clk_cpu);
                      
    -- Just a 1 clk delay to give ram time to perform a read
    process(clk_cpu)
    begin
        if (rising_edge(clk_cpu)) then
            if (reset_cpu = '1') then
                ram_read_valid_1 <= '0';
                ram_read_valid_2 <= '0';
            else
                ram_read_valid_1 <= to_slave_1.addr_read_valid;   
                ram_read_valid_2 <= ram_read_valid_1;
            end if;
        end if;
    end process;
                          
your_instance_name : blk_mem_gen_0
  PORT MAP (
    clka => clk_cpu,
    ena => to_slave_1.addr_write_valid,
    wea(0) => to_slave_1.addr_write_valid,
    addra => to_slave_1.addr_write(9 downto 0),
    dina => to_slave_1.data_write,
    clkb => clk_cpu,
    enb => to_slave_1.addr_read_valid,
    addrb => to_slave_1.addr_read(9 downto 0),
    doutb => from_slave_1.data
  );
    from_slave_1.data_valid <= ram_read_valid_2;
                          
    from_slave_3.data(31 downto 8) <= (others => '0');
    
    uart_controller : entity work.uart_interface(rtl)
                      port map(data_read_bus => from_slave_3.data(7 downto 0),
                               data_write_bus => to_slave_3.data_write(7 downto 0),
                               
                               addr_read_bus => to_slave_3.addr_read(2 downto 0),
                               addr_write_bus => to_slave_3.addr_write(2 downto 0),
                               
                               rx => uart_rx,
                               tx => uart_tx,
                               cts => uart_rts,
                               rts => uart_cts,
                               dsr => '0',
                               
                               clk => clk_cpu,
                               reset => reset_cpu,
                               cs => '1');

    resetn <= not reset_cpu;     
    led_out_debug <= led_temp;                     


end structural;
