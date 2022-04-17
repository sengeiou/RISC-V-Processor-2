library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

package pkg_fu is

    -- =====================================================
    --                   EXECUTION UNIT 0      
    -- =====================================================
    type exec_unit_0_pipeline_reg_0_type is record
        result : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        valid : std_logic;
    end record;
 
    constant PIPELINE_REG_0_INIT : exec_unit_0_pipeline_reg_0_type := ((others => '0'),
                                                                      (others => '0'),
                                                                      '0');
    
    -- =====================================================
    --              LOAD - STORE UNIT REGISTERS             
    -- =====================================================
    type lsu_pipeline_reg_1_type is record
        operand_1 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        operand_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        immediate : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        operation_sel : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        valid : std_logic;
    end record;
    
    type lsu_pipeline_reg_2_type is record
        store_data : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        address : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        operation_sel : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        valid : std_logic;
    end record;
    
    type lsu_pipeline_reg_3_type is record
        load_data : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        valid : std_logic;
    end record;
    
    constant LS_PIPELINE_REG_1_ZERO : lsu_pipeline_reg_1_type := ((others => '0'),
                                                                 (others => '0'),
                                                                 (others => '0'),
                                                                 (others => '0'),
                                                                 (others => '0'),
                                                                 '0');
                                                                      
    constant LS_PIPELINE_REG_2_ZERO : lsu_pipeline_reg_2_type := ((others => '0'),
                                                                 (others => '0'),
                                                                 (others => '0'),
                                                                 (others => '0'),
                                                                 '0');
                                                                      
    constant LS_PIPELINE_REG_3_ZERO : lsu_pipeline_reg_3_type := ((others => '0'),
                                                                 (others => '0'),
                                                                 '0');
end package;