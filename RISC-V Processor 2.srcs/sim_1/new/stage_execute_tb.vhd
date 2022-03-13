library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity stage_execute_tb is

end stage_execute_tb;

architecture Behavioral of stage_execute_tb is
    signal clk, rst, instr_rdy : std_logic;
    
    signal opcode : std_logic_vector(7 downto 0);
    signal rs1, rs2, rd : std_logic_vector(4 downto 0);
    signal imm : std_logic_vector(31 downto 0);
    signal instr_in : std_logic_vector(54 downto 0);
    
    constant T : time := 20ns;
begin
    rst <= '1', '0' after T * 2;

    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    uut : entity work.execution_unit(structural)
          port map(decoded_instruction => instr_in,
                   instr_ready => instr_rdy,
                   clk => clk,
                   reset => rst);
    
    instr_in <= opcode & rs1 & rs2 & rd & imm;
    
    process
    begin
        opcode <= "00000000";
        rs1 <= "00001";
        rs2 <= "00001";
        imm <= X"0000_0000";
        rd <= "00011";
        instr_rdy <= '0';
        
        wait for T * 10;
        
        -- ADDI x1, x0, 1
        opcode <= "00010000";
        rs1 <= "00000";
        rs2 <= "00000";
        imm <= X"0000_0001";
        rd <= "00001";
        instr_rdy <= '1';
        
        wait for T;
        
        -- ADD x7, x1, x1
        opcode <= "00000000";
        rs1 <= "00001";
        rs2 <= "00001";
        imm <= X"0000_0000";
        rd <= "00111";
        instr_rdy <= '1';
        
        wait for T;
        
        -- ADDI x2, x0, 1
        opcode <= "00010000";
        rs1 <= "00000";
        rs2 <= "00000";
        imm <= X"0000_0001";
        rd <= "00010";
        instr_rdy <= '1';
        
        wait for T;
        
        -- ADD x5, x1, x2
        opcode <= "00000000";
        rs1 <= "00001";
        rs2 <= "00010";
        imm <= X"0000_0000";
        rd <= "00101";
        instr_rdy <= '1';
        
        wait for T;
        
        -- ADDI x6, x5, 127
        opcode <= "00010000";
        rs1 <= "00101";
        rs2 <= "00000";
        imm <= X"0000_007F";
        rd <= "00110";
        instr_rdy <= '1';
        
        wait for T;
        
        opcode <= "00000000";
        rs1 <= "00001";
        rs2 <= "00001";
        imm <= X"0000_0000";
        rd <= "00001";
        instr_rdy <= '0';
        
        wait for T * 1000;
    end process;

end Behavioral;
