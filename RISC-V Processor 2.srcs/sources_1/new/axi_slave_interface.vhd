----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/31/2021 11:02:55 AM
-- Design Name: 
-- Module Name: axi_slave_interface - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_slave_interface is
    port(
        -- CHANNEL SIGNALS
        from_master : in work.axi_interface_signal_groups.FromMaster;
        to_master : out work.axi_interface_signal_groups.ToMaster;
        
        -- HANDSHAKE SIGNALS
        master_handshake : in work.axi_interface_signal_groups.HandshakeMasterSrc;
        slave_handshake : out work.axi_interface_signal_groups.HandshakeSlaveSrc;
        
        -- OTHER DATA SIGNALS
        from_slave : in work.axi_interface_signal_groups.FromSlave;
        to_slave : out work.axi_interface_signal_groups.ToSlave;
        
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

    signal write_addr_reg : std_logic_vector(2 ** work.axi_interface_signal_groups.AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal write_data_reg : std_logic_vector(2 ** work.axi_interface_signal_groups.AXI_DATA_BUS_WIDTH - 1 downto 0);
    
    signal read_addr_reg : std_logic_vector(2 ** work.axi_interface_signal_groups.AXI_ADDR_BUS_WIDTH - 1 downto 0);
    signal read_data_reg : std_logic_vector(2 ** work.axi_interface_signal_groups.AXI_DATA_BUS_WIDTH - 1 downto 0);

    signal write_state_reg : write_state_type;
    signal write_state_next : write_state_type;
    
    signal read_state_reg : read_state_type;
    signal read_state_next : read_state_type;
begin
    write_state_transition : process(all)
    begin
        case write_state_reg is
            when IDLE =>
                if (master_handshake.awvalid = '1') then
                    write_state_next <= DATA_STATE;
                else
                    write_state_next <= IDLE;
                end if;
            when DATA_STATE => 
                if (from_master.write_data_ch.last = '1') then
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
                slave_handshake.bvalid <= '0';

                slave_handshake.awready <= '1';
                slave_handshake.wready <= '0';
            when DATA_STATE => 
                slave_handshake.bvalid <= '0';

                slave_handshake.awready <= '0';
                slave_handshake.wready <= '1';
            when RESPONSE_STATE_1 => 
                slave_handshake.bvalid <= '1';

                slave_handshake.awready <= '0';
                slave_handshake.wready <= '0';
            when RESPONSE_STATE_2 => 
                slave_handshake.bvalid <= '1';
                
                slave_handshake.awready <= '0';
                slave_handshake.wready <= '0';
        end case;
    end process;
    
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
                if (master_handshake.rready = '1') then
                    read_state_next <= IDLE;
                end if;
        end case;
    end process;
    
    read_state_outputs : process(read_state_reg)
    begin
        case read_state_reg is
            when IDLE =>
                to_master.read_data_ch.data <= (others => '0');
                to_master.read_data_ch.resp <= (others => '0');
                to_master.read_data_ch.last <= '0';
                
                slave_handshake.rvalid <= '0';
                
                slave_handshake.arready <= '1';
            when ADDR_STATE => 
                to_master.read_data_ch.data <= (others => '0');
                to_master.read_data_ch.resp <= (others => '0');
                to_master.read_data_ch.last <= '0';
                
                slave_handshake.rvalid <= '0';
                
                slave_handshake.arready <= '0';
            when DATA_STATE => 
                to_master.read_data_ch.data <= from_slave.data_read;
                to_master.read_data_ch.resp <= (others => '0');
                to_master.read_data_ch.last <= '1';
                
                slave_handshake.rvalid <= '1';
                
                slave_handshake.arready <= '0';
        end case;
    end process;

    register_control : process(clk, reset)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                write_addr_reg <= (others => '0');
                write_data_reg <= (others => '0');
                
                read_addr_reg <= (others => '0');
                read_data_reg <= (others => '0');
                
                write_state_reg <= IDLE;
                read_state_reg <= IDLE;
            else
                if (master_handshake.wvalid = '1') then
                    write_data_reg <= from_master.write_data_ch.data;
                end if;
            
                if (master_handshake.awvalid = '1') then
                    write_addr_reg <= from_master.write_addr_ch.addr;
                end if;
            
                if (master_handshake.arvalid = '1') then
                    read_addr_reg <= from_master.read_addr_ch.addr;
                end if;
            
                write_state_reg <= write_state_next;
                read_state_reg <= read_state_next;
            end if;
        end if;
    end process;


    to_slave.data_write <= write_data_reg;
    to_slave.addr_write <= write_addr_reg;
    
    from_slave.addr_read <= read_addr_reg;

end rtl;











