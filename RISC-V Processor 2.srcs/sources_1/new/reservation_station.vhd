library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

-- ================ NOTES ================ 
-- Possible optimization (?): Do reads on falling edge and writes on rising edge (or vise versa)
-- Remove register destination address and put reservation station tags to indentify where results of computation have to go
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
        -- COMMON DATA BUS
        cdb : in cdb_type;
    
        -- INPUTS
        i1_operation_type : in std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        i1_operation_sel : in std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        i1_src_tag_1 : in std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0); 
        i1_src_tag_2 : in std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0); 
        i1_operand_1 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        i1_operand_2 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        i1_immediate : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        i1_dest_reg : in std_logic_vector(REG_ADDR_BITS - 1 downto 0);
        
        -- OUTPUTS
        -- ===== PORT 1 =====
        o1_operation_type : out std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        o1_operation_sel : out std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        o1_operand_1 : out std_logic_vector(OPERAND_BITS - 1 downto 0);
        o1_operand_2 : out std_logic_vector(OPERAND_BITS - 1 downto 0); 
        o1_immediate : out std_logic_vector(OPERAND_BITS - 1 downto 0); 
        o1_rs_entry_tag : out std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
        -- ==================
        
        -- CONTROL
        rs_alloc_dest_tag : out std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
        
        write_en : in std_logic;
        rs_dispatch_1_en : in std_logic;
        full : out std_logic;
        
        clk : in std_logic;
        reset : in std_logic
    );
end reservation_station;

architecture rtl of reservation_station is
    -- Reservation station format [OP. TYPE | OP. SEL | RES_STAT_1 | RES_STAT_2 | OPERAND_1 | OPERAND_2 | IMMEDIATE | DISPATCHED | BUSY]
    constant ENTRY_TAG_BITS : integer := integer(ceil(log2(real(NUM_ENTRIES))));
    constant ENTRY_BITS : integer := OPERATION_TYPE_BITS + OPERATION_SELECT_BITS + 2 * ENTRY_TAG_BITS + 3 * OPERAND_BITS + 2;
    constant RS_SEL_ZERO : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0) := (others => '0');
    constant REG_ADDR_ZERO : std_logic_vector(REG_ADDR_BITS - 1 downto 0) := (others => '0');
    
    type reservation_station_entries is array(NUM_ENTRIES - 1 downto 0) of std_logic_vector(ENTRY_BITS - 1 downto 0);  -- Number of bits in one entry of the reservation station
    
    signal rs_entries : reservation_station_entries;
    signal rs_res_stat_1 : std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
    signal rs_res_stat_2 : std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
    signal rs_busy_bits : std_logic_vector(NUM_ENTRIES - 1 downto 0);
    signal rs_ready_bits : std_logic_vector(NUM_ENTRIES - 1 downto 0);
    
    signal rs_sel_write_1 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0);
    signal rs_sel_read_1 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0);
    
    signal rs1_src_tag_1 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0); 
    signal rs1_src_tag_2 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0); 
    signal rs1_operand_1 : std_logic_vector(OPERAND_BITS - 1 downto 0); 
    signal rs1_operand_2 : std_logic_vector(OPERAND_BITS - 1 downto 0); 
begin
    rs_full_proc : process(rs_entries)
        variable res : std_logic := '1';
    begin
        for i in 0 to NUM_ENTRIES - 1 loop
            if (rs_entries(i)(0) = '0') then
                res := '0';
            end if;
        end loop;
        full <= res;
    end process;

    -- Generates a vector containing all busy bits of the reservation station
    rs_busy_bits_proc : process(rs_entries)
    begin
        for i in 0 to NUM_ENTRIES - 1 loop
            rs_busy_bits(i) <= not rs_entries(i)(0);
        end loop;
    end process;
    
    -- Generates a vector of ready bits for the reservation station. Ready bits indicate to the allocators that the reservation station entry
    -- is ready to be dispatched. That means that the entry has all operands (both entry tags are 0), is busy and has not yet been dispatched
    rs_ready_bits_proc : process(rs_entries)
    begin
        for i in 0 to NUM_ENTRIES - 1 loop
            if (rs_entries(i)(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - ENTRY_TAG_BITS) = RS_SEL_ZERO and
                rs_entries(i)(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 1 - ENTRY_TAG_BITS downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS) = RS_SEL_ZERO and
                rs_entries(i)(0) = '1' and rs_entries(i)(1) = '0') then
                rs_ready_bits(i) <= '1';
            else
                rs_ready_bits(i) <= '0';
            end if;
        end loop;
    end process;

    -- Priority encoder that takes busy bits as its input and selects one free entry to be written into 
    prio_enc_write_1 : entity work.priority_encoder(rtl)
                       generic map(NUM_INPUTS => NUM_ENTRIES)
                       port map(d => rs_busy_bits,
                                q => rs_sel_write_1);
                                
    -- Priority encoder that takes ready bits as its input and selects one entry to be dispatched
    prio_enc_read_1 : entity work.priority_encoder(rtl)
                      generic map(NUM_INPUTS => NUM_ENTRIES)
                      port map(d => rs_ready_bits,
                               q => rs_sel_read_1);
                               
    -- This is a check for whether current instruction's operands are being broadcast on the CDB. If they are then that will immediately be taken
    -- into consideration. Without this part the instruction in an entry could keep waiting for a result of an instruction that has already finished execution.  
    reservation_station_operand_select_proc : process(cdb.rs_entry_tag, cdb.data, i1_src_tag_1, i1_operand_1, i1_src_tag_2, i1_operand_2)
    begin
        if (i1_src_tag_1 /= cdb.rs_entry_tag) then
            rs1_src_tag_1 <= i1_src_tag_1;
            rs1_operand_1 <= i1_operand_1;
        else
            rs1_src_tag_1 <= (others => '0');
            rs1_operand_1 <= cdb.data;
        end if;
        
        if (i1_src_tag_2 /= cdb.rs_entry_tag) then
            rs1_src_tag_2 <= i1_src_tag_2;
            rs1_operand_2 <= i1_operand_2;
        else
            rs1_src_tag_2 <= (others => '0');
            rs1_operand_2 <= cdb.data;
        end if;
    end process;
                               
    -- Controls writing into an entry of the reservation station. Appropriately sets 'dispatched' and 'busy' bits by listening to the CDB.
    reservation_station_write_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to NUM_ENTRIES - 1 loop
                    rs_entries(i) <= (others => '0');
                end loop;
            else
                if (write_en = '1') then
                    rs_entries(to_integer(unsigned(rs_sel_write_1))) <= i1_operation_type & i1_operation_sel & rs1_src_tag_1 & rs1_src_tag_2 & rs1_operand_1 & rs1_operand_2 & i1_immediate & '0' & '1';
                end if;

                for i in 0 to NUM_ENTRIES - 1 loop
                    if (cdb.rs_entry_tag = std_logic_vector(to_unsigned(i, ENTRY_TAG_BITS)) and rs_entries(i)(0) = '1') then
                        rs_entries(i)(1) <= '0';
                        rs_entries(i)(0) <= '0';
                    end if;
                    
                    if (rs_dispatch_1_en = '1') then
                        rs_entries(to_integer(unsigned(rs_sel_read_1)))(1) <= '1';
                    end if;
                
                    if (rs_entries(i)(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - ENTRY_TAG_BITS) /= "000" and
                        rs_entries(i)(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - ENTRY_TAG_BITS) = cdb.rs_entry_tag) then
                        rs_entries(i)(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - ENTRY_TAG_BITS) <= (others => '0');
                        rs_entries(i)(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - 1 
                                      downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - OPERAND_BITS) <= cdb.data;
                    end if;
                    
                    if (rs_entries(i)(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - ENTRY_TAG_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS) /= "000" and
                        rs_entries(i)(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - ENTRY_TAG_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS) = cdb.rs_entry_tag) then
                        rs_entries(i)(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - ENTRY_TAG_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS) <= (others => '0');
                        rs_entries(i)(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - OPERAND_BITS - 1 
                                      downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - 2 * OPERAND_BITS) <= cdb.data;
                    end if;
                end loop;
            end if;
        end if;
    end process;
    
    -- Puts the selected entry onto one exit port of the reservation station
    reservation_station_dispatch_proc : process(rs_dispatch_1_en, rs_entries, rs_sel_read_1)
    begin
        if (rs_dispatch_1_en = '1') then
            o1_operation_type <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS);
            o1_operation_sel <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_BITS - OPERATION_TYPE_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS);
            o1_operand_1 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - OPERAND_BITS);
            o1_operand_2 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - OPERAND_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - 2 * OPERAND_BITS);
            o1_immediate <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - 2 * OPERAND_BITS - 1 downto ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - 3 * OPERAND_BITS);
            o1_rs_entry_tag <= rs_sel_read_1;
        else
            o1_operation_type <= (others => '0');
            o1_operation_sel <= (others => '0');
            o1_operand_1 <= (others => '0');
            o1_operand_2 <= (others => '0');
            o1_immediate <= (others => '0');
            o1_rs_entry_tag <= (others => '0');
        end if;
    end process;
    
    rs_alloc_dest_tag <= rs_sel_write_1;

end rtl;












