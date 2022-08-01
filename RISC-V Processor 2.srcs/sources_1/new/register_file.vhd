--------------------------------
-- NOTES:
-- 1) Does this infer LUT-RAM?
--------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.pkg_cpu.all;

entity register_file is
    generic(
        REG_DATA_WIDTH_BITS : integer;                                                        -- Number of bits in the registers (XLEN)
        REGFILE_ENTRIES : integer                                                                -- Number of registers in the register file (2 ** REGFILE_SIZE)
    );
    port(
        -- Address busses
        rd_1_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        rd_2_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        rd_3_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        rd_4_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        wr_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        
        
        alloc_reg_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        alloc_reg_addr_v : in std_logic;
        
        reg_1_valid_bit_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        reg_2_valid_bit_addr : in std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0);
        reg_1_valid : out std_logic;
        reg_2_valid : out std_logic;
        -- Data busses
        rd_1_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        rd_2_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        rd_3_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        rd_4_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        wr_data : in std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        
        -- Control busses
    
        en : in std_logic;
        reset : in std_logic;                                                           -- Sets all registers to 0 when high (synchronous)
        clk : in std_logic;                                                             -- Clock signal input
        clk_dbg : in std_logic                                                           
    );
end register_file;

architecture rtl of register_file is
    -- ========== CONSTANTS ==========
    constant REG_ADDR_ZERO : std_logic_vector(integer(ceil(log2(real(REGFILE_ENTRIES)))) - 1 downto 0) := (others => '0'); 
    -- ===============================

    -- ========== RF REGISTERS ==========
    type reg_file_type is array (REGFILE_ENTRIES - 1 downto 0) of std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
    signal reg_file : reg_file_type;
    
    signal reg_file_valid_bits : std_logic_vector(REGFILE_ENTRIES - 1 downto 0);
    -- ==================================
    
begin
    -- Read from registers
    rd_1_data <= reg_file(to_integer(unsigned(rd_1_addr)));
    rd_2_data <= reg_file(to_integer(unsigned(rd_2_addr)));
    rd_3_data <= reg_file(to_integer(unsigned(rd_3_addr)));
    rd_4_data <= reg_file(to_integer(unsigned(rd_4_addr)));

    rf_access_proc : process(clk)
    begin
        -- Writing to registers
        if (rising_edge(clk)) then
            if (reset = '1') then
                reg_file <= (others => (others => '0'));
                reg_file_valid_bits <= (others => '1');
            else
                if (en = '1' and wr_addr /= REG_ADDR_ZERO) then                    
                    reg_file(to_integer(unsigned(wr_addr))) <= wr_data;
                    reg_file_valid_bits(to_integer(unsigned(wr_addr))) <= '1';
                end if;
                
                if (alloc_reg_addr_v = '1') then
                    reg_file_valid_bits(to_integer(unsigned(alloc_reg_addr))) <= '0';
                end if;
            end if;
        end if;
    end process;
    
    reg_1_valid <= reg_file_valid_bits(to_integer(unsigned(reg_1_valid_bit_addr)));
    reg_2_valid <= reg_file_valid_bits(to_integer(unsigned(reg_2_valid_bit_addr)));
end rtl;
