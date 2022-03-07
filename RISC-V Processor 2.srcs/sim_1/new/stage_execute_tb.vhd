library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity stage_execute_tb is

end stage_execute_tb;

architecture Behavioral of stage_execute_tb is
    signal clk, rst, instr_rdy : std_logic;
    
    signal instr_in : std_logic_vector(53 downto 0);
    
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
    
    uut : entity work.execution_unit(rtl)
          port map(decoded_instruction => instr_in,
                   instr_ready => instr_rdy,
                   clk => clk,
                   reset => rst);
    
    process
    begin
        instr_in <= (others => '0');
        instr_rdy <= '0';
        
        wait for T * 10;
        
        instr_in <= (others => '1');
        instr_rdy <= '1';
        
        wait for T * 3;
        
        instr_in <= (others => '0');
        instr_rdy <= '0';
        
        wait for T * 1000;
    end process;

end Behavioral;
