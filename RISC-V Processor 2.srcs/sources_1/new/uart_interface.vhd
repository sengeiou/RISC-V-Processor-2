library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- TO DO
-- 1) Add resynchronization on every non spurious data line change
-- 2) Add options to change number of data bits per transfer
-- 3) Add parity bit options
-- 4) Add number of end bits options
--

entity uart_interface is
    port(
        addr_read_bus : in std_logic_vector(2 downto 0);
        addr_write_bus : in std_logic_vector(2 downto 0);
        
        data_write_bus : in std_logic_vector(7 downto 0);
        data_read_bus : out std_logic_vector(7 downto 0);
        
        tx : out std_logic;
        rx : in std_logic;
        
        rts : out std_logic;
        cts : in std_logic;
        dtr : out std_logic;
        dsr : in std_logic;
        
        cs : in std_logic;
        reset : in std_logic;
        clk : in std_logic
    );
end uart_interface;

architecture rtl of uart_interface is
    -- =============================================================
    --                TX DATA REGISTERS & CONTROL
    -- =============================================================

    
    signal tx_data_reg : std_logic_vector(7 downto 0);
    signal tx_data_reg_en : std_logic;
    signal tx_data_reg_next : std_logic_vector(7 downto 0);
    
    signal tx_data_shift_reg : std_logic_vector(7 downto 0);
    signal tx_data_shift_reg_shift_en : std_logic;
    signal tx_data_shift_reg_write_en : std_logic;
    
    signal tx_bits_transfered_counter : unsigned(3 downto 0);
    signal tx_bits_transfered_counter_en : std_logic;
    signal tx_bits_transfered_counter_fill_en : std_logic;
    
    signal tx_data_reg_state_set : std_logic;
    signal tx_data_reg_state_reset : std_logic;
    
    -- =============================================================
    --                RX DATA REGISTERS & CONTROL
    -- =============================================================
    signal rx_data_reg : std_logic_vector(7 downto 0);
    signal rx_data_reg_en : std_logic;
    
    signal rx_data_shift_reg : std_logic_vector(7 downto 0);
    signal rx_data_shift_reg_shift_en : std_logic;
    
    signal rx_sampler_counter_reg : std_logic_vector(3 downto 0);
    signal rx_sampler_counter_fill : std_logic_vector(3 downto 0);
    signal rx_sampler_counter_reg_count_en : std_logic;
    signal rx_sampler_counter_reg_fill_en : std_logic;
    
    signal rx_bits_received_counter_reg : std_logic_vector(3 downto 0);
    signal rx_bits_received_counter_fill : std_logic_vector(3 downto 0);
    signal rx_bits_received_counter_reg_count_en : std_logic;
    signal rx_bits_received_counter_reg_fill_en : std_logic;

    -- =============================================================
    --                  UART 16550 REGISTER SET
    -- =============================================================
    signal divisor_latch_ls : std_logic_vector(7 downto 0);     -- Lower 8 bits of the divisor
    signal divisor_latch_ms : std_logic_vector(7 downto 0);     -- Upper 8 bits of the divisor
    signal divisor_updated : std_logic;
    
    signal line_control_reg : std_logic_vector(7 downto 0);     
     
    signal line_status_reg : std_logic_vector(7 downto 0);      -- 0 -> Transmitter data hold reg. empty (1 - yes, 0 - no) | 1 -> Line used (1 - yes, 0 - no)
    signal line_status_reg_en : std_logic;
    
    signal modem_control_reg : std_logic_vector(7 downto 0);
    signal modem_control_reg_en : std_logic;
    
    -- ============================================================= 
    --              BAUD RATE GENERATION REGISTERS
    -- =============================================================
    signal baud_rate_gen_x16_counter_reg : std_logic_vector(15 downto 0);
    signal baud_rate_x16_tick : std_logic;
    
    signal baud_rate_gen_counter_reg : std_logic_vector(3 downto 0);
    signal baud_rate_counter_zero : std_logic;
    signal baud_rate_counter_zero_delay : std_logic;
    signal baud_rate_tick : std_logic;
    signal baud_rate_tick_happened : std_logic;
    
    
    signal divisor_latch_full : std_logic_vector(15 downto 0);
    
    type transmitter_state_type is (IDLE,
                                    INIT_TRANSMISSION,
                                    START_BIT,
                                    DATA_TRANSFER,
                                    END_BIT);
                                    
    type receiver_state_type is (IDLE,
                                 INIT_RECEIVE,
                                 START_BIT,
                                 START_VALID,
                                 DATA_TRANSFER,
                                 END_BIT);
                                    
    signal transmitter_state : transmitter_state_type;
    signal transmitter_state_next : transmitter_state_type;
    
    signal receiver_state : receiver_state_type;
    signal receiver_state_next : receiver_state_type;
begin

    -- =================== RX CONTROL ===================
    divisor_latch_full <= divisor_latch_ms & divisor_latch_ls;

    baud_rate_gen_x16_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                baud_rate_gen_x16_counter_reg <= (others => '0');
            elsif (baud_rate_x16_tick = '1' or divisor_updated = '1') then
                baud_rate_gen_x16_counter_reg <= divisor_latch_full;
            else
                baud_rate_gen_x16_counter_reg <= std_logic_vector(unsigned(baud_rate_gen_x16_counter_reg) - 1);
            end if;
        end if;
    end process;
    
    baud_rate_x16_tick <= '1' when baud_rate_gen_x16_counter_reg = X"0000" else
                                          '0';

    baud_rate_gen_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                baud_rate_gen_counter_reg <= (others => '0');
            elsif (baud_rate_x16_tick = '1') then
                baud_rate_gen_counter_reg <= std_logic_vector(unsigned(baud_rate_gen_counter_reg) - 1);
            end if;
        end if;
    end process;
    
    baud_rate_counter_zero <= '1' when baud_rate_gen_counter_reg = X"0" else
                              '0';
    
    baud_rate_cnt_zero_delay : process(clk)
    begin
        if (rising_edge(clk)) then
            baud_rate_counter_zero_delay <= baud_rate_counter_zero;
        end if;
    end process;
    
    baud_rate_tick <= baud_rate_counter_zero and (not baud_rate_counter_zero_delay);
    
-- =================== LINE STATUS REGISTER LOGIC ===================
    tx_data_reg_state_set <= '0';

    line_status_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                line_status_reg <= "00000001";
            elsif (line_status_reg_en = '1') then
                line_status_reg(7 downto 1) <= line_status_reg(7 downto 1);
                
                
                line_status_reg(0) <= (line_status_reg(0) and not tx_data_reg_state_reset) or tx_data_reg_state_set;
            end if;
        end if;
    end process;
    
    transmitter_data_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                tx_data_reg <= (others => '0');
            elsif (tx_data_reg_en = '1') then
                tx_data_reg <= tx_data_reg_next;
            end if;
        end if;
    end process;

    register_write_control : process(all)
    begin    
        if (rising_edge(clk)) then
            data_read_bus <= (others => '0');
            tx_data_reg_next <= (others => '0');
            modem_control_reg <= (others => '0');
                    
            tx_data_reg_state_reset <= '0';    
            line_status_reg_en <= '0';
            tx_data_reg_en <= '0';
            modem_control_reg_en <= '0'; 
            divisor_updated <= '0';
        
            if (reset = '1') then
                line_control_reg <= (others => '0');
                
                divisor_latch_ls <= (others => '1');
                divisor_latch_ms <= (others => '1');
            elsif (cs = '1') then                  -- ALLOCATED ADDRESSES ARE TEMPORARY AND DO NOT CORRESPOND TO THE 16550 UART IC!!!
                case addr_write_bus is
                    when "001" =>
                        tx_data_reg_next <= data_write_bus;
                        tx_data_reg_en <= '1';
                                
                        tx_data_reg_state_reset <= '1';
                               
                        line_status_reg_en <= '1';
                    when "100" =>       -- MODEM CONTROL REGISTER
                        modem_control_reg <= data_write_bus;
                    when "110" =>
                        divisor_latch_ls <= data_write_bus;
                        divisor_updated <= '1';
                    when "111" =>
                        divisor_latch_ms <= data_write_bus;
                        divisor_updated <= '1';
                    when others =>
                        
                end case;
            end if;
        end if;
    end process;
    
    register_read_control : process(clk)
    begin
        if (rising_edge(clk)) then
            if (cs = '1') then                  -- ALLOCATED ADDRESSES ARE TEMPORARY AND DO NOT CORRESPOND TO THE 16550 UART IC!!!
                case addr_read_bus is 
                    when "000" =>
                        data_read_bus <= rx_data_reg;
                    when "001" =>
                        data_read_bus <= (others => '0');
                    when "010" =>
                        data_read_bus <= line_status_reg;
                    when "100" =>
                        data_read_bus <= (others => '0');
                    when "110" =>
                        data_read_bus <= divisor_latch_ls;
                    when "111" =>
                        data_read_bus <= data_write_bus;
                    when others =>
                        data_read_bus <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    
    transmitter_bits_transfered_counter_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                tx_bits_transfered_counter <= (others => '0');
            else
                if (tx_bits_transfered_counter_fill_en = '1') then
                    tx_bits_transfered_counter <= "0111";      -- 8 BITS FOR NOW
                elsif (tx_bits_transfered_counter_en = '1') then
                    tx_bits_transfered_counter <= tx_bits_transfered_counter - 1;
                end if;
            end if;
        end if;
    end process;
    
    transmitter_data_shift_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                tx_data_shift_reg <= (others => '0');
            else
                if (tx_data_shift_reg_write_en = '1') then
                    tx_data_shift_reg <= tx_data_reg;
                elsif (tx_data_shift_reg_shift_en = '1') then
                    tx_data_shift_reg <= std_logic_vector(shift_right(unsigned(tx_data_shift_reg), 1));
                end if;
            end if;
        end if;
    end process;
    
    -- ==================== TRANSMITTER STATE MACHINE CONTROL ====================
    transmitter_state_reg_update : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                transmitter_state <= IDLE;
            else
                transmitter_state <= transmitter_state_next;
            end if;
        end if;
    end process;
    
    transmitter_next_state : process(all)
    begin
        case transmitter_state is
            when IDLE => 
                if (modem_control_reg(1) = '1') then
                    transmitter_state_next <= INIT_TRANSMISSION;
                else
                    transmitter_state_next <= IDLE;
                end if;
            when INIT_TRANSMISSION =>
                if (cts = '0' and baud_rate_tick = '1') then
                    transmitter_state_next <= START_BIT;
                else
                    transmitter_state_next <= INIT_TRANSMISSION;
                end if;
            when START_BIT =>
                transmitter_state_next <= DATA_TRANSFER when baud_rate_tick = '1' else
                                          START_BIT;
            when DATA_TRANSFER =>
                if (tx_bits_transfered_counter = 0 and baud_rate_tick = '1') then
                    transmitter_state_next <= END_BIT;
                else
                    transmitter_state_next <= DATA_TRANSFER;
                end if;
            when END_BIT =>
                transmitter_state_next <= IDLE when baud_rate_tick = '1' else
                                          END_BIT;
            when others =>
                transmitter_state_next <= IDLE;
        end case;
    end process;
    
    transmitter_state_machine_outputs : process(all)
    begin
        tx_data_shift_reg_write_en <= '0';
        tx_data_shift_reg_shift_en <= '0';
        
        tx_bits_transfered_counter_fill_en <= '0';
        tx_bits_transfered_counter_en <= '0';
        
        rts <= '1';
        case transmitter_state is
            when IDLE =>
                tx <= '1';
            when INIT_TRANSMISSION => 
                rts <= '0';
            when START_BIT => 
                tx <= '0';
                
                tx_data_shift_reg_write_en <= '1';
                tx_bits_transfered_counter_fill_en <= '1';
            when DATA_TRANSFER =>
                tx <= tx_data_shift_reg(0);
                
                tx_data_shift_reg_shift_en <= baud_rate_tick;
                tx_bits_transfered_counter_en <= baud_rate_tick;
            when END_BIT =>
                tx <= '1';
            when others =>
                tx <= '1';
        end case;
    end process;
    
    -- =================== RECEIVER DATA REG ===================
    receiver_data_reg_update : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                rx_data_reg <= (others => '0');
            else
                if (rx_data_reg_en = '1') then
                    rx_data_reg <= rx_data_shift_reg;
                end if;
            end if;
        end if;
    end process;
    
    -- =================== RECEIVER SAMPLER COUNTER REG ===================
    receiver_sampler_reg_update : process(clk)
    begin  
        if (rising_edge(clk)) then
            if (reset = '1') then
                rx_sampler_counter_reg <= (others => '0');
            elsif (rx_sampler_counter_reg_fill_en = '1') then
                rx_sampler_counter_reg <= rx_sampler_counter_fill;
            elsif (rx_sampler_counter_reg_count_en = '1' and baud_rate_x16_tick = '1') then
                rx_sampler_counter_reg <= std_logic_vector(unsigned(rx_sampler_counter_reg) - 1);
            end if;
        end if;
    end process;
    
    -- =================== RECEIVER SHIFT REGISTER CONTROL ===================
    receiver_shift_reg_update : process(clk)
    begin
        if (reset = '1') then
            rx_data_shift_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            if (rx_sampler_counter_reg = X"0" and baud_rate_x16_tick = '1') then
                rx_data_shift_reg(7 downto 1) <= rx_data_shift_reg(6 downto 0);
                rx_data_shift_reg(0) <= rx;
            end if;
        end if;
    end process;
    
    -- =================== RECEIVER STATE MACHINE CONTROL ===================
    receiver_state_reg_update : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                receiver_state <= IDLE;
            else
                receiver_state <= receiver_state_next when (baud_rate_x16_tick = '1' or receiver_state = IDLE);
            end if;
        end if;
    end process;
    
    receiver_bits_received_counter_reg_update : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                rx_bits_received_counter_reg <= (others => '0');
            elsif (rx_bits_received_counter_reg_fill_en = '1') then
                rx_bits_received_counter_reg <= rx_bits_received_counter_fill;
            elsif (rx_sampler_counter_reg = "0000" and baud_rate_x16_tick = '1') then
                rx_bits_received_counter_reg <= std_logic_vector(unsigned(rx_bits_received_counter_reg) - 1);
            end if;
        end if;
    end process;
    
    receiver_next_state : process(rx, rx_sampler_counter_reg, receiver_state, rx_bits_received_counter_reg, modem_control_reg)
    begin
        case receiver_state is 
            when IDLE => 
                if (modem_control_reg(0) = '1') then
                    receiver_state_next <= INIT_RECEIVE;
                else
                    receiver_state_next <= IDLE;
                end if;
            when INIT_RECEIVE =>
                receiver_state_next <= START_BIT when rx = '0' else
                                       INIT_RECEIVE;
            when START_BIT => 
                receiver_state_next <= START_VALID;
            when START_VALID =>
                if (rx_sampler_counter_reg = X"0" and rx = '0') then
                    receiver_state_next <= DATA_TRANSFER;
                elsif (not (rx_sampler_counter_reg = X"0")) then
                    receiver_state_next <= START_VALID;
                else
                    receiver_state_next <= IDLE;
                end if;
            when DATA_TRANSFER => 
                if (rx_bits_received_counter_reg = X"0") then
                    receiver_state_next <= END_BIT;
                else
                    receiver_state_next <= DATA_TRANSFER;
                end if;
            when END_BIT =>
                receiver_state_next <= IDLE;
        end case;
    end process; 
    
    receiver_state_machine_outputs : process(all)
    begin
        rx_sampler_counter_fill <= (others => '0');
        rx_bits_received_counter_fill <= (others => '0');
        
        rx_sampler_counter_reg_count_en <= '0';
        rx_sampler_counter_reg_fill_en <= '0';
        
        rx_bits_received_counter_reg_count_en <= '0';
        rx_bits_received_counter_reg_fill_en <= '0';
        rx_data_reg_en <= '0';
        dtr <= '1';
        case receiver_state is 
            when IDLE => 
                dtr <= modem_control_reg(0);
            when INIT_RECEIVE => 
                
            when START_BIT => 
                rx_sampler_counter_fill <= "0110";
                rx_sampler_counter_reg_fill_en <= '1';
            when START_VALID =>
                rx_bits_received_counter_fill <= "1000";
                
                rx_bits_received_counter_reg_fill_en <= '1';
                rx_sampler_counter_reg_count_en <= '1';
            when DATA_TRANSFER => 
                rx_sampler_counter_reg_count_en <= '1';
            when END_BIT =>
                rx_data_reg_en <= '1';
        end case;
    end process;

end rtl;














