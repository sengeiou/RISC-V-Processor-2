----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/19/2021 12:44:37 PM
-- Design Name: 
-- Module Name: stage_execute_cntrl - rtl
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

entity stage_execute_cntrl is
    port(
        -- INPUT CONTROL SIGNALS
        alu_op_in : in std_logic_vector(3 downto 0);
        
        -- OUTPUT CONTROL SIGNALS FOR EXECUTE STAGE
        alu_op_out : out std_logic_vector(3 downto 0)
    );
end stage_execute_cntrl;

architecture rtl of stage_execute_cntrl is

begin
    alu_op_out <= alu_op_in

end rtl;
