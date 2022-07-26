library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;

-- ======================================
-- TO DO:
-- 1. Delete contents of first two pipeline registers in case of branch!
-- ======================================

package pkg_cpu is
    -- CPU Config Parameters
    constant CPU_DATA_WIDTH_BITS : integer := 32;
    constant CPU_ADDR_WIDTH_BITS : integer := 32;
    
    constant ARCH_REGFILE_ENTRIES : integer range 1 to 1024 := 32;
    constant ARCH_REGFILE_ADDR_BITS : integer := integer(ceil(log2(real(ARCH_REGFILE_ENTRIES))));
    
    constant PHYS_REGFILE_ENTRIES : integer range 1 to 1024 := 96;
    constant PHYS_REGFILE_ADDR_BITS : integer := integer(ceil(log2(real(PHYS_REGFILE_ENTRIES))));
    
    constant SCHEDULER_ENTRIES : integer range 1 to 1023 := 8;
    constant REORDER_BUFFER_ENTRIES : integer := 24;
    constant STORE_QUEUE_ENTRIES : integer := 8;
    constant LOAD_QUEUE_ENTRIES : integer := 8;
    constant BRANCHING_DEPTH : integer := 6;            -- How many branches this CPU is capable of speculating against. For ex. 4 Means 4 cond. branch instructions before further fetching is halted
    
    constant OPERATION_TYPE_BITS : integer := 3;
    constant OPERATION_SELECT_BITS : integer := 8;
    constant OPERAND_BITS : integer := CPU_DATA_WIDTH_BITS;
    constant STORE_QUEUE_TAG_BITS : integer := integer(ceil(log2(real(STORE_QUEUE_ENTRIES))));
    constant LOAD_QUEUE_TAG_BITS : integer := integer(ceil(log2(real(LOAD_QUEUE_ENTRIES))));
    constant INSTR_TAG_BITS : integer := integer(ceil(log2(real(REORDER_BUFFER_ENTRIES))));
    
    -- Constants
    constant INSTR_TAG_ZERO : std_logic_vector(INSTR_TAG_BITS - 1 downto 0) := (others => '0');
    constant REG_ADDR_ZERO : std_logic_vector(ARCH_REGFILE_ADDR_BITS - 1 downto 0) := (others => '0');
    constant PHYS_REG_TAG_ZERO : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0) := (others => '0');
    constant ADDR_ZERO : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0) := (others => '0');
    constant DATA_ZERO : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0) := (others => '0');
    constant BRANCH_MASK_ZERO : std_logic_vector(BRANCHING_DEPTH - 1 downto 0) := (others => '0');
    
    -- Debugging Configuration
    constant ENABLE_REGFILE_ILA : boolean := true;
    
    -- Logic Vector Constants
    constant NUM_4 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0) := X"00000004";
    
    -- CPU Data Types
    type uop_type is record
        pc : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        -- Determines what kinds of functional units can execute this type of instruction. Used to select one or multiple functional units.
        operation_type : std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        
        -- Selects the operation to be performed once the instruction has been passed to the functional unit. Ex: ALU operation selection
        operation_select : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        
        -- Source register addresses
        arch_src_reg_1 : std_logic_vector(ARCH_REGFILE_ADDR_BITS - 1 downto 0);
        arch_src_reg_2 : std_logic_vector(ARCH_REGFILE_ADDR_BITS - 1 downto 0);
        arch_dest_reg : std_logic_vector(ARCH_REGFILE_ADDR_BITS - 1 downto 0);
        
        immediate : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    end record;
    
    type rat_type is array (ARCH_REGFILE_ENTRIES - 1 downto 0) of std_logic_vector(PHYS_REGFILE_ADDR_BITS downto 0);
    constant RAT_TYPE_ZERO : rat_type := (others => (others => '0'));
    
    -- Operation Type Definitions
    constant OP_TYPE_INTEGER : std_logic_vector(2 downto 0) := "000";
    constant OP_TYPE_LOAD_STORE : std_logic_vector(2 downto 0) := "001";
    constant OP_TYPE_COND_BRANCH : std_logic_vector(2 downto 0) := "010";
    constant OP_TYPE_JUMP : std_logic_vector(2 downto 0) := "011";
    
    -- Load-Store Unit Operation Definitions
    constant LSU_OP_LW : std_logic_vector(7 downto 0) := "00000000";
    constant LSU_OP_SW : std_logic_vector(7 downto 0) := "10000000";    
    
    -- Integer EU Operation Definitions
    constant ALU_OP_ADD : std_logic_vector(3 downto 0) := "0000";
    constant ALU_OP_SUB : std_logic_vector(3 downto 0) := "1000";
    constant ALU_OP_XOR : std_logic_vector(3 downto 0) := "0100";
    constant ALU_OP_EQ : std_logic_vector(3 downto 0) := "1100";
    constant ALU_OP_LESS : std_logic_vector(3 downto 0) := "0010";
    constant ALU_OP_LESSU : std_logic_vector(3 downto 0) := "1110";
    constant ALU_OP_OR : std_logic_vector(3 downto 0) := "0110";
    constant ALU_OP_AND : std_logic_vector(3 downto 0) := "0111";
    constant ALU_OP_SLL : std_logic_vector(3 downto 0) := "0001";
    constant ALU_OP_SRL : std_logic_vector(3 downto 0) := "0101";
    constant ALU_OP_SRA : std_logic_vector(3 downto 0) := "1101";
    
    -- Opcode Definitions
    constant REG_ALU_OP : std_logic_vector(6 downto 0) := "0110011";
    constant IMM_ALU_OP : std_logic_vector(6 downto 0) := "0010011";
    constant LUI : std_logic_vector(6 downto 0) := "0110111";
    constant AUIPC : std_logic_vector(6 downto 0) := "0010111";
    constant LOAD : std_logic_vector(6 downto 0) := "0000011";
    constant STORE : std_logic_vector(6 downto 0) := "0100011";
    constant JAL : std_logic_vector(6 downto 0) := "1101111";
    constant JALR : std_logic_vector(6 downto 0) := "1100111";
    constant BR_COND : std_logic_vector(6 downto 0) := "1100011";
    
    -- Program Flow Definitions
    constant PROG_FLOW_NORM : std_logic_vector(1 downto 0) := "00";
    constant PROG_FLOW_COND : std_logic_vector(1 downto 0) := "01";
    constant PROG_FLOW_JAL : std_logic_vector(1 downto 0) := "10";
    constant PROG_FLOW_JALR : std_logic_vector(1 downto 0) := "11";
    
    -- CDB Configuration
    
    type cdb_type is record
        instr_tag : std_logic_vector(INSTR_TAG_BITS - 1 downto 0);
        phys_dest_reg : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        data : std_logic_vector(OPERAND_BITS - 1 downto 0);
        branch_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0); 
        branch_taken : std_logic;
        valid : std_logic;
    end record;
    
    function branch_mask_to_int(branch_mask : in std_logic_vector(BRANCHING_DEPTH - 1 downto 0)) return integer;
end pkg_cpu;

package body pkg_cpu is
    -- ASSUMES ONE-HOT ENCODING!
    function branch_mask_to_int(branch_mask : in std_logic_vector(BRANCHING_DEPTH - 1 downto 0)) return integer is
        variable temp : integer := 0;
    begin
        for i in 0 to BRANCHING_DEPTH - 1 loop
            if (branch_mask(i) = '1') then
                temp := i;
            end if;
        end loop;
        return temp;
    end function branch_mask_to_int;
end package body;







