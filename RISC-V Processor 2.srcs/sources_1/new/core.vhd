library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_AXI.ALL;

entity core is
    port(
        -- TEMPORARY BUS STUFF
        bus_addr_read : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        bus_addr_write : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        bus_data_read : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        bus_data_write : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        bus_stbr : out std_logic;
        bus_stbw : out std_logic;
        bus_ackr : in std_logic;
        bus_ackw : in std_logic;
    
        clk : in std_logic;
        clk_dbg : in std_logic;
        reset : in std_logic
    );
end core;

architecture structural of core is
    signal uop : uop_type;
    signal instruction_ready : std_logic;
    
    signal branch_taken : std_logic;
    signal branch_target_pc : std_logic_vector(31 downto 0);
begin
    front_end : entity work.front_end(structural)
                port map(uop => uop,
                         instruction_ready => instruction_ready,
                         
                         branch_taken => branch_taken,
                         branch_target_pc => branch_target_pc,
                         
                         clk => clk,
                         reset => reset);

    execution_engine : entity work.execution_engine(structural)
                       port map(bus_addr_read => bus_addr_read,
                                bus_addr_write => bus_addr_write,
                                bus_data_read => bus_data_read,
                                bus_data_write => bus_data_write,
                                bus_stbr => bus_stbr,
                                bus_stbw => bus_stbw,
                                bus_ackr => bus_ackr,
                                bus_ackw => bus_ackw,
                                
                                branch_taken => branch_taken,
                                branch_target_pc => branch_target_pc,
                                
                                decoded_instruction => uop,
                                instr_ready => instruction_ready,
                                clk => clk,
                                clk_dbg => clk_dbg,
                                reset => reset);

end structural;