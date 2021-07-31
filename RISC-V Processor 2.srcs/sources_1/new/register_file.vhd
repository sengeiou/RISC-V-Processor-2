--------------------------------
-- NOTES:
-- 1) Does this infer LUT-RAM?
--------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_cpu.all;

entity register_file is
    generic(
        REG_DATA_WIDTH_BITS : integer;                                                        -- Number of bits in the registers (XLEN)
        REGFILE_SIZE : integer                                                                -- Number of registers in the register file (2 ** REGFILE_SIZE)
    );
    port(
        -- Address busses
        rd_1_addr : in std_logic_vector(REGFILE_SIZE - 1 downto 0);
        rd_2_addr : in std_logic_vector(REGFILE_SIZE - 1 downto 0);                           -- Register selection address (read)
        wr_addr : in std_logic_vector(REGFILE_SIZE - 1 downto 0);                             -- Register selection address (write)
        
        -- Data busses
        wr_data : in std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);                      -- Data input port
        rd_1_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        rd_2_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);        -- Data output ports
        
        -- Control busses
        reset : in std_logic;                                                           -- Sets all registers to 0 when high (synchronous)
        clk : in std_logic;                                                             -- Clock signal input
        wr_en : in std_logic                                                            -- Write enable
    );
end register_file;

architecture rtl of register_file is
    type reg_file_type is array (2 ** REGFILE_SIZE - 1 downto 0) of std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
    
    signal reg_file : reg_file_type;
begin
    reg_file_access : process(all)
    begin
        -- Read from registers
        rd_1_data <= reg_file(to_integer(unsigned(rd_1_addr)));
        rd_2_data <= reg_file(to_integer(unsigned(rd_2_addr)));
         
        -- Writing to registers
        if (falling_edge(clk)) then
            if (reset = '1') then
                reg_file <= (others => (others => '0'));
            elsif (reset = '0' and wr_en = '1' and unsigned(wr_addr) /= 0) then
                reg_file(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
        end if;
    end process;
end rtl;
