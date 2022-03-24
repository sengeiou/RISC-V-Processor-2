library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

package pkg_fu is

    -- =====================================================
    --                INTEGER UNIT REGISTERS         
    -- =====================================================
    type int_br_pipeline_reg_1_type is record
        operand_1 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        operand_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        immediate : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        operation_sel : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        rs_entry_tag : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
        valid : std_logic;
    end record;
    
    type int_br_pipeline_reg_2_type is record
        alu_result : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        rs_entry_tag : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
        valid : std_logic;
    end record;
    
    constant INT_PIPELINE_REG_1_ZERO : int_br_pipeline_reg_1_type := ((others => '0'),
                                                                      (others => '0'),
                                                                      (others => '0'),
                                                                      (others => '0'),
                                                                      (others => '0'),
                                                                      '0');
                                                                      
    constant INT_PIPELINE_REG_2_ZERO : int_br_pipeline_reg_2_type := ((others => '0'),
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
        rs_entry_tag : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
        valid : std_logic;
    end record;
    
    type lsu_pipeline_reg_2_type is record
        store_data : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        address : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        operation_sel : std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        rs_entry_tag : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
        valid : std_logic;
    end record;
    
    type lsu_pipeline_reg_3_type is record
        load_data : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        rs_entry_tag : std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
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