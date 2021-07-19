----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/19/2021 12:29:42 PM
-- Design Name: 
-- Module Name: stage_decode - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- 0.01 - File Created
-- 0.1.0 - Added and connected instruction decoder and register file for basic functionality
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity stage_decode is
    generic(
        CPU_DATA_WIDTH_BITS : integer
    );
    
    port(
        -- ========== OUTPUT DATA SIGNALS ==========
        reg_1_data : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        reg_2_data : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    
        -- ========== INPUT CONTROL SIGNALS ==========
        instruction_bus : in std_logic_vector(31 downto 0);
        
        clk : in std_logic;
        reset : in std_logic;
        
        -- ========== OUTPUT CONTROL SIGNALS ==========
        reg_1_addr : out std_logic_vector(4 downto 0);
        reg_2_addr : out std_logic_vector(4 downto 0);
        reg_wr_addr : out std_logic_vector(4 downto 0);
        reg_1_used : out std_logic;
        reg_2_used : out std_logic;
        reg_wr_en : out std_logic;
        
        alu_op_sel : out std_logic_vector(3 downto 0)
    );
end stage_decode;

architecture structural of stage_decode is
    signal reg_1_addr_i : std_logic_vector(4 downto 0);
    signal reg_2_addr_i : std_logic_vector(4 downto 0);
    
    signal reg_1_used_i : std_logic;
    signal reg_2_used_i : std_logic;
begin
    instruction_decoder : entity work.instruction_decoder(rtl)
                          port map(instruction_bus => instruction_bus,
                                   reg_rd_1_addr => reg_1_addr_i,
                                   reg_rd_2_addr => reg_2_addr_i,
                                   reg_wr_addr => reg_wr_addr,
                                   reg_rd_1_used => reg_1_used,
                                   reg_rd_2_used => reg_2_used,
                                   -- ===== ALU =====
                                   alu_op_sel => alu_op_sel);
    
    register_file : entity work.register_file(rtl)
                    generic map(REG_SIZE_BITS => CPU_DATA_WIDTH_BITS)
                    port map(-- ADDRESSES
                             rd_1_addr => reg_1_addr_i,
                             rd_2_addr => reg_2_addr_i,
                             wr_addr => (others => '0'),
                             
                             -- DATA
                             wr_data => (others => '0'),
                             rd_1_data => reg_1_data,
                             rd_2_data => reg_2_data,
                             
                             -- CONTROL
                             wr_en => '0',
                             reset => reset,
                             clk => clk);
    
    reg_1_addr <= reg_1_addr_i;
    reg_2_addr <= reg_2_addr_i;
    
end structural;












