-- Functional unit capable of executing integer and branch instructions

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity integer_branch_fu is
    generic(
        OPERAND_BITS : integer range 1 to 128
    );
    port(
        operand_1 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        operand_2 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        result : out std_logic_vector(OPERAND_BITS - 1 downto 0);
        operation_sel : in std_logic_vector(3 downto 0)
    );
end integer_branch_fu;

architecture structural of integer_branch_fu is
begin
    alu : entity work.arithmetic_logic_unit(rtl)
          generic map(OPERAND_WIDTH_BITS => OPERAND_BITS)
          port map(operand_1 => operand_1,
                   operand_2 => operand_2,
                   result => result,
                   alu_op_sel => operation_sel);

end structural;
