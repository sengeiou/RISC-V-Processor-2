----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/19/2021 12:44:37 PM
-- Design Name: Execute stage datapath
-- Module Name: stage_execute_dp - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- 0.01 - File Created
-- 0.1.0 - Added basic ALU functionality
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity stage_execute_dp is
    generic(
        CPU_DATA_WIDTH_BITS : integer
    );
    port(
        -- DATA SIGNALS
        reg_1_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        reg_2_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        alu_result : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        
        -- CONTROL SIGNALS
        alu_op_sel : in std_logic_vector(3 downto 0)
    );
end stage_execute_dp;

architecture structural of stage_execute_dp is

begin
    alu : entity work.arithmetic_logic_unit(rtl)
          generic map(OPERAND_WIDTH_BITS => CPU_DATA_WIDTH_BITS)
          port map(operand_1 => reg_1_data,
                   operand_2 => reg_2_data,
                   result => alu_result,
                   alu_op_sel => alu_op_sel);

end structural;













