library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.PKG_CPU.ALL;

-- Implements a circular FIFO buffer to allow instruction to be committed in-order. 

-- Currently PC is stored for EVERY instruction which might not be necessary and takes a LOT of space. A better solution 
-- might be needed in the future

entity reorder_buffer is
    generic(
        ARCH_REGFILE_ENTRIES : integer range 1 to 1024;
        PHYS_REGFILE_ENTRIES : integer range 1 to 1024;
        OPERATION_TYPE_BITS : integer range 1 to 64
    );
    port(
        head_operation_type : out std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        head_arch_dest_reg : out std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0);
        head_phys_dest_reg : out std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        head_stq_tag : out std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);
    
        cdb : in cdb_type;
    
        next_instr_tag : out std_logic_vector(integer(ceil(log2(real(REORDER_BUFFER_ENTRIES)))) - 1 downto 0);
    
        operation_1_type : in std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        arch_dest_reg_1 : in std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0);
        phys_dest_reg_1 : in std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        stq_tag_1 : in std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);
        pc_1_in : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        branch_mask : in std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        commit_ready_1 : in std_logic;
        
        write_1_en : in std_logic;
        commit_1_en : in std_logic;
        head_valid : out std_logic;

        rob_entry_addr : in std_logic_vector(integer(ceil(log2(real(REORDER_BUFFER_ENTRIES)))) - 1 downto 0);
        pc_1_out : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);

        full : out std_logic;
        empty : out std_logic;
    
        clk : in std_logic;
        reset : in std_logic
    );
end reorder_buffer;

architecture rtl of reorder_buffer is
    constant ROB_TAG_BITS : integer := integer(ceil(log2(real(REORDER_BUFFER_ENTRIES))));
    constant ARCH_REG_TAG_BITS : integer := integer(ceil(log2(real(ARCH_REGFILE_ENTRIES))));
    constant PHYS_REG_TAG_BITS : integer := integer(ceil(log2(real(PHYS_REGFILE_ENTRIES))));
    constant ROB_ENTRY_BITS : integer := OPERATION_TYPE_BITS + ARCH_REG_TAG_BITS + PHYS_REG_TAG_BITS + STORE_QUEUE_TAG_BITS + CPU_ADDR_WIDTH_BITS + 1 + 1;
    
    constant TAG_ZERO : std_logic_vector(ROB_TAG_BITS - 1 downto 0) := (others => '0');
    constant ROB_TAG_ZERO : std_logic_vector(integer(ceil(log2(real(REORDER_BUFFER_ENTRIES)))) - 1 downto 0) := (others => '0');
    constant REGFILE_TAG_ZERO : std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0) := (others => '0');
    constant COUNTER_ONE : std_logic_vector(ROB_TAG_BITS - 1 downto 0) := std_logic_vector(to_unsigned(1, ROB_TAG_BITS));
    
    -- ========== STARTING AND ENDING INDEXES OF ROB ENTRIES ==========
    constant OP_TYPE_START : integer := ROB_ENTRY_BITS - 1;
    constant OP_TYPE_END : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS;
    constant ARCH_DEST_REG_START : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - 1;
    constant ARCH_DEST_REG_END : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - ARCH_REG_TAG_BITS;
    constant PHYS_DEST_REG_START : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - ARCH_REG_TAG_BITS - 1;
    constant PHYS_DEST_REG_END : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - ARCH_REG_TAG_BITS - PHYS_REG_TAG_BITS;
    constant STQ_TAG_START : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - ARCH_REG_TAG_BITS - PHYS_REG_TAG_BITS - 1;
    constant STQ_TAG_END : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - ARCH_REG_TAG_BITS - PHYS_REG_TAG_BITS - STORE_QUEUE_TAG_BITS;
    constant PC_START : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - ARCH_REG_TAG_BITS - PHYS_REG_TAG_BITS - STORE_QUEUE_TAG_BITS - 1;
    constant PC_END : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - ARCH_REG_TAG_BITS - PHYS_REG_TAG_BITS - STORE_QUEUE_TAG_BITS - CPU_ADDR_WIDTH_BITS;
    constant BRANCH_RESULT_BIT : integer := 1;          -- 0 = NOT TAKEN | 1 = TAKEN
    -- ================================================================
    
    -- ENTRY FORMAT: [OPERATION TYPE | DEST. TAG | DEST. REG | STQ TAG | PC | BRANCH TAKEN | READY]
    type reorder_buffer_type is array (REORDER_BUFFER_ENTRIES - 1 downto 0) of std_logic_vector(ROB_ENTRY_BITS - 1 downto 0);
    signal reorder_buffer : reorder_buffer_type;
    
    -- ENTRY WITH INDEX 0 IS UNUSED BUT SIMPLIFIES WRITING AND READING LOGIC
    type rob_tail_mispredict_recovery_memory_type is array (BRANCHING_DEPTH downto 0) of std_logic_vector(ROB_TAG_BITS - 1 downto 0);
    signal rob_tail_mispredict_recovery_memory : rob_tail_mispredict_recovery_memory_type;
    
    -- ===== HEAD & TAIL COUNTERS =====
    signal rob_head_counter_reg : std_logic_vector(ROB_TAG_BITS - 1 downto 0);
    signal rob_tail_counter_reg : std_logic_vector(ROB_TAG_BITS - 1 downto 0);
    
    signal rob_head_counter_next : std_logic_vector(ROB_TAG_BITS - 1 downto 0);
    signal rob_tail_counter_next : std_logic_vector(ROB_TAG_BITS - 1 downto 0);
    -- ================================
    
    -- ===== STATUS SIGNALS =====
    signal rob_full : std_logic;
    signal rob_empty : std_logic;
    
    signal commit_ready : std_logic;
    -- ===========================
    
    -- ===== CONTROL SIGNALS =====

    -- ===========================
begin
    commit_ready <= '1' when commit_1_en = '1' and reorder_buffer(to_integer(unsigned(rob_head_counter_reg)))(0) = '1' and rob_empty = '0' else '0';
    head_valid <= commit_ready;

    -- ========== HEAD & TAIL COUNTER PROCESSES ==========
    tail_counter_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                rob_tail_counter_reg <= COUNTER_ONE;
            elsif ((write_1_en = '1' and rob_full = '0') or (cdb.branch_taken = '1' and cdb.valid = '1')) then
                rob_tail_counter_reg <= rob_tail_counter_next;
            end if;
        end if;
    end process;
    
    head_counter_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                rob_head_counter_reg <= COUNTER_ONE;
            elsif (commit_ready = '1') then
                rob_head_counter_reg <= rob_head_counter_next;
            end if;
        end if;
    end process;
    
    counters_next_proc : process(rob_head_counter_reg, rob_tail_counter_reg, cdb)
    begin
        if (unsigned(rob_head_counter_reg) = REORDER_BUFFER_ENTRIES - 1) then
            rob_head_counter_next <= COUNTER_ONE;
        else
            rob_head_counter_next <= std_logic_vector(unsigned(rob_head_counter_reg) + 1);
        end if;
        
        if (cdb.branch_taken = '1' and cdb.valid = '1') then        -- Clear all instructions after branch in ROB
            rob_tail_counter_next <= rob_tail_mispredict_recovery_memory(branch_mask_to_int(cdb.branch_mask));
        elsif (unsigned(rob_tail_counter_reg) = REORDER_BUFFER_ENTRIES - 1) then
            rob_tail_counter_next <= COUNTER_ONE;
        else
            rob_tail_counter_next <= std_logic_vector(unsigned(rob_tail_counter_reg) + 1);
        end if;
    end process;
    -- =======================================
    
    -- ========== ROB CONTROL ==========
    rob_control_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                reorder_buffer <= (others => (others => '0'));
            else 
                -- Writes a new entry into the ROB
                if (write_1_en = '1' and rob_full = '0' and cdb.branch_taken = '0') then
                    reorder_buffer(to_integer(unsigned(rob_tail_counter_reg))) <= operation_1_type & 
                                                                              arch_dest_reg_1 &
                                                                              phys_dest_reg_1 &  
                                                                              stq_tag_1 & 
                                                                              pc_1_in &
                                                                              '0' & 
                                                                              commit_ready_1;
                                                                              
                    rob_tail_mispredict_recovery_memory(branch_mask_to_int(branch_mask)) <= rob_tail_counter_reg;
                end if;

                if (cdb.valid = '1') then
                    reorder_buffer(to_integer(unsigned(cdb.instr_tag)))(0) <= '1';
                end if;
            end if;
        end if;
    end process;
    -- =====================================
    
    rob_full <= '1' when rob_tail_counter_next = rob_head_counter_reg else '0';
    rob_empty <= '1' when rob_head_counter_reg = rob_tail_counter_reg else '0';

    full <= rob_full;
    empty <= rob_empty;
    
    next_instr_tag <= rob_tail_counter_reg;
    
    pc_1_out <= reorder_buffer(to_integer(unsigned(rob_entry_addr)))(PC_START downto PC_END);
    
    head_arch_dest_reg <= reorder_buffer(to_integer(unsigned(rob_head_counter_reg)))(ARCH_DEST_REG_START downto ARCH_DEST_REG_END) when commit_ready = '1' else (others => '0');
    head_phys_dest_reg <= reorder_buffer(to_integer(unsigned(rob_head_counter_reg)))(PHYS_DEST_REG_START downto PHYS_DEST_REG_END) when commit_ready = '1' else (others => '0');
    head_stq_tag <= reorder_buffer(to_integer(unsigned(rob_head_counter_reg)))(STQ_TAG_START downto STQ_TAG_END) when commit_ready = '1' else (others => '0');
    head_operation_type <= reorder_buffer(to_integer(unsigned(rob_head_counter_reg)))(OP_TYPE_START downto OP_TYPE_END) when commit_ready = '1' else (others => '0');

end rtl;







