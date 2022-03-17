library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.PKG_CPU.ALL;

entity front_end is
    port(
        decoded_instruction : out decoded_instruction_type;
        instruction_ready : out std_logic;
    
        reset : in std_logic;
        clk : in std_logic
    );
end front_end;

architecture Structural of front_end is
    signal fetched_instruction : std_logic_vector(31 downto 0);

    signal program_counter_reg : std_logic_vector(15 downto 0);
    signal program_counter_next : std_logic_vector(15 downto 0);
begin
    instruction_decoder : entity work.instruction_decoder(rtl)
                          port map(instruction => fetched_instruction,
                                   decoded_instruction => decoded_instruction,
                                   instruction_ready => instruction_ready);

    program_memory_temp : entity work.rom_memory(rtl)
                          port map(addr => program_counter_reg(7 downto 0),
                                   data => fetched_instruction,
                                   clk => clk);
                          
    pc_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                program_counter_reg <= (others => '0');
            else
                program_counter_reg <= std_logic_vector(unsigned(program_counter_next) + 4);
            end if;
        end if;
    end process;
    
    program_counter_next <= program_counter_reg;

end Structural;