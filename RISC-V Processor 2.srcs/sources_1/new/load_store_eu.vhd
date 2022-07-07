library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_FU.ALL;
use WORK.PKG_AXI.ALL;

-- Note: Addresses are tagged with QUEUE entry numbers. Data entries in the store queue are tagged with the physical register tag.
-- Ready bit in LQ might be unnecessary
-- Potential problem: What if another data comes in before the current one has been written into the register file?

entity load_store_eu is
    generic(
        SQ_ENTRIES : integer;
        LQ_ENTRIES : integer  
    );
    port(
        -- Instruction tags
        instr_tag : in std_logic_vector(INSTR_TAG_BITS - 1 downto 0);
    
        -- Address generation results bus
        generated_address : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        sq_calc_addr_tag : in std_logic_vector(integer(ceil(log2(real(SQ_ENTRIES)))) - 1 downto 0);
        sq_calc_addr_valid : in std_logic;
        lq_calc_addr_tag : in std_logic_vector(integer(ceil(log2(real(LQ_ENTRIES)))) - 1 downto 0); 
        lq_calc_addr_valid : in std_logic;
        
        -- Store data fetch results bus
        sq_store_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        sq_store_data_tag : in std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        sq_store_data_valid : in std_logic;
        
        -- Tag of the next entry that will be allocated
        sq_alloc_tag : out std_logic_vector(integer(ceil(log2(real(SQ_ENTRIES)))) - 1 downto 0);
        lq_alloc_tag : out std_logic_vector(integer(ceil(log2(real(LQ_ENTRIES)))) - 1 downto 0);
        
        sq_data_tag : in std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);       
        lq_dest_tag : in std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        
        sq_full : out std_logic;
        lq_full : out std_logic;
        
        sq_enqueue_en : in std_logic;
        
        -- Tag of the instruction that has been retired in this cycle
        sq_retire_tag : in std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);
        sq_retire_tag_valid : in std_logic;
        
        lq_enqueue_en : in std_logic;

        cdb : out cdb_type;
        cdb_request : out std_logic;
        cdb_granted : in std_logic;
        
        -- TEMPORARY BUS STUFF
        bus_addr_read : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        bus_addr_write : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        bus_data_read : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        bus_data_write : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        bus_stbr : out std_logic;
        bus_stbw : out std_logic;
        bus_ackr : in std_logic;
        bus_ackw : in std_logic;

        reset : in std_logic;
        clk : in std_logic
    );
end load_store_eu;

architecture rtl of load_store_eu is
    constant DATA_TAG_BITS : integer := PHYS_REGFILE_ADDR_BITS;

    constant SQ_TAG_BITS : integer := integer(ceil(log2(real(SQ_ENTRIES))));
    constant LQ_TAG_BITS : integer := integer(ceil(log2(real(LQ_ENTRIES))));
    constant SQ_ENTRY_BITS : integer := CPU_ADDR_WIDTH_BITS + PHYS_REGFILE_ADDR_BITS + CPU_DATA_WIDTH_BITS + 4;
    constant LQ_ENTRY_BITS : integer := CPU_ADDR_WIDTH_BITS + DATA_TAG_BITS + SQ_ENTRIES + INSTR_TAG_BITS + 4;

    -- SQ ENTRY INDEXES
    constant SQ_ADDR_VALID : integer := SQ_ENTRY_BITS - 1;
    constant SQ_ADDR_START : integer := SQ_ENTRY_BITS - 2;
    constant SQ_ADDR_END : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - 1;
    constant SQ_DATA_TAG_START : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - 2;
    constant SQ_DATA_TAG_END : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - 1;
    constant SQ_DATA_VALID : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - 2;
    constant SQ_DATA_START : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - 3;
    constant SQ_DATA_END : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - CPU_DATA_WIDTH_BITS - 2;
    constant SQ_RETIRED_BIT : integer := 1;
    constant SQ_FINISHED_BIT : integer := 0;
    
    -- LQ ENTRY INDEXES
    constant LQ_ADDR_VALID : integer := LQ_ENTRY_BITS - 1;
    constant LQ_ADDR_START : integer := LQ_ENTRY_BITS - 2;
    constant LQ_ADDR_END : integer := LQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - 1;
    constant LQ_DATA_TAG_START : integer := LQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - 2;
    constant LQ_DATA_TAG_END : integer := LQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - 1;
    constant LQ_STQ_MASK_START : integer := LQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - 2;
    constant LQ_STQ_MASK_END : integer := LQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - SQ_ENTRIES - 1;
    constant LQ_INSTR_TAG_START : integer := LQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - SQ_ENTRIES - 2;
    constant LQ_INSTR_TAG_END : integer := LQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - SQ_ENTRIES - INSTR_TAG_BITS - 1;
    constant LQ_READY_BIT : integer := 2;
    constant LQ_EXECUTED_BIT : integer := 1;
    constant LQ_VALID_BIT : integer := 0;

    -- INITIALIZATION CONSTANTS
    constant SQ_ZERO_PART : std_logic_vector(SQ_ENTRY_BITS - 3 downto 0) := (others => '0');
    constant SQ_INIT : std_logic_vector(SQ_ENTRY_BITS - 1 downto 0) := SQ_ZERO_PART & "11";      -- Set starting value of retired bits of SQ entries to 1
    
    constant LQ_STQ_MASK_ZERO : std_logic_vector(SQ_ENTRIES - 1 downto 0) := (others => '0');

    type sq_type is array(SQ_ENTRIES - 1 downto 0) of std_logic_vector(SQ_ENTRY_BITS - 1 downto 0);     -- [ADDR VALID | ADDRESS | DATA SRC TAG | DATA VALID | DATA | RETIRED | FINISHED]
    type lq_type is array(LQ_ENTRIES - 1 downto 0) of std_logic_vector(LQ_ENTRY_BITS - 1 downto 0);     -- [ADDR VALID | ADDRESS | DATA DEST TAG | STQ MASK BITS | READY | EXECUTED | VALID]
    
    signal store_queue : sq_type;
    signal load_queue : lq_type;
    
    -- STORE QUEUE HEAD AND TAIL COUNTER REGISTERS
    signal sq_head_counter_reg : unsigned(SQ_TAG_BITS - 1 downto 0);
    signal sq_head_counter_next : unsigned(SQ_TAG_BITS - 1 downto 0);
    signal sq_tail_counter_reg : unsigned(SQ_TAG_BITS - 1 downto 0);
    signal sq_tail_counter_next : unsigned(SQ_TAG_BITS - 1 downto 0);
    
    -- LOAD QUEUE HEAD AND TAIL COUNTER REGISTERS
    signal lq_head_counter_reg : unsigned(LQ_TAG_BITS - 1 downto 0);
    signal lq_head_counter_next : unsigned(LQ_TAG_BITS - 1 downto 0);
    signal lq_tail_counter_reg : unsigned(LQ_TAG_BITS - 1 downto 0);
    signal lq_tail_counter_next : unsigned(LQ_TAG_BITS - 1 downto 0);
    
    -- LOAD QUEUE ENTRY ALLOCATION LOGIC
    signal lq_mask_bits : std_logic_vector(SQ_ENTRIES - 1 downto 0);
    
    -- CONTROL SIGNALS
    signal sq_finished_tag : std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);
    signal sq_finished_tag_valid : std_logic;
    
    signal sq_store_ready : std_logic;
    signal lq_ready_loads : std_logic_vector(LQ_ENTRIES - 1 downto 0);
    signal lq_load_ready : std_logic;
    signal lq_selected_index : std_logic_vector(LOAD_QUEUE_TAG_BITS - 1 downto 0);
    
    signal sq_dequeue_en : std_logic;
    signal lq_dequeue_en : std_logic;
    
    signal i_sq_full : std_logic;
    signal sq_empty : std_logic;
    
    signal i_lq_full : std_logic;
    signal lq_empty : std_logic;
    
    signal load_data_reg : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal load_data_reg_en : std_logic;
    
    signal load_active_tag_reg : std_logic_vector(LOAD_QUEUE_TAG_BITS - 1 downto 0);
    signal load_active_tag_reg_en : std_logic;
    
    
    --signal load_data : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    --signal load_dest_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    --signal load_data_valid : std_logic;
    
    -- STATE MACHINES
    type store_state_type is (STORE_IDLE,
                              STORE_BUSY,
                              STORE_FINALIZE);
                              
    signal store_state_reg : store_state_type;
    signal store_state_next : store_state_type;
                              
    type load_state_type is (LOAD_IDLE,
                             LOAD_BUSY,
                             LOAD_WRITEBACK,
                             LOAD_FINALIZE);
                             
    signal load_state_reg : load_state_type;
    signal load_state_next : load_state_type;
begin
    lq_select_ready_prioenc : entity work.priority_encoder(rtl)
                              generic map(NUM_INPUTS => LQ_ENTRIES,
                                          HIGHER_INPUT_HIGHER_PRIO => false)
                              port map(d => lq_ready_loads,
                                       q => lq_selected_index,
                                       valid => lq_load_ready);

    -- STATE MACHINES
    store_state_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                store_state_reg <= STORE_IDLE;
            else
                store_state_reg <= store_state_next;
            end if;
        end if;
    end process;

    store_next_state_proc : process(store_state_reg, sq_store_ready, bus_ackw)
    begin
        case store_state_reg is
            when STORE_IDLE => 
                if (sq_store_ready = '1') then
                    store_state_next <= STORE_BUSY;
                else
                    store_state_next <= STORE_IDLE;
                end if;
            when STORE_BUSY =>
                if (bus_ackw = '1') then
                    store_state_next <= STORE_FINALIZE;
                else
                    store_state_next <= STORE_BUSY;
                end if;
            when STORE_FINALIZE => 
                store_state_next <= STORE_IDLE;
        end case;
    end process;
    
    store_state_outputs_proc : process(store_state_reg)
    begin
        sq_finished_tag_valid <= '0';
        sq_dequeue_en <= '0';
        bus_stbw <= '0';
        case store_state_reg is
            when STORE_IDLE =>
            
            when STORE_BUSY => 
                bus_stbw <= '1';
            when STORE_FINALIZE => 
                sq_finished_tag_valid <= '1';
                sq_dequeue_en <= '1';
        end case;
    end process;

    load_next_state_proc : process(load_state_reg, lq_load_ready, bus_ackr, cdb_granted)
    begin
        case load_state_reg is
            when LOAD_IDLE => 
                if (lq_load_ready = '1') then
                    load_state_next <= LOAD_BUSY;
                else
                    load_state_next <= LOAD_IDLE;
                end if;
            when LOAD_BUSY =>
                if (bus_ackr = '1') then
                    load_state_next <= LOAD_WRITEBACK;
                else
                    load_state_next <= LOAD_BUSY;
                end if;
            when LOAD_WRITEBACK =>
                if (cdb_granted = '1') then
                    load_state_next <= LOAD_FINALIZE;
                else
                    load_state_next <= LOAD_IDLE;
                end if;
            when LOAD_FINALIZE => 
                load_state_next <= LOAD_IDLE;
        end case;
    end process;
    
    load_state_outputs_proc : process(load_state_reg)
    begin
        lq_dequeue_en <= '0';
        bus_stbr <= '0';
        load_active_tag_reg_en <= '0';
        cdb_request <= '0';
        cdb.valid <= '0';
        load_data_reg_en <= '0';
        case load_state_reg is
            when LOAD_IDLE => 
                load_active_tag_reg_en <= '1';
            when LOAD_BUSY => 
                bus_stbr <= '1';
                load_data_reg_en <= '1';
            when LOAD_WRITEBACK => 
                cdb_request <= '1';
                cdb.valid <= '1';
            when LOAD_FINALIZE =>
                lq_dequeue_en <= '1'; 
        end case;
    end process;
    
    load_state_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                load_state_reg <= LOAD_IDLE;
            else
                load_state_reg <= load_state_next;
            end if;
        end if;
    end process;

    load_in_exec_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                load_active_tag_reg <= (others => '0');
            else
                if (load_active_tag_reg_en = '1') then
                    load_active_tag_reg <= lq_selected_index;
                end if;
            end if;
        end if;
    end process;

    -- QUEUE CONTROL
    queue_control_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                store_queue <= (others => SQ_INIT);
                load_queue <= (others => (others => '0'));
            else
                if (sq_enqueue_en = '1' and i_sq_full = '0') then
                    store_queue(to_integer(sq_tail_counter_reg)) <= '0' &         
                                                                    ADDR_ZERO &   
                                                                    sq_data_tag & 
                                                                    '0' &         
                                                                    DATA_ZERO &
                                                                    '0' &
                                                                    '0';
                end if;
                
                if (lq_enqueue_en = '1' and i_lq_full = '0') then
                    load_queue(to_integer(lq_tail_counter_reg)) <= '0' &
                                                                   ADDR_ZERO &
                                                                   lq_dest_tag &
                                                                   lq_mask_bits &
                                                                   instr_tag & 
                                                                   '0' &
                                                                   '0' &
                                                                   '1';
                end if;
                
                if (sq_retire_tag_valid = '1') then
                    store_queue(to_integer(unsigned(sq_retire_tag)))(SQ_RETIRED_BIT) <= '1';
                end if;
                
                if (sq_dequeue_en = '1') then
                    store_queue(to_integer(sq_head_counter_reg))(SQ_FINISHED_BIT) <= '1';
                end if;
                
                if (bus_ackr = '1') then
                    load_queue(to_integer(unsigned(load_active_tag_reg)))(LQ_VALID_BIT) <= '0';
                end if;
                                                                   
                for i in 0 to SQ_ENTRIES - 1 loop
                    if (to_integer(unsigned(sq_calc_addr_tag)) = i and store_queue(i)(SQ_ADDR_VALID) = '0' and sq_calc_addr_valid = '1') then
                        store_queue(i)(SQ_ADDR_START downto SQ_ADDR_END) <= generated_address;
                        store_queue(i)(SQ_ADDR_VALID) <= '1';
                    end if;
                    
                    if (sq_store_data_tag = store_queue(i)(SQ_DATA_TAG_START downto SQ_DATA_TAG_END) and store_queue(i)(SQ_DATA_VALID) = '0' and sq_store_data_valid = '1') then
                        store_queue(i)(SQ_DATA_START downto SQ_DATA_END) <= sq_store_data;
                        store_queue(i)(SQ_DATA_VALID) <= '1';
                    end if;
                end loop;
                
                for i in 0 to LQ_ENTRIES - 1 loop
                    if (to_integer(unsigned(lq_calc_addr_tag)) = i and load_queue(i)(LQ_ADDR_VALID) = '0' and lq_calc_addr_valid = '1') then
                        load_queue(i)(LQ_ADDR_START downto LQ_ADDR_END) <= generated_address;
                        load_queue(i)(LQ_ADDR_VALID) <= '1';
                    end if;
                    
                    if (sq_finished_tag_valid = '1') then
                        load_queue(i)(to_integer(unsigned(sq_finished_tag)) + 3) <= '0';
                    end if;
                end loop;
            end if;
        end if;
    end process;
    
    load_ready_proc : process(load_queue)
    begin
        for i in 0 to LQ_ENTRIES - 1 loop
            if (load_queue(i)(LQ_STQ_MASK_START downto LQ_STQ_MASK_END) = LQ_STQ_MASK_ZERO and load_queue(i)(LQ_ADDR_VALID) = '1' and load_queue(i)(LQ_VALID_BIT) = '1') then
                lq_ready_loads(i) <= '1';
            else
                lq_ready_loads(i) <= '0';
            end if;
        end loop;
    end process;

    queue_counters_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                sq_head_counter_reg <= (others => '0');
                sq_tail_counter_reg <= (others => '0');
                
                lq_head_counter_reg <= (others => '0');
                lq_tail_counter_reg <= (others => '0');
                
                load_data_reg <= (others => '0');
            else
                if (sq_enqueue_en = '1' and i_sq_full = '0') then
                    sq_tail_counter_reg <= sq_tail_counter_next;
                end if;
                
                if (sq_dequeue_en = '1' and sq_empty = '0') then
                    sq_head_counter_reg <= sq_head_counter_next;
                end if;
                
                if (lq_enqueue_en = '1' and i_lq_full = '0') then
                    lq_tail_counter_reg <= lq_tail_counter_next;
                end if;
                
                if (lq_dequeue_en = '1' and lq_empty = '0') then
                    lq_head_counter_reg <= lq_head_counter_next;
                end if;
                
                if (load_data_reg_en = '1') then
                    load_data_reg <= bus_data_read;
                end if;
            end if;
        end if;
    end process;
    
    sq_head_counter_next <= (others => '0') when sq_head_counter_reg = SQ_ENTRIES - 1 else
                            sq_head_counter_reg + 1;
    sq_tail_counter_next <= (others => '0') when sq_tail_counter_reg = SQ_ENTRIES - 1 else
                            sq_tail_counter_reg + 1;
    lq_head_counter_next <= (others => '0') when lq_head_counter_reg = LQ_ENTRIES - 1 else
                            lq_head_counter_reg + 1;
    lq_tail_counter_next <= (others => '0') when lq_tail_counter_reg = LQ_ENTRIES - 1 else
                            lq_tail_counter_reg + 1;
              
    -- ============================ LOAD INSTRUCTION ALLOCATION LOGIC ============================
    process(lq_enqueue_en, store_queue)
    begin
        if (lq_enqueue_en = '1') then
            for i in 0 to SQ_ENTRIES - 1 loop
                lq_mask_bits(i) <= not store_queue(i)(0);
            end loop;
        else
            lq_mask_bits <= (others => '0');
        end if;
    end process;
    
    -- ===========================================================================================
    sq_finished_tag <= std_logic_vector(sq_head_counter_reg);                 
    -- A store instruction can issue a write to memory when the address is valid, data is valid AND it has been retired in the ROB
    sq_store_ready <= '1' when store_queue(to_integer(sq_head_counter_reg))(SQ_ADDR_VALID) = '1' and 
                               store_queue(to_integer(sq_head_counter_reg))(SQ_DATA_VALID) = '1' and 
                               store_queue(to_integer(sq_head_counter_reg))(SQ_RETIRED_BIT) = '1' else '0';
                            
    i_sq_full <= '1' when sq_tail_counter_next = sq_head_counter_reg else '0';
    i_lq_full <= '1' when lq_tail_counter_next = lq_head_counter_reg else '0';
    
    sq_empty <= '1' when sq_head_counter_reg = sq_tail_counter_reg else '0';
    lq_empty <= '1' when lq_head_counter_reg = lq_tail_counter_reg else '0';
    
    sq_full <= i_sq_full;
    lq_full <= i_lq_full;
    
    sq_alloc_tag <= std_logic_vector(sq_tail_counter_reg);
    lq_alloc_tag <= std_logic_vector(lq_tail_counter_reg);
                 
    cdb.data <= load_data_reg;
    cdb.phys_dest_reg <= load_queue(to_integer(unsigned(load_active_tag_reg)))(LQ_DATA_TAG_START downto LQ_DATA_TAG_END);
    cdb.instr_tag <= load_queue(to_integer(unsigned(load_active_tag_reg)))(LQ_INSTR_TAG_START downto LQ_INSTR_TAG_END);
                            
    bus_addr_write <= store_queue(to_integer(sq_head_counter_reg))(SQ_ADDR_START downto SQ_ADDR_END);
    bus_addr_read <= load_queue(to_integer(unsigned(load_active_tag_reg)))(LQ_ADDR_START downto LQ_ADDR_END);
    bus_data_write <= store_queue(to_integer(sq_head_counter_reg))(SQ_DATA_START downto SQ_DATA_END);
    
end rtl;














