library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.axi_interface_signal_groups.all;

entity axi_slave_interface is
    port(
        -- CHANNEL SIGNALS
        from_master_interface : in FromMasterInterfaceToBus;
        to_master_interface : out ToMasterInterfaceFromBus;
        
        -- HANDSHAKE SIGNALS
        master_handshake : in HandshakeMasterSrc;
        slave_handshake : out HandshakeSlaveSrc;
        
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
                              DATA_STATE,
                              RESPONSE_STATE_1,
                              RESPONSE_STATE_2);
                              
    type read_state_type is (IDLE,
                             ADDR_STATE,
                             DATA_STATE);

    -- ========== WRITE REGISTERS ==========
    signal write_addr_reg : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal write_addr_next : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal write_addr_reg_en : std_logic;
    signal write_addr_incr : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);

    signal write_burst_size_reg : std_logic_vector(2 downto 0);
    
    signal write_burst_type_reg : std_logic_vector(1 downto 0);
    
    signal write_data_reg : std_logic_vector(2 ** AXI_DATA_BUS_WIDTH - 1 downto 0);

    signal write_state_reg : write_state_type;
    signal write_state_next : write_state_type;
    
   
    -- ========== READ REGISTERS ==========
    signal read_addr_reg : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal read_addr_next : std_logic_vector(2 ** AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal read_addr_reg_en : std_logic;
    
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
    write_state_transition : process(master_handshake.awvalid, from_master_interface.write_data_ch.last, slave_handshake.bvalid)
    begin
        case write_state_reg is
            when IDLE =>
                if (master_handshake.awvalid = '1') then
                    write_state_next <= DATA_STATE;
                else
                    write_state_next <= IDLE;
                end if;
            when DATA_STATE => 
                if (from_master_interface.write_data_ch.last = '1') then
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
        slave_handshake.bvalid <= '0';

        slave_handshake.awready <= '1';
        slave_handshake.wready <= '0';
        
        write_addr_reg_en <= '0';
        
        write_addr_next_sel <= "11";
        case write_state_reg is
            when IDLE =>
                write_addr_reg_en <= master_handshake.awvalid;
                
            when DATA_STATE => 
                slave_handshake.awready <= '0';
                slave_handshake.wready <= '1';
                
                write_addr_reg_en <= '1';
                
                write_addr_next_sel <= write_burst_type_reg;
                
            when RESPONSE_STATE_1 => 
                slave_handshake.bvalid <= '1';

                slave_handshake.awready <= '0';
                
            when RESPONSE_STATE_2 => 
                slave_handshake.bvalid <= '1';
                
                slave_handshake.awready <= '0';
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
    
    write_addr_reg_next_mux_proc : process(write_addr_next_sel, write_addr_reg, from_master_interface.write_addr_ch.addr)   -- CAUTION: DO NOT USE process(all) AS TEMPTING AS IT MAY BE BECAUSE IT WONT WORK (at least in the sim)!
    begin
        if (write_addr_next_sel = BURST_FIXED) then
            write_addr_next <= write_addr_reg;
        elsif (write_addr_next_sel = BURST_INCR) then
            write_addr_next <= std_logic_vector(unsigned(write_addr_reg) + 4);
        elsif (write_addr_next_sel = BURST_WRAP) then
            write_addr_next <= std_logic_vector(unsigned(write_addr_reg) + 4);      -- TEMP UNTIL WRAP MODE GETS IMPLEMENTED
        else
            write_addr_next <= from_master_interface.write_addr_ch.addr;
        end if;
    end process;
    
    -- =========================== READING =================================
    -- READ STATE MACHINE
    read_state_transition : process(all)
    begin
        case read_state_reg is 
            when IDLE => 
                if (master_handshake.arvalid = '1') then
                    read_state_next <= ADDR_STATE;
                else
                    read_state_next <= IDLE;
                end if;
            when ADDR_STATE => 
                    read_state_next <= DATA_STATE;
            when DATA_STATE => 
                if (read_burst_len_reg_zero = '1') then
                    read_state_next <= IDLE;
                else
                    read_state_next <= DATA_STATE;
                end if;
        end case;
    end process;
    
    read_state_outputs : process(all)
    begin
        to_master_interface.read_data_ch.data <= (others => '0');
        to_master_interface.read_data_ch.resp <= (others => '0');
        to_master_interface.read_data_ch.last <= '0';
                
        slave_handshake.rvalid <= '0';
        
        read_addr_reg_en <= '0';
        read_burst_len_reg_en <= '0';
        
        read_burst_len_mux_sel <= '0';
                
        slave_handshake.arready <= '1';
        case read_state_reg is
            when IDLE =>
                read_burst_len_reg_en <= master_handshake.arvalid;
                read_addr_reg_en <= master_handshake.arvalid;
                
                read_addr_next_sel <= "11";
            when ADDR_STATE => 
                slave_handshake.arready <= '0';
                
                -- ====================================
                read_burst_len_reg_en <= '0';
                read_addr_reg_en <= '0';
                
                read_addr_next_sel <= "00";
            when DATA_STATE => 
                to_master_interface.read_data_ch.data <= from_slave.data_read;
                to_master_interface.read_data_ch.last <= read_burst_len_reg_zero;
                
                slave_handshake.rvalid <= '1';
                slave_handshake.arready <= '0';
                
                to_master_interface.read_data_ch.last <= read_burst_len_reg_zero;
                
                read_burst_len_mux_sel <= '1';
                
                -- ====================================
                read_burst_len_reg_en <= not read_burst_len_reg_zero and
                                         master_handshake.rready;
                read_addr_reg_en <= master_handshake.rready;
                                         
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
    
    read_burst_len_next_mux_proc : process(read_burst_len_mux_sel, from_master_interface.read_addr_ch.len, read_burst_len_reg)
    begin
        if (read_burst_len_mux_sel = '0') then
            read_burst_len_next <= from_master_interface.read_addr_ch.len;
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
    
    read_addr_next_mux_proc : process(read_addr_next_sel)
    begin   
        if (read_addr_next_sel = BURST_FIXED) then
            read_addr_next <= read_addr_reg;
        elsif (read_addr_next_sel = BURST_INCR) then
            read_addr_next <= std_logic_vector(unsigned(read_addr_reg) + 4);
        elsif (read_addr_next_sel = BURST_WRAP) then
            read_addr_next <= std_logic_vector(unsigned(read_addr_reg) + 4);        -- TEMP UNTIL WRAP IMPLEMENTED
        else
            read_addr_next <= from_master_interface.read_addr_ch.addr;
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
                
                write_burst_type_reg <= (others => '0');
                write_burst_size_reg <= (others => '0');
                
                write_state_reg <= IDLE;
                read_state_reg <= IDLE;
            else
                if (master_handshake.wvalid = '1') then
                    write_data_reg <= from_master_interface.write_data_ch.data;
                end if;
            
                if (master_handshake.arvalid = '1') then     
                    read_burst_size_reg <= from_master_interface.read_addr_ch.size;
                    read_burst_type_reg <= from_master_interface.read_addr_ch.burst_type;
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











