-- Functional unit capable of executing integer and branch instructions

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_FU.ALL;

entity integer_branch_fu is
    generic(
        OPERAND_BITS : integer range 1 to 128
    );
    port(
        operand_1 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        operand_2 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        immediate : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        operation_sel : in std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        rf_write_reg_addr : in std_logic_vector(4 downto 0);
        rs_entry_tag : in std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) downto 0);
        
        cdb_data : out std_logic_vector(OPERAND_BITS - 1 downto 0);
        cdb_rf_write_reg_addr : out std_logic_vector(4 downto 0);
        cdb_rs_update_index : out std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) downto 0);
        
        reset : in std_logic;
        clk : in std_logic
    );
end integer_branch_fu;

architecture structural of integer_branch_fu is
    signal pipeline_reg_1 : int_br_pipeline_reg_1_type;
    signal pipeline_reg_2 : int_br_pipeline_reg_2_type;
    
    signal alu_operand_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal alu_result : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
begin
    pipeline_reg_1_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_1 <= (others => (others => '0'));
            else
                pipeline_reg_1.operand_1 <= operand_1;
                pipeline_reg_1.operand_2 <= operand_2;
                pipeline_reg_1.immediate <= immediate;
                pipeline_reg_1.operation_sel <= operation_sel;
                pipeline_reg_1.rf_write_reg_addr <= rf_write_reg_addr;
                pipeline_reg_1.rs_entry_tag <= rs_entry_tag;
            end if;
        end if;
    end process;
    
    pipeline_reg_2_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_2 <= (others => (others => '0'));
            else
                pipeline_reg_2.alu_result <= alu_result;
                pipeline_reg_2.rf_write_reg_addr <= pipeline_reg_1.rf_write_reg_addr;
                pipeline_reg_2.rs_entry_tag <= pipeline_reg_1.rs_entry_tag;
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
                   
    cdb_data <= pipeline_reg_2.alu_result;
    cdb_rf_write_reg_addr <= pipeline_reg_2.rf_write_reg_addr;
    cdb_rs_update_index <= pipeline_reg_2.rs_entry_tag;

end structural;
