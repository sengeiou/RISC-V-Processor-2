library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cpu_tb is

end cpu_tb;

architecture Behavioral of cpu_tb is
    signal clk, reset : std_logic;
    
    constant T : time := 20ns;
begin
    cpu : entity work.cpu(structural)
          port map(clk_cpu => clk,
                   clk_dbg => '0',
                   reset_cpu => reset);

    reset <= '1', '0' after T * 2;

    clock : process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;

    tb : process
    begin
        wait for T * 500;
        
        --report "Simulation Finished." severity FAILURE;
    end process;

end Behavioral;
