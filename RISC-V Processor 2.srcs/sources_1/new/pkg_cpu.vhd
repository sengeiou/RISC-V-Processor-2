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
    constant ENABLE_BIG_REGFILE : integer range 0 to 1 := 1;        -- Selects between 16 entry register file and the 32 entry one (RV32E and RV32I)
    constant REGFILE_SIZE : integer range 1 to 1024 := 32;
    constant RESERVATION_STATION_ENTRY_CNT : integer range 1 to 1023 := 7;
    
    -- Debugging Configuration
    constant ENABLE_REGFILE_ILA : boolean := true;
    
    -- Logic Vector Constants
    constant NUM_4 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0) := X"00000004";
    
    -- ALU Operation Definitions
    constant ALU_OP_ADD : std_logic_vector(3 downto 0) := "0000";
    constant ALU_OP_SUB : std_logic_vector(3 downto 0) := "1000";
    constant ALU_OP_EQ : std_logic_vector(3 downto 0) := "1100";
    constant ALU_OP_LESS : std_logic_vector(3 downto 0) := "0010";
    constant ALU_OP_LESSU : std_logic_vector(3 downto 0) := "1110";
    constant ALU_OP_XOR : std_logic_vector(3 downto 0) := "0100";
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
    constant RESERVATION_STATION_ENTRIES : integer range 1 to 1024 := 4;
    constant OPERATION_TYPE_BITS : integer := 3;
    constant OPERATION_SELECT_BITS : integer := 5;
    constant OPERAND_BITS : integer := CPU_DATA_WIDTH_BITS;
    
    type cdb_type is record
        rs_entry_tag : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) downto 0);
        data : std_logic_vector(OPERAND_BITS - 1 downto 0);
    end record;
end pkg_cpu;







