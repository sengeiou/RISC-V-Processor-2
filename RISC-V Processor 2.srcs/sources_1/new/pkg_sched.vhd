library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

-- Definitions of input ports, output ports, types and constants required to create and configure 
-- the unified scheduler for the processor

package pkg_sched is
    constant ENTRY_BITS : integer := OPERATION_TYPE_BITS + OPERATION_SELECT_BITS + 3 * PHYS_REGFILE_ADDR_BITS + OPERAND_BITS + STORE_QUEUE_TAG_BITS + LOAD_QUEUE_TAG_BITS + INSTR_TAG_BITS + 2 * BRANCHING_DEPTH + 3;
    constant ENTRY_TAG_BITS : integer := integer(ceil(log2(real(SCHEDULER_ENTRIES))));
    
    constant ENTRY_TAG_ZERO : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0) := (others => '0');
    constant OUTPUT_PORT_COUNT : integer := 2;

    -- ================================================================================
    --                                TYPE DECLARATIONS 
    -- ================================================================================
    type sched_in_port_type is record
        instr_tag : std_logic_vector(INSTR_TAG_BITS - 1 downto 0);
        operation_type : std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        operation_select : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        immediate : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        phys_dest_reg : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0); 
        store_queue_tag : std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);
        load_queue_tag : std_logic_vector(LOAD_QUEUE_TAG_BITS - 1 downto 0);
        curr_branch_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        dependent_branches_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        src_tag_1 : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        src_tag_2 : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        src_tag_1_valid : std_logic;
        src_tag_2_valid : std_logic;
    end record;
    
    type sched_out_port_type is record
        instr_tag : std_logic_vector(INSTR_TAG_BITS - 1 downto 0);
        operation_type : std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        operation_sel : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        immediate : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        store_queue_tag : std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0); 
        load_queue_tag : std_logic_vector(LOAD_QUEUE_TAG_BITS - 1 downto 0); 
        phys_src_reg_1 : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        phys_src_reg_2 : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);         
        phys_dest_reg : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        curr_branch_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        dependent_branches_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        valid : std_logic;
    end record; 
    
    constant SCHED_IN_PORT_DEFAULT : sched_in_port_type := ((others => '0'),
                                                            (others => '0'),
                                                            (others => '0'),
                                                            (others => '0'),
                                                            (others => '0'),
                                                            (others => '0'),
                                                            (others => '0'),
                                                            (others => '0'),
                                                            (others => '0'),
                                                            (others => '0'),
                                                            (others => '0'),
                                                            '0',
                                                            '0');
                                                            
    constant SCHED_OUT_PORT_DEFAULT : sched_out_port_type := ((others => '0'),
                                                              (others => '0'),
                                                              (others => '0'),
                                                              (others => '0'),
                                                              (others => '0'),
                                                              (others => '0'),
                                                              (others => '0'),
                                                              (others => '0'),
                                                              (others => '0'),
                                                              (others => '0'),
                                                              (others => '0'),
                                                              '0');
    
    -- Scheduler entry format [OP. TYPE | OP. SEL | OPERAND_1_TAG | OPERAND_1_TAG_V | OPERAND_2_TAG | OPERAND_2_TAG_V | DEST_PHYS_REG_TAG | STORE QUEUE TAG | LOAD QUEUE TAG | IMMEDIATE | INSTR. TAG | CURR. BRANCH MASK | DEP. BRANCH TAG | BUSY]
    type reservation_station_entries_type is array(SCHEDULER_ENTRIES - 1 downto 0) of std_logic_vector(ENTRY_BITS - 1 downto 0);
    type sched_optype_bits_type is array(1 downto 0) of std_logic_vector(SCHEDULER_ENTRIES - 1 downto 0);
    type sched_dispatch_ready_bits_type is array(1 downto 0) of std_logic_vector(SCHEDULER_ENTRIES - 1 downto 0);
    type sched_read_sel_type is array(1 downto 0) of std_logic_vector(ENTRY_TAG_BITS - 1 downto 0);
    -- ================================================================================
    -- ////////////////////////////////////////////////////////////////////////////////
    -- ================================================================================
    
    -- ================================================================================
    --                        OPERATION TYPE - PORT MAPPINGS
    -- ================================================================================
    constant PORT_0_OPTYPE : std_logic_vector(2 downto 0) := "000";
    constant PORT_1_OPTYPE : std_logic_vector(2 downto 0) := "001";
    -- ================================================================================
    -- ////////////////////////////////////////////////////////////////////////////////
    -- ================================================================================
end package;