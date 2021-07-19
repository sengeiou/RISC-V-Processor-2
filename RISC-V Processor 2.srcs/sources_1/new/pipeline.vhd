----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/19/2021 12:47:00 PM
-- Design Name: 
-- Module Name: pipeline - structural
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

use work.config.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pipeline is
    port(
        clk : in std_logic;
        reset : in std_logic
    );
end pipeline;

architecture structural of pipeline is
-- ========== DECODE STAGE SIGNALS ==========
signal dec_reg_1_data : std_logic_vector;
signal dec_reg_2_data : std_logic_vector;
signal dec_reg_1_addr : std_logic_vector(4 downto 0); 
signal dec_reg_2_addr : std_logic_vector(4 downto 0);
signal dec_reg_1_used : std_logic;
signal dec_reg_2_used : std_logic;

signal dec_alu_op_sel : std_logic_vector(3 downto 0);

begin
    -- ========== STAGES ==========
    stage_decode : entity work.stage_decode(structural)
                   generic map(CPU_DATA_WIDTH_BITS => CPU_DATA_WIDTH_BITS)
                   port map(-- DATA SIGNALS
                            reg_1_data => dec_reg_1_data,
                            reg_2_data => dec_reg_2_data,
                            
                            -- CONTROL SIGNALS
                            reg_1_addr => dec_reg_1_addr,
                            reg_2_addr => dec_reg_2_addr,
                            reg_1_used => dec_reg_1_used,
                            reg_2_used => dec_reg_2_used,
                            alu_op_sel => dec_alu_op_sel,
                            
                            clk => clk
                            );

    -- ========== PIPELINE REGISTERS ==========
    reg_de_ex : entity work.register_var(rtl)
                generic map(WIDTH_BITS => CPU_DATA_WIDTH_BITS)
                port map(-- ===== DATA =====
                         d(31 downto 0) => dec_reg_1_data,
                         d(63 downto 32) => dec_reg_2_data,
                         
                         -- ===== CONTROL (REGISTERS) =====
                         d(67 downto 64) => dec_reg_1_addr,
                         d(71 downto 68) => dec_reg_2_addr,
                         d(72) => dec_reg_1_used,
                         d(73) => dec_reg_2_used,
                         
                         -- ===== CONTROL (EXECUTE) =====
                         d(77 downto 74) => dec_alu_op_sel,
                         
                         -- ===== PIPELINE REGISTER CONTROL =====
                         clk => clk,
                         reset => '0',
                         en => '1'
                         );

end structural;















