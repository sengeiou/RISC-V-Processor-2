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
        
        cs : in std_logic;
        reset : in std_logic;
        clk : in std_logic
    );
end uart_interface;

architecture rtl of uart_interface is
    -- ========== DATA REGISTERS ==========
    signal receiver_data_reg : std_logic_vector(7 downto 0);
    
    signal transmitter_data_reg : std_logic_vector(7 downto 0);
    signal transmitter_data_reg_en : std_logic;
    signal transmitter_data_reg_next : std_logic_vector(7 downto 0);
    
    
    signal transmitter_data_shift_reg : std_logic_vector(7 downto 0);
    signal transmitter_data_shift_reg_shift_en : std_logic;
    signal transmitter_data_shift_reg_write_en : std_logic;
    
    signal transmitter_bits_transfered_counter : unsigned(3 downto 0);
    signal transmitter_bits_transfered_counter_en : std_logic;
    signal transmitter_bits_transfered_counter_fill : std_logic;

    -- ========== CONTROL REGISTERS ==========
    signal line_control_reg : std_logic_vector(7 downto 0);     --
     
    signal line_status_reg : std_logic_vector(7 downto 0);      -- 0 -> Transmitter data hold reg. empty (1 - yes, 0 - no) | 1 -> Line used (1 - yes, 0 - no)
    signal line_status_reg_en : std_logic;
    
    -- OTHER
    signal transmitter_data_reg_state_set : std_logic;
    signal transmitter_data_reg_state_reset : std_logic;
    
    type transmitter_state_type is (IDLE,
                                    START_BIT,
                                    DATA_TRANSFER,
                                    END_BIT);
                                    
    signal transmitter_state : transmitter_state_type;
    signal transmitter_state_next : transmitter_state_type;
begin
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
            end if;
        end if;
 
        data_read_bus <= (others => '0');
        transmitter_data_reg_next <= (others => '0');
            
        transmitter_data_reg_state_reset <= '0';    
        line_status_reg_en <= '0';
        transmitter_data_reg_en <= '0';
        
        if (cs = '1') then
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
                if (line_status_reg(0) = '0') then
                    transmitter_state_next <= START_BIT;
                else
                    transmitter_state_next <= IDLE;
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
        case transmitter_state is
            when IDLE =>
                tx_line <= '1';
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

end rtl;














