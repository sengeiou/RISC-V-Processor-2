library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.PKG_CPU.ALL;
--use WORK.PKG_AXI.ALL;

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
--    type test1 is array (2 downto 0) of FromMasterInterface;
--    type test2 is array (2 downto 0) of FromSlaveInterface;

--    signal test1S : test1;
--    signal test2S : test2;

--    signal from_master_1 : ToMasterInterface; 
--    signal to_master_1 : FromMasterInterface; 
    
--    signal from_slave_1 : ToSlaveInterface;
--    signal to_slave_1 : FromSlaveInterface;
    
--    signal from_slave_2 : ToSlaveInterface;
--    signal to_slave_2 : FromSlaveInterface;
    
--    signal from_slave_3 : ToSlaveInterface;
--    signal to_slave_3 : FromSlaveInterface;
    
        -- TEMPORARY BUS STUFF
    signal bus_addr_read : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal bus_addr_write : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal bus_data_read : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal bus_data_write : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal bus_stbr : std_logic;
    signal bus_stbw : std_logic;
    signal bus_ackr : std_logic;
    signal bus_ackw : std_logic;
    
    signal resetn : std_logic;
    signal ram_en : std_logic;
    signal ram_read_valid_1 : std_logic;
    signal ram_read_valid_2 : std_logic;
    
    signal bus_data_read_ram : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal bus_data_read_uart : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    
    signal cs_led : std_logic;
    signal cs_uart : std_logic;
    signal cs_ram : std_logic;
    
    signal re_ram : std_logic;
    signal re_uart : std_logic;
    signal we_led : std_logic;
    signal we_ram : std_logic;
    signal we_uart : std_logic;
    
    signal ackr_uart : std_logic;
    signal ackr_ram : std_logic;
    signal ackw_led : std_logic;
    signal ackw_uart : std_logic;
    signal ackw_ram : std_logic;
    
    signal led_temp : std_logic_vector(15 downto 0);
begin
    -- AXI Interconnect
--    axi_interconnect : entity work.axi_interconnect_simple(rtl)
--                       generic map(NUM_MASTERS => 4,
--                                   NUM_SLAVES => 4)
--                       port map(to_masters(0) => to_master_1,
--                                to_masters(1) => test1S(0),
--                                to_masters(2) => test1S(1),
--                                to_masters(3) => test1S(2),
                       
--                                from_masters(0) => from_master_1,
--                                from_masters(1) => TO_MASTER_CLEAR,       -- Indicates that no device is connected to the corresponding input
--                                from_masters(2) => TO_MASTER_CLEAR,
--                                from_masters(3) => TO_MASTER_CLEAR,

--                                to_slaves(0) => to_slave_1,
--                                to_slaves(1) => to_slave_2,
--                                to_slaves(2) => to_slave_3,
--                                to_slaves(3) => test2S(2),
                                
--                                from_slaves(0) => from_slave_1,
--                                from_slaves(1) => from_slave_2,
--                                from_slaves(2) => from_slave_3,
--                                from_slaves(3) => FROM_SLAVE_CLEAR,
                                
--                                clk => clk_cpu,
--                                reset => resetn);

    -- AXI Masters
    core_1 : entity work.core(structural)
             port map(bus_addr_read => bus_addr_read,
                      bus_addr_write => bus_addr_write,
                      bus_data_read => bus_data_read,
                      bus_data_write => bus_data_write,
                      bus_stbr => bus_stbr,
                      bus_stbw => bus_stbw,
                      bus_ackr => bus_ackr,
                      bus_ackw => bus_ackw,
             
                      clk => clk_cpu,
                      clk_dbg => clk_dbg,
                      
                      reset => reset_cpu);

    -- AXI Slaves
    led_device : entity work.led_interface(rtl)
                 port map(--data_write => to_slave_2.data_write,
                          --addr_write => to_slave_2.addr_write(11 downto 0),
                          addr_write => bus_addr_write(11 downto 0),
                          data_write => bus_data_write,
                          
                          led_out => led_temp,
                          
                          cs => cs_led,
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
                ackr_ram <= '0';
                ackr_uart <= '0';
                ackw_uart <= '0';
                ackw_ram <= '0';
                ackw_led <= '0';
            else
                ram_read_valid_1 <= re_ram;
                ackr_ram <= ram_read_valid_1 and not ackr_ram and bus_stbr;
                ackr_uart <= re_uart and not ackr_uart;
                ackw_uart <= we_uart and not ackw_uart;
                ackw_ram <= we_ram and not ackw_ram;
                ackw_led <= we_led and not ackw_led;
            end if;
        end if;
    end process;
                          
your_instance_name : blk_mem_gen_0
  PORT MAP (
    clka => clk_cpu,
    ena => cs_ram,
    wea(0) => we_ram,
    addra => bus_addr_write(9 downto 0),
    dina => bus_data_write,
    clkb => clk_cpu,
    enb => re_ram,
    addrb => bus_addr_read(9 downto 0),
    doutb => bus_data_read_ram
  );
    
    uart_controller : entity work.uart_interface(rtl)
                      port map(data_read_bus => bus_data_read_uart(7 downto 0),
                               data_write_bus => bus_data_write(7 downto 0),
                              
                               addr_read_bus => bus_addr_read(2 downto 0),
                               addr_write_bus => bus_addr_write(2 downto 0),
                               
                               rx => uart_rx,
                               tx => uart_tx,
                               cts => uart_rts,
                               rts => uart_cts,
                               dsr => '0',
                               
                               clk => clk_cpu,
                               reset => reset_cpu,
                               cs => cs_uart);

    bus_data_read <= bus_data_read_ram when re_ram = '1' else
                     bus_data_read_uart when re_uart = '1' else
                     (others => '0');

    re_ram <= '1' when bus_addr_read(31 downto 28) = X"2" and bus_stbr = '1' else '0';
    re_uart <= '1' when bus_addr_read(31 downto 28) = X"1" and bus_stbr = '1' else '0';
    we_led <= '1' when bus_addr_write(31 downto 28) = X"0" and bus_stbw = '1' else '0';
    we_uart <= '1' when bus_addr_write(31 downto 28) = X"1" and bus_stbw = '1' else '0';
    we_ram <= '1' when bus_addr_write(31 downto 28) = X"2" and bus_stbw = '1' else '0';

    cs_led <=  we_led;
    cs_uart <= we_uart or re_uart;
    cs_ram <= we_ram or re_ram; 

    bus_ackr <= ackr_ram or ackr_uart;
    bus_ackw <= ackw_led or ackw_ram or ackw_uart;

    resetn <= not reset_cpu;     
    led_out_debug <= led_temp;                     


end structural;
