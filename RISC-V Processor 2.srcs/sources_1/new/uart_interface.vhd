library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_interface is
    port(
        addr_bus : in std_logic_vector(2 downto 0);
        
        data_write_bus : in std_logic_vector(7 downto 0);
        data_read_bus : out std_logic_vector(7 downto 0);
        
        tx_line : out std_logic;
        rx_line : in std_logic;
        
        req_to_send : out std_logic;
        clr_to_send : in std_logic;
        data_term_ready : out std_logic;
        data_set_ready : in std_logic;
        
        cs : in std_logic;
        reset : in std_logic;
        clk : in std_logic
    );
end uart_interface;

architecture rtl of uart_interface is
    -- ========== DATA REGISTERS ==========
    signal receiver_data_reg : std_logic_vector(7 downto 0);
    signal receiver_data_reg_en : std_logic;
    
    signal transmitter_data_reg : std_logic_vector(7 downto 0);
    signal transmitter_data_reg_en : std_logic;
    signal transmitter_data_reg_next : std_logic_vector(7 downto 0);
    
    signal transmitter_data_shift_reg : std_logic_vector(7 downto 0);
    signal transmitter_data_shift_reg_shift_en : std_logic;
    signal transmitter_data_shift_reg_write_en : std_logic;
    
    signal transmitter_bits_transfered_counter : unsigned(3 downto 0);
    signal transmitter_bits_transfered_counter_en : std_logic;
    signal transmitter_bits_transfered_counter_fill : std_logic;
    
    ------------------------
    signal receiver_data_shift_reg : std_logic_vector(7 downto 0);
    signal receiver_data_shift_reg_shift_en : std_logic;
    
    signal receiver_sampler_counter_reg : std_logic_vector(3 downto 0);
    signal receiver_sampler_counter_fill : std_logic_vector(3 downto 0);
    signal receiver_sampler_counter_reg_count_en : std_logic;
    signal receiver_sampler_counter_reg_fill_en : std_logic;
    
    signal receiver_bits_received_counter_reg : std_logic_vector(3 downto 0);
    signal receiver_bits_received_counter_fill : std_logic_vector(3 downto 0);
    signal receiver_bits_received_counter_reg_count_en : std_logic;
    signal receiver_bits_received_counter_reg_fill_en : std_logic;

    -- ========== CONTROL REGISTERS ==========
    signal divisor_latch_ls : std_logic_vector(7 downto 0);     -- Lower 8 bits of the divisor
    signal divisor_latch_ms : std_logic_vector(7 downto 0);     -- Upper 8 bits of the divisor
    
    signal line_control_reg : std_logic_vector(7 downto 0);      
    signal line_status_reg : std_logic_vector(7 downto 0);      -- 0 -> Transmitter data hold reg. empty (1 - yes, 0 - no) | 1 -> Line used (1 - yes, 0 - no)
    signal line_status_reg_en : std_logic;
    
    signal modem_control_reg : std_logic_vector(7 downto 0);
    signal modem_control_reg_en : std_logic;
    
    -- OTHER
    signal divisor_latch_full : std_logic_vector(15 downto 0);
    signal baud_x16 : std_logic;
    
    signal transmitter_data_reg_state_set : std_logic;
    signal transmitter_data_reg_state_reset : std_logic;
    
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

    -- =================== BAUD RATE GENERATOR x16 ===================
    divisor_latch_full <= divisor_latch_ms & divisor_latch_ls;

    baud_x16_generator : entity work.clock_divider(rtl)
                          port map(divider => divisor_latch_full,
                                   clk_src => clk,
                                   clk_div => baud_x16,
                                   reset => reset);

    transmitter_data_reg_state_set <= '0';

    line_status_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                line_status_reg <= "00000001";
            elsif (line_status_reg_en = '1') then
                line_status_reg(7 downto 1) <= line_status_reg(7 downto 1);
                
                
                line_status_reg(0) <= (line_status_reg(0) and not transmitter_data_reg_state_reset) or transmitter_data_reg_state_set;
            end if;
        end if;
    end process;
    
    modem_control_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                modem_control_reg <= (others => '0');
            elsif (modem_control_reg_en = '1') then
                modem_control_reg <= data_write_bus;
            end if;
        end if;
    end process;
    
    transmitter_data_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                transmitter_data_reg <= (others => '0');
            elsif (transmitter_data_reg_en = '1') then
                transmitter_data_reg <= transmitter_data_reg_next;
            end if;
        end if;
    end process;

    register_control_proc : process(all)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                line_control_reg <= (others => '0');
                
                divisor_latch_ls <= (others => '1');
                divisor_latch_ms <= (others => '1');
            end if;
        end if;
 
        data_read_bus <= (others => '0');
        transmitter_data_reg_next <= (others => '0');
            
        transmitter_data_reg_state_reset <= '0';    
        line_status_reg_en <= '0';
        transmitter_data_reg_en <= '0';
        modem_control_reg_en <= '0'; 
        
        if (cs = '1') then                  -- ALLOCATED ADDRESSES ARE TEMPORARY AND DO NOT CORRESPOND TO THE 16550 UART IC!!!
            case addr_bus is 
                when "000" =>
                    data_read_bus <= receiver_data_reg;
                when "001" =>
                    transmitter_data_reg_next <= data_write_bus;
                    transmitter_data_reg_en <= '1';
                            
                    transmitter_data_reg_state_reset <= '1';
                           
                    line_status_reg_en <= '1';
                when "010" =>
                    data_read_bus <= line_status_reg;
                when "100" =>       -- MODEM CONTROL REGISTER
                    modem_control_reg_en <= '1';
                when "110" =>
                    divisor_latch_ls <= data_write_bus;
                when "111" =>
                    divisor_latch_ms <= data_write_bus;
                when others =>
                           
            end case;
        end if;
    end process;
    
    transmitter_bits_transfered_counter_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                transmitter_bits_transfered_counter <= (others => '0');
            else
                if (transmitter_bits_transfered_counter_fill = '1') then
                    transmitter_bits_transfered_counter <= "0111";      -- 8 BITS FOR NOW
                elsif (transmitter_bits_transfered_counter_en = '1') then
                    transmitter_bits_transfered_counter <= transmitter_bits_transfered_counter - 1;
                end if;
            end if;
        end if;
    end process;
    
    transmitter_data_shift_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                transmitter_data_shift_reg <= (others => '0');
            else
                if (transmitter_data_shift_reg_write_en = '1') then
                    transmitter_data_shift_reg <= transmitter_data_reg;
                elsif (transmitter_data_shift_reg_shift_en = '1') then
                    transmitter_data_shift_reg <= std_logic_vector(shift_right(unsigned(transmitter_data_shift_reg), 1));
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
                if (clr_to_send = '0') then
                    transmitter_state_next <= START_BIT;
                else
                    transmitter_state_next <= INIT_TRANSMISSION;
                end if;
            when START_BIT =>
                transmitter_state_next <= DATA_TRANSFER;
            when DATA_TRANSFER =>
                if (transmitter_bits_transfered_counter = 0) then
                    transmitter_state_next <= END_BIT;
                else
                    transmitter_state_next <= DATA_TRANSFER;
                end if;
            when END_BIT =>
                transmitter_state_next <= IDLE;
            when others =>
                transmitter_state_next <= IDLE;
        end case;
    end process;
    
    transmitter_state_machine_outputs : process(all)
    begin
        transmitter_data_shift_reg_write_en <= '0';
        transmitter_data_shift_reg_shift_en <= '0';
        
        transmitter_bits_transfered_counter_fill <= '0';
        transmitter_bits_transfered_counter_en <= '0';
        
        req_to_send <= '1';
        case transmitter_state is
            when IDLE =>
                tx_line <= '1';
            when INIT_TRANSMISSION => 
                req_to_send <= '0';
            when START_BIT => 
                tx_line <= '0';
                
                transmitter_data_shift_reg_write_en <= '1';
                transmitter_bits_transfered_counter_fill <= '1';
            when DATA_TRANSFER =>
                tx_line <= transmitter_data_shift_reg(0);
                
                transmitter_data_shift_reg_shift_en <= '1';
                transmitter_bits_transfered_counter_en <= '1';
            when END_BIT =>
                tx_line <= '1';
            when others =>
                tx_line <= '1';
        end case;
    end process;
    
    -- =================== RECEIVER DATA REG ===================
    receiver_data_reg_update : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                receiver_data_reg <= (others => '0');
            else
                if (receiver_data_reg_en = '1') then
                    receiver_data_reg <= receiver_data_shift_reg;
                end if;
            end if;
        end if;
    end process;
    
    -- =================== RECEIVER SAMPLER COUNTER REG ===================
    receiver_sampler_reg_update : process(baud_x16)
    begin  
        if (rising_edge(baud_x16)) then      -- MAYBE MAKE IT CLOCK ON THE "NORMAL" CLK SIGNAL? PROBLEM OR NOT?
            if (reset = '1') then
                receiver_sampler_counter_reg <= (others => '0');
            elsif (receiver_sampler_counter_reg_fill_en = '1') then
                receiver_sampler_counter_reg <= receiver_sampler_counter_fill;
            elsif (receiver_sampler_counter_reg_count_en = '1') then
                receiver_sampler_counter_reg <= std_logic_vector(unsigned(receiver_sampler_counter_reg) - 1);
            end if;
        end if;
    end process;
    
    -- =================== RECEIVER SHIFT REGISTER CONTROL ===================
    receiver_shift_reg_update : process(baud_x16)
    begin
        if (reset = '1') then
            receiver_data_shift_reg <= (others => '0');
        elsif (rising_edge(baud_x16)) then     -- MAYBE MAKE IT CLOCK ON THE "NORMAL" CLK SIGNAL? PROBLEM OR NOT?
            if (receiver_sampler_counter_reg = X"0") then
                receiver_data_shift_reg(7 downto 1) <= receiver_data_shift_reg(6 downto 0);
                receiver_data_shift_reg(0) <= rx_line;
            end if;
        end if;
    end process;
    
    -- =================== RECEIVER STATE MACHINE CONTROL ===================
    receiver_state_reg_update : process(baud_x16)
    begin
        if (rising_edge(baud_x16)) then
            if (reset = '1') then
                receiver_state <= IDLE;
            else
                receiver_state <= receiver_state_next;
            end if;
        end if;
    end process;
    
    receiver_bits_received_counter_reg_update : process(baud_x16)
    begin
        if (reset = '1') then
            receiver_bits_received_counter_reg <= (others => '0');
        elsif (rising_edge(baud_x16)) then     -- MAYBE MAKE IT CLOCK ON THE "NORMAL" CLK SIGNAL? PROBLEM OR NOT?
            if (receiver_bits_received_counter_reg_fill_en = '1') then
                receiver_bits_received_counter_reg <= receiver_bits_received_counter_fill;
            elsif (receiver_sampler_counter_reg = X"0") then
                receiver_bits_received_counter_reg <= std_logic_vector(unsigned(receiver_bits_received_counter_reg) - 1);
            end if;
        end if;
    end process;
    
    receiver_next_state : process(rx_line, receiver_sampler_counter_reg, receiver_state, receiver_bits_received_counter_reg, modem_control_reg)
    begin
        case receiver_state is 
            when IDLE => 
                if (modem_control_reg(0) = '1') then
                    receiver_state_next <= INIT_RECEIVE;
                else
                    receiver_state_next <= IDLE;
                end if;
            when INIT_RECEIVE =>
                if (rx_line = '1') then
                    receiver_state_next <= INIT_RECEIVE;
                else
                    receiver_state_next <= START_BIT;
                end if;
            when START_BIT => 
                receiver_state_next <= START_VALID;
            when START_VALID =>
                if (receiver_sampler_counter_reg = X"0" and rx_line = '0') then
                    receiver_state_next <= DATA_TRANSFER;
                elsif (not (receiver_sampler_counter_reg = X"0")) then
                    receiver_state_next <= START_VALID;
                else
                    receiver_state_next <= IDLE;
                end if;
            when DATA_TRANSFER => 
                if (receiver_bits_received_counter_reg = X"0") then
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
        receiver_sampler_counter_fill <= (others => '0');
        receiver_bits_received_counter_fill <= (others => '0');
        
        receiver_sampler_counter_reg_count_en <= '0';
        receiver_sampler_counter_reg_fill_en <= '0';
        
        receiver_bits_received_counter_reg_count_en <= '0';
        receiver_bits_received_counter_reg_fill_en <= '0';
        receiver_data_reg_en <= '0';
        data_term_ready <= '1';
        case receiver_state is 
            when IDLE => 
                data_term_ready <= modem_control_reg(0);
            when INIT_RECEIVE => 
                
            when START_BIT => 
                receiver_sampler_counter_fill <= "0110";
                receiver_sampler_counter_reg_fill_en <= '1';
            when START_VALID =>
                receiver_bits_received_counter_fill <= "1000";
            
                
                receiver_bits_received_counter_reg_fill_en <= '1';
                receiver_sampler_counter_reg_count_en <= '1';
            when DATA_TRANSFER => 
                receiver_sampler_counter_reg_count_en <= '1';
            when END_BIT =>
                receiver_data_reg_en <= '1';
        end case;
    end process;

end rtl;














