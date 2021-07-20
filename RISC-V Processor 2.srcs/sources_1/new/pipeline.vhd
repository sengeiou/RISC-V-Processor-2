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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pipeline is
    port(
        instruction_debug : in std_logic_vector(31 downto 0);
    
        clk : in std_logic;
        reset : in std_logic
    );
end pipeline;

architecture structural of pipeline is
-- ========== DECODE STAGE SIGNALS ==========
signal dec_reg_1_data : std_logic_vector(31 downto 0);
signal dec_reg_2_data : std_logic_vector(31 downto 0);

signal dec_reg_1_addr : std_logic_vector(4 downto 0); 
signal dec_reg_2_addr : std_logic_vector(4 downto 0);
signal dec_reg_1_used : std_logic;
signal dec_reg_2_used : std_logic;
signal dec_reg_wr_addr : std_logic_vector(4 downto 0);
signal dec_reg_wr_en : std_logic;

signal dec_alu_op_sel : std_logic_vector(3 downto 0);

-- ========== EXECUTE STAGE SIGNALS ==========
signal exe_reg_1_data : std_logic_vector(31 downto 0);
signal exe_reg_2_data : std_logic_vector(31 downto 0);
signal exe_alu_result : std_logic_vector(31 downto 0);

signal exe_alu_op_sel : std_logic_vector(3 downto 0);

signal exe_reg_1_addr : std_logic_vector(4 downto 0);
signal exe_reg_2_addr : std_logic_vector(4 downto 0);
signal exe_reg_1_used : std_logic;
signal exe_reg_2_used : std_logic;

signal exe_reg_wr_addr : std_logic_vector(4 downto 0);
signal exe_reg_wr_en : std_logic;

-- ========== MEMORY STAGE SIGNALS ==========
signal mem_data_in : std_logic_vector(31 downto 0);
signal mem_data_out : std_logic_vector(31 downto 0);

signal mem_reg_wr_addr : std_logic_vector(4 downto 0);
signal mem_reg_wr_en : std_logic;

-- ========== WRITEBACK STAGE SIGNALS ==========
signal wb_reg_wr_data : std_logic_vector(31 downto 0);

signal wb_reg_wr_addr : std_logic_vector(4 downto 0);
signal wb_reg_wr_en : std_logic;

begin
    -- ========== STAGES ==========
    stage_decode : entity work.stage_decode(structural)
                   generic map(CPU_DATA_WIDTH_BITS => 32)
                   port map(-- DATA SIGNALS
                            instruction_bus => instruction_debug,
                            reg_1_data => dec_reg_1_data,
                            reg_2_data => dec_reg_2_data,
                            
                            reg_wr_data => wb_reg_wr_data,
                            
                            -- CONTROL SIGNALS
                            reg_1_addr => dec_reg_1_addr,
                            reg_2_addr => dec_reg_2_addr,
                            reg_1_used => dec_reg_1_used,
                            reg_2_used => dec_reg_2_used,
                            alu_op_sel => dec_alu_op_sel,
                            
                            reg_wr_addr => dec_reg_wr_addr,
                            reg_wr_en => dec_reg_wr_en,
                            
                            reg_wr_addr_in => wb_reg_wr_addr,
                            reg_wr_en_in => wb_reg_wr_en,
                            
                            reset => reset,
                            clk => clk
                            );
                            
    stage_execute : entity work.stage_execute(structural)
                    generic map(CPU_DATA_WIDTH_BITS => 32)
                    port map(-- DATA SIGNALS
                             reg_1_data => exe_reg_1_data,
                             reg_2_data => exe_reg_2_data,
                             alu_result => exe_alu_result,
                                
                             -- CONTROL SIGNALS
                             alu_op_sel => exe_alu_op_sel
                             );
                             
    stage_memory : entity work.stage_memory(structural)
                   port map(data_in => mem_data_in,
                            data_out => mem_data_out);

    -- ========== PIPELINE REGISTERS ==========
    reg_de_ex : entity work.register_var(rtl)
                generic map(WIDTH_BITS => 86)
                port map(-- ===== DATA =====
                         d(31 downto 0) => dec_reg_1_data,
                         d(63 downto 32) => dec_reg_2_data,
                         
                         -- ===== CONTROL (REGISTERS) =====
                         d(68 downto 64) => dec_reg_1_addr,
                         d(73 downto 69) => dec_reg_2_addr,
                         d(74) => dec_reg_1_used,
                         d(75) => dec_reg_2_used,
                         
                         -- ===== CONTROL (EXECUTE) =====
                         d(79 downto 76) => dec_alu_op_sel,
                         
                         -- ===== CONTROL (WRITEBACK) =====
                         d(84 downto 80) => dec_reg_wr_addr,
                         d(85) => dec_reg_wr_en, 
                         
                         -- =================================================================
                         
                         -- ===== DATA =====
                         q(31 downto 0) => exe_reg_1_data,
                         q(63 downto 32) => exe_reg_2_data,
                         
                         -- ===== CONTROL (REGISTERS) =====
                         q(68 downto 64) => exe_reg_1_addr,
                         q(73 downto 69) => exe_reg_2_addr,
                         q(74) => exe_reg_1_used,
                         q(75) => exe_reg_2_used, 
                         
                         -- ===== CONTROL (EXECUTE) =====
                         q(79 downto 76) => exe_alu_op_sel,
                         
                         -- ===== CONTROL (WRITEBACK) =====
                         q(84 downto 80) => exe_reg_wr_addr,
                         q(85) => exe_reg_wr_en,
                         
                         -- ===== PIPELINE REGISTER CONTROL =====
                         clk => clk,
                         reset => reset,
                         en => '1'
                         );
                         
    reg_ex_mem : entity work.register_var(rtl)
                 generic map(WIDTH_BITS => 38)
                 port map(-- ===== DATA =====
                          d(31 downto 0) => exe_alu_result,
                          
                          -- ===== CONTROL (WRITEBACK) =====
                          d(36 downto 32) => exe_reg_wr_addr,
                          d(37) => exe_reg_wr_en,
                          
                          -- =================================================================
                          
                          -- ===== DATA =====
                          q(31 downto 0) => mem_data_in,
                          
                          -- ===== CONTROL (WRITEBACK) =====
                          q(36 downto 32) => mem_reg_wr_addr,
                          q(37) => mem_reg_wr_en,
                          
                          -- ===== PIPELINE REGISTER CONTROL =====
                          clk => clk,
                          reset => reset,
                          en => '1'
                 );

    reg_mem_wb : entity work.register_var(rtl)
                 generic map(WIDTH_BITS => 38)
                 port map(-- ===== DATA =====
                          d(31 downto 0) => mem_data_out,
                          
                          -- ===== CONTROL (WRITEBACK) =====
                          d(36 downto 32) => mem_reg_wr_addr,
                          d(37) => mem_reg_wr_en,
                          
                          -- =================================================================
                          
                          -- ===== DATA =====
                          q(31 downto 0) => wb_reg_wr_data,
                          
                          -- ===== CONTROL (WRITEBACK) =====
                          q(36 downto 32) => wb_reg_wr_addr,
                          q(37) => wb_reg_wr_en,
                          
                          -- ===== PIPELINE REGISTER CONTROL =====
                          clk => clk,
                          reset => reset,
                          en => '1'
                 );

end structural;















