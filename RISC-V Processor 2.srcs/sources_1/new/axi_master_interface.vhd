library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi_master_interface is
    port(
        -- CHANNEL SIGNALS
        from_master : out work.axi_interface_signal_groups.FromMasterInterfaceToBus;
        to_master : in work.axi_interface_signal_groups.ToMasterInterfaceFromBus;
        
        -- HANDSHAKE SIGNALS
        master_handshake : out work.axi_interface_signal_groups.HandshakeMasterSrc;
        slave_handshake : in work.axi_interface_signal_groups.HandshakeSlaveSrc;

        -- OTHER CONTROL SIGNALS
        interface_to_master : out work.axi_interface_signal_groups.ToMaster;
        master_to_interface : in work.axi_interface_signal_groups.FromMaster;
        
        clk : in std_logic;
        reset : in std_logic
    );
end axi_master_interface;

architecture rtl of axi_master_interface is
    type write_state_type is (IDLE,
                              ADDR_STATE_1,
                              DATA_STATE,
                              RESPONSE_STATE_1,
                              RESPONSE_STATE_2);
                              
    type read_state_type is (IDLE,
                             ADDR_STATE,
                             DATA_STATE,
                             FINALIZE_STATE);
                            
    -- ========== WRITE REGISTERS ==========                              
    signal write_addr_reg : std_logic_vector(2 ** work.axi_interface_signal_groups.AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal write_data_reg : std_logic_vector(2 ** work.axi_interface_signal_groups.AXI_ADDR_BUS_WIDTH - 1 downto 0);
                              
    signal write_state_reg : write_state_type;
    signal write_state_next : write_state_type;
    
    signal write_burst_len_reg_zero : std_logic;
    signal write_burst_len_reg : std_logic_vector(7 downto 0);
    signal write_burst_len_next : std_logic_vector(7 downto 0);
    signal write_burst_len_reg_en : std_logic;
    signal write_burst_len_mux_sel : std_logic;
    
    -- ========== READ REGISTERS ==========
    signal read_data_reg : std_logic_vector(2 ** work.axi_interface_signal_groups.AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal read_data_reg_en : std_logic;
    
    signal read_state_reg : read_state_type;
    signal read_state_next : read_state_type;
    
    
begin
    -- WRITE STATE MACHINE
    write_state_transition : process(all)
    begin
        case write_state_reg is
            when IDLE =>
                if (master_to_interface.execute_write = '1') then
                    write_state_next <= ADDR_STATE_1;
                else
                    write_state_next <= IDLE;
                end if;
            when ADDR_STATE_1 =>
                if (slave_handshake.awready = '1') then
                    write_state_next <= DATA_STATE;
                else
                    write_state_next <= ADDR_STATE_1;
                end if;
            when DATA_STATE => 
                if (slave_handshake.wready = '1' and write_burst_len_reg_zero = '1') then
                    write_state_next <= RESPONSE_STATE_1;
                else
                    write_state_next <= DATA_STATE;
                end if;
            when RESPONSE_STATE_1 => 
                if (slave_handshake.bvalid = '1') then
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
        interface_to_master.done_write <= '0'; 
        
        from_master.write_addr_ch.addr <= (others => '0');
        from_master.write_addr_ch.len <= (others => '0');
        from_master.write_addr_ch.size <= (others => '0');
        from_master.write_addr_ch.burst_type <= (others => '0');
        
        from_master.write_data_ch.data <= (others => '0');
        from_master.write_data_ch.strb <= "0000";      
        from_master.write_data_ch.last <= '0';   
        
        master_handshake.awvalid <= '0';
        master_handshake.wvalid <= '0';
                
        master_handshake.bready <= '0';
        
        write_burst_len_mux_sel <= '0';
        write_burst_len_reg_en <= '0';
        case write_state_reg is
            when IDLE =>
            
            when ADDR_STATE_1 => 
                -- WRITE ADDRESS CHANNEL
                from_master.write_addr_ch.addr <= write_addr_reg;
                from_master.write_addr_ch.len <= master_to_interface.burst_len;
                from_master.write_addr_ch.size <= master_to_interface.burst_size;
                from_master.write_addr_ch.burst_type <= master_to_interface.burst_type;
                
                -- WRITE DATA CHANNEL
                from_master.write_data_ch.data <= write_data_reg;
                from_master.write_data_ch.strb <= "1111";
                
                -- HANDSHAKE
                master_handshake.awvalid <= '1';
                
                -- BURST CONTROL
                write_burst_len_reg_en <= '1';
            when DATA_STATE => 
                -- WRITE DATA CHANNEL
                from_master.write_data_ch.data <= write_data_reg;
                from_master.write_data_ch.strb <= "1111";
                from_master.write_data_ch.last <= write_burst_len_reg_zero;
                
                -- HANDSHAKE
                master_handshake.wvalid <= '1';
                
                -- BURST CONTROL
                write_burst_len_mux_sel <= '1';
                write_burst_len_reg_en <= not write_burst_len_reg_zero and
                                          slave_handshake.wready;
            when RESPONSE_STATE_1 => 

            when RESPONSE_STATE_2 => 
                -- HANDSHAKE
                master_handshake.bready <= '1';
                
                interface_to_master.done_write <= '1';
        end case;
    end process;
    
    -- ========== BURST LEN REGISTER CONTROL (WRITE) ==========
    write_burst_len_reg_zero <= not write_burst_len_reg(7) and
                               not write_burst_len_reg(6) and
                               not write_burst_len_reg(5) and
                               not write_burst_len_reg(4) and
                               not write_burst_len_reg(3) and
                               not write_burst_len_reg(2) and
                               not write_burst_len_reg(1) and
                               not write_burst_len_reg(0);
    
    write_burst_len_reg_cntrl : process(all)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                write_burst_len_reg <= (others => '0');
            else
                if (write_burst_len_reg_en = '1') then
                    write_burst_len_reg <= write_burst_len_next;
                end if;
            end if;
        end if;
    end process;
    
    write_burst_len_next_mux_proc : process(write_burst_len_mux_sel, master_to_interface.burst_len, write_burst_len_reg)
    begin
        if (write_burst_len_mux_sel = '0') then
            write_burst_len_next <= master_to_interface.burst_len;
        elsif (write_burst_len_mux_sel = '1') then
            write_burst_len_next <= std_logic_vector(unsigned(write_burst_len_reg) - 1);
        else
            write_burst_len_next <= (others => '0');
        end if;
    end process;
    
    -- READ STATE MACHINE
    read_state_transition : process(read_state_reg, master_to_interface.execute_read, slave_handshake.arready, to_master.read_data_ch.last)
    begin
        case read_state_reg is 
            when IDLE => 
                if (master_to_interface.execute_read = '1') then
                    read_state_next <= ADDR_STATE;
                else
                    read_state_next <= IDLE;
                end if;
            when ADDR_STATE => 
                if (slave_handshake.arready = '1') then
                    read_state_next <= DATA_STATE;
                else
                    read_state_next <= ADDR_STATE;
                end if;
            when DATA_STATE => 
                if (to_master.read_data_ch.last = '1') then
                    read_state_next <= FINALIZE_STATE;
                else
                    read_state_next <= DATA_STATE;
                end if;
            when FINALIZE_STATE => 
                read_state_next <= IDLE;
        end case;
    end process;
    
    read_state_outputs : process(all)
    begin
        interface_to_master.done_read <= '0';
        
        from_master.read_addr_ch.addr <= (others => '0');
        from_master.read_addr_ch.len <= (others => '0');
        from_master.read_addr_ch.size <= (others => '0');
        from_master.read_addr_ch.burst_type <= (others => '0');
                
        -- HANDSHAKE
        master_handshake.arvalid <= '0';

        master_handshake.rready <= '0';
                
        read_data_reg_en <= '0';
        case read_state_reg is
            when IDLE =>

            when ADDR_STATE => 
                from_master.read_addr_ch.addr <= master_to_interface.addr_read;
                from_master.read_addr_ch.len <= master_to_interface.burst_len;
                from_master.read_addr_ch.size <= master_to_interface.burst_size;
                from_master.read_addr_ch.burst_type <= master_to_interface.burst_type;
                
                -- HANDSHAKE
                master_handshake.arvalid <= '1';
            when DATA_STATE => 
                -- HANDSHAKE
                master_handshake.rready <= '1';
                
                read_data_reg_en <= '1';
            when FINALIZE_STATE => 
                interface_to_master.done_read <= '1'; 
        end case;
    end process;
    
    process(all)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                write_addr_reg <= (others => '0');
                write_data_reg <= (others => '0');
                read_data_reg <= (others => '0');
                
                write_state_reg <= IDLE;
                read_state_reg <= IDLE;
            else
                if (master_to_interface.execute_write = '1') then
                    write_addr_reg <= master_to_interface.addr_write;
                    write_data_reg <= master_to_interface.data_write;
                end if;
                
                if (read_data_reg_en = '1') then
                    read_data_reg <= to_master.read_data_ch.data;
                end if;
                
                write_state_reg <= write_state_next;
                read_state_reg <= read_state_next;
            end if;
        end if;
    end process;

    interface_to_master.data_read <= read_data_reg;

end rtl;
