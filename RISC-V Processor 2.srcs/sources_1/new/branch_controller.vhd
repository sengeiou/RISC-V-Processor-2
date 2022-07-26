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
        branch_commit_en : in std_logic;
        
        empty : out std_logic;
        
        reset : in std_logic;
        clk : in std_logic
    );
end branch_controller;

architecture rtl of branch_controller is
    constant BRANCH_MASK_START : integer := BRANCHING_DEPTH - 1;
    constant BRANCH_MASK_END : integer := 0;

    type cb_type is array (BRANCHING_DEPTH downto 0) of std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    signal cb : cb_type;
    
    type branch_controller_mispredict_recovery_memory_type is array(BRANCHING_DEPTH downto 0) of unsigned(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0);
    signal branch_controller_mispredict_recovery_memory : branch_controller_mispredict_recovery_memory_type;

    signal outstanding_branches_mask_i : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    signal alloc_branch_mask_i : std_logic_vector(BRANCHING_DEPTH - 1 downto 0);

    signal cb_full : std_logic;
    signal cb_empty : std_logic;

    signal head_counter_reg : unsigned(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0); 
    signal tail_counter_reg : unsigned(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0);
    
    signal head_counter_next : unsigned(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0); 
    signal tail_counter_next : unsigned(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0); 
    
    constant COUNTERS_ONE : unsigned(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0) := to_unsigned(1, integer(ceil(log2(real(BRANCHING_DEPTH)))));
begin
    buffer_cntr_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to BRANCHING_DEPTH - 1 loop
                    cb(i)(BRANCH_MASK_START downto BRANCH_MASK_END) <= std_logic_vector(to_unsigned(2 ** i, BRANCHING_DEPTH));
                end loop;
                tail_counter_reg <= (others => '0');
                head_counter_reg <= (others => '0');
            else                            
                if (branch_alloc_en = '1' and cb_empty = '0' and cdb.branch_taken = '0') then
                    tail_counter_reg <= tail_counter_next;
                    
                    branch_controller_mispredict_recovery_memory(branch_mask_to_int(alloc_branch_mask_i)) <= tail_counter_reg;
                end if;
            
                if (branch_commit_en = '1') then
                    head_counter_reg <= head_counter_next;
                end if;
            end if;
        end if;
    end process;
    
    
    counters_next_proc : process(head_counter_reg, tail_counter_reg, cdb)
    begin
        if (head_counter_reg = BRANCHING_DEPTH) then
            head_counter_next <= COUNTERS_ONE;
        else
            head_counter_next <= head_counter_reg + 1;
        end if;
        
        if (cdb.branch_taken = '1') then
            tail_counter_next <= branch_controller_mispredict_recovery_memory(branch_mask_to_int(cdb.branch_mask));
        elsif (tail_counter_reg = BRANCHING_DEPTH) then
            tail_counter_next <= COUNTERS_ONE;
        else
            tail_counter_next <= tail_counter_reg + 1;
        end if;
    end process;
    
    outstanding_branches_mask_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                outstanding_branches_mask_i <= (others => '0');
            elsif (branch_alloc_en = '1') then
                outstanding_branches_mask_i <= outstanding_branches_mask_i or alloc_branch_mask_i;
            end if;
        end if;
    end process;
    
    alloc_branch_mask_i <= cb(to_integer(tail_counter_reg));
    alloc_branch_mask <= alloc_branch_mask_i when branch_alloc_en = '1' else (others => '0');
    
    outstanding_branches_mask <= outstanding_branches_mask_i;
    
    cb_full <= '1' when head_counter_reg = tail_counter_reg else '0';
    cb_empty <= '1' when tail_counter_next = head_counter_reg else '0';
    empty <= cb_empty;
end rtl;
