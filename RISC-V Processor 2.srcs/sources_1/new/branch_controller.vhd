-- Holds calculated branch target addresses that the CPU will jump to in case the branch or jump is taken.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.PKG_CPU.ALL;

entity branch_controller is
    port(
        branch_target_addr : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        
        branch_mask : out std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        
        alloc_branch_tag : out std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        
        alloc_en : in std_logic;
        commit_en : in std_logic;
        
        reset : in std_logic;
        clk : in std_logic
    );
end branch_controller;

architecture rtl of branch_controller is
    constant BRANCH_TAG_START : integer := BRANCHING_DEPTH + CPU_ADDR_WIDTH_BITS - 1;
    constant BRANCH_TAG_END : integer := CPU_ADDR_WIDTH_BITS;
    constant BRANCH_TARGET_ADDRESS_START : integer := CPU_ADDR_WIDTH_BITS - 1;
    constant BRANCH_TARGET_ADDRESS_END : integer := 0;

    type cb_type is array (BRANCHING_DEPTH - 1 downto 0) of std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
    signal cb : cb_type;

    signal cb_full : std_logic;
    signal cb_empty : std_logic;
   
    signal entries_allocated : unsigned(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0);
   
    signal head_counter_reg : unsigned(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0); 
    signal tail_counter_reg : unsigned(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0);
    
    signal head_counter_next : unsigned(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0); 
    signal tail_counter_next : unsigned(integer(ceil(log2(real(BRANCHING_DEPTH)))) - 1 downto 0); 
begin
    buffer_cntr_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to BRANCHING_DEPTH - 1 loop
                    cb(i) <= std_logic_vector(to_unsigned(2 ** i, BRANCHING_DEPTH));
                end loop;
            
                entries_allocated <= (others => '0');
                tail_counter_reg <= (others => '0');
                head_counter_reg <= (others => '0');
            else                
                if (alloc_en = '1' and cb_empty = '0') then
                    tail_counter_reg <= tail_counter_next;
                    entries_allocated <= entries_allocated + 1;
                end if;
            
                if (commit_en = '1') then
                    head_counter_reg <= head_counter_next;
                    entries_allocated <= entries_allocated - 1;
                end if;
            end if;
        end if;
    end process;
    
    
    counters_next_proc : process(head_counter_reg, tail_counter_reg)
    begin
        if (head_counter_reg = BRANCHING_DEPTH - 1) then
            head_counter_next <= (others => '0');
        else
            head_counter_next <= head_counter_reg + 1;
        end if;
        
        if (tail_counter_reg = BRANCHING_DEPTH - 1) then
            tail_counter_next <= (others => '0');
        else
            tail_counter_next <= tail_counter_reg + 1;
        end if;
    end process;
    
    alloc_branch_tag <= cb(to_integer(tail_counter_reg));
    
    cb_empty <= '1' when entries_allocated = BRANCHING_DEPTH else '0';
end rtl;
