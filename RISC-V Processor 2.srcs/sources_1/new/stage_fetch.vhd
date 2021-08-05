library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_cpu.all;

entity stage_fetch is
    port(
        instruction_addr : out std_logic_vector(31 downto 0);
        
        clk : in std_logic;
        reset : in std_logic
    );
end stage_fetch;

architecture rtl of stage_fetch is
    signal program_counter_reg : unsigned(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal program_counter_next : unsigned(CPU_ADDR_WIDTH_BITS - 1 downto 0);
begin
    pc_update_process : process(clk, reset)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                program_counter_reg <= (others => '0');
            else
                program_counter_reg <= program_counter_next;
            end if;
        end if;
    end process;
    
    program_counter_next <= program_counter_reg + 4;
    
    instruction_addr <= std_logic_vector(program_counter_reg);

end rtl;
