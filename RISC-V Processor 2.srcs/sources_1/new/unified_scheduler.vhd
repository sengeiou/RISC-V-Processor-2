library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_SCHED.ALL;
use WORK.PKG_CPU.ALL;

-- ================ NOTES ================ 
-- Possible optimization (?): Do reads on falling edge and writes on rising edge (or vise versa)
-- Remove register destination address and put reservation station tags to indentify where results of computation have to go
-- =======================================

entity unified_scheduler is
    port(
        -- COMMON DATA BUS
        cdb : in cdb_type;
    
        -- INPUTS
        in_port_0 : in sched_in_port_type;
        
        -- OUTPUTS
        out_port_0 : out sched_out_port_type;
        out_port_1 : out sched_out_port_type;

        -- CONTROL
        write_en : in std_logic;
        p0_unit_ready : in std_logic;
        p1_unit_ready : in std_logic;
        full : out std_logic;
        
        clk : in std_logic;
        reset : in std_logic
    );
end unified_scheduler;

architecture rtl of unified_scheduler is    
    signal rs_entries : reservation_station_entries_type;
    signal rs_busy_bits : std_logic_vector(SCHEDULER_ENTRIES - 1 downto 0);
    signal rs_operands_ready_bits : std_logic_vector(SCHEDULER_ENTRIES - 1 downto 0);
    signal rs_port_0_optype_bits : std_logic_vector(SCHEDULER_ENTRIES - 1 downto 0);
    signal rs_port_1_optype_bits : std_logic_vector(SCHEDULER_ENTRIES - 1 downto 0);
    signal rs_port_0_dispatch_ready_bits : std_logic_vector(SCHEDULER_ENTRIES - 1 downto 0);
    signal rs_port_1_dispatch_ready_bits : std_logic_vector(SCHEDULER_ENTRIES - 1 downto 0);
    
    signal rs_sel_write_1 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0);
    signal rs_sel_read_1 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0);
    signal rs_sel_read_2 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0);

    signal rs1_src_tag_1_v : std_logic;
    signal rs1_src_tag_2_v : std_logic;
    
    signal port_0_dispatch_en : std_logic;
    signal port_1_dispatch_en : std_logic;
begin
    rs_full_proc : process(rs_entries)
        variable temp : std_logic;
    begin
        temp := '1';
        for i in 0 to SCHEDULER_ENTRIES - 1 loop
            temp := temp and rs_entries(i)(0);
        end loop;
        full <= temp;
    end process;

    -- Generates a vector containing all busy bits of the reservation station
    rs_busy_bits_proc : process(rs_entries)
    begin
        for i in 0 to SCHEDULER_ENTRIES - 1 loop
            rs_busy_bits(i) <= not rs_entries(i)(0);
        end loop;
    end process;
    
    -- Generates a vector of ready bits for the reservation station. Ready bits indicate to the allocators that the reservation station entry
    -- is ready to be dispatched. That means that the entry has all operands (both entry tags are 0), is busy and has not yet been dispatched
    rs_operands_ready_bits_proc : process(rs_entries)
    begin
        for i in 0 to SCHEDULER_ENTRIES - 1 loop
            if (rs_entries(i)(OPERAND_TAG_1_VALID) = '1' and
                rs_entries(i)(OPERAND_TAG_2_VALID) = '1' and
                rs_entries(i)(0) = '1') then
                rs_operands_ready_bits(i) <= '1';
            else
                rs_operands_ready_bits(i) <= '0';
            end if;
        end loop;
    end process;
    
    -- Generates a vector of bits which indicate that the corresponding reservation station entry should output to port 0.
    rs_port_0_optype_bits_proc : process(rs_entries)
    begin
        for i in 0 to SCHEDULER_ENTRIES - 1 loop
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
        for i in 0 to SCHEDULER_ENTRIES - 1 loop
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
                       generic map(NUM_INPUTS => SCHEDULER_ENTRIES)
                       port map(d => rs_busy_bits,
                                q => rs_sel_write_1);
                                
    -- Priority encoder that takes ready bits as its input and selects one entry to be dispatched to port 0. 
    prio_enc_read_1 : entity work.priority_encoder(rtl)
                      generic map(NUM_INPUTS => SCHEDULER_ENTRIES)
                      port map(d => rs_port_0_dispatch_ready_bits,
                               q => rs_sel_read_1);
                               
    -- Priority encoder that takes ready bits as its input and selects one entry to be dispatched to port 1. 
    prio_enc_read_2 : entity work.priority_encoder(rtl)
                      generic map(NUM_INPUTS => SCHEDULER_ENTRIES)
                      port map(d => rs_port_1_dispatch_ready_bits,
                               q => rs_sel_read_2);
                               
    -- This is a check for whether current instruction's required tags are being broadcast on the CDB right now. If they are then that will immediately be taken
    -- into consideration. Without this part the instruction in an entry could keep waiting for a result of an instruction that has already finished execution.  
    reservation_station_operand_select_proc : process(cdb, in_port_0)
    begin
        if (in_port_0.src_tag_1 /= cdb.tag) then
            rs1_src_tag_1_v <= in_port_0.src_tag_1_valid;
        else
            rs1_src_tag_1_v <= '1';
        end if;
        
        if (in_port_0.src_tag_2 /= cdb.tag) then
            rs1_src_tag_2_v <= in_port_0.src_tag_2_valid;
        else
            rs1_src_tag_2_v <= '1';
        end if;
    end process;
                               
    -- Controls writing into an entry of the reservation station. Appropriately sets 'dispatched' and 'busy' bits by listening to the CDB.
    reservation_station_write_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to SCHEDULER_ENTRIES - 1 loop
                    rs_entries(i) <= (others => '0');
                end loop;
            else
                if (write_en = '1') then
                    rs_entries(to_integer(unsigned(rs_sel_write_1))) <= in_port_0.operation_type & 
                                                                        in_port_0.operation_select & 
                                                                        in_port_0.src_tag_1 & 
                                                                        rs1_src_tag_1_v &
                                                                        in_port_0.src_tag_2 & 
                                                                        rs1_src_tag_2_v &
                                                                        in_port_0.dest_tag & 
                                                                        in_port_0.immediate & '1';
                end if;

                if (p0_unit_ready = '1') then
                    rs_entries(to_integer(unsigned(rs_sel_read_1)))(0) <= '0';
                end if;
                    
                if (p1_unit_ready = '1') then
                    rs_entries(to_integer(unsigned(rs_sel_read_2)))(0) <= '0';
                end if;

                for i in 0 to SCHEDULER_ENTRIES - 1 loop
                    if (rs_entries(i)(OPERAND_TAG_1_START downto OPERAND_TAG_1_END) = cdb.tag and
                        rs_entries(i)(0) = '1' and rs_entries(i)(OPERAND_TAG_1_VALID) = '0') then
                        rs_entries(i)(OPERAND_TAG_1_VALID) <= '1';
                    end if;
                    
                    if (rs_entries(i)(OPERAND_TAG_2_START downto OPERAND_TAG_2_END) = cdb.tag and
                        rs_entries(i)(0) = '1' and rs_entries(i)(OPERAND_TAG_2_VALID) = '0') then
                        rs_entries(i)(OPERAND_TAG_2_VALID) <= '1';
                    end if;
                end loop;
            end if;
        end if;
    end process;
    
    -- Puts the selected entry onto one exit port of the reservation station
    reservation_station_dispatch_proc : process(port_0_dispatch_en, port_1_dispatch_en, rs_entries, rs_sel_read_1, rs_sel_read_2)
    begin
        if (port_0_dispatch_en = '1') then
            out_port_0.operation_type <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(OPERATION_TYPE_START downto OPERATION_TYPE_END);
            out_port_0.operation_sel <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(OPERATION_SELECT_START downto OPERATION_SELECT_END);
            out_port_0.src_tag_1 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(OPERAND_TAG_1_START downto OPERAND_TAG_1_END);
            out_port_0.src_tag_2 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(OPERAND_TAG_2_START downto OPERAND_TAG_2_END);
            out_port_0.immediate <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(IMMEDIATE_START downto IMMEDIATE_END);
            out_port_0.dest_tag <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(DEST_TAG_START downto DEST_TAG_END);
            out_port_0.valid <= '1';
        else
            out_port_0.operation_type <= (others => '0');
            out_port_0.operation_sel <= (others => '0');
            out_port_0.src_tag_1 <= (others => '0');
            out_port_0.src_tag_2 <= (others => '0');
            out_port_0.immediate <= (others => '0');
            out_port_0.dest_tag <= (others => '0');
            out_port_0.valid <= '0';
        end if;
        
        if (port_1_dispatch_en = '1') then
            out_port_1.operation_type <= rs_entries(to_integer(unsigned(rs_sel_read_2)))(OPERATION_TYPE_START downto OPERATION_TYPE_END);
            out_port_1.operation_sel <= rs_entries(to_integer(unsigned(rs_sel_read_2)))(OPERATION_SELECT_START downto OPERATION_SELECT_END);
            out_port_1.src_tag_1 <= rs_entries(to_integer(unsigned(rs_sel_read_2)))(OPERAND_TAG_1_START downto OPERAND_TAG_1_END);
            out_port_1.src_tag_2 <= rs_entries(to_integer(unsigned(rs_sel_read_2)))(OPERAND_TAG_2_START downto OPERAND_TAG_2_END);
            out_port_1.immediate <= rs_entries(to_integer(unsigned(rs_sel_read_2)))(IMMEDIATE_START downto IMMEDIATE_END);
            out_port_1.dest_tag <= rs_entries(to_integer(unsigned(rs_sel_read_2)))(DEST_TAG_START downto DEST_TAG_END);
            out_port_1.valid <= '1';
        else
            out_port_1.operation_type <= (others => '0');
            out_port_1.operation_sel <= (others => '0');
            out_port_1.src_tag_1 <= (others => '0');
            out_port_1.src_tag_2 <= (others => '0');
            out_port_1.immediate <= (others => '0');
            out_port_1.dest_tag <= (others => '0');
            out_port_1.valid <= '0';
        end if;
    end process;
    
    port_0_dispatch_en <= '1' when p0_unit_ready = '1' and (rs_sel_read_1 /= ENTRY_TAG_ZERO) else '0'; 
    port_1_dispatch_en <= '1' when p1_unit_ready = '1' and (rs_sel_read_2 /= ENTRY_TAG_ZERO) else '0'; 
end rtl;












