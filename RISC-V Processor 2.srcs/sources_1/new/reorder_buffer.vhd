library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Implements a circular FIFO buffer to allow instruction to be committed in-order. 

entity reorder_buffer is
    generic(
        ENTRIES : integer range 1 to 1024;
        REGFILE_ENTRIES : integer range 1 to 1024;
        OPERAND_BITS : integer range 1 to 128;
        OPERATION_TYPE_BITS : integer range 1 to 64
    );
    port(
        head_dest_reg : out std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        head_result : out std_logic_vector(OPERAND_BITS - 1 downto 0);
    
        cdb_data : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        cdb_tag : in std_logic_vector(integer(ceil(log2(real(ENTRIES)))) - 1 downto 0);
    
        operation_1_type : in std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        dest_reg_1 : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        write_1_en : in std_logic;
        commit_1_en : in std_logic;
        
        next_alloc_entry_tag : out std_logic_vector(integer(ceil(log2(real(ENTRIES)))) - 1 downto 0);
    
        full : out std_logic;
        empty : out std_logic;
    
        clk : in std_logic;
        reset : in std_logic
    );
end reorder_buffer;

architecture rtl of reorder_buffer is
    constant ROB_TAG_BITS : integer := integer(ceil(log2(real(ENTRIES))));
    constant REGFILE_TAG_BITS : integer := integer(ceil(log2(real(REGFILE_ENTRIES))));
    constant ROB_ENTRY_BITS : integer := OPERATION_TYPE_BITS + REGFILE_TAG_BITS + OPERAND_BITS + 1;
    
    constant ROB_TAG_ZERO : std_logic_vector(integer(ceil(log2(real(ENTRIES)))) - 1 downto 0) := (others => '0');
    constant REGFILE_TAG_ZERO : std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0) := (others => '0');
    constant OPERAND_ZERO : std_logic_vector(OPERAND_BITS - 1 downto 0) := (others => '0');
    constant COUNTER_ONE : std_logic_vector(ROB_TAG_BITS - 1 downto 0) := std_logic_vector(to_unsigned(1, ROB_TAG_BITS));
    
    -- ========== STARTING AND ENDING INDEXES OF ROB ENTRIES ==========
    constant OP_TYPE_START : integer := ROB_ENTRY_BITS - 1;
    constant OP_TYPE_END : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS;
    constant DEST_REG_START : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - 1;
    constant DEST_REG_END : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - REGFILE_TAG_BITS;
    constant RESULT_START : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - REGFILE_TAG_BITS - 1;
    constant RESULT_END : integer := ROB_ENTRY_BITS - OPERATION_TYPE_BITS - REGFILE_TAG_BITS - OPERAND_BITS;
    -- ================================================================
    
    -- ENTRY FORMAT: [OPERATION TYPE | DEST. REG | RESULT | READY]
    type reorder_buffer_type is array(ENTRIES - 1 downto 0) of std_logic_vector(ROB_ENTRY_BITS - 1 downto 0);
    signal reorder_buffer : reorder_buffer_type;
    
    -- ===== HEAD & TAIL COUNTERS =====
    signal head_counter_reg : std_logic_vector(ROB_TAG_BITS - 1 downto 0);
    signal tail_counter_reg : std_logic_vector(ROB_TAG_BITS - 1 downto 0);
    
    signal head_counter_next : std_logic_vector(ROB_TAG_BITS - 1 downto 0);
    signal tail_counter_next : std_logic_vector(ROB_TAG_BITS - 1 downto 0);
    -- ================================
    
    -- ===== STATUS SIGNALS =====
    signal rob_full : std_logic;
    signal rob_empty : std_logic;
    -- ===========================
    
    -- ===== CONTROL SIGNALS =====

    -- ===========================
begin
    next_alloc_entry_tag <= tail_counter_reg;

    -- ========== HEAD & TAIL COUNTER PROCESSES ==========
    head_counter_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                tail_counter_reg <= COUNTER_ONE;
            elsif (write_1_en = '1' and rob_full = '0') then
                tail_counter_reg <= tail_counter_next;
            end if;
        end if;
    end process;
    
    tail_counter_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                head_counter_reg <= COUNTER_ONE;
            elsif (commit_1_en = '1' and reorder_buffer(to_integer(unsigned(head_counter_reg)))(0) = '1' and rob_empty = '0') then
                head_counter_reg <= head_counter_next;
            end if;
        end if;
    end process;
    
    counters_next_proc : process(head_counter_reg, tail_counter_reg)
    begin
        if (unsigned(head_counter_reg) = ENTRIES - 1) then
            head_counter_next <= COUNTER_ONE;
        else
            head_counter_next <= std_logic_vector(unsigned(head_counter_reg) + 1);
        end if;
        
        if (unsigned(tail_counter_reg) = ENTRIES - 1) then
            tail_counter_next <= COUNTER_ONE;
        else
            tail_counter_next <= std_logic_vector(unsigned(tail_counter_reg) + 1);
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
                if (write_1_en = '1' and rob_full = '0') then
                    reorder_buffer(to_integer(unsigned(tail_counter_reg))) <= operation_1_type & dest_reg_1 & OPERAND_ZERO & '0';
                end if;
                
                -- Sets the result operand of an entry to cdb's data field when the cdb tag matches the entry's tag
                for i in 0 to ENTRIES - 1 loop
                    if (i = to_integer(unsigned(cdb_tag))) then
                        reorder_buffer(i)(OPERAND_BITS downto 1) <= cdb_data;
                        reorder_buffer(i)(0) <= '1';
                    end if;
                end loop;
            end if;
        end if;
    end process;
    -- =====================================
    
    rob_full <= '1' when tail_counter_next = head_counter_reg else '0';
    rob_empty <= '1' when head_counter_reg = tail_counter_reg else '0';

    full <= rob_full;
    empty <= rob_empty;
    
    head_dest_reg <= reorder_buffer(to_integer(unsigned(head_counter_reg)))(DEST_REG_START downto DEST_REG_END);
    head_result <= reorder_buffer(to_integer(unsigned(head_counter_reg)))(RESULT_START downto RESULT_END);

end rtl;







