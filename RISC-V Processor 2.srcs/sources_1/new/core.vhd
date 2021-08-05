library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity core is
    port(
        clk_cpu : in std_logic;
        reset_cpu : in std_logic
    );
end core;

architecture structural of core is
    signal instruction_debug : std_logic_vector(31 downto 0);
    signal instruction_addr_debug : std_logic_vector(31 downto 0);
begin
    core_pipeline : entity work.pipeline(structural)
                    port map(instruction_debug => instruction_debug,
                             instruction_addr_debug => instruction_addr_debug,
                             clk => clk_cpu,
                             reset => reset_cpu);
                             
    rom : entity work.rom_memory(rtl)
          port map(data => instruction_debug,
                   addr => instruction_addr_debug(9 downto 2),
                   clk => clk_cpu);

end structural;
