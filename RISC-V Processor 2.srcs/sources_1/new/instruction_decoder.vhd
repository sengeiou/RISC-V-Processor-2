----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/19/2021 02:20:42 PM
-- Design Name: 
-- Module Name: instruction_decoder - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.1.0 - Added support for Reg-Reg ALU instructions
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity instruction_decoder is
    port(
        -- ========== INSTRUCTION INPUT ==========
        instruction_bus : in std_logic_vector(31 downto 0);
        
        -- ========== GENERATED CONTROL SIGNALS ==========
        -- ALU
        alu_op_sel : out std_logic_vector(3 downto 0);
        
        -- Immediates
        immediate_data : out std_logic_vector(31 downto 0);
        
        immediate_used : out std_logic;
        
        -- Register control
        reg_rd_1_addr : out std_logic_vector(4 downto 0);
        reg_rd_2_addr : out std_logic_vector(4 downto 0);
        reg_wr_addr : out std_logic_vector(4 downto 0);
        
        reg_rd_1_used : out std_logic;
        reg_rd_2_used : out std_logic;
        reg_wr_en : out std_logic
    );
end instruction_decoder;

architecture rtl of instruction_decoder is

begin

    decoder : process(all)
    begin
    -- Default values for signals in case the instruction does not set them
    alu_op_sel <= "0000";
    
    reg_rd_1_used <= '0';
    reg_rd_2_used <= '0';
    reg_wr_en <= '0';
    immediate_used <= '0';
    
    -- Always decode register addresses
    reg_rd_1_addr <= instruction_bus(19 downto 15);
    reg_rd_2_addr <= instruction_bus(24 downto 20);
    reg_wr_addr <= instruction_bus(11 downto 7);
    
    if (instruction_bus(6 downto 0) = "0110011") then                       -- Reg-Reg ALU Operations
        alu_op_sel <= instruction_bus(30) & instruction_bus(14 downto 12);
        
        reg_rd_1_used <= '1';
        reg_rd_2_used <= '1';
        reg_wr_en <= '1';
    elsif (instruction_bus(6 downto 0) = "0010011") then
        alu_op_sel <= '0' & instruction_bus(14 downto 12);
        
        reg_rd_1_used <= '1';
        reg_wr_en <= '1';
        immediate_used <= '1';
        
        -- Immediate decoding
        immediate_data(11 downto 0) <= instruction_bus(31 downto 20);
        immediate_data(31 downto 12) <= (others => instruction_bus(31));
    end if;
    end process;
    
end rtl;
















