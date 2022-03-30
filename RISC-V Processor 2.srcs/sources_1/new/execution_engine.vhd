library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_EE.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_SCHED.ALL;
use WORK.PKG_AXI.ALL;

-- Implements the Tomasulo algorithm with unified reservation station. Might get broken up into multiple modules
-- in the future
-- Allow the hardware to stop execution with some signal

entity execution_engine is
    port(
        from_master_1 : out ToMasterInterface; 
        to_master_1 : in FromMasterInterface; 
    
        decoded_instruction : in decoded_instruction_type;
        
        instr_ready : in std_logic;
        
        reset : in std_logic;
        clk : in std_logic;
        clk_dbg : in std_logic
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
    
    -- ========== PIPELINE REGISTERS ==========
    signal pipeline_reg_1 : execution_engine_pipeline_register_1_type;
    signal pipeline_reg_1_next : execution_engine_pipeline_register_1_type;
    -- ========================================
    
    -- ========== REGISTER RENAMING SIGNALS ==========
    signal renamed_dest_reg : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    signal renamed_src_reg_1 : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    signal renamed_src_reg_2 : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    
    signal raa_put_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    signal raa_put_en : std_logic;
    
    signal raa_empty : std_logic;
    -- ===============================================
    
    -- ========== REGISTER FILE SIGNALS ==========
    signal rf_rd_data_1 : std_logic_vector(31 downto 0);
    signal rf_rd_data_2 : std_logic_vector(31 downto 0);
    signal rf_src_tag_1 : std_logic_vector(integer(ceil(log2(real(REORDER_BUFFER_ENTRIES)))) - 1 downto 0);
    signal rf_src_tag_2 : std_logic_vector(integer(ceil(log2(real(REORDER_BUFFER_ENTRIES)))) - 1 downto 0);
    -- ===========================================
    
    signal next_instr_ready : std_logic; 
    
    -- ========== SCHEDULER CONTROL SIGNALS ==========
    signal sched_full : std_logic;
    -- ===============================================
    
    -- ========== RESERVATION STATION PORTS ==========
    signal port_0 : port_type;
    signal port_1 : port_type;
    -- ================================================
    
    -- ========== REORDER BUFFER SIGNALS ==========
    signal rob_head_dest_reg : std_logic_vector(ARCH_REGFILE_ADDR_BITS - 1 downto 0);
    signal rob_head_dest_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    
    signal rob_commit_ready : std_logic;
    signal rob_full : std_logic;
    signal rob_empty : std_logic;
    -- ============================================
    
    signal next_instruction : decoded_instruction_type;
    
    signal iq_full : std_logic;
    signal iq_empty : std_logic;
    
    -- ========== EXECUTION UNITS BUSY SIGNALS ==========
    signal int_eu_busy : std_logic;
    signal ls_eu_busy : std_logic;
    
    signal n_int_eu_busy : std_logic;
    signal n_ls_eu_busy : std_logic;
    -- ==================================================
    
    -- ========== COMMON DATA BUS ==========
    signal cdb : cdb_type;
    
    signal cdb_req_1 : std_logic;
    signal cdb_req_2 : std_logic;
    
    signal cdb_grant_1 : std_logic;
    signal cdb_grant_2 : std_logic;
    
    signal cdb_int_eu : cdb_type;
    signal cdb_ls_eu : cdb_type;
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
      
    pipeline_reg_1_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_1 <= EE_PIPELINE_REG_1_INIT;
            else
                pipeline_reg_1 <= pipeline_reg_1_next;
            end if;
        end if;
    end process;
    
    pipeline_reg_1_next.operation_type <= next_instruction.operation_type;
    pipeline_reg_1_next.operation_select <= next_instruction.operation_select;
    pipeline_reg_1_next.renamed_src_reg_1 <= renamed_src_reg_1;
    pipeline_reg_1_next.renamed_src_reg_2 <= renamed_src_reg_2;
    pipeline_reg_1_next.renamed_dest_reg <= renamed_dest_reg;
    pipeline_reg_1_next.dest_reg <= next_instruction.reg_dest;
    pipeline_reg_1_next.immediate <= next_instruction.immediate;
    pipeline_reg_1_next.valid <= next_instr_ready;
      
    -- ==================================================================================================
    --                                        REGISTER RENAMING
    -- ==================================================================================================
      
    next_instr_ready <= not (iq_empty or sched_full or raa_empty);
      
    register_alias_allocator : entity work.register_alias_allocator(rtl)
                               generic map(PHYS_REGFILE_ENTRIES => PHYS_REGFILE_ENTRIES,
                                           ARCH_REGFILE_ENTRIES => ARCH_REGFILE_ENTRIES)
                               port map(put_reg_alias => raa_put_tag,
                                        get_reg_alias => renamed_dest_reg,
                                        
                                        put_en => raa_put_en,
                                        get_en => next_instr_ready,
                                        
                                        empty => raa_empty,
                                        clk => clk,
                                        reset => reset);
      
    -- What happenes when there are no more registers to allocate...?
    register_alias_table : entity work.register_alias_table(rtl)
                                generic map(PHYS_REGFILE_ENTRIES => PHYS_REGFILE_ENTRIES,
                                            ARCH_REGFILE_ENTRIES => ARCH_REGFILE_ENTRIES)
                                port map(commited_dest_reg_arch_addr => rob_head_dest_reg,
                                         commited_dest_reg_phys_addr => rob_head_dest_tag,
                                         commit_ready => rob_commit_ready,
                                         
                                         freed_phys_reg_tag => raa_put_tag,
                                         tag_freed => raa_put_en,
                                
                                         arch_reg_addr_read_1 => next_instruction.reg_src_1,
                                         arch_reg_addr_read_2 => next_instruction.reg_src_2,
                                         
                                         phys_reg_addr_read_1 => renamed_src_reg_1,
                                         phys_reg_addr_read_2 => renamed_src_reg_2,
                                         
                                         arch_reg_addr_write_1 => next_instruction.reg_dest,
                                         phys_reg_addr_write_1 => renamed_dest_reg,
                                         
                                         clk => clk,
                                         reset => reset);  
                                         
    -- ==================================================================================================
    -- ==================================================================================================
    -- ==================================================================================================
      
    register_file : entity work.register_file(rtl)
                    generic map(REG_DATA_WIDTH_BITS => CPU_DATA_WIDTH_BITS,
                                REGFILE_ENTRIES => PHYS_REGFILE_ENTRIES)
                    port map(
                             -- ADDRESSES
                             rd_1_addr => pipeline_reg_1.renamed_src_reg_1,
                             rd_2_addr => pipeline_reg_1.renamed_src_reg_2,
                             wr_addr => cdb.tag,
                             
                             -- DATA
                             rd_1_data => rf_rd_data_1,
                             rd_2_data => rf_rd_data_2,
                             wr_data => cdb.data,
                             
                             -- CONTROL
                             en => '1',
                             reset => reset,
                             clk => clk,
                             clk_dbg => clk_dbg);
                             
    reorder_buffer : entity work.reorder_buffer(rtl)
                     generic map(ROB_ENTRIES => REORDER_BUFFER_ENTRIES,
                                 REGFILE_ENTRIES => 2 ** (4 + ENABLE_BIG_REGFILE),
                                 TAG_BITS => PHYS_REGFILE_ADDR_BITS,
                                 OPERATION_TYPE_BITS => OPERATION_TYPE_BITS)
                     port map(cdb_tag => cdb.tag,

                              head_dest_tag => rob_head_dest_tag,
                              head_dest_reg => rob_head_dest_reg,
                              
                              operation_1_type => pipeline_reg_1.operation_type,
                              dest_reg_1 => pipeline_reg_1.dest_reg,
                              dest_tag_1 => pipeline_reg_1.renamed_dest_reg,
                              write_1_en => pipeline_reg_1.valid,
                              commit_1_en => '1',

                              head_valid => rob_commit_ready,
                              full => rob_full,
                              empty => rob_empty,
                              
                              clk => clk,
                              reset => reset);
      
    unified_scheduler : entity work.unified_scheduler(rtl)
                          generic map(SCHEDULER_ENTRIES => SCHEDULER_ENTRIES,
                                      TAG_BITS => PHYS_REGFILE_ADDR_BITS,
                                      OPERATION_TYPE_BITS => OPERATION_TYPE_BITS,
                                      OPERATION_SELECT_BITS => OPERATION_SELECT_BITS,
                                      OPERAND_BITS => CPU_DATA_WIDTH_BITS,
                                      PORT_0_OPTYPE => "000",
                                      PORT_1_OPTYPE => "001")
                          port map(cdb_data => cdb.data,
                                   cdb_tag => cdb.tag,
                                    
                                   i1_operation_type => pipeline_reg_1.operation_type,
                                   i1_operation_sel => pipeline_reg_1.operation_select,
                                   i1_src_tag_1 => pipeline_reg_1.renamed_src_reg_1,
                                   i1_src_tag_2 => pipeline_reg_1.renamed_src_reg_2,
                                   i1_dest_tag => pipeline_reg_1.renamed_dest_reg,
                                   i1_operand_1 => rf_rd_data_1,
                                   i1_operand_2 => rf_rd_data_2,
                                   i1_immediate => pipeline_reg_1.immediate,
                                   
                                   o1_operand_1 => port_0.operand_1,
                                   o1_operand_2 => port_0.operand_2,
                                   o1_immediate => port_0.immediate,
                                   o1_operation_type => port_0.operation_type,
                                   o1_operation_sel => port_0.operation_sel,
                                   o1_dest_tag => port_0.tag,
                                   o1_dispatch_ready => port_0.dispatch_ready,
                                   
                                   o2_operand_1 => port_1.operand_1,
                                   o2_operand_2 => port_1.operand_2,
                                   o2_immediate => port_1.immediate,
                                   o2_operation_type => port_1.operation_type,
                                   o2_operation_sel => port_1.operation_sel,
                                   o2_dest_tag => port_1.tag,
                                   o2_dispatch_ready => port_1.dispatch_ready,

                                   write_en => next_instr_ready,
                                   port_0_ready => n_int_eu_busy,
                                   port_1_ready => n_ls_eu_busy,
                                   full => sched_full,
                                   
                                   clk => clk,
                                   reset => reset);
      
    integer_unit : entity work.integer_eu(structural)
                               generic map(OPERAND_BITS => CPU_DATA_WIDTH_BITS)
                               port map(operand_1 => port_0.operand_1,
                                        operand_2 => port_0.operand_2,
                                        immediate => port_0.immediate,
                                        operation_sel => port_0.operation_sel, 
                                        tag => port_0.tag,
                                        dispatch_ready => port_0.dispatch_ready,
                                        
                                        cdb => cdb_int_eu,
                                        cdb_request => cdb_req_1,
                                        cdb_granted => cdb_grant_1,
                                        
                                        busy => int_eu_busy,
                                        
                                        reset => reset,
                                        clk => clk);
                                        
    load_store_unit : entity work.load_store_eu(rtl)
                      port map(from_master_interface => to_master_1,
                               to_master_interface => from_master_1,
                      
                               operand_1 => port_1.operand_1,
                               operand_2 => port_1.operand_2,
                               immediate => port_1.immediate,
                               operation_sel => port_1.operation_sel, 
                               tag => port_1.tag,
                               dispatch_ready => port_1.dispatch_ready,
                                        
                               cdb => cdb_ls_eu,
                               cdb_request => cdb_req_2,
                               cdb_granted => cdb_grant_2,
                                        
                               busy => ls_eu_busy,
                                        
                               reset => reset,
                               clk => clk);

    cdb <= cdb_ls_eu when cdb_grant_2 = '1' else
           cdb_int_eu;

    cdb_grant_1 <= cdb_req_1 and (not cdb_req_2);
    cdb_grant_2 <= cdb_req_2;
    
    n_int_eu_busy <= not int_eu_busy;
    n_ls_eu_busy <= not ls_eu_busy;

end structural;
