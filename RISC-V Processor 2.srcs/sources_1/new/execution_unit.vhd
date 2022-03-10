library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

-- Implements the Tomasulo algorithm with unified reservation station. Might get broken up into multiple modules
-- in the future

entity execution_unit is
    port(
        decoded_instruction : in std_logic_vector(53 downto 0);     -- OPERATION SELECT (4) | OPERATION TYPE (3) | REG_S1 (5) | REG_S2 (5) | REG_DST (5) | IMMEDIATE (32)
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
          din : IN STD_LOGIC_VECTOR(53 DOWNTO 0);
          wr_en : IN STD_LOGIC;
          rd_en : IN STD_LOGIC;
          dout : OUT STD_LOGIC_VECTOR(53 DOWNTO 0);
          full : OUT STD_LOGIC;
          empty : OUT STD_LOGIC
        );
    END COMPONENT;
    
    -- ========== 
    
    signal rf_wr_addr : std_logic_vector(4 downto 0) := "00000";
    signal rf_wr_data : std_logic_vector(31 downto 0) := X"00000000";
    signal rf_rd_data_1 : std_logic_vector(31 downto 0);
    signal rf_rd_data_2 : std_logic_vector(31 downto 0);
    
    -- ========== RESERVATION STATION PORT 0 ==========
    signal p0_operand_1 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal p0_operand_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal p0_operation_type : std_logic_vector(2 downto 0);
    signal p0_operation_sel : std_logic_vector(3 downto 0);
    signal p0_dest_reg_addr : std_logic_vector(4 downto 0);
    signal p0_rs_producer : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRY_CNT)))) - 1 downto 0);
    -- ================================================
    
    signal next_instruction : std_logic_vector(53 downto 0);
    
    signal iq_full : std_logic;
    signal iq_empty : std_logic;
    signal iq_empty_n : std_logic;
    signal iq_issue_ready : std_logic;
    
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
        rd_en => iq_issue_ready,
        dout => next_instruction,
        full => iq_full,
        empty => iq_empty
      );
      iq_empty_n <= not iq_empty;
      
    register_file : entity work.register_file(rtl)
                    generic map(REG_DATA_WIDTH_BITS => CPU_DATA_WIDTH_BITS,
                                REGFILE_SIZE => 4 + ENABLE_BIG_REGFILE)
                    port map(-- ADDRESSES
                             rd_1_addr => decoded_instruction(46 downto 42),
                             rd_2_addr => decoded_instruction(41 downto 37),
                             wr_addr => rf_wr_addr,
                             
                             -- DATA
                             wr_data => rf_wr_data,
                             rd_1_data => rf_rd_data_1,
                             rd_2_data => rf_rd_data_2,
                             
                             -- CONTROL
                             wr_en => '0',
                             reset => reset,
                             clk => clk,
                             clk_dbg => '0');
      
    reservation_station : entity work.reservation_station(rtl)
                          generic map(NUM_ENTRIES => RESERVATION_STATION_ENTRY_CNT,
                                      REG_ADDR_BITS => integer(ceil(log2(real(REGFILE_SIZE)))),
                                      OPERATION_TYPE_BITS => 3,
                                      OPERATION_SELECT_BITS => 4,
                                      OPERAND_BITS => CPU_DATA_WIDTH_BITS)
                          port map(i1_operation_type => decoded_instruction(53 downto 51),
                                   i1_operation_sel => decoded_instruction(50 downto 47),
                                   i1_reg_src_1 => decoded_instruction(46 downto 42),
                                   i1_reg_src_2 => decoded_instruction(41 downto 37),
                                   i1_operand_1 => rf_rd_data_1,
                                   i1_operand_2 => rf_rd_data_2,
                                   i1_dest_reg => decoded_instruction(36 downto 32),
                                   
                                   o1_operand_1 => p0_operand_1,
                                   o1_operand_2 => p0_operand_2,
                                   o1_operation_type => p0_operation_type,
                                   o1_operation_sel => p0_operation_sel,
                                   o1_dest_reg => p0_dest_reg_addr,
                                   o1_rs_entry_tag => p0_rs_producer,
                                   
                                   write_en => instr_ready,
                                   rs_dispatch_1_en => '1',
                                   
                                   clk => clk,
                                   reset => reset);
      
    integer_branch_func_unit : entity work.integer_branch_fu(structural)
                               generic map(OPERAND_BITS => CPU_DATA_WIDTH_BITS)
                               port map(operand_1 => p0_operand_1,
                                        operand_2 => p0_operand_2,
                                        operation_sel => p0_operation_sel, 
                                        rf_write_reg_addr => p0_dest_reg_addr,
                                        rs_entry_tag => p0_rs_producer,
                                        
                                        cdb_data => cdb_1.data,
                                        cdb_rf_write_reg_addr => cdb_1.rf_write_reg_addr,
                                        cdb_rs_update_index => cdb_1.rs_update_index,
                                        
                                        reset => reset,
                                        clk => clk);

end structural;
