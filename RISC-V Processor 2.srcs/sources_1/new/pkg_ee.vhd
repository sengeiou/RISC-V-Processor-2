library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

-- Package for the execution engine

package pkg_ee is
    type execution_engine_pipeline_register_1_type is record
        operation_type : std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        operation_select : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        renamed_dest_reg : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        renamed_src_reg_1 : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        renamed_src_reg_2 : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        immediate : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    end record;
    
    constant EE_PIPELINE_REG_1_INIT : execution_engine_pipeline_register_1_type := ((others => '0'),
                                                                                    (others => '0'),
                                                                                    (others => '0'),
                                                                                    (others => '0'),
                                                                                    (others => '0'),
                                                                                    (others => '0'));
end package;