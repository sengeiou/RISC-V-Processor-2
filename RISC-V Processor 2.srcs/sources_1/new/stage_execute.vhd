----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/19/2021 12:29:42 PM
-- Design Name: 
-- Module Name: stage_execute - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity stage_execute is
    generic(
        CPU_DATA_WIDTH_BITS : integer
    );
    
    port(
        -- ========== DATA SIGNALS ==========
        reg_1_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        reg_2_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        
        alu_result : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        -- ========== CONTROL SIGNALS ==========
        alu_op_sel : in std_logic_vector(3 downto 0)
    );
end stage_execute;

architecture structural of stage_execute is
    signal alu_op_sel_i : std_logic_vector(3 downto 0);
begin
    alu : entity work.arithmetic_logic_unit(rtl)
          generic map(OPERAND_WIDTH_BITS => 32)
          port map(operand_1 => reg_1_data,
                   operand_2 => reg_2_data,
                   result => alu_result,
                   alu_op_sel => alu_op_sel);
end structural;











