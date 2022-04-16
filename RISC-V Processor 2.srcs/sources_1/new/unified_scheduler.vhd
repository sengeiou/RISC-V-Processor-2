library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_SCHED.ALL;
use WORK.PKG_CPU.ALL;

-- ================ NOTES ================ 
-- Possible optimization (?): Do reads on falling edge and writes on rising edge (or vise versa)
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
        dispatch_en : in std_logic_vector(OUTPUT_PORT_COUNT - 1 downto 0);
        full : out std_logic;
        
        clk : in std_logic;
        reset : in std_logic
    );
end unified_scheduler;

architecture rtl of unified_scheduler is    
    signal sched_entries : reservation_station_entries_type;
    signal sched_busy_bits : std_logic_vector(SCHEDULER_ENTRIES - 1 downto 0);
    signal sched_operands_ready_bits : std_logic_vector(SCHEDULER_ENTRIES - 1 downto 0);

    signal sched_optype_bits : sched_optype_bits_type;
    signal sched_dispatch_ready_bits : sched_dispatch_ready_bits_type;
    signal sched_read_sel : sched_read_sel_type;
    
    signal sched_sel_write_1 : std_logic_vector(ENTRY_TAG_BITS - 1 downto 0);

    signal sched_read_sel_valid : std_logic_vector(OUTPUT_PORT_COUNT - 1 downto 0);

    signal rs1_src_tag_1_v : std_logic;
    signal rs1_src_tag_2_v : std_logic;
begin
    sched_full_proc : process(sched_entries)
        variable temp : std_logic;
    begin
        temp := '1';
        for i in 0 to SCHEDULER_ENTRIES - 1 loop
            temp := temp and sched_entries(i)(0);
        end loop;
        full <= temp;
    end process;

    -- Generates a vector containing all busy bits of the reservation station
    sched_busy_bits_proc : process(sched_entries)
    begin
        for i in 0 to SCHEDULER_ENTRIES - 1 loop
            sched_busy_bits(i) <= not sched_entries(i)(0);
        end loop;
    end process;
    
    -- Generates a vector of ready bits for the reservation station. Ready bits indicate to the allocators that the reservation station entry
    -- is ready to be dispatched. That means that the entry has all operands (both entry tags are 0), is busy and has not yet been dispatched
    sched_operands_ready_bits_proc : process(sched_entries)
    begin
        for i in 0 to SCHEDULER_ENTRIES - 1 loop
            if (sched_entries(i)(OPERAND_TAG_1_VALID) = '1' and
                sched_entries(i)(OPERAND_TAG_2_VALID) = '1' and
                sched_entries(i)(0) = '1') then
                sched_operands_ready_bits(i) <= '1';
            else
                sched_operands_ready_bits(i) <= '0';
            end if;
        end loop;
    end process;
    
    -- Generates a vector of bits which indicate that the corresponding scheduler entry is ready to dispatch to its corresponding port
    sched_optype_bits_proc : process(sched_entries, sched_operands_ready_bits)
    begin
        for i in 0 to SCHEDULER_ENTRIES - 1 loop
            if (sched_entries(i)(OPERATION_TYPE_START downto OPERATION_TYPE_END) = PORT_0_OPTYPE) then
                sched_dispatch_ready_bits(0)(i) <= sched_operands_ready_bits(i);
            else
                sched_dispatch_ready_bits(0)(i) <= '0';
            end if;
            
            if (sched_entries(i)(OPERATION_TYPE_START downto OPERATION_TYPE_END) = PORT_1_OPTYPE) then
                sched_dispatch_ready_bits(1)(i) <= sched_operands_ready_bits(i);
            else
                sched_dispatch_ready_bits(1)(i) <= '0';
            end if;
        end loop;
    end process;

    -- Priority encoder that takes busy bits as its input and selects one free entry to be written into 
    prio_enc_write_1 : entity work.priority_encoder(rtl)
                       generic map(NUM_INPUTS => SCHEDULER_ENTRIES,
                                   HIGHER_INPUT_HIGHER_PRIO => false)
                       port map(d => sched_busy_bits,
                                q => sched_sel_write_1);
     
    -- Generates priority encoders used to select an entry that is ready to dispatch to the corresponding port
    prio_enc_read_sel_gen : for i in 0 to OUTPUT_PORT_COUNT - 1 generate
        prio_enc_read_sel : entity work.priority_encoder(rtl)
                            generic map(NUM_INPUTS => SCHEDULER_ENTRIES,
                                        HIGHER_INPUT_HIGHER_PRIO => false)
                            port map(d => sched_dispatch_ready_bits(i),
                                     q => sched_read_sel(i),
                                     valid => sched_read_sel_valid(i));
    end generate;

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
                sched_entries <= (others => (others => '0'));
            else
                if (write_en = '1') then
                    sched_entries(to_integer(unsigned(sched_sel_write_1))) <= in_port_0.operation_type & 
                                                                        in_port_0.operation_select & 
                                                                        in_port_0.src_tag_1 & 
                                                                        rs1_src_tag_1_v &
                                                                        in_port_0.src_tag_2 & 
                                                                        rs1_src_tag_2_v &
                                                                        in_port_0.dest_tag & 
                                                                        in_port_0.store_queue_tag &
                                                                        in_port_0.load_queue_tag & 
                                                                        in_port_0.immediate & '1';
                end if;

                for i in 0 to OUTPUT_PORT_COUNT - 1 loop
                    if (dispatch_en(i) = '1' and sched_read_sel_valid(i) = '1') then
                        sched_entries(to_integer(unsigned(sched_read_sel(i))))(0) <= '0';
                    end if;
                end loop;

                for i in 0 to SCHEDULER_ENTRIES - 1 loop
                    if (sched_entries(i)(OPERAND_TAG_1_START downto OPERAND_TAG_1_END) = cdb.tag and
                        sched_entries(i)(0) = '1' and sched_entries(i)(OPERAND_TAG_1_VALID) = '0') then
                        sched_entries(i)(OPERAND_TAG_1_VALID) <= '1';
                    end if;
                    
                    if (sched_entries(i)(OPERAND_TAG_2_START downto OPERAND_TAG_2_END) = cdb.tag and
                        sched_entries(i)(0) = '1' and sched_entries(i)(OPERAND_TAG_2_VALID) = '0') then
                        sched_entries(i)(OPERAND_TAG_2_VALID) <= '1';
                    end if;
                end loop;
            end if;
        end if;
    end process;
    
    -- Puts the selected entry onto one exit port of the reservation station
    reservation_station_dispatch_proc : process(sched_entries, sched_read_sel)
    begin
        out_port_0.operation_type <= sched_entries(to_integer(unsigned(sched_read_sel(0))))(OPERATION_TYPE_START downto OPERATION_TYPE_END);
        out_port_0.operation_sel <= sched_entries(to_integer(unsigned(sched_read_sel(0))))(OPERATION_SELECT_START downto OPERATION_SELECT_END);
        out_port_0.src_tag_1 <= sched_entries(to_integer(unsigned(sched_read_sel(0))))(OPERAND_TAG_1_START downto OPERAND_TAG_1_END);
        out_port_0.src_tag_2 <= sched_entries(to_integer(unsigned(sched_read_sel(0))))(OPERAND_TAG_2_START downto OPERAND_TAG_2_END);
        out_port_0.immediate <= sched_entries(to_integer(unsigned(sched_read_sel(0))))(IMMEDIATE_START downto IMMEDIATE_END);
        out_port_0.store_queue_tag <= sched_entries(to_integer(unsigned(sched_read_sel(0))))(STORE_QUEUE_TAG_START downto STORE_QUEUE_TAG_END);
        out_port_0.load_queue_tag <= sched_entries(to_integer(unsigned(sched_read_sel(0))))(LOAD_QUEUE_TAG_START downto LOAD_QUEUE_TAG_END);
        out_port_0.dest_tag <= sched_entries(to_integer(unsigned(sched_read_sel(0))))(DEST_TAG_START downto DEST_TAG_END);
        out_port_0.valid <= dispatch_en(0) and sched_read_sel_valid(0);
        
        out_port_1.operation_type <= sched_entries(to_integer(unsigned(sched_read_sel(1))))(OPERATION_TYPE_START downto OPERATION_TYPE_END);
        out_port_1.operation_sel <= sched_entries(to_integer(unsigned(sched_read_sel(1))))(OPERATION_SELECT_START downto OPERATION_SELECT_END);
        out_port_1.src_tag_1 <= sched_entries(to_integer(unsigned(sched_read_sel(1))))(OPERAND_TAG_1_START downto OPERAND_TAG_1_END);
        out_port_1.src_tag_2 <= sched_entries(to_integer(unsigned(sched_read_sel(1))))(OPERAND_TAG_2_START downto OPERAND_TAG_2_END);
        out_port_1.immediate <= sched_entries(to_integer(unsigned(sched_read_sel(1))))(IMMEDIATE_START downto IMMEDIATE_END);
        out_port_1.store_queue_tag <= sched_entries(to_integer(unsigned(sched_read_sel(1))))(STORE_QUEUE_TAG_START downto STORE_QUEUE_TAG_END);
        out_port_1.load_queue_tag <= sched_entries(to_integer(unsigned(sched_read_sel(1))))(LOAD_QUEUE_TAG_START downto LOAD_QUEUE_TAG_END);
        out_port_1.dest_tag <= sched_entries(to_integer(unsigned(sched_read_sel(1))))(DEST_TAG_START downto DEST_TAG_END);
        out_port_1.valid <= dispatch_en(1) and sched_read_sel_valid(1);
    end process;
end rtl;












