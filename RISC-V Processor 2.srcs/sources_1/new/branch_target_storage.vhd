-- Holds calculated branch target addresses that the CPU will jump to in case the branch or jump is taken.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.PKG_CPU.ALL;

entity branch_target_storage is
    port(
        branch_target_addr : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        
        speculation_tag : out std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        alloc_branch_tag : out std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        alloc_en : in std_logic;
        
        reset : in std_logic;
        clk : in std_logic
    );
end branch_target_storage;

architecture rtl of branch_target_storage is
    constant BRANCH_TAG_START : integer := BRANCHING_DEPTH + CPU_ADDR_WIDTH_BITS - 1;
    constant BRANCH_TAG_END : integer := CPU_ADDR_WIDTH_BITS;
    constant BRANCH_TARGET_ADDRESS_START : integer := CPU_ADDR_WIDTH_BITS - 1;
    constant BRANCH_TARGET_ADDRESS_END : integer := 0;

    type branch_table_type is array (BRANCHING_DEPTH - 1 downto 0) of std_logic_vector(BRANCHING_DEPTH + CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal branch_table : branch_table_type;
   
    signal i_alloc_branch_tag : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    signal free_bits : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    signal selected_entry_num : std_logic_vector(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0);
    signal selected_entry_valid : std_logic;
begin
    prio_enc : entity work.priority_encoder(rtl)
               generic map(HIGHER_INPUT_HIGHER_PRIO => false,
                           NUM_INPUTS => BRANCHING_DEPTH)
               port map(d => free_bits,
                        q => selected_entry_num,
                        valid => selected_entry_valid);

    process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to BRANCHING_DEPTH - 1 loop
                    branch_table(i)(BRANCH_TAG_START downto BRANCH_TAG_END) <= std_logic_vector(to_unsigned(2 ** i, BRANCHING_DEPTH));
                    branch_table(i)(BRANCH_TARGET_ADDRESS_START - 1 downto BRANCH_TARGET_ADDRESS_END) <= (others => '0');
                    free_bits <= (others => '1');
                end loop;
            elsif (alloc_en = '1' and selected_entry_valid = '1') then
                free_bits(to_integer(unsigned(selected_entry_num))) <= '0';
            end if;
        end if;
    end process;
    
    alloc_branch_tag <= branch_table(to_integer(unsigned(selected_entry_num)))(BRANCH_TAG_START downto BRANCH_TAG_END);
    speculation_tag <= not free_bits;

end rtl;
