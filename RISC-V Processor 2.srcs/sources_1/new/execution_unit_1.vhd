library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_FU.ALL;

-- MODULES --
-- 1) ADDRESS GENERATION UNIT
-- 2) STORE DATA

-- Currently both data and address are generated by a single uop. Logic might become more complicated in the future when address calculations for
-- STORE instruction could be fired earlier then data generation

entity execution_unit_1 is
    port(
        cdb : in cdb_type;
    
        store_data_value : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);        -- Data for store
        base_addr_value : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);         -- Base address
        immediate : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);               -- Base address offset
        
        operation_select : in std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);      -- Determines whether we are dealing with a load or a store
        stq_tag : in std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);                -- Store queue tag into which to write the results
        stq_data_tag : in std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);                -- Store queue tag into which to write the results
        ldq_tag : in std_logic_vector(LOAD_QUEUE_TAG_BITS - 1 downto 0);                 -- Load queue into which to write the results
        
        dependent_branches_mask : in std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    
        valid : in std_logic;       -- Signals that the input values are valid
        ready : out std_logic;      -- Whether this EU is ready to start executing a new operation
        
        -- TO LOAD-STORE UNIT
        lsu_generated_address : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        lsu_generated_data : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        lsu_generated_data_tag : out std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        lsu_generated_data_valid : out std_logic;
        lsu_stq_tag : out std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);
        lsu_stq_tag_valid : out std_logic;
        lsu_ldq_tag : out std_logic_vector(LOAD_QUEUE_TAG_BITS - 1 downto 0);
        lsu_ldq_tag_valid : out std_logic;
        
        clk : in std_logic;
        reset : in std_logic
    );
end execution_unit_1;

architecture rtl of execution_unit_1 is
    signal pipeline_reg_0 : exec_unit_1_pipeline_reg_0_type;
    signal pipeline_reg_0_next : exec_unit_1_pipeline_reg_0_type;
begin
    process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_0 <= EU_1_PIPELINE_REG_0_INIT;
            else
                pipeline_reg_0 <= pipeline_reg_0_next;
            end if;
        end if;
    end process;
    
    pipeline_reg_0_next.generated_address <= std_logic_vector(unsigned(base_addr_value) + unsigned(immediate));
    pipeline_reg_0_next.generated_data <= store_data_value;
    pipeline_reg_0_next.generated_data_tag <= stq_data_tag;
    pipeline_reg_0_next.generated_data_valid <= operation_select(7) and valid;
    pipeline_reg_0_next.ldq_tag <= ldq_tag;
    pipeline_reg_0_next.ldq_tag_valid <= not operation_select(7) and valid;
    pipeline_reg_0_next.stq_tag <= stq_tag;
    pipeline_reg_0_next.stq_tag_valid <= operation_select(7) and valid;
    pipeline_reg_0_next.dependent_branches_mask <= dependent_branches_mask;
    pipeline_reg_0_next.valid <= '0' when valid = '0' or ((dependent_branches_mask and cdb.branch_mask) /= BRANCH_MASK_ZERO and cdb.branch_taken = '1') else '1';

    lsu_generated_address <= pipeline_reg_0.generated_address;
    lsu_generated_data <= pipeline_reg_0.generated_data;
    lsu_generated_data_tag <= pipeline_reg_0.generated_data_tag;
    lsu_generated_data_valid <= pipeline_reg_0.generated_data_valid;
    lsu_stq_tag <= pipeline_reg_0.stq_tag;
    lsu_stq_tag_valid <= pipeline_reg_0.stq_tag_valid;
    lsu_ldq_tag <= pipeline_reg_0.ldq_tag;
    lsu_ldq_tag_valid <= pipeline_reg_0.ldq_tag_valid;

    ready <= '1';       -- Always ready

end rtl;
