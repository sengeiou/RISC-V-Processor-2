library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pipeline_tb is
end pipeline_tb;

architecture Behavioral of pipeline_tb is
    signal instruction_bus : std_logic_vector(31 downto 0);
    signal reset, clk : std_logic;
    
    
    type test_instructions_array is array (natural range <>) of std_logic_vector(31 downto 0);
    constant test_instructions : test_instructions_array := (
        ("00000000000100001000000010110011"),         -- ADD x1, x1, x1
        ("00000000000100001000000010110011")         -- ADD x1, x1, x1
        
    );
    
    constant T : time := 20ns;
begin
    pipeline : entity work.pipeline(structural)
               port map(instruction_debug => instruction_bus,
                        reset => reset,
                        clk => clk);

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
        wait for T * 2;
        for i in test_instructions'range loop
            instruction_bus <= test_instructions(i);
        
            wait for T;
        
        end loop;
    end process;

end Behavioral;
