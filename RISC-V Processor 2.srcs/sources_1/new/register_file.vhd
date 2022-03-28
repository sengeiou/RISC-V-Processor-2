--------------------------------
-- NOTES:
-- 1) Does this infer LUT-RAM?
--------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

use work.pkg_cpu.all;

entity register_file is
    generic(
        REORDER_BUFFER_TAG_BITS : integer;                                              -- Number of entries in the associated reservation station
        REG_DATA_WIDTH_BITS : integer;                                                        -- Number of bits in the registers (XLEN)
        REGFILE_SIZE : integer                                                                -- Number of registers in the register file (2 ** REGFILE_SIZE)
    );
    port(
        -- Address busses
        rd_1_addr : in std_logic_vector(REGFILE_SIZE - 1 downto 0);
        rd_2_addr : in std_logic_vector(REGFILE_SIZE - 1 downto 0);                           -- Register selection address (read)
        wr_addr : in std_logic_vector(REGFILE_SIZE - 1 downto 0);
        
        -- Data busses
        rd_1_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
        rd_2_data : out std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);             -- Data output ports
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
    constant REG_STATUS_TAG_ZERO : std_logic_vector(REORDER_BUFFER_TAG_BITS - 1 downto 0) := (others => '0');
    constant REG_ADDR_ZERO : std_logic_vector(REGFILE_SIZE - 1 downto 0) := (others => '0'); 
    -- ===============================

    -- ========== RF REGISTERS ==========
    type reg_file_type is array (2 ** REGFILE_SIZE - 1 downto 0) of std_logic_vector(REG_DATA_WIDTH_BITS - 1 downto 0);
    signal reg_file : reg_file_type;
    -- ==================================
    
    COMPONENT ila_reg_file

    PORT (
	clk : IN STD_LOGIC;



	probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe6 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	probe7 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END COMPONENT  ;
begin
    -- Read from registers
    rd_1_data <= reg_file(to_integer(unsigned(rd_1_addr)));
    rd_2_data <= reg_file(to_integer(unsigned(rd_2_addr)));

    rf_access_proc : process(clk)
    begin
        -- Writing to registers
        if (rising_edge(clk)) then
            if (reset = '1') then
                reg_file <= (others => (others => '0'));
            elsif (en = '1') then
                reg_file(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
        end if;
    end process;
    
    your_instance_name : ila_reg_file
    PORT MAP (
	clk => clk_dbg,

	probe0 => reg_file(1), 
	probe1 => reg_file(2), 
	probe2 => reg_file(3), 
	probe3 => reg_file(4), 
	probe4 => reg_file(5), 
	probe5 => reg_file(6), 
	probe6 => reg_file(7),
	probe7 => reg_file(8)
);
end rtl;
