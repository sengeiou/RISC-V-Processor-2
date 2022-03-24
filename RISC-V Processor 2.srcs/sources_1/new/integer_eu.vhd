-- Functional unit capable of executing integer and branch instructions

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_FU.ALL;

entity integer_eu is
    generic(
        OPERAND_BITS : integer range 1 to 128
    );
    port(
        -- Instruction Fields
        operand_1 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        operand_2 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        immediate : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        operation_sel : in std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        rs_entry_tag : in std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
        dispatch_ready : in std_logic;
        
        
        -- CDB Control
        cdb : out cdb_type;
        cdb_request : out std_logic;
        cdb_granted : in std_logic;
        
        busy : out std_logic;
        reset : in std_logic;
        clk : in std_logic
    );
end integer_eu;

architecture structural of integer_eu is
    signal pipeline_reg_1 : int_br_pipeline_reg_1_type;
    signal pipeline_reg_2 : int_br_pipeline_reg_2_type;
    
    signal pipeline_enable : std_logic;
    
    signal alu_operand_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal alu_result : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
begin
    pipeline_reg_1_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_1 <= INT_PIPELINE_REG_1_ZERO;
            elsif (pipeline_enable = '1') then
                pipeline_reg_1.operand_1 <= operand_1;
                pipeline_reg_1.operand_2 <= operand_2;
                pipeline_reg_1.immediate <= immediate;
                pipeline_reg_1.operation_sel <= operation_sel;
                pipeline_reg_1.rs_entry_tag <= rs_entry_tag;
                pipeline_reg_1.valid <= dispatch_ready;
            end if;
        end if;
    end process;
    
    pipeline_reg_2_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_2 <= INT_PIPELINE_REG_2_ZERO;
            elsif (pipeline_enable = '1') then
                pipeline_reg_2.alu_result <= alu_result;
                pipeline_reg_2.rs_entry_tag <= pipeline_reg_1.rs_entry_tag;
                pipeline_reg_2.valid <= pipeline_reg_1.valid;
            elsif (pipeline_reg_2.valid = '1' and cdb_granted = '1') then
                pipeline_reg_2.valid <= '0';
            end if;
        end if;
    end process;
    
    alu_operand_2 <= pipeline_reg_1.operand_2 when (pipeline_reg_1.operation_sel(4) = '0') else
                     pipeline_reg_1.immediate;

    alu : entity work.arithmetic_logic_unit(rtl)
          generic map(OPERAND_WIDTH_BITS => OPERAND_BITS)
          port map(operand_1 => pipeline_reg_1.operand_1,
                   operand_2 => alu_operand_2,
                   result => alu_result,
                   alu_op_sel => pipeline_reg_1.operation_sel(3 downto 0));
                   
    pipeline_enable <= (not pipeline_reg_2.valid) or cdb_granted;
                   
    cdb_request <= pipeline_reg_2.valid;
    
    cdb.data <= pipeline_reg_2.alu_result;
    cdb.rs_entry_tag <= pipeline_reg_2.rs_entry_tag;
    
    busy <= '0';

end structural;
