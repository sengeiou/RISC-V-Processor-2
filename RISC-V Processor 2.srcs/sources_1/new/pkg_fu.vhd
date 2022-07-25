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
        instr_tag : std_logic_vector(INSTR_TAG_BITS - 1 downto 0);
        phys_dest_reg : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        curr_branch_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        dependent_branches_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        branch_taken : std_logic;
        valid : std_logic;
    end record;
 
    constant EU_0_PIPELINE_REG_0_INIT : exec_unit_0_pipeline_reg_0_type := ((others => '0'),
                                                                      (others => '0'),
                                                                      (others => '0'),
                                                                      (others => '0'),
                                                                      (others => '0'),
                                                                      '0',
                                                                      '0');
    
    -- =====================================================
    --              LOAD - STORE UNIT REGISTERS             
    -- =====================================================
    type exec_unit_1_pipeline_reg_0_type is record
        generated_address : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        generated_data : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        generated_data_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        generated_data_valid : std_logic;
        ldq_tag : std_logic_vector(LOAD_QUEUE_TAG_BITS - 1 downto 0);
        ldq_tag_valid : std_logic;
        stq_tag : std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);
        stq_tag_valid : std_logic;
        dependent_branches_mask : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        valid : std_logic;
    end record;
    
    constant EU_1_PIPELINE_REG_0_INIT : exec_unit_1_pipeline_reg_0_type := ((others => '0'),
                                                                            (others => '0'),
                                                                            (others => '0'),
                                                                            '0',
                                                                            (others => '0'),
                                                                            '0',
                                                                            (others => '0'),
                                                                            '0',
                                                                            (others => '0'),
                                                                            '0');
end package;