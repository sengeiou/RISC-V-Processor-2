----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/19/2021 11:18:11 AM
-- Design Name: 
-- Module Name: arithmetic_logic_unit - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Revision 1.00 - Added first ALU operations
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

begin
    alu_process : process(all)
    begin
        if (alu_op_sel = "0000") then               -- ADD
            result <= std_logic_vector(signed(operand_1) + signed(operand_2));
        elsif (alu_op_sel = "1000") then            -- SUB
            result <= std_logic_vector(signed(operand_1) - signed(operand_2));
        elsif (alu_op_sel = "0010") then            -- SET ON OP_1 < OP_2 SIGNED            
            result <= (OPERAND_WIDTH_BITS downto 1 => '0') & '1' when signed(operand_1) < signed(operand_2) else
                      (others => '0');
        elsif (alu_op_sel = "0011") then            -- SET ON OP_1 < OP_2 UNSIGNED            
            result <= (OPERAND_WIDTH_BITS downto 1 => '0') & '1' when unsigned(operand_1) < unsigned(operand_2) else
                      (others => '0');
        elsif (alu_op_sel = "0100") then            -- XOR         
            result <= operand_1 xor operand_2;
        elsif (alu_op_sel = "0110") then            -- OR
            result <= operand_1 or operand_2;
        elsif (alu_op_sel = "0111") then            -- AND
            result <= operand_1 and operand_2;
        end if;
    end process;

end rtl;






