library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

-- Potentially change it to a synchronous read

entity register_alias_table is
    generic(
        PHYS_REGFILE_ENTRIES : integer range 1 to 1024;
        ARCH_REGFILE_ENTRIES : integer range 1 to 1024;
        
        VALID_BIT_INIT_VAL : std_logic;
        ENABLE_VALID_BITS : boolean
    );
    port(
        cdb : in cdb_type;
        -- ========== READING PORTS ==========
        -- Inputs take the architectural register address for which we want the physical entry address
        arch_reg_addr_read_1 : in std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0);
        arch_reg_addr_read_2 : in std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0);
        
        -- Outputs give the physical entry address
        phys_reg_addr_read_1 : out std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        phys_reg_addr_read_1_v : out std_logic;
        phys_reg_addr_read_2 : out std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        phys_reg_addr_read_2_v : out std_logic;
        -- ===================================
        
        -- ========== WRITING PORTS ==========        
        arch_reg_addr_write_1 : in std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0); 
        phys_reg_addr_write_1 : in std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        -- ===================================
              
        -- ========== SPECULATION ==========
        next_instr_branch_mask : in std_logic_vector(BRANCHING_DEPTH - 1 downto 0);
        -- =================================
                
        -- Control signals
        
        clk : in std_logic;
        reset : in std_logic
    );
end register_alias_table;

architecture rtl of register_alias_table is
    constant PHYS_REGFILE_ADDR_BITS : integer := integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))); 
    constant ARCH_REGFILE_ADDR_BITS : integer := integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))); 

    constant ARCH_REGFILE_ADDR_ZERO : std_logic_vector(ARCH_REGFILE_ADDR_BITS - 1 downto 0) := (others => '0');
    constant PHYS_REGFILE_ADDR_ZERO : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0) := (others => '0');

    type rat_type is array (ARCH_REGFILE_ENTRIES - 1 downto 0) of std_logic_vector(PHYS_REGFILE_ADDR_BITS downto 0);
    constant RAT_TYPE_ZERO : rat_type := (others => (others => '0'));
    
    type rat_mispredict_recovery_memory_type is array (BRANCHING_DEPTH - 1 downto 0) of rat_type;

    signal rat : rat_type;
    signal rat_mispredict_recovery_memory : rat_mispredict_recovery_memory_type;
begin
    rat_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to ARCH_REGFILE_ENTRIES - 1 loop
                    rat(i) <= std_logic_vector(to_unsigned(i, PHYS_REGFILE_ADDR_BITS)) & VALID_BIT_INIT_VAL;
                end loop;
                
                for i in 0 to BRANCHING_DEPTH - 1 loop
                    rat_mispredict_recovery_memory(i) <= RAT_TYPE_ZERO;
                end loop;
            else
                if (arch_reg_addr_write_1 /= ARCH_REGFILE_ADDR_ZERO) then
                    rat(to_integer(unsigned(arch_reg_addr_write_1))) <= phys_reg_addr_write_1 & '0';
                end if;
                
                -- Questionable implementation of conditional generation
                if (ENABLE_VALID_BITS = true) then
                    for i in 0 to ARCH_REGFILE_ENTRIES - 1 loop
                        if (rat(i)(PHYS_REGFILE_ADDR_BITS downto 1) = cdb.phys_dest_reg and cdb.valid = '1') then
                            rat(i)(0) <= '1';
                        end if;
                    end loop;
                end if;
                
                -- Speculation
                if (cdb.branch_taken = '1' and cdb.valid = '1') then
                    rat <= rat_mispredict_recovery_memory(branch_mask_to_int(cdb.branch_mask));
                elsif (next_instr_branch_mask /= BRANCH_MASK_ZERO) then
                    rat_mispredict_recovery_memory(branch_mask_to_int(next_instr_branch_mask)) <= rat;
                end if;
            end if;
        end if;
    end process;
    
    phys_reg_addr_read_1 <= rat(to_integer(unsigned(arch_reg_addr_read_1)))(PHYS_REGFILE_ADDR_BITS downto 1);
    phys_reg_addr_read_2 <= rat(to_integer(unsigned(arch_reg_addr_read_2)))(PHYS_REGFILE_ADDR_BITS downto 1);
    
    phys_reg_addr_read_1_v <= rat(to_integer(unsigned(arch_reg_addr_read_1)))(0);
    phys_reg_addr_read_2_v <= rat(to_integer(unsigned(arch_reg_addr_read_2)))(0);
end rtl;
