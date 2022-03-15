library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

package pkg_fu is
    type int_br_pipeline_reg_1_type is record
        operand_1 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        operand_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        immediate : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        operation_sel : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        rs_entry_tag : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
    end record;
    
    type int_br_pipeline_reg_2_type is record
        alu_result : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        rs_entry_tag : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
    end record;
end package;