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

--------------------------------
-- NOTES:
-- 1) Comparator logic is POORLY implemented with VHDL operators so it will require re-implementation
--------------------------------

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
    signal i_barrel_shifter_result : std_logic_vector(OPERAND_WIDTH_BITS - 1 downto 0);
    
    signal i_barrel_shifter_airth : std_logic;
    signal i_barrel_shifter_direction : std_logic;
begin
    barrel_shifter_generate : if (OPERAND_WIDTH_BITS = 32) generate
            barrel_shifter : entity work.barrel_shifter(rtl)
                             port map(data_in => operand_1,
                                      data_out => i_barrel_shifter_result,
                                      shift_amount => operand_2(4 downto 0),
                                      shift_arith => i_barrel_shifter_airth,
                                      shift_direction => i_barrel_shifter_direction);
        elsif (OPERAND_WIDTH_BITS = 64) generate
            barrel_shifter : entity work.barrel_shifter_64(rtl)
                         port map(data_in => operand_1,
                                  data_out => i_barrel_shifter_result,
                                  shift_amount => operand_2(5 downto 0),
                                  shift_arith => i_barrel_shifter_airth,
                                  shift_direction => i_barrel_shifter_direction);
    end generate barrel_shifter_generate;
                              
    alu_process : process(all)
    begin
        if (alu_op_sel = "0000") then               -- ADD
            result <= std_logic_vector(signed(operand_1) + signed(operand_2));
        elsif (alu_op_sel = "1000") then            -- SUB
            result <= std_logic_vector(signed(operand_1) - signed(operand_2));
        elsif (alu_op_sel = "0010") then            -- SET ON OP_1 < OP_2 SIGNED            
            result <= (OPERAND_WIDTH_BITS - 1 downto 1 => '0') & '1' when signed(operand_1) < signed(operand_2) else
                      (others => '0');
        elsif (alu_op_sel = "0011") then            -- SET ON OP_1 < OP_2 UNSIGNED            
            result <= (OPERAND_WIDTH_BITS - 1 downto 1 => '0') & '1' when unsigned(operand_1) < unsigned(operand_2) else
                      (others => '0');
        elsif (alu_op_sel = "0100") then            -- XOR         
            result <= operand_1 xor operand_2;
        elsif (alu_op_sel = "0110") then            -- OR
            result <= operand_1 or operand_2;
        elsif (alu_op_sel = "0111") then            -- AND
            result <= operand_1 and operand_2;
        elsif (alu_op_sel = "0001") then            -- SLL
            i_barrel_shifter_direction <= '1';
            i_barrel_shifter_airth <= '0';
        
            result <= i_barrel_shifter_result;
        elsif (alu_op_sel = "0101") then            -- SRL
            i_barrel_shifter_direction <= '0';
            i_barrel_shifter_airth <= '0';
        
            result <= i_barrel_shifter_result;
        elsif (alu_op_sel = "1101") then            -- SRA
            i_barrel_shifter_direction <= '0';
            i_barrel_shifter_airth <= '1';
        
            result <= i_barrel_shifter_result;
        end if;
    end process;

end rtl;






