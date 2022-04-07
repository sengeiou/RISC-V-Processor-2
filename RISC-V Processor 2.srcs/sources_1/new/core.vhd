library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_AXI.ALL;

entity core is
    port(
        from_master_1 : out ToMasterInterface; 
        to_master_1 : in FromMasterInterface; 
    
        clk : in std_logic;
        clk_dbg : in std_logic;
        reset : in std_logic
    );
end core;

architecture structural of core is
    signal uop : uop_type;
    signal instruction_ready : std_logic;
begin
    front_end : entity work.front_end(structural)
                port map(uop => uop,
                         instruction_ready => instruction_ready,
                         clk => clk,
                         reset => reset);

    execution_engine : entity work.execution_engine(structural)
                       port map(from_master_1 => from_master_1,
                                to_master_1 => to_master_1,
                                
                                decoded_instruction => uop,
                                instr_ready => instruction_ready,
                                clk => clk,
                                clk_dbg => clk_dbg,
                                reset => reset);

end structural;