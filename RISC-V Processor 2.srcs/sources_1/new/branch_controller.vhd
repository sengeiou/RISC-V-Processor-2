-- Holds calculated branch target addresses that the CPU will jump to in case the branch or jump is taken.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.PKG_CPU.ALL;

entity branch_controller is
    port(
        cdb : in cdb_type; 
   
        outstanding_branches_mask : out std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        alloc_branch_mask : out std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        
        branch_alloc_en : in std_logic;
        
        empty : out std_logic;
        
        reset : in std_logic;
        clk : in std_logic
    );
end branch_controller;

architecture rtl of branch_controller is
    -- [BRANCH MASK | BUSY]
    type bc_masks_type is array (BRANCHING_DEPTH - 1 downto 0) of std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    type bc_dependent_masks_type is array (BRANCHING_DEPTH - 1 downto 0) of std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    
    signal bc_masks : bc_masks_type;
    signal bc_dependent_masks : bc_dependent_masks_type;
    signal bc_available_bits : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    
    -- Contains a 1 at every bit that has been allocated and not yet deallocated
    signal outstanding_branches_mask_i : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    
    signal allocated_mask_index : std_logic_vector(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0);
    signal bc_empty_i : std_logic;
begin
    empty <= not bc_empty_i;

    free_mask_select_index : entity work.priority_encoder(rtl)
                         generic map(NUM_INPUTS => BRANCHING_DEPTH,
                                     HIGHER_INPUT_HIGHER_PRIO => false)
                         port map(d => bc_available_bits,
                                  q => allocated_mask_index,
                                  valid => bc_empty_i);

    bc_table_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to BRANCHING_DEPTH - 1 loop
                    bc_masks(i)(BRANCHING_DEPTH - 1 downto 0) <= std_logic_vector(to_unsigned(2 ** i, BRANCHING_DEPTH));
                end loop;
                outstanding_branches_mask_i <= (others => '0');
                bc_dependent_masks <= (others => (others => '0'));
                bc_available_bits <= (others => '1');
            else
                if (branch_alloc_en = '1') then
                    bc_available_bits(to_integer(unsigned(allocated_mask_index))) <= '0';
                    bc_dependent_masks(to_integer(unsigned(allocated_mask_index))) <= outstanding_branches_mask_i or alloc_branch_mask;
                    outstanding_branches_mask_i <= outstanding_branches_mask_i or alloc_branch_mask;
                end if;
                
                if (cdb.branch_mask /= BRANCH_MASK_ZERO and cdb.branch_taken = '0' and cdb.valid = '1') then        -- CORRECTLY PREDICTED
                    bc_available_bits(branch_mask_to_int(cdb.branch_mask)) <= '1';
                    outstanding_branches_mask_i <= outstanding_branches_mask_i and not cdb.branch_mask;
                elsif (cdb.branch_taken = '1' and cdb.valid = '1') then                                             -- MISPREDICT! CLEAR ALL ENTRIES ALLOCATED TO BRANCHES AFTER THE MISPREDICTED ONE
                    outstanding_branches_mask_i <= bc_dependent_masks(branch_mask_to_int(cdb.branch_mask)) and not cdb.branch_mask;
                    for i in 0 to BRANCHING_DEPTH - 1 loop
                        if ((cdb.branch_mask and bc_dependent_masks(i)) /= BRANCH_MASK_ZERO) then
                            bc_available_bits(i) <= '1';
                        end if;
                    end loop; 
                end if;
            end if;
        end if;
    end process;
    
    outstanding_branches_mask <= outstanding_branches_mask_i;
    alloc_branch_mask <= bc_masks(to_integer(unsigned(allocated_mask_index))) when branch_alloc_en = '1' else (others => '0');
end rtl;
