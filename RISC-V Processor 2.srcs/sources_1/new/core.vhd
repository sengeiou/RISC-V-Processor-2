library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity core is
    port(
        instruction_debug : in std_logic_vector(31 downto 0);
    
        clk_cpu : in std_logic;
        reset_cpu : in std_logic
    );
end core;

architecture structural of core is

begin
    core_pipeline : entity work.pipeline(structural)
                    port map(instruction_debug => instruction_debug,
                             clk => clk_cpu,
                             reset => reset_cpu);

end structural;
