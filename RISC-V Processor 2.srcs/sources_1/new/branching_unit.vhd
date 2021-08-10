library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pkg_cpu.all;

entity branching_unit is
    port(
        -- Target address generation data
        pc : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        immediate : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        
        -- Control signals
--        alu_eq : in std_logic;
--        alu_lt : in std_logic;
--        alu_ltu : in std_logic;
        
        prog_flow_cntrl : in std_logic_vector(2 downto 0);
        
        branch_target_addr : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        branch_taken : out std_logic
    );
end branching_unit;

architecture rtl of branching_unit is
    signal base_addr_i : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);

    signal base_addr_sel_i : std_logic_vector(1 downto 0);
begin
    base_addr_mux : entity work.mux_4_1(rtl)
                    generic map(WIDTH_BITS => 32)
                    port map(in_0 => pc,
                             in_1 => (others => '0'),
                             in_2 => (others => '0'),
                             in_3 => (others => '0'),
                             output => base_addr_i,
                             sel => base_addr_sel_i);
                             
    base_addr_sel_i <= "00";
    
    branch_taken <= (not prog_flow_cntrl(2) and not prog_flow_cntrl(1) and prog_flow_cntrl(0));
    
    branch_target_addr <= std_logic_vector(signed(base_addr_i) + signed(immediate));

end rtl;
