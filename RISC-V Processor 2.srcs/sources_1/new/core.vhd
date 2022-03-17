library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.PKG_CPU.ALL;
use WORK.AXI_INTERFACE_SIGNAL_GROUPS.ALL;

entity core is
    port(
        from_master_1 : out FromMaster; 
        to_master_1 : in ToMaster; 
    
        clk : in std_logic;
        reset : in std_logic
    );
end core;

architecture structural of core is
    signal decoded_instruction : decoded_instruction_type;
    signal instruction_ready : std_logic;
begin
    front_end : entity work.front_end(structural)
                port map(decoded_instruction => decoded_instruction,
                         instruction_ready => instruction_ready,
                         clk => clk,
                         reset => reset);

    execution_engine : entity work.execution_engine(structural)
                       port map(from_master_1 => from_master_1,
                                to_master_1 => to_master_1,
                                
                                decoded_instruction => decoded_instruction,
                                instr_ready => instruction_ready,
                                clk => clk,
                                reset => reset);

end structural;