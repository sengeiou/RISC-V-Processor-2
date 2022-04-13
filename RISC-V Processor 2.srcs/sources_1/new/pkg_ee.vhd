library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_SCHED.ALL;
use WORK.PKG_CPU.ALL;

-- Package for the execution engine

package pkg_ee is
    type execution_engine_pipeline_register_1_type is record
        sched_in_port_0 : sched_in_port_type;
        dest_reg : std_logic_vector(ARCH_REGFILE_ADDR_BITS - 1 downto 0);
        valid : std_logic;
    end record;
    
    type execution_engine_pipeline_register_2_p0_type is record
        sched_out_port_0 : sched_out_port_type;
        valid : std_logic;
    end record;
    
    type execution_engine_pipeline_register_2_p1_type is record
        sched_out_port_1 : sched_out_port_type;
        valid : std_logic;
    end record;
    
    type execution_engine_pipeline_register_3_int_type is record
        operand_1 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        operand_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        immediate : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        dest_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        operation_select : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        valid : std_logic;
    end record;
    
    type execution_engine_pipeline_register_3_ldst_type is record
        store_data_value : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        base_addr_value : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        immediate : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        data_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        store_queue_tag : std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);
        load_queue_tag : std_logic_vector(LOAD_QUEUE_TAG_BITS - 1 downto 0);
        operation_select : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        valid : std_logic;
    end record;
    
    constant EE_PIPELINE_REG_1_INIT : execution_engine_pipeline_register_1_type := (SCHED_IN_PORT_DEFAULT,
                                                                                    (others => '0'),
                                                                                    '0');
                                                                                    
    constant EE_PIPELINE_REG_2_P0_INIT : execution_engine_pipeline_register_2_p0_type := (SCHED_OUT_PORT_DEFAULT,
                                                                                         '0');
                                                                                    
    constant EE_PIPELINE_REG_2_P1_INIT : execution_engine_pipeline_register_2_p1_type := (SCHED_OUT_PORT_DEFAULT,
                                                                                         '0');
                                                                                    
    constant EE_PIPELINE_REG_3_INT_INIT : execution_engine_pipeline_register_3_int_type := ((others => '0'),
                                                                                        (others => '0'),
                                                                                        (others => '0'),
                                                                                        (others => '0'),
                                                                                        (others => '0'),
                                                                                        '0');
                                                                                        
    constant EE_PIPELINE_REG_3_LDST_INIT : execution_engine_pipeline_register_3_ldst_type := ((others => '0'),
                                                                                            (others => '0'),
                                                                                            (others => '0'),
                                                                                            (others => '0'),
                                                                                            (others => '0'),
                                                                                            (others => '0'),
                                                                                            (others => '0'),
                                                                                            '0');
end package;