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
        reg_1_data : std_logic_vector(31 downto 0);
        reg_2_data : std_logic_vector(31 downto 0);
        
        -- ========== CONTROL SIGNALS ==========
        alu_op_sel : std_logic_vector(3 downto 0)
    );
end stage_execute;

architecture structural of stage_execute is
    signal alu_op_sel_i : std_logic_vector(3 downto 0);
begin
    stage_exec_cntrl : entity work.stage_execute_cntrl(rtl)
                       port map(alu_op_in => alu_op_sel,
                                alu_op_out => alu_op_sel_i);
                       
    stage_exec_dp : entity work.stage_execute_dp(rtl)
                    generic map(CPU_DATA_WIDTH_BITS => CPU_DATA_WIDTH_BITS)
                    port map(-- DATA SIGNALS
                             reg_1_data => reg_1_data,
                             reg_2_data => reg_2_data,
                             
                             -- CONTROL SIGNALS
                             alu_op_sel => alu_op_sel_i);

end rtl;











