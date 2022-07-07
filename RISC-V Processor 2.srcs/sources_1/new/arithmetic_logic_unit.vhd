--------------------------------
-- NOTES:
-- 1) Comparator logic is POORLY implemented with VHDL operators so it will require re-implementation
--------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.pkg_cpu.all;

entity arithmetic_logic_unit is
    generic(
        OPERAND_WIDTH_BITS : integer
    );
    port(
        operand_1 : in std_logic_vector(OPERAND_WIDTH_BITS - 1 downto 0);
        operand_2 : in std_logic_vector(OPERAND_WIDTH_BITS - 1 downto 0);
        result : out std_logic_vector(OPERAND_WIDTH_BITS - 1 downto 0);
        alu_op_sel : in std_logic_vector(3 downto 0)
    );
end arithmetic_logic_unit;

architecture rtl of arithmetic_logic_unit is
    signal i_barrel_shifter_result : std_logic_vector(OPERAND_WIDTH_BITS - 1 downto 0);
    
    signal i_barrel_shifter_airth : std_logic;
    signal i_barrel_shifter_direction : std_logic;
begin
    barrel_shifter : entity work.barrel_shifter_2(rtl)
                     generic map(DATA_WIDTH => OPERAND_WIDTH_BITS)
                     port map(data_in => operand_1,
                              data_out => i_barrel_shifter_result,
                              shift_amount => operand_2(integer(log2(real(OPERAND_WIDTH_BITS))) - 1 downto 0),
                              shift_arith => i_barrel_shifter_airth,
                              shift_direction => i_barrel_shifter_direction);
                              
    alu_process : process(alu_op_sel, operand_1, operand_2)
    begin
        i_barrel_shifter_direction <= '0';
        i_barrel_shifter_airth <= '0';
    
        if (alu_op_sel = ALU_OP_ADD) then               -- ADD        
            result <= std_logic_vector(signed(operand_1) + signed(operand_2));
        elsif (alu_op_sel = ALU_OP_SUB) then            -- SUB        
            result <= std_logic_vector(signed(operand_1) - signed(operand_2));
        elsif (alu_op_sel = ALU_OP_LESS) then            -- SET ON OP_1 < OP_2 SIGNED  
            result <= (OPERAND_WIDTH_BITS - 1 downto 1 => '0') & '1' when signed(operand_1) < signed(operand_2) else
                      (others => '0');
            --result <= (others => '0');
        elsif (alu_op_sel = ALU_OP_LESSU) then            -- SET ON OP_1 < OP_2 UNSIGNED         
            result <= (OPERAND_WIDTH_BITS - 1 downto 1 => '0') & '1' when unsigned(operand_1) < unsigned(operand_2) else
                      (others => '0');
            --result <= (others => '0');
        elsif (alu_op_sel = ALU_OP_EQ) then             -- OP_1 = OP_2
            result <= (OPERAND_WIDTH_BITS - 1 downto 1 => '0') & '1' when operand_1 = operand_2 else
                      (others => '0');
            --result <= (others => '0');
        elsif (alu_op_sel = ALU_OP_XOR) then            -- XOR         
            result <= operand_1 xor operand_2;
        elsif (alu_op_sel = ALU_OP_OR) then            -- OR
            result <= operand_1 or operand_2;
        elsif (alu_op_sel = ALU_OP_AND) then            -- AND
            result <= operand_1 and operand_2;
        elsif (alu_op_sel = ALU_OP_SLL) then            -- SLL
            i_barrel_shifter_direction <= '1';
        
            result <= i_barrel_shifter_result;
        elsif (alu_op_sel = ALU_OP_SRL) then            -- SRL
            result <= i_barrel_shifter_result;
        elsif (alu_op_sel = ALU_OP_SRA) then            -- SRA
            i_barrel_shifter_airth <= '1';
        
            result <= i_barrel_shifter_result;
        else
            result <= (others => '0');
        end if;
    end process;

end rtl;






