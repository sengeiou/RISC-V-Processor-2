library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
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
    
        decoded_instruction : in uop_type;
        
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
    
    signal pipeline_reg_2_p0 : execution_engine_pipeline_register_2_p0_type;
    signal pipeline_reg_2_p0_next : execution_engine_pipeline_register_2_p0_type;
    
    signal pipeline_reg_2_p1 : execution_engine_pipeline_register_2_p1_type;
    signal pipeline_reg_2_p1_next : execution_engine_pipeline_register_2_p1_type;
    
    signal pipeline_reg_3_int : execution_engine_pipeline_register_3_int_type;
    signal pipeline_reg_3_int_next : execution_engine_pipeline_register_3_int_type;
    
    signal pipeline_reg_3_ldst : execution_engine_pipeline_register_3_ldst_type;
    signal pipeline_reg_3_ldst_next : execution_engine_pipeline_register_3_ldst_type;
    -- ========================================
    
    -- ========== REGISTER RENAMING SIGNALS ==========
    signal renamed_dest_reg : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    signal renamed_src_reg_1 : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    signal renamed_src_reg_1_v : std_logic;
    signal renamed_src_reg_2 : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    signal renamed_src_reg_2_v : std_logic;
    
    signal freed_reg_addr : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    
    signal raa_put_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    signal raa_put_en : std_logic;
    
    signal raa_empty : std_logic;
    -- ===============================================
    
    -- ========== REGISTER FILE SIGNALS ==========
    signal rf_rd_data_1 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal rf_rd_data_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal rf_rd_data_3 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal rf_rd_data_4 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    -- ===========================================
    
    signal next_instr_ready : std_logic; 
    
    -- ========== SCHEDULER CONTROL SIGNALS ==========
    signal sched_full : std_logic;
    -- ===============================================
    
    -- ========== RESERVATION STATION PORTS ==========
    signal port_0 : sched_out_port_type;
    signal port_1 : sched_out_port_type;
    -- ================================================
    
    -- ========== REORDER BUFFER SIGNALS ==========
    signal rob_head_operation_type : std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
    signal rob_head_dest_reg : std_logic_vector(ARCH_REGFILE_ADDR_BITS - 1 downto 0);
    signal rob_head_dest_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    
    signal rob_commit_ready : std_logic;
    signal rob_full : std_logic;
    signal rob_empty : std_logic;
    -- ============================================
    
    -- ========== LOAD - STORE UNIT SIGNALS ==========
    signal sq_calc_addr : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal sq_calc_addr_tag : std_logic_vector(integer(ceil(log2(real(STORE_QUEUE_ENTRIES)))) - 1 downto 0);
    signal sq_calc_addr_valid : std_logic;
    signal lq_calc_addr : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0); 
    signal lq_calc_addr_tag : std_logic_vector(integer(ceil(log2(real(LOAD_QUEUE_ENTRIES)))) - 1 downto 0); 
    signal lq_calc_addr_valid : std_logic;
    
    signal sq_store_data : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal sq_store_data_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    signal sq_store_data_valid : std_logic;
    
    signal sq_enqueue_en : std_logic;
    
    signal sq_alloc_tag : std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);
    signal lq_alloc_tag : std_logic_vector(LOAD_QUEUE_TAG_BITS - 1 downto 0);
    
    signal sq_data_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);       
    signal lq_dest_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    
    signal sq_retire_tag : std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);
    signal sq_retire_tag_valid : std_logic;

    -- ===============================================
    
    signal next_uop : uop_type;
    signal next_uop_commit_ready : std_logic;
    
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
        
      dout(54 downto 52) => next_uop.operation_type,
      dout(51 downto 47) => next_uop.operation_select,
      dout(46 downto 42) => next_uop.reg_src_1,
      dout(41 downto 37) => next_uop.reg_src_2,
      dout(36 downto 32) => next_uop.reg_dest,
      dout(31 downto 0) => next_uop.immediate,
        
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
    
    pipeline_reg_2_p0_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_2_p0 <= EE_PIPELINE_REG_2_P0_INIT;
            else
                pipeline_reg_2_p0 <= pipeline_reg_2_p0_next;
            end if;
        end if;
    end process;
    
    pipeline_reg_2_p1_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_2_p1 <= EE_PIPELINE_REG_2_P1_INIT;
            else
                pipeline_reg_2_p1 <= pipeline_reg_2_p1_next;
            end if;
        end if;
    end process;
    
    pipeline_reg_3_int_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_3_int <= EE_PIPELINE_REG_3_INT_INIT;
            else
                pipeline_reg_3_int <= pipeline_reg_3_int_next;
            end if;
        end if;
    end process;
    
    pipeline_reg_3_ldst_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_3_ldst <= EE_PIPELINE_REG_3_LDST_INIT;
            else
                pipeline_reg_3_ldst <= pipeline_reg_3_ldst_next;
            end if;
        end if;
    end process;
    
    pipeline_reg_1_next.sched_in_port_0.operation_type <= next_uop.operation_type;
    pipeline_reg_1_next.sched_in_port_0.operation_select <= next_uop.operation_select;
    pipeline_reg_1_next.sched_in_port_0.src_tag_1 <= renamed_src_reg_1;
    pipeline_reg_1_next.sched_in_port_0.src_tag_1_valid <= '1' when cdb.tag = renamed_src_reg_1 or renamed_src_reg_1_v = '1' else '0';
    pipeline_reg_1_next.sched_in_port_0.src_tag_2 <= renamed_src_reg_2;
    pipeline_reg_1_next.sched_in_port_0.src_tag_2_valid <= '1' when cdb.tag = renamed_src_reg_2 or renamed_src_reg_2_v = '1' else '0';
    pipeline_reg_1_next.sched_in_port_0.dest_tag <= renamed_dest_reg;
    pipeline_reg_1_next.sched_in_port_0.immediate <= next_uop.immediate;
    pipeline_reg_1_next.sched_in_port_0.store_queue_tag <= sq_alloc_tag;
    pipeline_reg_1_next.dest_reg <= next_uop.reg_dest;
    pipeline_reg_1_next.valid <= next_instr_ready;
    
    pipeline_reg_2_p0_next.sched_out_port_0 <= port_0;
    pipeline_reg_2_p0_next.valid <= port_0.valid;
    
    pipeline_reg_2_p1_next.sched_out_port_1 <= port_1;
    pipeline_reg_2_p1_next.valid <= port_1.valid;
    
    pipeline_reg_3_int_next.operand_1 <= rf_rd_data_1;
    pipeline_reg_3_int_next.operand_2 <= rf_rd_data_2;
    pipeline_reg_3_int_next.immediate <= pipeline_reg_2_p0.sched_out_port_0.immediate;
    pipeline_reg_3_int_next.dest_tag <= pipeline_reg_2_p0.sched_out_port_0.dest_tag;
    pipeline_reg_3_int_next.operation_select <= pipeline_reg_2_p0.sched_out_port_0.operation_sel;
    pipeline_reg_3_int_next.valid <= pipeline_reg_2_p0.sched_out_port_0.valid;
    
    pipeline_reg_3_ldst_next.store_data_value <= rf_rd_data_3;
    pipeline_reg_3_ldst_next.store_addr_value <= rf_rd_data_4;
    pipeline_reg_3_ldst_next.immediate <= pipeline_reg_2_p1.sched_out_port_1.immediate;
    pipeline_reg_3_ldst_next.data_tag <= pipeline_reg_2_p1.sched_out_port_1.src_tag_2;
    pipeline_reg_3_ldst_next.store_queue_tag <= pipeline_reg_2_p1.sched_out_port_1.store_queue_tag;
    pipeline_reg_3_ldst_next.operation_select <= pipeline_reg_2_p1.sched_out_port_1.operation_sel;
    pipeline_reg_3_ldst_next.valid <= pipeline_reg_2_p1.sched_out_port_1.valid;
      
    next_uop_commit_ready <= '1' when next_uop.operation_type = OP_TYPE_LOAD_STORE else '0';
    sq_retire_tag_valid <= '1' when rob_head_operation_type = OP_TYPE_LOAD_STORE else '0';
      
    -- ==================================================================================================
    --                                        REGISTER RENAMING
    -- ==================================================================================================
      
    next_instr_ready <= not (iq_empty or sched_full or raa_empty);
      
    register_alias_allocator : entity work.register_alias_allocator(rtl)
                               generic map(PHYS_REGFILE_ENTRIES => PHYS_REGFILE_ENTRIES,
                                           ARCH_REGFILE_ENTRIES => ARCH_REGFILE_ENTRIES)
                               port map(put_reg_alias => freed_reg_addr,
                                        get_reg_alias => renamed_dest_reg,
                                        
                                        put_en => rob_commit_ready,
                                        get_en => next_instr_ready,
                                        
                                        empty => raa_empty,
                                        clk => clk,
                                        reset => reset);
      
    -- Holds mappings for in-flight instructions. Updates whenewer a new instruction issues
    frontend_register_alias_table : entity work.register_alias_table(rtl)
                                    generic map(PHYS_REGFILE_ENTRIES => PHYS_REGFILE_ENTRIES,
                                                ARCH_REGFILE_ENTRIES => ARCH_REGFILE_ENTRIES,
                                                VALID_BIT_INIT_VAL => '1',
                                                ENABLE_VALID_BITS => true)
                                    port map(cdb_tag => cdb.tag,
                                            
                                             arch_reg_addr_read_1 => next_uop.reg_src_1,
                                             arch_reg_addr_read_2 => next_uop.reg_src_2,
                                             
                                             phys_reg_addr_read_1 => renamed_src_reg_1,
                                             phys_reg_addr_read_1_v => renamed_src_reg_1_v,
                                             phys_reg_addr_read_2 => renamed_src_reg_2,
                                             phys_reg_addr_read_2_v => renamed_src_reg_2_v,
                                             
                                             arch_reg_addr_write_1 => next_uop.reg_dest,
                                             phys_reg_addr_write_1 => renamed_dest_reg,
                                             
                                             clk => clk,
                                             reset => reset);  
                                         
    retirement_register_alias_table : entity work.register_alias_table(rtl)
                                      generic map(PHYS_REGFILE_ENTRIES => PHYS_REGFILE_ENTRIES,
                                                ARCH_REGFILE_ENTRIES => ARCH_REGFILE_ENTRIES,
                                                VALID_BIT_INIT_VAL => '0',
                                                ENABLE_VALID_BITS => false)
                                      port map(cdb_tag => PHYS_REG_TAG_ZERO,
                                      
                                               arch_reg_addr_read_1 => rob_head_dest_reg,                   -- Architectural address of a register to be added onto the allocator's stack
                                               arch_reg_addr_read_2 => REG_ADDR_ZERO,                       -- Currently unused
                                               
                                               phys_reg_addr_read_1 => freed_reg_addr,                      -- Address of a physical register to be added onto the allocator's stack
                                                 
                                               arch_reg_addr_write_1 => rob_head_dest_reg,
                                               phys_reg_addr_write_1 => rob_head_dest_tag,
                                                 
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
                             rd_1_addr => pipeline_reg_2_p0.sched_out_port_0.src_tag_1,     -- Operand for ALU operations
                             rd_2_addr => pipeline_reg_2_p0.sched_out_port_0.src_tag_2,     -- Operand for ALU operations
                             rd_3_addr => pipeline_reg_2_p1.sched_out_port_1.src_tag_2,     -- Operand for memory data read operations
                             rd_4_addr => pipeline_reg_2_p1.sched_out_port_1.src_tag_1,     -- Operand for memory address operations
                             wr_addr => cdb.tag,
                             
                             -- DATA
                             rd_1_data => rf_rd_data_1,
                             rd_2_data => rf_rd_data_2,
                             rd_3_data => rf_rd_data_3,
                             rd_4_data => rf_rd_data_4,
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

                              head_operation_type => rob_head_operation_type,
                              head_dest_tag => rob_head_dest_tag,
                              head_stq_tag => sq_retire_tag,
                              head_dest_reg => rob_head_dest_reg,
                              
                              operation_1_type => pipeline_reg_1.sched_in_port_0.operation_type,
                              dest_reg_1 => pipeline_reg_1.dest_reg,
                              dest_tag_1 => pipeline_reg_1.sched_in_port_0.dest_tag,
                              stq_tag_1 => pipeline_reg_1.sched_in_port_0.store_queue_tag,
                              commit_ready_1 => next_uop_commit_ready,
                              
                              write_1_en => pipeline_reg_1.valid,
                              commit_1_en => '1',

                              head_valid => rob_commit_ready,
                              full => rob_full,
                              empty => rob_empty,
                              
                              clk => clk,
                              reset => reset);
      
    unified_scheduler : entity work.unified_scheduler(rtl)
                          port map(cdb => cdb,
                                    
                                   in_port_0 => pipeline_reg_1.sched_in_port_0,
                                   
                                   out_port_0 => port_0,
                                   out_port_1 => port_1,
                                   
                                   write_en => pipeline_reg_1.valid,
                                   p0_unit_ready => n_int_eu_busy,
                                   p1_unit_ready => n_ls_eu_busy,
                                   full => sched_full,
                                   
                                   clk => clk,
                                   reset => reset);
      
    integer_unit : entity work.integer_eu(structural)
                               generic map(OPERAND_BITS => CPU_DATA_WIDTH_BITS)
                               port map(operand_1 => pipeline_reg_3_int.operand_1,
                                        operand_2 => pipeline_reg_3_int.operand_2,
                                        immediate => pipeline_reg_3_int.immediate,
                                        operation_sel => pipeline_reg_3_int.operation_select, 
                                        tag => pipeline_reg_3_int.dest_tag,
                                        dispatch_ready => pipeline_reg_3_int.valid,
                                        
                                        cdb => cdb_int_eu,
                                        cdb_request => cdb_req_1,
                                        cdb_granted => cdb_grant_1,
                                        
                                        busy => int_eu_busy,
                                        
                                        reset => reset,
                                        clk => clk);
                                        
    load_store_unit : entity work.load_store_eu(rtl)
                      generic map(SQ_ENTRIES => STORE_QUEUE_ENTRIES,
                                  LQ_ENTRIES => LOAD_QUEUE_ENTRIES)
                      port map(from_master_interface => to_master_1,
                               to_master_interface => from_master_1,
                      
                               sq_calc_addr => sq_calc_addr,
                               sq_calc_addr_tag => sq_calc_addr_tag,
                               sq_calc_addr_valid => sq_calc_addr_valid,
                               lq_calc_addr => lq_calc_addr,
                               lq_calc_addr_tag => lq_calc_addr_tag,
                               lq_calc_addr_valid => lq_calc_addr_valid,
                               
                               sq_store_data => sq_store_data,
                               sq_store_data_tag => sq_store_data_tag,
                               sq_store_data_valid => sq_store_data_valid,
                               
                               sq_data_tag => sq_data_tag,
                               lq_dest_tag => lq_dest_tag,
                               
                               sq_alloc_tag => sq_alloc_tag,
                               lq_alloc_tag => lq_alloc_tag,
                               
                               sq_enqueue_en => sq_enqueue_en,
                               
                               sq_retire_tag => sq_retire_tag,
                               sq_retire_tag_valid => sq_retire_tag_valid,
                               
                               lq_enqueue_en => '0',
                               lq_dequeue_en => '0',
                               
                               cdb_granted => '1',
                               
                               reset => reset,
                               clk => clk);

    sq_store_data <= pipeline_reg_3_ldst.store_data_value;
    sq_store_data_tag <= pipeline_reg_3_ldst.data_tag;
    sq_store_data_valid <= '1' when pipeline_reg_3_ldst.operation_select(4 downto 3) = "10" else '0';

    -- VERY TEMPORARY!!! WILL BE IN ADDRESS GENERATION UNIT MODULE IN THE FUTURE
    sq_calc_addr <= std_logic_vector(unsigned(pipeline_reg_3_ldst.store_addr_value) + unsigned(pipeline_reg_3_ldst.immediate));
    sq_calc_addr_tag <= pipeline_reg_3_ldst.store_queue_tag;
    sq_calc_addr_valid <= '1' when pipeline_reg_3_ldst.operation_select(4 downto 3) = "10" else '0';

    sq_data_tag <= renamed_src_reg_2;
    sq_enqueue_en <= '1' when next_uop.operation_type = OP_TYPE_LOAD_STORE and next_uop.operation_select(4) = '1' and next_instr_ready = '1' else '0';      -- 5th bit of operation select indicates a store

    --cdb <= cdb_ls_eu when cdb_grant_2 = '1' else
    --       cdb_int_eu;
    cdb <= cdb_int_eu;

    --cdb_grant_1 <= cdb_req_1 and (not cdb_req_2);
    cdb_grant_1 <= '1';
    --cdb_grant_2 <= cdb_req_2;
    
    n_int_eu_busy <= not int_eu_busy;
    --n_ls_eu_busy <= not ls_eu_busy;
    n_ls_eu_busy <= '1';

end structural;
