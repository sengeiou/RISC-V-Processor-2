library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_SCHED.ALL;

-- Implements the Tomasulo algorithm with unified reservation station. Might get broken up into multiple modules
-- in the future

entity execution_engine is
    port(
        decoded_instruction : in decoded_instruction_type;
        
        instr_ready : in std_logic;
        
        reset : in std_logic;
        clk : in std_logic
    );
end execution_engine;

architecture Structural of execution_engine is
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
    
    -- ========== REGISTER FILE SIGNALS ==========
    signal rf_rd_data_1 : std_logic_vector(31 downto 0);
    signal rf_rd_data_2 : std_logic_vector(31 downto 0);
    signal rf_src_tag_1 : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
    signal rf_src_tag_2 : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
    -- ===========================================
    
    signal next_instr_ready : std_logic; 
    
    -- ========== SCHEDULER CONTROL SIGNALS ==========
    signal sched_full : std_logic;
    signal next_alloc_entry_tag : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
    -- ===============================================
    
    -- ========== RESERVATION STATION PORTS ==========
    signal port_0 : port_type;
    -- ================================================
    
    signal next_instruction : decoded_instruction_type;
    
    signal iq_full : std_logic;
    signal iq_empty : std_logic;
    
    -- ========== COMMON DATA BUS ==========
    signal cdb_1 : cdb_type;
    -- =====================================
begin
    instruction_queue : fifo_generator_1
    port map (
      clk => clk,
      srst => reset,
        
      din(54 downto 52) => decoded_instruction.operation_type,
      din(51 downto 47) => decoded_instruction.operation_select,
      din(46 downto 42) => decoded_instruction.reg_src_1,
      din(41 downto 37) => decoded_instruction.reg_src_2,
      din(36 downto 32) => decoded_instruction.reg_dest,
      din(31 downto 0) => decoded_instruction.immediate,
        
      wr_en => instr_ready,
      rd_en => next_instr_ready,
        
      dout(54 downto 52) => next_instruction.operation_type,
      dout(51 downto 47) => next_instruction.operation_select,
      dout(46 downto 42) => next_instruction.reg_src_1,
      dout(41 downto 37) => next_instruction.reg_src_2,
      dout(36 downto 32) => next_instruction.reg_dest,
      dout(31 downto 0) => next_instruction.immediate,
        
      full => iq_full,
      empty => iq_empty
    );
      
    next_instr_ready <= not (iq_empty or sched_full);
      
    register_file : entity work.register_file(rtl)
                    generic map(RESERVATION_STATION_TAG_BITS => integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))),
                                REG_DATA_WIDTH_BITS => CPU_DATA_WIDTH_BITS,
                                REGFILE_SIZE => 4 + ENABLE_BIG_REGFILE)
                    port map(
                             -- COMMON DATA BUS
                             cdb => cdb_1,
                             
                             -- ADDRESSES
                             rd_1_addr => next_instruction.reg_src_1,
                             rd_2_addr => next_instruction.reg_src_2,
                             wr_addr => next_instruction.reg_dest,
                             
                             -- DATA
                             rd_1_data => rf_rd_data_1,
                             rd_2_data => rf_rd_data_2,
                             
                             -- CONTROL
                             rf_src_tag_1 => rf_src_tag_1,
                             rf_src_tag_2 => rf_src_tag_2,
                             
                             rs_alloc_dest_tag => next_alloc_entry_tag,
                             
                             en => next_instr_ready,
                             reset => reset,
                             clk => clk,
                             clk_dbg => '0');
      
    reservation_station : entity work.reservation_station(rtl)
                          generic map(RESERVATION_STATION_ENTRIES => RESERVATION_STATION_ENTRIES,
                                      REG_ADDR_BITS => 4 + ENABLE_BIG_REGFILE,
                                      OPERATION_TYPE_BITS => OPERATION_TYPE_BITS,
                                      OPERATION_SELECT_BITS => OPERATION_SELECT_BITS,
                                      OPERAND_BITS => CPU_DATA_WIDTH_BITS,
                                      PORT_0_OPTYPE => "000",
                                      PORT_1_OPTYPE => "001")
                          port map(cdb_data => cdb_1.data,
                                   cdb_rs_entry_tag => cdb_1.rs_entry_tag,
                                    
                                   i1_operation_type => next_instruction.operation_type,
                                   i1_operation_sel => next_instruction.operation_select,
                                   i1_src_tag_1 => rf_src_tag_1,
                                   i1_src_tag_2 => rf_src_tag_2,
                                   i1_operand_1 => rf_rd_data_1,
                                   i1_operand_2 => rf_rd_data_2,
                                   i1_immediate => next_instruction.immediate,
                                   i1_dest_reg => next_instruction.reg_dest,
                                   
                                   o1_operand_1 => port_0.operand_1,
                                   o1_operand_2 => port_0.operand_2,
                                   o1_immediate => port_0.immediate,
                                   o1_operation_type => port_0.operation_type,
                                   o1_operation_sel => port_0.operation_sel,
                                   o1_rs_entry_tag => port_0.rs_entry_tag,
                                   
                                   next_alloc_entry_tag => next_alloc_entry_tag,
                                   
                                   write_en => next_instr_ready,
                                   port_0_dispatch_en => '1',
                                   port_1_dispatch_en => '1',
                                   full => sched_full,
                                   
                                   clk => clk,
                                   reset => reset);
      
    integer_branch_exec_unit : entity work.integer_eu(structural)
                               generic map(OPERAND_BITS => CPU_DATA_WIDTH_BITS)
                               port map(operand_1 => port_0.operand_1,
                                        operand_2 => port_0.operand_2,
                                        immediate => port_0.immediate,
                                        operation_sel => port_0.operation_sel, 
                                        rs_entry_tag => port_0.rs_entry_tag,
                                        
                                        cdb => cdb_1,
                                        
                                        reset => reset,
                                        clk => clk);

end structural;
