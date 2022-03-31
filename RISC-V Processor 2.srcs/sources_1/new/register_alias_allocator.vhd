library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- This module implements a stack which holds all unallocated aliases for register renaming.

entity register_alias_allocator is
    generic(
        PHYS_REGFILE_ENTRIES : integer range 1 to 1024;
        ARCH_REGFILE_ENTRIES : integer range 1 to 1024
    );
    port(
        put_reg_alias : in std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        get_reg_alias : out std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        
        put_en : in std_logic;
        get_en : in std_logic;
        
        empty : out std_logic;
        clk : in std_logic;
        reset : in std_logic
    );
end register_alias_allocator;

architecture rtl of register_alias_allocator is
    constant PHYS_REGFILE_ADDR_BITS : integer := integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))); 
    constant ARCH_REGFILE_ADDR_BITS : integer := integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))); 
    constant ALLOCATOR_STACK_SIZE : integer := PHYS_REGFILE_ENTRIES - ARCH_REGFILE_ENTRIES;
    constant ALLOCATOR_STACK_ADDR_BITS : integer := integer(ceil(log2(real(ALLOCATOR_STACK_SIZE))));

    constant HEAD_COUNTER_MAXVAL : unsigned(ALLOCATOR_STACK_ADDR_BITS - 1 downto 0) := to_unsigned(ALLOCATOR_STACK_SIZE - 1, ALLOCATOR_STACK_ADDR_BITS);
    constant HEAD_COUNTER_ZERO : unsigned(ALLOCATOR_STACK_ADDR_BITS - 1 downto 0) := (others => '0');

    -- Contains tags of registers that are free to be allocated. Note that only physical registers that do not correspond
    -- to architectural registers can be allocated which means that 32 registers in the physical register file will always
    -- not be able to be allocated
    type raa_stack_type is array (ALLOCATOR_STACK_SIZE - 1 downto 0) of std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    signal raa_stack : raa_stack_type;
    
    signal head_counter_reg : unsigned(ALLOCATOR_STACK_ADDR_BITS - 1 downto 0);
    
    signal raa_full : std_logic;
    signal raa_empty : std_logic;
begin
    raa_stack_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to ALLOCATOR_STACK_SIZE - 1 loop
                    -- We start making physical registers with tags > 32 allocable since the first 32 registers will 
                    -- always start out as architectural registers (unable to be allocated)
                    raa_stack(i) <= std_logic_vector(to_unsigned(i + ARCH_REGFILE_ENTRIES, PHYS_REGFILE_ADDR_BITS));
                end loop;
            elsif (put_en = '1') then
                raa_stack(to_integer(head_counter_reg)) <= put_reg_alias;
            end if;
        end if;
    end process;
    
    head_counter_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                head_counter_reg <= HEAD_COUNTER_MAXVAL;
            elsif (raa_empty = '0') then
                if (get_en = '1' and put_en = '1') then
                    head_counter_reg <= head_counter_reg;
                elsif (get_en = '1') then
                    head_counter_reg <= head_counter_reg - 1;
                elsif (put_en = '1') then
                    head_counter_reg <= head_counter_reg + 1;
                end if;
            end if;
        end if;
    end process;
    
    get_reg_alias <= raa_stack(to_integer(head_counter_reg));

    raa_full <= '1' when head_counter_reg = HEAD_COUNTER_MAXVAL else '0';
    raa_empty <= '1' when head_counter_reg = HEAD_COUNTER_ZERO else '0';
    
    empty <= raa_empty;

end rtl;
