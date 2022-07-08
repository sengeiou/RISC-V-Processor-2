library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.PKG_CPU.ALL;

entity front_end is
    port(
        uop : out uop_type;
        instruction_ready : out std_logic;
    
        reset : in std_logic;
        clk : in std_logic
    );
end front_end;

architecture Structural of front_end is


    signal fetched_instruction : std_logic_vector(31 downto 0);

    signal program_counter_reg : std_logic_vector(31 downto 0);
    signal program_counter_next : std_logic_vector(31 downto 0);
    
    signal rom_en : std_logic;
    signal resetn : std_logic;
begin
    resetn <= not reset;

    instruction_decoder : entity work.instruction_decoder(rtl)
                          port map(instruction => fetched_instruction,
                                   uop => uop,
                                   pc => program_counter_reg,
                                   
                                   instruction_ready => instruction_ready);

    program_memory_temp : entity work.rom_memory(rtl)
                          port map(addr => program_counter_reg(7 downto 0),
                                   data => fetched_instruction,
                                   en => rom_en,
                                   clk => clk);
                          
    rom_en <= '1' when program_counter_reg(31 downto 8) = X"000000" else '0';
                          
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
