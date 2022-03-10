library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- ================ NOTES ================ 
-- Possible optimization (?): Do reads on falling edge and writes on rising edge (or vise versa)
-- Add detection on wether the reservation station is full or empty
-- =======================================

use work.pkg_cpu.all;

entity reservation_station is
    generic(
        NUM_ENTRIES : integer range 1 to 1024;
        REG_ADDR_BITS : integer range 1 to 10;
        OPERATION_TYPE_BITS : integer range 1 to 32;
        OPERATION_SELECT_BITS : integer range 1 to 32;
        OPERAND_BITS : integer range 1 to 64
    );
    port(
        -- INPUTS
        i1_operation_type : in std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        i1_operation_sel : in std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        i1_reg_src_1 : in std_logic_vector(REG_ADDR_BITS - 1 downto 0); 
        i1_reg_src_2 : in std_logic_vector(REG_ADDR_BITS - 1 downto 0); 
        i1_operand_1 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        i1_operand_2 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        i1_dest_reg : in std_logic_vector(REG_ADDR_BITS - 1 downto 0);
        
        -- OUTPUTS
        -- ===== PORT 1 =====
        o1_operation_type : out std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        o1_operation_sel : out std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        o1_operand_1 : out std_logic_vector(OPERAND_BITS - 1 downto 0);
        o1_operand_2 : out std_logic_vector(OPERAND_BITS - 1 downto 0); 
        o1_dest_reg : out std_logic_vector(REG_ADDR_BITS - 1 downto 0);
        o1_rs_entry_tag : out std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
        -- ==================
        
        write_en : in std_logic;
        rs_dispatch_1_en : in std_logic;
        
        clk : in std_logic;
        reset : in std_logic
    );
end reservation_station;

architecture rtl of reservation_station is
    -- Reservation station format [OP. TYPE | OP. SEL | RES_STAT_1 | RES_STAT_2 | OPERAND_1 | OPERAND_2 | REG_DEST | BUSY]
    constant RS_SEL_ENTRY_BITS : integer := integer(ceil(log2(real(NUM_ENTRIES))));
    constant ENTRY_LEN_BITS : integer := OPERATION_TYPE_BITS + OPERATION_SELECT_BITS + REG_ADDR_BITS + 2 * RS_SEL_ENTRY_BITS + 2 * OPERAND_BITS + 1;
    constant RS_SEL_ZERO : std_logic_vector(RS_SEL_ENTRY_BITS - 1 downto 0) := (others => '0');
    constant REG_ADDR_ZERO : std_logic_vector(REG_ADDR_BITS - 1 downto 0) := (others => '0');

    -- ========== RF STATUS REGISTER ==========
    type rf_status_reg_type is array (31 downto 0) of std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRY_CNT)))) - 1 downto 0);
    signal rf_status_reg : rf_status_reg_type;
    
    signal rs_producer_index_1 : std_logic_vector(RS_SEL_ENTRY_BITS - 1 downto 0);
    signal rs_producer_index_2 : std_logic_vector(RS_SEL_ENTRY_BITS - 1 downto 0);
    -- ========================================
    
    type reservation_station_entries is array(NUM_ENTRIES - 1 downto 0) of std_logic_vector(ENTRY_LEN_BITS - 1 downto 0);  -- Number of bits in one entry of the reservation station
    
    signal rs_entries : reservation_station_entries;
    signal rs_res_stat_1 : std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
    signal rs_res_stat_2 : std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
    signal rs_busy_bits : std_logic_vector(NUM_ENTRIES - 1 downto 0);
    signal rs_ready_bits : std_logic_vector(NUM_ENTRIES - 1 downto 0);
    
    signal rs_sel_write_1 : std_logic_vector(RS_SEL_ENTRY_BITS - 1 downto 0);
    signal rs_sel_read_1 : std_logic_vector(RS_SEL_ENTRY_BITS - 1 downto 0);
begin
    -- =============== RF STATUS REGISTER =============== 
    rf_status_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                rf_status_reg <= (others => (others => '0'));
            else    
                if (i1_dest_reg /= "00000" and write_en = '1') then
                    -- Set register station entry as the producer of the destination registers value so that it can be used to resolve dependencies with later instructions
                    rf_status_reg(to_integer(unsigned(i1_dest_reg))) <= rs_sel_write_1;
                end if;
                

            end if;
        end if;
    end process;
    
    rs_producer_index_1 <= rf_status_reg(to_integer(unsigned(i1_reg_src_1)));
    rs_producer_index_2 <= rf_status_reg(to_integer(unsigned(i1_reg_src_2)));
    -- ==================================================

    rs_busy_bits_proc : process(rs_entries)
    begin
        for i in 0 to NUM_ENTRIES - 1 loop
            rs_busy_bits(i) <= not rs_entries(i)(0);
        end loop;
    end process;
    
    rs_ready_bits_proc : process(rs_entries)
    begin
        for i in 0 to NUM_ENTRIES - 1 loop
            if (rs_entries(i)(ENTRY_LEN_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 1 downto ENTRY_LEN_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - RS_SEL_ENTRY_BITS) = RS_SEL_ZERO and
                rs_entries(i)(ENTRY_LEN_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 1 - RS_SEL_ENTRY_BITS downto ENTRY_LEN_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * RS_SEL_ENTRY_BITS) = RS_SEL_ZERO and
                rs_entries(i)(0) = '1') then
                rs_ready_bits(i) <= '1';
            else
                rs_ready_bits(i) <= '0';
            end if;
        end loop;
    end process;

    prio_enc_write_1 : entity work.priority_encoder(rtl)
                       generic map(NUM_INPUTS => NUM_ENTRIES)
                       port map(d => rs_busy_bits,
                                q => rs_sel_write_1);
                                
    prio_enc_read_1 : entity work.priority_encoder(rtl)
                      generic map(NUM_INPUTS => NUM_ENTRIES)
                      port map(d => rs_ready_bits,
                               q => rs_sel_read_1);
                               
    reservation_station_write_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to NUM_ENTRIES - 1 loop
                    rs_entries(i) <= (others => '0');
                end loop;
            else
                if (write_en = '1') then
                    rs_entries(to_integer(unsigned(rs_sel_write_1))) <= i1_operation_type & i1_operation_sel & rs_producer_index_1 & rs_producer_index_2 & i1_operand_1 & i1_operand_2 & i1_dest_reg & '1';
                end if;
                
                if (rs_dispatch_1_en = '1') then
                    rs_entries(to_integer(unsigned(rs_sel_read_1)))(0) <= '0';
                end if;
            end if;
        end if;
    end process;
    
    reservation_station_dispatch_proc : process(rs_dispatch_1_en, rs_entries, rs_sel_read_1)
    begin
        if (rs_dispatch_1_en = '1') then
            o1_operation_type <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - 1 downto ENTRY_LEN_BITS - OPERATION_TYPE_BITS);
            o1_operation_sel <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - OPERATION_TYPE_BITS - 1 downto ENTRY_LEN_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS);
            --o1_res_stat_1 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - OPCODE_BITS - 1 downto ENTRY_LEN_BITS - OPCODE_BITS - RS_SEL_ENTRY_BITS);
            --o1_res_stat_2 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - OPCODE_BITS - RS_SEL_ENTRY_BITS - 1 downto ENTRY_LEN_BITS - OPCODE_BITS - 2 * RS_SEL_ENTRY_BITS);
            o1_operand_1 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * RS_SEL_ENTRY_BITS - 1 downto ENTRY_LEN_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * RS_SEL_ENTRY_BITS - OPERAND_BITS);
            o1_operand_2 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * RS_SEL_ENTRY_BITS - OPERAND_BITS - 1 downto ENTRY_LEN_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * RS_SEL_ENTRY_BITS - 2 * OPERAND_BITS);
            o1_dest_reg <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * RS_SEL_ENTRY_BITS - 2 * OPERAND_BITS - 1 downto 1);
            o1_rs_entry_tag <= rs_sel_read_1;
        else
            o1_operation_type <= (others => '0');
            o1_operation_sel <= (others => '0');
            o1_operand_1 <= (others => '0');
            o1_operand_2 <= (others => '0');
            o1_dest_reg <= (others => '0');
            o1_rs_entry_tag <= (others => '0');
        end if;
    end process;

end rtl;












