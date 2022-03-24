library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- ================ NOTES ================ 
-- Possible optimization (?): Do reads on falling edge and writes on rising edge (or vise versa)
-- Remove register destination address and put reservation station tags to indentify where results of computation have to go
-- =======================================

entity reservation_station is
    generic(
        RESERVATION_STATION_ENTRIES : integer;
        
        OPERATION_TYPE_BITS : integer;
        OPERATION_SELECT_BITS : integer;
        
        OPERAND_BITS : integer;
        REG_ADDR_BITS : integer;
        
        PORT_0_OPTYPE : std_logic_vector(2 downto 0);
        PORT_1_OPTYPE : std_logic_vector(2 downto 0)
    );
    port(
        -- COMMON DATA BUS
        cdb_data : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        cdb_rs_entry_tag : in std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
    
        -- INPUTS
        i1_operation_type : in std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        i1_operation_sel : in std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        i1_src_tag_1 : in std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0); 
        i1_src_tag_2 : in std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0); 
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
        o1_rs_entry_tag : out std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
        o1_dispatch_ready : out std_logic;
        -- ==================
        
        -- ===== PORT 2 =====
        o2_operation_type : out std_logic_vector(OPERATION_TYPE_BITS - 1 downto 0);
        o2_operation_sel : out std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        o2_operand_1 : out std_logic_vector(OPERAND_BITS - 1 downto 0);
        o2_operand_2 : out std_logic_vector(OPERAND_BITS - 1 downto 0); 
        o2_immediate : out std_logic_vector(OPERAND_BITS - 1 downto 0); 
        o2_rs_entry_tag : out std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
        o2_dispatch_ready : out std_logic;
        -- ==================
        
        -- CONTROL
        next_alloc_entry_tag : out std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
        
        write_en : in std_logic;
        port_0_ready : in std_logic;
        port_1_ready : in std_logic;
        full : out std_logic;
        
        clk : in std_logic;
        reset : in std_logic
    );
end reservation_station;

architecture rtl of reservation_station is
    -- Reservation station format [OP. TYPE | OP. SEL | RES_STAT_1 | RES_STAT_2 | OPERAND_1 | OPERAND_2 | IMMEDIATE | DISPATCHED | BUSY]
    constant ENTRY_TAG_BITS : integer := integer(ceil(log2(real(RESERVATION_STATION_ENTRIES))));
    constant ENTRY_BITS : integer := OPERATION_TYPE_BITS + OPERATION_SELECT_BITS + 2 * ENTRY_TAG_BITS + 3 * OPERAND_BITS + 2;
    
    -- ========== STARTING AND ENDING INDEXES OF RESERVATION STATION ENTRIES ==========
    constant OPERATION_TYPE_START : integer := ENTRY_BITS - 1;
    constant OPERATION_TYPE_END : integer := ENTRY_BITS - OPERATION_TYPE_BITS;
    constant OPERATION_SELECT_START : integer := ENTRY_BITS - OPERATION_TYPE_BITS - 1;
    constant OPERATION_SELECT_END : integer := ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS;
    constant ENTRY_TAG_1_START : integer := ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 1;
    constant ENTRY_TAG_1_END : integer := ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - ENTRY_TAG_BITS;
    constant ENTRY_TAG_2_START : integer := ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - ENTRY_TAG_BITS - 1;
    constant ENTRY_TAG_2_END : integer := ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS;
    constant OPERAND_1_START: integer := ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - 1;
    constant OPERAND_1_END : integer := ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - OPERAND_BITS;
    constant OPERAND_2_START: integer := ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - OPERAND_BITS - 1;
    constant OPERAND_2_END : integer := ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - 2 * OPERAND_BITS;
    constant IMMEDIATE_START : integer := ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - 2 * OPERAND_BITS - 1;
    constant IMMEDIATE_END : integer := ENTRY_BITS - OPERATION_TYPE_BITS - OPERATION_SELECT_BITS - 2 * ENTRY_TAG_BITS - 3 * OPERAND_BITS;
    -- ================================================================================
    
    constant ENTRY_TAG_ZERO : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0) := (others => '0');
    
    type reservation_station_entries_type is array(RESERVATION_STATION_ENTRIES - 1 downto 0) of std_logic_vector(ENTRY_BITS - 1 downto 0);  -- Number of bits in one entry of the reservation station
    
    signal rs_entries : reservation_station_entries_type;
    signal rs_busy_bits : std_logic_vector(RESERVATION_STATION_ENTRIES - 1 downto 0);
    signal rs_operands_ready_bits : std_logic_vector(RESERVATION_STATION_ENTRIES - 1 downto 0);
    signal rs_port_0_optype_bits : std_logic_vector(RESERVATION_STATION_ENTRIES - 1 downto 0);
    signal rs_port_1_optype_bits : std_logic_vector(RESERVATION_STATION_ENTRIES - 1 downto 0);
    signal rs_port_0_dispatch_ready_bits : std_logic_vector(RESERVATION_STATION_ENTRIES - 1 downto 0);
    signal rs_port_1_dispatch_ready_bits : std_logic_vector(RESERVATION_STATION_ENTRIES - 1 downto 0);
    
    signal rs_sel_write_1 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0);
    signal rs_sel_read_1 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0);
    signal rs_sel_read_2 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0);
    
    signal rs1_src_tag_1 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0); 
    signal rs1_src_tag_2 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0); 
    signal rs1_operand_1 : std_logic_vector(OPERAND_BITS - 1 downto 0); 
    signal rs1_operand_2 : std_logic_vector(OPERAND_BITS - 1 downto 0); 
    
    signal port_0_dispatch_en : std_logic;
    signal port_1_dispatch_en : std_logic;
begin
    rs_full_proc : process(rs_entries)
        variable temp : std_logic;
    begin
        temp := '1';
        for i in 0 to RESERVATION_STATION_ENTRIES - 1 loop
            temp := temp and rs_entries(i)(0);
        end loop;
        full <= temp;
    end process;

    -- Generates a vector containing all busy bits of the reservation station
    rs_busy_bits_proc : process(rs_entries)
    begin
        for i in 0 to RESERVATION_STATION_ENTRIES - 1 loop
            rs_busy_bits(i) <= not rs_entries(i)(0);
        end loop;
    end process;
    
    -- Generates a vector of ready bits for the reservation station. Ready bits indicate to the allocators that the reservation station entry
    -- is ready to be dispatched. That means that the entry has all operands (both entry tags are 0), is busy and has not yet been dispatched
    rs_operands_ready_bits_proc : process(rs_entries)
    begin
        for i in 0 to RESERVATION_STATION_ENTRIES - 1 loop
            if (rs_entries(i)(ENTRY_TAG_1_START downto ENTRY_TAG_1_END) = ENTRY_TAG_ZERO and
                rs_entries(i)(ENTRY_TAG_2_START downto ENTRY_TAG_2_END) = ENTRY_TAG_ZERO and
                rs_entries(i)(0) = '1' and rs_entries(i)(1) = '0') then
                rs_operands_ready_bits(i) <= '1';
            else
                rs_operands_ready_bits(i) <= '0';
            end if;
        end loop;
    end process;
    
    -- Generates a vector of bits which indicate that the corresponding reservation station entry should output to port 0.
    rs_port_0_optype_bits_proc : process(rs_entries)
    begin
        for i in 0 to RESERVATION_STATION_ENTRIES - 1 loop
            if (rs_entries(i)(OPERATION_TYPE_START downto OPERATION_TYPE_END) = PORT_0_OPTYPE) then
                rs_port_0_optype_bits(i) <= '1';
            else
                rs_port_0_optype_bits(i) <= '0';
            end if;
        end loop;
    end process;

    -- Generates a vector of bits which indicate that the corresponding reservation station entry should output to port 1.
    rs_port_1_optype_bits_proc : process(rs_entries)
    begin
        for i in 0 to RESERVATION_STATION_ENTRIES - 1 loop
            if (rs_entries(i)(OPERATION_TYPE_START downto OPERATION_TYPE_END) = PORT_1_OPTYPE) then
                rs_port_1_optype_bits(i) <= '1';
            else
                rs_port_1_optype_bits(i) <= '0';
            end if;
        end loop;
    end process;
    
    rs_port_0_dispatch_ready_bits <= rs_operands_ready_bits and rs_port_0_optype_bits;
    rs_port_1_dispatch_ready_bits <= rs_operands_ready_bits and rs_port_1_optype_bits;

    -- Priority encoder that takes busy bits as its input and selects one free entry to be written into 
    prio_enc_write_1 : entity work.priority_encoder(rtl)
                       generic map(NUM_INPUTS => RESERVATION_STATION_ENTRIES)
                       port map(d => rs_busy_bits,
                                q => rs_sel_write_1);
                                
    -- Priority encoder that takes ready bits as its input and selects one entry to be dispatched to port 0. 
    prio_enc_read_1 : entity work.priority_encoder(rtl)
                      generic map(NUM_INPUTS => RESERVATION_STATION_ENTRIES)
                      port map(d => rs_port_0_dispatch_ready_bits,
                               q => rs_sel_read_1);
                               
    -- Priority encoder that takes ready bits as its input and selects one entry to be dispatched to port 1. 
    prio_enc_read_2 : entity work.priority_encoder(rtl)
                      generic map(NUM_INPUTS => RESERVATION_STATION_ENTRIES)
                      port map(d => rs_port_1_dispatch_ready_bits,
                               q => rs_sel_read_2);
                               
    -- This is a check for whether current instruction's operands are being broadcast on the CDB. If they are then that will immediately be taken
    -- into consideration. Without this part the instruction in an entry could keep waiting for a result of an instruction that has already finished execution.  
    reservation_station_operand_select_proc : process(cdb_rs_entry_tag, cdb_data, i1_src_tag_1, i1_operand_1, i1_src_tag_2, i1_operand_2)
    begin
        if (i1_src_tag_1 /= cdb_rs_entry_tag) then
            rs1_src_tag_1 <= i1_src_tag_1;
            rs1_operand_1 <= i1_operand_1;
        else
            rs1_src_tag_1 <= (others => '0');
            rs1_operand_1 <= cdb_data;
        end if;
        
        if (i1_src_tag_2 /= cdb_rs_entry_tag) then
            rs1_src_tag_2 <= i1_src_tag_2;
            rs1_operand_2 <= i1_operand_2;
        else
            rs1_src_tag_2 <= (others => '0');
            rs1_operand_2 <= cdb_data;
        end if;
    end process;
                               
    -- Controls writing into an entry of the reservation station. Appropriately sets 'dispatched' and 'busy' bits by listening to the CDB.
    reservation_station_write_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to RESERVATION_STATION_ENTRIES - 1 loop
                    rs_entries(i) <= (others => '0');
                end loop;
            else
                if (write_en = '1') then
                    rs_entries(to_integer(unsigned(rs_sel_write_1))) <= i1_operation_type & i1_operation_sel & rs1_src_tag_1 & rs1_src_tag_2 & rs1_operand_1 & rs1_operand_2 & i1_immediate & '0' & '1';
                end if;

                for i in 0 to RESERVATION_STATION_ENTRIES - 1 loop
                    if (cdb_rs_entry_tag = std_logic_vector(to_unsigned(i, ENTRY_TAG_BITS)) and rs_entries(i)(0) = '1') then
                        rs_entries(i)(1) <= '0';
                        rs_entries(i)(0) <= '0';
                    end if;
                    
                    if (port_0_ready = '1') then
                        rs_entries(to_integer(unsigned(rs_sel_read_1)))(1) <= '1';
                    end if;
                    
                    if (port_1_ready = '1') then
                        rs_entries(to_integer(unsigned(rs_sel_read_2)))(1) <= '1';
                    end if;
                
                    if (rs_entries(i)(ENTRY_TAG_1_START downto ENTRY_TAG_1_END) /= ENTRY_TAG_ZERO and
                        rs_entries(i)(ENTRY_TAG_1_START downto ENTRY_TAG_1_END) = cdb_rs_entry_tag) then
                        rs_entries(i)(ENTRY_TAG_1_START downto ENTRY_TAG_1_END) <= (others => '0');
                        rs_entries(i)(OPERAND_1_START downto OPERAND_1_END) <= cdb_data;
                    end if;
                    
                    if (rs_entries(i)(ENTRY_TAG_2_START downto ENTRY_TAG_2_END) /= ENTRY_TAG_ZERO and
                        rs_entries(i)(ENTRY_TAG_2_START downto ENTRY_TAG_2_END) = cdb_rs_entry_tag) then
                        rs_entries(i)(ENTRY_TAG_2_START downto ENTRY_TAG_2_END) <= (others => '0');
                        rs_entries(i)(OPERAND_2_START downto OPERAND_2_END) <= cdb_data;
                    end if;
                end loop;
            end if;
        end if;
    end process;
    
    -- Puts the selected entry onto one exit port of the reservation station
    reservation_station_dispatch_proc : process(port_0_dispatch_en, port_1_dispatch_en, rs_entries, rs_sel_read_1, rs_sel_read_2)
    begin
        if (port_0_dispatch_en = '1') then
            o1_operation_type <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(OPERATION_TYPE_START downto OPERATION_TYPE_END);
            o1_operation_sel <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(OPERATION_SELECT_START downto OPERATION_SELECT_END);
            o1_operand_1 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(OPERAND_1_START downto OPERAND_1_END);
            o1_operand_2 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(OPERAND_2_START downto OPERAND_2_END);
            o1_immediate <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(IMMEDIATE_START downto IMMEDIATE_END);
            o1_rs_entry_tag <= rs_sel_read_1;
            o1_dispatch_ready <= '1';
        else
            o1_operation_type <= (others => '0');
            o1_operation_sel <= (others => '0');
            o1_operand_1 <= (others => '0');
            o1_operand_2 <= (others => '0');
            o1_immediate <= (others => '0');
            o1_rs_entry_tag <= (others => '0');
            o1_dispatch_ready <= '0';
        end if;
        
        if (port_1_dispatch_en = '1') then
            o2_operation_type <= rs_entries(to_integer(unsigned(rs_sel_read_2)))(OPERATION_TYPE_START downto OPERATION_TYPE_END);
            o2_operation_sel <= rs_entries(to_integer(unsigned(rs_sel_read_2)))(OPERATION_SELECT_START downto OPERATION_SELECT_END);
            o2_operand_1 <= rs_entries(to_integer(unsigned(rs_sel_read_2)))(OPERAND_1_START downto OPERAND_1_END);
            o2_operand_2 <= rs_entries(to_integer(unsigned(rs_sel_read_2)))(OPERAND_2_START downto OPERAND_2_END);
            o2_immediate <= rs_entries(to_integer(unsigned(rs_sel_read_2)))(IMMEDIATE_START downto IMMEDIATE_END);
            o2_rs_entry_tag <= rs_sel_read_2;
            o2_dispatch_ready <= '1';
        else
            o2_operation_type <= (others => '0');
            o2_operation_sel <= (others => '0');
            o2_operand_1 <= (others => '0');
            o2_operand_2 <= (others => '0');
            o2_immediate <= (others => '0');
            o2_rs_entry_tag <= (others => '0');
            o2_dispatch_ready <= '0';
        end if;
    end process;
    
    port_0_dispatch_en <= '1' when port_0_ready = '1' and (rs_sel_read_1 /= ENTRY_TAG_ZERO) else '0'; 
    port_1_dispatch_en <= '1' when port_1_ready = '1' and (rs_sel_read_2 /= ENTRY_TAG_ZERO) else '0'; 
    
    next_alloc_entry_tag <= rs_sel_write_1;

end rtl;












