library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- Potentially change it to a synchronous read

entity register_alias_table is
    generic(
        PHYS_REGFILE_ENTRIES : integer range 1 to 1024;
        ARCH_REGFILE_ENTRIES : integer range 1 to 1024
    );
    port(
        commited_dest_reg_arch_addr : in std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0);
        commited_dest_reg_phys_addr : in std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        commit_ready : in std_logic;
        
        freed_phys_reg_tag : out std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        tag_freed : out std_logic;
        -- ========== READING PORTS ==========
        -- Inputs take the architectural register address for which we want the physical entry address
        arch_reg_addr_read_1 : in std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0);
        arch_reg_addr_read_2 : in std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0);
        
        -- Outputs give the physical entry address
        phys_reg_addr_read_1 : out std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        phys_reg_addr_read_2 : out std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        -- ===================================
        
        -- ========== WRITING PORTS ==========
        arch_reg_addr_write_1 : in std_logic_vector(integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))) - 1 downto 0); 
        phys_reg_addr_write_1 : in std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        -- ===================================
                
        -- Control signals
        clk : in std_logic;
        reset : in std_logic
    );
end register_alias_table;

architecture rtl of register_alias_table is
    constant PHYS_REGFILE_ADDR_BITS : integer := integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))); 
    constant ARCH_REGFILE_ADDR_BITS : integer := integer(ceil(log2(real(ARCH_REGFILE_ENTRIES)))); 

    constant ARCH_REGFILE_ADDR_ZERO : std_logic_vector(ARCH_REGFILE_ADDR_BITS - 1 downto 0) := (others => '0');

    type rat_type is array (ARCH_REGFILE_ENTRIES - 1 downto 0) of std_logic_vector(PHYS_REGFILE_ADDR_BITS downto 0);
    signal rat : rat_type;
begin
    rat_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                rat <= (others => (others => '0'));
            else
                if (arch_reg_addr_write_1 /= ARCH_REGFILE_ADDR_ZERO) then
                    rat(to_integer(unsigned(arch_reg_addr_write_1))) <= phys_reg_addr_write_1 & '0';
                end if;
                
                if (commit_ready = '1') then
                    rat(to_integer(unsigned(commited_dest_reg_arch_addr))) <= commited_dest_reg_phys_addr & '1';
                end if;
            end if;
        end if;
    end process;
    
    freed_phys_reg_tag <= rat(to_integer(unsigned(commited_dest_reg_arch_addr)))(PHYS_REGFILE_ADDR_BITS downto 1);
    tag_freed <= commit_ready;
    
    phys_reg_addr_read_1 <= rat(to_integer(unsigned(arch_reg_addr_read_1)))(PHYS_REGFILE_ADDR_BITS downto 1);
    phys_reg_addr_read_2 <= rat(to_integer(unsigned(arch_reg_addr_read_2)))(PHYS_REGFILE_ADDR_BITS downto 1);
end rtl;
