library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ============================ TO DO ============================ 
-- 1) DRAM Controller
-- 2) A way to enable the processor to communicate with the PC (ex. UART)
-- 3) ROM with bootloader
-- 4) Peripherals (GPIO, Audio, Graphics, ...)
-- 5) Implement multiplication and floating-point RISC-V Extensions
-- 6) Add some sort of SIMD capability

-- x) Implement a branch predictor (gshare predictor or at least a more basic correlating one)
-- x) Implement D and I caches
-- x) Add FIFOs to the AXI interfaces
-- x) Implement a DMA controller
-- x) Allow more agressive re-ordering of LD-ST instructions
-- =============================================================== 

-- ====================== POSSIBLE PROBLEMS ====================== 
-- 1) What happenes when an instruction requires an operand which has been calculated but not commited
-- (still in reorder buffer) ?
-- 2) Due to the reorder buffer requiring that the destination physical register tag is not zero to set its valid
-- bits writing to x0 could cause the CPU to stall! URGENT
-- =============================================================== 

-- ========================= TO DO (AXI) =================================
-- 1) Generate STROBE signal in the master
-- 2) Make AXI bus data width configurable
-- 3) Generate proper response signals
-- =================================================================

entity top is
    port(
        LED : out std_logic_vector(15 downto 0);
        CLK100MHZ : in std_logic;
        BTNC : in std_logic;
        
        UART_TXD_IN : in std_logic;
        UART_RXD_OUT : out std_logic
        
    );
end top;

architecture strucutral of top is
    component clk_wiz_0
    port
     (-- Clock in ports
      -- Clock out ports
      clk_out1          : out    std_logic;
      clk_out2          : out    std_logic;
      -- Status and control signals
      reset             : in     std_logic;
      clk_in1           : in     std_logic
     );
    end component;
    
    signal clk_cpu : std_logic;
    signal clk_dbg : std_logic;
begin
    

    cpu : entity work.cpu(structural)
          port map(led_out_debug => LED,
          
                   uart_rx => UART_TXD_IN,
                   uart_tx => UART_RXD_OUT,
                   uart_rts => '0',
          
                   clk_cpu => clk_cpu,
                   clk_dbg => clk_dbg,
                   reset_cpu => BTNC);
                   
    your_instance_name : clk_wiz_0
        port map ( 
       -- Clock out ports  
        clk_out1 => clk_cpu,
        clk_out2 => clk_dbg,
       -- Status and control signals                
        reset => '0',
        -- Clock in ports
        clk_in1 => CLK100MHZ);

end strucutral;
