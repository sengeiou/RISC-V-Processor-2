library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_FU.ALL;

-- MODULES --
-- 1) INTEGER ALU
-- 2) INTEGER DIV (WIP)
-- 3) INTEGER MUL (WIP)

entity execution_unit_0 is
    port(
        reg_data_1 : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        reg_data_2 : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        immediate : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        
        -- Bit 7 indicates whether the instruction is of I-type or R-type; Bits 3 - 0 are ALU operation select bits; Others are reserved
        operation_select : in std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        tag : in std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    
        valid : in std_logic;       -- Signals that the input values are valid
        ready : out std_logic;      -- Whether this EU is ready to start executing a new operation
        
        cdb : out cdb_type;
        cdb_request : out std_logic;
        cdb_granted : in std_logic;
        
        clk : in std_logic;
        reset : in std_logic
    );
end execution_unit_0;

architecture structural of execution_unit_0 is
    signal operand_1 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal operand_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal alu_result : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal i_ready : std_logic;
    
    signal pipeline_reg_0 : exec_unit_0_pipeline_reg_0_type;
    signal pipeline_reg_0_next : exec_unit_0_pipeline_reg_0_type;
begin
    -- =====================================================
    --                  PIPELINE REGISTERS    
    -- =====================================================
    pipeline_reg_0_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_0 <= PIPELINE_REG_0_INIT;
            elsif (i_ready = '1') then
                pipeline_reg_0 <= pipeline_reg_0_next;  
            end if;
        end if;
    end process;
    
    pipeline_reg_0_next.result <= alu_result;
    pipeline_reg_0_next.tag <= tag;
    pipeline_reg_0_next.valid <= valid;
    -- =====================================================
    -- =====================================================

    operand_1 <= reg_data_1;
    operand_2 <= reg_data_2 when operation_select(7) = '0' else immediate;

    alu : entity work.arithmetic_logic_unit(rtl)
          generic map(OPERAND_WIDTH_BITS => CPU_DATA_WIDTH_BITS)
          port map(operand_1 => operand_1,
                   operand_2 => operand_2,
                   result => alu_result,
                   alu_op_sel => operation_select(3 downto 0));
    
    i_ready <= '0' when (not pipeline_reg_0.valid or cdb_granted) = '0' else '1';
    ready <= i_ready;
                   
    cdb.data <= pipeline_reg_0.result;
    cdb.tag <= pipeline_reg_0.tag;
    cdb.valid <= pipeline_reg_0.valid;
    
    cdb_request <= pipeline_reg_0.valid;

end structural;
