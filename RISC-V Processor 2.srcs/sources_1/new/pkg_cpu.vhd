library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package pkg_cpu is
    -- CPU Config Parameters
    constant CPU_DATA_WIDTH_BITS : integer := 32;
    constant CPU_ADDR_WIDTH_BITS : integer := 32;
    constant ENABLE_BIG_REGFILE : integer range 0 to 1 := 1;        -- Selects between 16 entry register file and the 32 entry one (RV32E and RV32I)
    
    -- ALU Operation Definitions
    constant ALU_OP_ADD : std_logic_vector(3 downto 0) := "0000";
    constant ALU_OP_SUB : std_logic_vector(3 downto 0) := "1000";
    constant ALU_OP_LESS : std_logic_vector(3 downto 0) := "0010";
    constant ALU_OP_LESSU : std_logic_vector(3 downto 0) := "0011";
    constant ALU_OP_XOR : std_logic_vector(3 downto 0) := "0100";
    constant ALU_OP_OR : std_logic_vector(3 downto 0) := "0110";
    constant ALU_OP_AND : std_logic_vector(3 downto 0) := "0111";
    constant ALU_OP_SLL : std_logic_vector(3 downto 0) := "0001";
    constant ALU_OP_SRL : std_logic_vector(3 downto 0) := "0101";
    constant ALU_OP_SRA : std_logic_vector(3 downto 0) := "1101";
end pkg_cpu;