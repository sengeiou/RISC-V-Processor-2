library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_FU.ALL;
use WORK.PKG_AXI.ALL;

-- Potential problem: When pipeline registers 2 and 3 have valid data in them and this unit is stalled due to a read or write operation
-- pipeline register 3 could cause the execution to stall (or worse) due to requesting the CDB.

-- Note: Addresses are tagged with QUEUE entry numbers. Data entries in the store queue are tagged with the SQ entry number.

entity load_store_eu is
    generic(
        SQ_ENTRIES : integer;
        LQ_ENTRIES : integer  
    );
    port(
        to_master_interface : out ToMasterInterface; 
        from_master_interface : in FromMasterInterface; 
    
        -- Address generation results bus
        sq_calc_addr : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        sq_calc_addr_tag : in std_logic_vector(integer(ceil(log2(real(SQ_ENTRIES)))) - 1 downto 0);
        sq_calc_addr_valid : in std_logic;
        lq_calc_addr : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0); 
        lq_calc_addr_tag : in std_logic_vector(integer(ceil(log2(real(LQ_ENTRIES)))) - 1 downto 0); 
        lq_calc_addr_valid : in std_logic;
        
        -- Store data fetch results bus
        sq_store_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        sq_store_data_tag : in std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        sq_store_data_valid : in std_logic;
        
        -- Tag of a newly allocated queue entry
        sq_alloc_tag : out std_logic_vector(integer(ceil(log2(real(SQ_ENTRIES)))) - 1 downto 0);
        lq_alloc_tag : out std_logic_vector(integer(ceil(log2(real(LQ_ENTRIES)))) - 1 downto 0);
        
        sq_data_tag : in std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);       
        lq_dest_tag : in std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        
        sq_enqueue_en : in std_logic;
        
        sq_retire_tag : in std_logic_vector(STORE_QUEUE_TAG_BITS - 1 downto 0);
        sq_retire_tag_valid : in std_logic;
        
        lq_enqueue_en : in std_logic;
        lq_dequeue_en : in std_logic;

        cdb : out cdb_type;
        cdb_request : out std_logic;
        cdb_granted : in std_logic;

        reset : in std_logic;
        clk : in std_logic
    );
end load_store_eu;

architecture rtl of load_store_eu is
    constant DATA_TAG_BITS : integer := PHYS_REGFILE_ADDR_BITS;

    constant SQ_TAG_BITS : integer := integer(ceil(log2(real(SQ_ENTRIES))));
    constant LQ_TAG_BITS : integer := integer(ceil(log2(real(LQ_ENTRIES))));
    constant SQ_ENTRY_BITS : integer := CPU_ADDR_WIDTH_BITS + PHYS_REGFILE_ADDR_BITS + CPU_DATA_WIDTH_BITS + 3;
    constant LQ_ENTRY_BITS : integer := CPU_ADDR_WIDTH_BITS + DATA_TAG_BITS + 1;

    -- SQ ENTRY INDEXES
    constant SQ_ADDR_VALID : integer := SQ_ENTRY_BITS - 1;
    constant SQ_ADDR_START : integer := SQ_ENTRY_BITS - 2;
    constant SQ_ADDR_END : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - 1;
    constant SQ_DATA_TAG_START : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - 2;
    constant SQ_DATA_TAG_END : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - 1;
    constant SQ_DATA_VALID : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - 2;
    constant SQ_DATA_START : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - 3;
    constant SQ_DATA_END : integer := SQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - CPU_DATA_WIDTH_BITS - 2;
    constant SQ_RETIRED_BIT : integer := 0;
    
    -- LQ ENTRY INDEXES
    constant LQ_ADDR_VALID : integer := LQ_ENTRY_BITS - 1;
    constant LQ_ADDR_START : integer := LQ_ENTRY_BITS - 2;
    constant LQ_ADDR_END : integer := LQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - 1;
    constant LQ_DATA_TAG_START : integer := LQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - 2;
    constant LQ_DATA_TAG_END : integer := LQ_ENTRY_BITS - CPU_ADDR_WIDTH_BITS - DATA_TAG_BITS - 1;

    type sq_type is array(SQ_ENTRIES - 1 downto 0) of std_logic_vector(SQ_ENTRY_BITS - 1 downto 0);     -- [ADDR VALID | ADDRESS | DATA SRC TAG | DATA VALID | DATA | RETIRED]
    type lq_type is array(LQ_ENTRIES - 1 downto 0) of std_logic_vector(LQ_ENTRY_BITS - 1 downto 0);     -- [ADDR VALID | ADDRESS | DATA DEST TAG]
    
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
    
    -- CONTROL SIGNALS
    signal sq_store_ready : std_logic;
    signal lq_load_ready : std_logic;
    
    signal sq_dequeue_en : std_logic;
    
    signal sq_full : std_logic;
    signal sq_empty : std_logic;
    
    signal lq_full : std_logic;
    signal lq_empty : std_logic;
    
    signal execute_store : std_logic;
    
    -- STATE MACHINES
    type store_state_type is (STORE_IDLE,
                              STORE_BUSY,
                              STORE_FINALIZE);
                              
    signal store_state_reg : store_state_type;
    signal store_state_next : store_state_type;
                              
    type load_state_type is (LOAD_IDLE,
                             LOAD_BUSY,
                             LOAD_FINALIZE);
                             
    signal load_state_reg : load_state_type;
    signal load_state_next : load_state_type;
begin
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

    store_next_state_proc : process(store_state_reg, sq_store_ready, from_master_interface)
    begin
        case store_state_reg is
            when STORE_IDLE => 
                if (sq_store_ready = '1') then
                    store_state_next <= STORE_BUSY;
                else
                    store_state_next <= STORE_IDLE;
                end if;
            when STORE_BUSY =>
                if (from_master_interface.done_write = '1') then
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
        sq_dequeue_en <= '0';
        case store_state_reg is
            when STORE_IDLE =>
                execute_store <= '0';
            when STORE_BUSY => 
                execute_store <= '1';
            when STORE_FINALIZE => 
                execute_store <= '0';
                sq_dequeue_en <= '1';
        end case;
    end process;

    -- QUEUE CONTROL
    queue_control_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                store_queue <= (others => (others => '0'));
                load_queue <= (others => (others => '0'));
            else
                if (sq_enqueue_en = '1' and sq_full = '0') then
                    store_queue(to_integer(sq_tail_counter_reg)) <= '0' &         
                                                                    ADDR_ZERO &   
                                                                    sq_data_tag & 
                                                                    '0' &         
                                                                    DATA_ZERO &
                                                                    '0';
                end if;
                
                if (lq_enqueue_en = '1' and lq_full = '0') then
                    load_queue(to_integer(lq_tail_counter_reg)) <= '0' &
                                                                   ADDR_ZERO &
                                                                   lq_dest_tag;
                end if;
                
                if (sq_retire_tag_valid = '1') then
                    store_queue(to_integer(unsigned(sq_retire_tag)))(SQ_RETIRED_BIT) <= '1';
                end if;
                                                                   
                for i in 0 to SQ_ENTRIES - 1 loop
                    if (to_integer(unsigned(sq_calc_addr_tag)) = i and store_queue(i)(SQ_ADDR_VALID) = '0' and sq_calc_addr_valid = '1') then
                        store_queue(i)(SQ_ADDR_START downto SQ_ADDR_END) <= sq_calc_addr;
                        store_queue(i)(SQ_ADDR_VALID) <= '1';
                    end if;
                    
                    if (sq_store_data_tag = store_queue(i)(SQ_DATA_TAG_START downto SQ_DATA_TAG_END) and store_queue(i)(SQ_DATA_VALID) = '0' and sq_store_data_valid = '1') then
                        store_queue(i)(SQ_DATA_START downto SQ_DATA_END) <= sq_store_data;
                        store_queue(i)(SQ_DATA_VALID) <= '1';
                    end if;
                end loop;
                
                for i in 0 to LQ_ENTRIES - 1 loop
                    if (to_integer(unsigned(lq_calc_addr_tag)) = i and load_queue(i)(LQ_ADDR_VALID) = '0' and lq_calc_addr_valid = '1') then
                        load_queue(i)(LQ_ADDR_START downto LQ_ADDR_END) <= lq_calc_addr;
                        load_queue(i)(LQ_ADDR_VALID) <= '1';
                    end if;
                end loop;
            end if;
        end if;
    end process;

    queue_counters_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                sq_head_counter_reg <= (others => '0');
                sq_tail_counter_reg <= (others => '0');
                
                lq_head_counter_reg <= (others => '0');
                lq_tail_counter_reg <= (others => '0');
            else
                if (sq_enqueue_en = '1' and sq_full = '0') then
                    sq_tail_counter_reg <= sq_tail_counter_next;
                end if;
                
                if (sq_dequeue_en = '1' and sq_empty = '0') then
                    sq_head_counter_reg <= sq_head_counter_next;
                end if;
                
                if (lq_enqueue_en = '1' and lq_full = '0') then
                    lq_tail_counter_reg <= lq_tail_counter_next;
                end if;
                
                if (lq_dequeue_en = '1' and lq_empty = '0') then
                    lq_head_counter_reg <= lq_head_counter_next;
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
                            lq_head_counter_reg + 1;
                       
    -- A store instruction can issue a write to memory when the address is valid, data is valid AND it has been retired in the ROB
    sq_store_ready <= '1' when store_queue(to_integer(sq_head_counter_reg))(SQ_ADDR_VALID) = '1' and 
                               store_queue(to_integer(sq_head_counter_reg))(SQ_DATA_VALID) = '1' and 
                               store_queue(to_integer(sq_head_counter_reg))(SQ_RETIRED_BIT) = '1' else '0';
                               
    lq_load_ready <= '1' when load_queue(to_integer(lq_head_counter_reg))(LQ_ADDR_VALID) = '1' else '0';
                            
    sq_full <= '1' when sq_tail_counter_next = sq_head_counter_reg else '0';
    lq_full <= '1' when lq_tail_counter_next = lq_head_counter_reg else '0';
    
    sq_empty <= '1' when sq_head_counter_reg = sq_tail_counter_reg else '0';
    lq_empty <= '1' when lq_head_counter_reg = lq_tail_counter_reg else '0';
    
    sq_alloc_tag <= std_logic_vector(sq_tail_counter_reg);
    lq_alloc_tag <= std_logic_vector(lq_tail_counter_reg);
                            
    to_master_interface.data_write <= store_queue(to_integer(sq_head_counter_reg))(SQ_DATA_START downto SQ_DATA_END);
    to_master_interface.addr_write <= store_queue(to_integer(sq_head_counter_reg))(SQ_ADDR_START downto SQ_ADDR_END);
    to_master_interface.addr_read <= (others => '0');
    to_master_interface.burst_len <= (others => '0');
    to_master_interface.burst_size <= (others => '0');
    to_master_interface.burst_type <= (others => '0');
    to_master_interface.execute_read <= '0';
    to_master_interface.execute_write <= execute_store;
    
end rtl;














