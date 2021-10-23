library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.axi_interface_signal_groups.all;

entity axi_slave_interface is
    port(
        -- CHANNEL SIGNALS
        axi_write_addr_ch : in WriteAddressChannel;
        axi_read_addr_ch : in ReadAddressChannel;
        
        axi_write_data_ch : in WriteDataChannel;
        axi_read_data_ch : out ReadDataChannel;
        
        axi_write_resp_ch : out WriteResponseChannel;
        
        -- HANDSHAKE SIGNALS
        master_write_handshake : in HandshakeWriteMaster; 
        master_read_handshake : in HandshakeReadMaster;
        slave_write_handshake : out HandshakeWriteSlave;
        slave_read_handshake : out HandshakeReadSlave;
        
        -- OTHER DATA SIGNALS
        from_slave : in FromSlave;
        to_slave : out ToSlave;
        
        -- OTHER CONTROL SIGNALS
        clk : in std_logic;
        reset : in std_logic
    );
end axi_slave_interface;

architecture rtl of axi_slave_interface is
    type write_state_type is (IDLE,
                              WRAP_INIT_1,
                              WRAP_INIT_2,
                              DATA_STATE,
                              RESPONSE_STATE_1,
                              RESPONSE_STATE_2);
                              
    type read_state_type is (IDLE,
                             WRAP_INIT_1,
                             WRAP_INIT_2,
                             DATA_STATE);

    -- ========== WRITE REGISTERS ==========
    signal write_addr_reg : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal write_addr_next : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal write_addr_reg_en : std_logic;
    signal write_addr_incr : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);

    signal write_wrap_addr_start_reg : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal write_wrap_addr_end_reg : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal write_wrap_addr_start_reg_en : std_logic;
    signal write_wrap_addr_end_reg_en : std_logic;
    
    signal write_burst_len_ext : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal write_burst_len_shifted : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal write_burst_size_ext : std_logic_vector(4 downto 0);
    
    signal write_burst_len_reg : std_logic_vector(7 downto 0);
    signal write_burst_size_reg : std_logic_vector(2 downto 0);
    signal write_burst_type_reg : std_logic_vector(1 downto 0);
    
    signal write_data_reg : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);

    signal write_state_reg : write_state_type;
    signal write_state_next : write_state_type;
   
    -- ========== READ REGISTERS ==========
    signal read_addr_reg : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal read_addr_next : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal read_addr_reg_en : std_logic;
    signal read_addr_incr : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    
    signal read_wrap_addr_start_reg : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal read_wrap_addr_end_reg : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal read_wrap_addr_start_reg_en : std_logic;
    signal read_wrap_addr_end_reg_en : std_logic;
    
    signal read_burst_len_ext : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal read_burst_len_shifted : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal read_burst_size_ext : std_logic_vector(4 downto 0);
    
    signal read_data_reg : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);
   
    signal read_burst_len_reg : std_logic_vector(7 downto 0);
    signal read_burst_len_reg_en : std_logic;
    signal read_burst_len_next : std_logic_vector(7 downto 0);
    
    signal read_burst_size_reg : std_logic_vector(2 downto 0);
    signal read_burst_type_reg : std_logic_vector(1 downto 0);
    
    signal read_state_reg : read_state_type;
    signal read_state_next : read_state_type;
    
    -- CONTROL SIGNALS
    signal read_burst_len_mux_sel : std_logic;
    signal read_burst_len_reg_zero : std_logic;
    signal read_addr_next_sel : std_logic_vector(1 downto 0);
    
    signal write_addr_next_sel : std_logic_vector(1 downto 0);
begin
    write_state_transition : process(master_write_handshake.awvalid, axi_write_data_ch.last, slave_write_handshake.bvalid, clk)
    begin
        case write_state_reg is
            when IDLE =>
                if (master_write_handshake.awvalid = '1') then
                    if (axi_write_addr_ch.burst_type = BURST_WRAP) then
                        write_state_next <= WRAP_INIT_1;
                    else
                        write_state_next <= DATA_STATE;
                    end if;
                else
                    write_state_next <= IDLE;
                end if;
            when WRAP_INIT_1 => 
                write_state_next <= WRAP_INIT_2;
            when WRAP_INIT_2 =>
                write_state_next <= DATA_STATE;
            when DATA_STATE => 
                if (axi_write_data_ch.last = '1') then
                    write_state_next <= RESPONSE_STATE_1;
                else
                    write_state_next <= DATA_STATE;
                end if;
            when RESPONSE_STATE_1 => 
                if (slave_write_handshake.bvalid = '1') then
                    write_state_next <= RESPONSE_STATE_2;
                else 
                    write_state_next <= RESPONSE_STATE_1;
                end if;
            when RESPONSE_STATE_2 => 
                write_state_next <= IDLE;
        end case;
    end process;

    write_state_outputs : process(all)
    begin
        slave_write_handshake.bvalid <= '0';

        slave_write_handshake.awready <= '1';
        slave_write_handshake.wready <= '0';
        
        write_addr_reg_en <= '0';
        write_wrap_addr_start_reg_en <= '0';
        write_wrap_addr_end_reg_en <= '0';
        
        axi_write_resp_ch.resp <= RESP_OKAY;
        
        write_addr_next_sel <= "11";
        case write_state_reg is
            when IDLE =>
                write_addr_reg_en <= master_write_handshake.awvalid;
                
            when WRAP_INIT_1 => 
                write_wrap_addr_start_reg_en <= '1';
                
            when WRAP_INIT_2 =>
                write_wrap_addr_end_reg_en <= '1';
                
            when DATA_STATE => 
                slave_write_handshake.awready <= '0';
                slave_write_handshake.wready <= '1';
                
                write_addr_reg_en <= '1';
                
                write_addr_next_sel <= write_burst_type_reg;
                
            when RESPONSE_STATE_1 => 
                axi_write_resp_ch.resp <= RESP_EXOKAY;
            
                slave_write_handshake.bvalid <= '1';
                slave_write_handshake.awready <= '0';
                
            when RESPONSE_STATE_2 => 
                slave_write_handshake.bvalid <= '1';
                slave_write_handshake.awready <= '0';
        end case;
    end process;
    
    -- ========== WRITE ADDRESS REGISTER CONTROL ==========
    write_addr_reg_proc : process(all)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                write_addr_reg <= (others => '0');
            else
                if (write_addr_reg_en = '1') then
                    write_addr_reg <= write_addr_next;
                end if;
            end if;
        end if;
    end process;
    
    write_addr_reg_next_mux_proc : process(write_addr_next_sel, write_addr_reg, write_addr_incr, write_wrap_addr_start_reg, axi_write_addr_ch.addr)   -- CAUTION: DO NOT USE process(all) AS TEMPTING AS IT MAY BE BECAUSE IT WONT WORK (at least in the sim)!
    begin
        if (write_addr_next_sel = BURST_FIXED) then
            write_addr_next <= write_addr_reg;
        elsif (write_addr_next_sel = BURST_INCR) then
            write_addr_next <= std_logic_vector(unsigned(write_addr_reg) + unsigned(write_addr_incr));
        elsif (write_addr_next_sel = BURST_WRAP) then
            if (write_addr_reg = write_wrap_addr_end_reg) then
                write_addr_next <= write_wrap_addr_start_reg;
            else
                write_addr_next <= std_logic_vector(unsigned(write_addr_reg) + unsigned(write_addr_incr));
            end if;
            --write_addr_next <= std_logic_vector(unsigned(write_addr_reg) + 4);      -- TEMP UNTIL WRAP MODE GETS IMPLEMENTED
        else
            write_addr_next <= axi_write_addr_ch.addr;
        end if;
    end process;
    
    shifter_left_write : entity work.barrel_shifter_2(rtl)
                         generic map(DATA_WIDTH => 8)
                         port map(data_in => "00000001",
                                  data_out => write_addr_incr(7 downto 0),
                                  shift_direction => '1',
                                  shift_arith => '0',
                                  shift_amount => write_burst_size_reg);
    
    write_addr_incr(31 downto 8) <= (others => '0');
    
    -- ========== WRITE WRAP ADDRESSES CONTROL ==========
    write_burst_len_ext(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 8) <= (others => '0');
    write_burst_len_ext(7 downto 0) <= std_logic_vector(unsigned(write_burst_len_reg) + 1);
    
    write_burst_size_ext(4 downto 3) <= "00";
    write_burst_size_ext(2 downto 0) <= write_burst_size_reg;
    
    write_shifter_left_mask_gen : entity work.barrel_shifter_2(rtl)
                            generic map(DATA_WIDTH => 32)
                            port map(data_in => write_burst_len_ext,
                                     data_out => write_burst_len_shifted,
                                     shift_direction => '1',
                                     shift_arith => '0',
                                     shift_amount => write_burst_size_ext);
                                     
    write_wrap_addr_start_reg_cntrl : process(all)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                write_wrap_addr_start_reg <= (others => '0');
            else
                if (write_wrap_addr_start_reg_en = '1') then
                    write_wrap_addr_start_reg <= write_addr_reg and not std_logic_vector(unsigned(write_burst_len_shifted) - 1);
                end if;
            end if;
        end if;
    end process;
    
    write_wrap_addr_end_reg_cntrl : process(all)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                write_wrap_addr_end_reg <= (others => '0');
            else
                if (write_wrap_addr_end_reg_en = '1') then
                    write_wrap_addr_end_reg <= std_logic_vector(unsigned(write_wrap_addr_start_reg) + unsigned(write_burst_len_shifted) - unsigned(write_addr_incr));
                end if;
            end if;
        end if;
    end process;
    
    -- =========================== READING =================================
    -- READ STATE MACHINE
    read_state_transition : process(all)
    begin
        case read_state_reg is 
            when IDLE => 
                if (master_read_handshake.arvalid = '1') then
                    if (axi_read_addr_ch.burst_type = BURST_WRAP) then
                        read_state_next <= WRAP_INIT_1;
                    else
                        read_state_next <= DATA_STATE;
                    end if;
                else
                    read_state_next <= IDLE;
                end if;
            when WRAP_INIT_1 => 
                read_state_next <= WRAP_INIT_2;
            when WRAP_INIT_2 => 
                read_state_next <= DATA_STATE;
            when DATA_STATE => 
                if (read_burst_len_reg_zero = '1' and master_read_handshake.rready = '1' and from_slave.data_ready = '1') then
                    read_state_next <= IDLE;
                else
                    read_state_next <= DATA_STATE;
                end if;
        end case;
    end process;
    
    read_state_outputs : process(all)
    begin
        axi_read_data_ch.data <= (others => '0');
        axi_read_data_ch.resp <= (others => '0');
        axi_read_data_ch.last <= '0';
                
        slave_read_handshake.rvalid <= '0';
        
        read_addr_reg_en <= '0';
        read_burst_len_reg_en <= '0';
        read_wrap_addr_start_reg_en <= '0';
        read_wrap_addr_end_reg_en <= '0';
        
        read_burst_len_mux_sel <= '0';
        
        axi_read_data_ch.resp <= RESP_OKAY; 
                
        slave_read_handshake.arready <= '1';

        case read_state_reg is
            when IDLE =>
                read_burst_len_reg_en <= master_read_handshake.arvalid;
                read_addr_reg_en <= master_read_handshake.arvalid;
                
                slave_read_handshake.arready <= '0';
                read_addr_next_sel <= "11";
            when WRAP_INIT_1 => 
                read_wrap_addr_start_reg_en <= '1';
            when WRAP_INIT_2 => 
                read_wrap_addr_end_reg_en <= '1';
            when DATA_STATE => 
                axi_read_data_ch.data <= from_slave.data_read;
                axi_read_data_ch.last <= read_burst_len_reg_zero;
                
                slave_read_handshake.rvalid <= from_slave.data_ready;
                slave_read_handshake.arready <= '0';
                
                axi_read_data_ch.last <= read_burst_len_reg_zero;
                axi_read_data_ch.resp <= RESP_EXOKAY;                 -- The slave will currently only respond as if every transaction is successfull. This will change in the future.
                
                read_burst_len_mux_sel <= '1';
                
                -- ====================================
                read_burst_len_reg_en <= not read_burst_len_reg_zero and
                                         master_read_handshake.rready and from_slave.data_ready;
                read_addr_reg_en <= master_read_handshake.rready and from_slave.data_ready;
                                         
                read_addr_next_sel <= read_burst_type_reg;
        end case;
    end process;
    
    -- ========== BURST LEN REGISTER CONTROL (READ) ==========
    read_burst_len_reg_zero <= not read_burst_len_reg(7) and
                               not read_burst_len_reg(6) and
                               not read_burst_len_reg(5) and
                               not read_burst_len_reg(4) and
                               not read_burst_len_reg(3) and
                               not read_burst_len_reg(2) and
                               not read_burst_len_reg(1) and
                               not read_burst_len_reg(0);
    
    read_burst_len_reg_cntrl : process(all)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                read_burst_len_reg <= (others => '0');
            else
                if (read_burst_len_reg_en = '1') then
                    read_burst_len_reg <= read_burst_len_next;
                end if;
            end if;
        end if;
    end process;
    
    read_burst_len_next_mux_proc : process(read_burst_len_mux_sel, axi_read_addr_ch.len, read_burst_len_reg)
    begin
        if (read_burst_len_mux_sel = '0') then
            read_burst_len_next <= axi_read_addr_ch.len;
        elsif (read_burst_len_mux_sel = '1') then
            read_burst_len_next <= std_logic_vector(unsigned(read_burst_len_reg) - 1);
        else
            read_burst_len_next <= (others => '0');
        end if;
    end process;
    
    -- ========== READ ADDR REGISTER CONTROL ==========
    read_addr_reg_cntrl : process(all)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                read_addr_reg <= (others => '0');
            else
                if (read_addr_reg_en = '1') then
                    read_addr_reg <= read_addr_next;
                end if;
            end if;
        end if;
    end process;
    
    read_addr_next_mux_proc : process(read_addr_next_sel, read_addr_reg, read_addr_incr, axi_read_addr_ch.addr)
    begin   
        if (read_addr_next_sel = BURST_FIXED) then
            read_addr_next <= read_addr_reg;
        elsif (read_addr_next_sel = BURST_INCR) then
            read_addr_next <= std_logic_vector(unsigned(read_addr_reg) + unsigned(read_addr_incr));
        elsif (read_addr_next_sel = BURST_WRAP) then
            if (read_addr_reg = read_wrap_addr_end_reg) then
                read_addr_next <= read_wrap_addr_start_reg;
            else
                read_addr_next <= std_logic_vector(unsigned(read_addr_reg) + unsigned(read_addr_incr));
            end if;
        else
            read_addr_next <= axi_read_addr_ch.addr;
        end if;
    end process;
    
    shifter_left_read : entity work.barrel_shifter_2(rtl)
                         generic map(DATA_WIDTH => 8)
                         port map(data_in => "00000001",
                                  data_out => read_addr_incr(7 downto 0),
                                  shift_direction => '1',
                                  shift_arith => '0',
                                  shift_amount => read_burst_size_reg);
   
    read_addr_incr(31 downto 8) <= (others => '0');
   
    -- ========== READ WRAP ADDRESSES CONTROL ==========
    read_burst_len_ext(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 8) <= (others => '0');
    read_burst_len_ext(7 downto 0) <= std_logic_vector(unsigned(read_burst_len_reg) + 1);
    
    read_burst_size_ext(4 downto 3) <= "00";
    read_burst_size_ext(2 downto 0) <= read_burst_size_reg;
    
    read_shifter_left_mask_gen : entity work.barrel_shifter_2(rtl)
                            generic map(DATA_WIDTH => 32)
                            port map(data_in => read_burst_len_ext,
                                     data_out => read_burst_len_shifted,
                                     shift_direction => '1',
                                     shift_arith => '0',
                                     shift_amount => read_burst_size_ext);
                                     
    read_wrap_addr_start_reg_cntrl : process(all)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                read_wrap_addr_start_reg <= (others => '0');
            else
                if (read_wrap_addr_start_reg_en = '1') then
                    read_wrap_addr_start_reg <= read_addr_reg and not std_logic_vector(unsigned(read_burst_len_shifted) - 1);
                end if;
            end if;
        end if;
    end process;
    
    read_wrap_addr_end_reg_cntrl : process(all)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                read_wrap_addr_end_reg <= (others => '0');
            else
                if (read_wrap_addr_end_reg_en = '1') then
                    read_wrap_addr_end_reg <= std_logic_vector(unsigned(read_wrap_addr_start_reg) + unsigned(read_burst_len_shifted) - unsigned(read_addr_incr));
                end if;
            end if;
        end if;
    end process;
   
    -- ========== REGISTER CONTROL ==========
    register_control : process(all)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                write_data_reg <= (others => '0');
                
                read_data_reg <= (others => '0');
                
                read_burst_type_reg <= (others => '0');
                read_burst_size_reg <= (others => '0');
                
                write_burst_len_reg <= (others => '0');
                write_burst_type_reg <= (others => '0');
                write_burst_size_reg <= (others => '0');
                
                write_state_reg <= IDLE;
                read_state_reg <= IDLE;
            else
                if (master_write_handshake.awvalid = '1') then
                    write_burst_len_reg <= axi_write_addr_ch.len;
                    write_burst_type_reg <= axi_write_addr_ch.burst_type;
                    write_burst_size_reg <= axi_write_addr_ch.size;
                end if;
            
                if (master_write_handshake.wvalid = '1') then
                    write_data_reg <= axi_write_data_ch.data;
                end if;
            
                if (master_read_handshake.arvalid = '1') then     
                    read_burst_size_reg <= axi_read_addr_ch.size;
                    read_burst_type_reg <= axi_read_addr_ch.burst_type;
                end if;
            
                write_state_reg <= write_state_next;
                read_state_reg <= read_state_next;
            end if;
        end if;
    end process;


    to_slave.data_write <= write_data_reg;
    to_slave.addr_write <= write_addr_reg;
    
    to_slave.addr_read <= read_addr_reg;

end rtl;











