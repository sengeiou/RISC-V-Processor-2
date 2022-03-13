library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

-- Implements the Tomasulo algorithm with unified reservation station. Might get broken up into multiple modules
-- in the future

entity execution_unit is
    generic(
        INT_RESERVATION_STATION_ENTRY_NUM : integer := 7
    );
    port(
        decoded_instruction : in std_logic_vector(54 downto 0);     -- OPERATION SELECT (4) | OPERATION TYPE (3) | REG_S1 (5) | REG_S2 (5) | REG_DST (5) | IMMEDIATE (32)
                                                                    -- OPERATION TYPE tells us which type of functional units can execute this instruction. This data is used
                                                                    -- to determine where this instruction can be sent for execution. One operation type can potentially be executed
                                                                    -- by multiple functional units, so this decision is made by the scheduler
                                                                    -- OPERATION SELECT tells the functional unit what operation to perform. It can, but doesn't have to use all bits 
        
        instr_ready : in std_logic;
        
        reset : in std_logic;
        clk : in std_logic
    );
end execution_unit;

architecture structural of execution_unit is
    COMPONENT fifo_generator_1
        PORT (
          clk : IN STD_LOGIC;
          srst : IN STD_LOGIC;
          din : IN STD_LOGIC_VECTOR(54 DOWNTO 0);
          wr_en : IN STD_LOGIC;
          rd_en : IN STD_LOGIC;
          dout : OUT STD_LOGIC_VECTOR(54 DOWNTO 0);
          full : OUT STD_LOGIC;
          empty : OUT STD_LOGIC
        );
    END COMPONENT;
    
    -- ========== 
    signal rf_rd_data_1 : std_logic_vector(31 downto 0);
    signal rf_rd_data_2 : std_logic_vector(31 downto 0);
    
    signal next_instr_ready : std_logic; 
    
    -- ========== SCHEDULER CONTROL SIGNALS ==========
    signal sched_full : std_logic;
    
    signal rf_src_tag_1 : std_logic_vector(integer(ceil(log2(real(INT_RESERVATION_STATION_ENTRY_NUM)))) - 1 downto 0);
    signal rf_src_tag_2 : std_logic_vector(integer(ceil(log2(real(INT_RESERVATION_STATION_ENTRY_NUM)))) - 1 downto 0);
    
    signal rs_alloc_dest_tag : std_logic_vector(integer(ceil(log2(real(INT_RESERVATION_STATION_ENTRY_NUM)))) - 1 downto 0);
    
    -- ========== RESERVATION STATION PORT 0 ==========
    signal p0_operand_1 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal p0_operand_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal p0_immediate : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal p0_operation_type : std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
    signal p0_operation_sel : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
    signal p0_rs_producer : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRY_CNT)))) - 1 downto 0);
    -- ================================================
    
    signal next_instruction : std_logic_vector(54 downto 0);
    
    signal iq_full : std_logic;
    signal iq_empty : std_logic;
    signal iq_empty_n : std_logic;
    signal iq_read_ready : std_logic;
    
    -- ========== COMMON DATA BUS ==========
    signal cdb_1 : cdb_type;
    -- =====================================
begin
    instruction_queue : fifo_generator_1
      port map (
        clk => clk,
        srst => reset,
        din => decoded_instruction,
        wr_en => instr_ready,
        rd_en => next_instr_ready,
        dout => next_instruction,
        full => iq_full,
        empty => iq_empty
      );
      
      iq_read_ready <= '1';
      iq_empty_n <= not iq_empty;
      
      next_instr_ready <= not (iq_empty or sched_full);
      
    register_file : entity work.register_file(rtl)
                    generic map(RESERVATION_STATION_ENTRY_NUM => INT_RESERVATION_STATION_ENTRY_NUM,
                                REG_DATA_WIDTH_BITS => CPU_DATA_WIDTH_BITS,
                                REGFILE_SIZE => 4 + ENABLE_BIG_REGFILE)
                    port map(
                             -- COMMON DATA BUS
                             cdb => cdb_1,
                             
                             -- ADDRESSES
                             rd_1_addr => next_instruction(46 downto 42),
                             rd_2_addr => next_instruction(41 downto 37),
                             wr_addr => next_instruction(36 downto 32),
                             
                             -- DATA
                             rd_1_data => rf_rd_data_1,
                             rd_2_data => rf_rd_data_2,
                             
                             -- CONTROL
                             rf_src_tag_1 => rf_src_tag_1,
                             rf_src_tag_2 => rf_src_tag_2,
                             
                             rs_alloc_dest_tag => rs_alloc_dest_tag,
                             
                             en => next_instr_ready,
                             reset => reset,
                             clk => clk,
                             clk_dbg => '0');
      
    reservation_station : entity work.reservation_station(rtl)
                          generic map(NUM_ENTRIES => INT_RESERVATION_STATION_ENTRY_NUM,
                                      REG_ADDR_BITS => integer(ceil(log2(real(REGFILE_SIZE)))),
                                      OPERATION_TYPE_BITS => 3,
                                      OPERATION_SELECT_BITS => 5,
                                      OPERAND_BITS => CPU_DATA_WIDTH_BITS)
                          port map(cdb => cdb_1,
                                    
                                   i1_operation_type => next_instruction(54 downto 52),
                                   i1_operation_sel => next_instruction(51 downto 47),
                                   i1_src_tag_1 => rf_src_tag_1,
                                   i1_src_tag_2 => rf_src_tag_2,
                                   i1_operand_1 => rf_rd_data_1,
                                   i1_operand_2 => rf_rd_data_2,
                                   i1_immediate => next_instruction(31 downto 0),
                                   i1_dest_reg => next_instruction(36 downto 32),
                                   
                                   o1_operand_1 => p0_operand_1,
                                   o1_operand_2 => p0_operand_2,
                                   o1_immediate => p0_immediate,
                                   o1_operation_type => p0_operation_type,
                                   o1_operation_sel => p0_operation_sel,
                                   o1_rs_entry_tag => p0_rs_producer,
                                   
                                   rs_alloc_dest_tag => rs_alloc_dest_tag,
                                   
                                   write_en => next_instr_ready,
                                   rs_dispatch_1_en => '1',
                                   full => sched_full,
                                   
                                   clk => clk,
                                   reset => reset);
      
    integer_branch_func_unit : entity work.integer_branch_fu(structural)
                               generic map(OPERAND_BITS => CPU_DATA_WIDTH_BITS)
                               port map(operand_1 => p0_operand_1,
                                        operand_2 => p0_operand_2,
                                        immediate => p0_immediate,
                                        operation_sel => p0_operation_sel, 
                                        rs_entry_tag => p0_rs_producer,
                                        
                                        cdb => cdb_1,
                                        
                                        reset => reset,
                                        clk => clk);

end structural;
