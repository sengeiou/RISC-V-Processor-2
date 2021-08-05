library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_master_interface is
    port(
        -- CHANNEL SIGNALS
        from_master : out work.axi_interface_signal_groups.FromMaster;
        to_master : in work.axi_interface_signal_groups.ToMaster;
        
        -- HANDSHAKE SIGNALS
        master_handshake : out work.axi_interface_signal_groups.HandshakeMasterSrc;
        slave_handshake : in work.axi_interface_signal_groups.HandshakeSlaveSrc;

        -- OTHER CONTROL SIGNALS
        interface_from_master : out work.axi_interface_signal_groups.FromMasterToInterface;
        interface_to_master : in work.axi_interface_signal_groups.ToMasterFromInterface;
        
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
                             DATA_STATE);
                              
    signal write_addr_reg : std_logic_vector(2 ** work.axi_interface_signal_groups.AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal write_data_reg : std_logic_vector(2 ** work.axi_interface_signal_groups.AXI_ADDR_BUS_WIDTH - 1 downto 0);
                              
    signal write_state_reg : write_state_type;
    signal write_state_next : write_state_type;
    
    
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
                if (interface_to_master.execute_write = '1') then
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
                if (slave_handshake.wready = '1') then
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
    
    write_state_outputs : process(write_state_reg)
    begin
        case write_state_reg is
            when IDLE =>
                -- WRITE ADDRESS CHANNEL
                from_master.write_addr_ch.addr <= (others => '0');
                from_master.write_addr_ch.len <= (others => '0');
                from_master.write_addr_ch.size <= (others => '0');
                from_master.write_addr_ch.burst <= (others => '0');
                
                -- WRITE DATA CHANNEL
                from_master.write_data_ch.data <= (others => '0');
                from_master.write_data_ch.strb <= "0000";      
                from_master.write_data_ch.last <= '0';     
                
                -- HANDSHAKE
                master_handshake.awvalid <= '0';
                master_handshake.wvalid <= '0';
                
                master_handshake.bready <= '0';
            when ADDR_STATE_1 => 
                -- WRITE ADDRESS CHANNEL
                from_master.write_addr_ch.addr <= write_addr_reg;
                from_master.write_addr_ch.len <= (others => '0');
                from_master.write_addr_ch.size <= (others => '0');
                from_master.write_addr_ch.burst <= (others => '0');
                
                -- WRITE DATA CHANNEL
                from_master.write_data_ch.data <= write_data_reg;
                from_master.write_data_ch.strb <= "1111";
                from_master.write_data_ch.last <= '0';
                
                -- HANDSHAKE
                master_handshake.awvalid <= '1';
                master_handshake.wvalid <= '0';
                
                master_handshake.bready <= '0';
            when DATA_STATE => 
                -- WRITE ADDRESS CHANNEL
                from_master.write_addr_ch.addr <= (others => '0');
                from_master.write_addr_ch.len <= (others => '0');
                from_master.write_addr_ch.size <= (others => '0');
                from_master.write_addr_ch.burst <= (others => '0');
                
                -- WRITE DATA CHANNEL
                from_master.write_data_ch.data <= write_data_reg;
                from_master.write_data_ch.strb <= "1111";
                from_master.write_data_ch.last <= '1';
                
                -- HANDSHAKE
                master_handshake.awvalid <= '0';
                master_handshake.wvalid <= '1';
                
                master_handshake.bready <= '0';
            when RESPONSE_STATE_1 => 
                -- WRITE ADDRESS CHANNEL
                from_master.write_addr_ch.addr <= (others => '0');
                from_master.write_addr_ch.len <= (others => '0');
                from_master.write_addr_ch.size <= (others => '0');
                from_master.write_addr_ch.burst <= (others => '0');
                
                -- WRITE DATA CHANNEL
                from_master.write_data_ch.data <= (others => '0');
                from_master.write_data_ch.strb <= (others => '0');
                from_master.write_data_ch.last <= '0';
                
                -- HANDSHAKE
                master_handshake.awvalid <= '0';
                master_handshake.wvalid <= '0';
                
                master_handshake.bready <= '0';
            when RESPONSE_STATE_2 => 
                -- WRITE ADDRESS CHANNEL
                from_master.write_addr_ch.addr <= (others => '0');
                from_master.write_addr_ch.len <= (others => '0');
                from_master.write_addr_ch.size <= (others => '0');
                from_master.write_addr_ch.burst <= (others => '0');
                
                -- WRITE DATA CHANNEL
                from_master.write_data_ch.data <= (others => '0');
                from_master.write_data_ch.strb <= (others => '0');
                from_master.write_data_ch.last <= '0';
                
                -- HANDSHAKE
                master_handshake.awvalid <= '0';
                master_handshake.wvalid <= '0';
                
                master_handshake.bready <= '1';
        end case;
    end process;
    
    -- READ STATE MACHINE
    read_state_transition : process(read_state_reg, interface_to_master.execute_read, slave_handshake.arready, to_master.read_data_ch.last)
    begin
        case read_state_reg is 
            when IDLE => 
                if (interface_to_master.execute_read = '1') then
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
                    read_state_next <= IDLE;
                else
                    read_state_next <= DATA_STATE;
                end if;
        end case;
    end process;
    
    read_state_outputs : process(read_state_reg)
    begin
        case read_state_reg is
            when IDLE =>
                from_master.read_addr_ch.addr <= (others => '0');
                from_master.read_addr_ch.len <= (others => '0');
                from_master.read_addr_ch.size <= (others => '0');
                from_master.read_addr_ch.burst <= (others => '0');
                
                -- HANDSHAKE
                master_handshake.arvalid <= '0';

                master_handshake.rready <= '0';
                
                read_data_reg_en <= '0';
            when ADDR_STATE => 
                from_master.read_addr_ch.addr <= interface_from_master.addr_read;
                from_master.read_addr_ch.len <= (others => '0');
                from_master.read_addr_ch.size <= (others => '0');
                from_master.read_addr_ch.burst <= (others => '0');
                
                -- HANDSHAKE
                master_handshake.arvalid <= '1';

                master_handshake.rready <= '0';
                
                read_data_reg_en <= '0';
            when DATA_STATE => 
                from_master.read_addr_ch.addr <= (others => '0');
                from_master.read_addr_ch.len <= (others => '0');
                from_master.read_addr_ch.size <= (others => '0');
                from_master.read_addr_ch.burst <= (others => '0');
                
                -- HANDSHAKE
                master_handshake.arvalid <= '0';
                
                master_handshake.rready <= '1';
                
                read_data_reg_en <= '1';
        end case;
    end process;
    
    process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                write_addr_reg <= (others => '0');
                write_data_reg <= (others => '0');
                read_data_reg <= (others => '0');
                
                write_state_reg <= IDLE;
                read_state_reg <= IDLE;
            else
                if (interface_to_master.execute_write = '1') then
                    write_addr_reg <= interface_to_master.addr_write;
                    write_data_reg <= interface_to_master.data_write;
                end if;
                
                if (read_data_reg_en = '1') then
                    read_data_reg <= to_master.read_data_ch.data;
                end if;
                
                write_state_reg <= write_state_next;
                read_state_reg <= read_state_next;
            end if;
        end if;
    end process;

    interface_from_master.data_read <= read_data_reg;

end rtl;
