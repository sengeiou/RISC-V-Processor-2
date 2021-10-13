use work.axi_interface_signal_groups.all;

package test is
    type to_master_array is array(3 downto 0) of ToMaster;
    type from_master_array is array(3 downto 0) of FromMaster;
    type to_slave_array is array(3 downto 0) of ToSlave;
    type from_slave_array is array(3 downto 0) of FromSlave;
end package test;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use work.axi_interface_signal_groups.all;
use work.test.all;

entity axi_interconnect_simple is
    generic(
        NUM_MASTERS : integer;
        NUM_SLAVES : integer
    );
    port(
        to_masters : out to_master_array;
        from_masters : in from_master_array;
        
        to_slaves : out to_slave_array;
        from_slaves : in from_slave_array;
        
        clk : in std_logic;
        reset : in std_logic
    );
end axi_interconnect_simple;

architecture rtl of axi_interconnect_simple is
    -- ===== TYPE DEFINITIONS =====
    type write_addr_ch_master_array is array(0 to NUM_MASTERS - 1) of WriteAddressChannel;
    type write_data_ch_master_array is array(0 to NUM_MASTERS - 1) of WriteDataChannel; 
    type write_resp_ch_master_array is array(0 to NUM_MASTERS - 1) of WriteResponseChannel; 
    type read_addr_ch_master_array is array(0 to NUM_MASTERS - 1) of ReadAddressChannel; 
    type read_data_ch_master_array is array(0 to NUM_MASTERS - 1) of ReadDataChannel; 

    type write_addr_ch_slave_array is array(0 to NUM_SLAVES - 1) of WriteAddressChannel;
    type write_data_ch_slave_array is array(0 to NUM_SLAVES - 1) of WriteDataChannel; 
    type write_resp_ch_slave_array is array(0 to NUM_SLAVES - 1) of WriteResponseChannel; 
    type read_addr_ch_slave_array is array(0 to NUM_SLAVES - 1) of ReadAddressChannel; 
    type read_data_ch_slave_array is array(0 to NUM_SLAVES - 1) of ReadDataChannel; 
    
    type handshakes_read_master_array is array(0 to NUM_MASTERS - 1) of HandshakeReadMaster;
    type handshakes_write_master_array is array(0 to NUM_MASTERS - 1) of HandshakeWriteMaster;
    type handshakes_read_slave_array is array(0 to NUM_SLAVES - 1) of HandshakeReadSlave;
    type handshakes_write_slave_array is array(0 to NUM_SLAVES - 1) of HandshakeWriteSlave;
    -- ============================

    -- ===== MASTER AND SLAVE CONTROLLER INTERFACES =====
    signal write_addr_master_chs : write_addr_ch_master_array;
    signal write_data_master_chs : write_data_ch_master_array;
    signal write_resp_master_chs : write_resp_ch_master_array;
    signal read_addr_master_chs : read_addr_ch_master_array;
    signal read_data_master_chs : read_data_ch_master_array;
        
    signal write_addr_slave_chs : write_addr_ch_slave_array;
    signal write_data_slave_chs : write_data_ch_slave_array;
    signal write_resp_slave_chs : write_resp_ch_slave_array;
    signal read_addr_slave_chs : read_addr_ch_slave_array;
    signal read_data_slave_chs : read_data_ch_slave_array;
    
    signal handshakes_read_masters_to_bus : handshakes_read_master_array;
    signal handshakes_write_masters_to_bus : handshakes_write_master_array;
    signal handshakes_read_slaves_to_bus : handshakes_read_slave_array;
    signal handshakes_write_slaves_to_bus : handshakes_write_slave_array;
    
    signal handshakes_read_masters_from_bus : handshakes_read_master_array;
    signal handshakes_write_masters_from_bus : handshakes_write_master_array;
    signal handshakes_read_slaves_from_bus : handshakes_read_slave_array;
    signal handshakes_write_slaves_from_bus : handshakes_write_slave_array;
    -- ==================================================

    -- ===== BUS SIGNALS =====
    signal write_addr_bus_ch : WriteAddressChannel;
    signal write_data_bus_ch : WriteDataChannel;
    signal write_resp_bus_ch : WriteResponseChannel;
    signal read_addr_bus_ch : ReadAddressChannel;
    signal read_data_bus_ch : ReadDataChannel;
    
    signal handshake_read_master : HandshakeReadMaster;
    signal handshake_write_master : HandshakeWriteMaster;
    signal handshake_read_slave : HandshakeReadSlave;
    signal handshake_write_slave : HandshakeWriteSlave;
    -- =======================
    
    signal write_bus_slave_sel : std_logic_vector(integer(ceil(log2(real(NUM_MASTERS)))) - 1 downto 0);
    signal write_bus_master_sel : std_logic_vector(integer(ceil(log2(real(NUM_MASTERS)))) - 1 downto 0);
    
    signal read_bus_slave_sel : std_logic_vector(integer(ceil(log2(real(NUM_MASTERS)))) - 1 downto 0);
    signal read_bus_master_sel : std_logic_vector(integer(ceil(log2(real(NUM_MASTERS)))) - 1 downto 0);
begin
    GEN_MASTER_CONTROLLERS : for i in 0 to NUM_MASTERS - 1 generate
        master_controller : entity work.axi_master_interface(rtl)
                            port map(axi_write_addr_ch => write_addr_master_chs(i),
                                     axi_write_data_ch => write_data_master_chs(i),
                                     axi_write_resp_ch => write_resp_master_chs(i),
                                     axi_read_addr_ch => read_addr_master_chs(i),
                                     axi_read_data_ch => read_data_master_chs(i),
                                     
                                     master_write_handshake => handshakes_write_masters_to_bus(i),
                                     master_read_handshake => handshakes_read_masters_to_bus(i),
                                     slave_write_handshake => handshakes_write_slaves_from_bus(i),
                                     slave_read_handshake => handshakes_read_slaves_from_bus(i),
                                     
                                     interface_to_master => to_masters(i),
                                     master_to_interface => from_masters(i),
                                     
                                     clk => clk,
                                     reset => reset);
    end generate; 
    
    GEN_SLAVE_CONTROLLERS : for i in 0 to NUM_SLAVES - 1 generate
        master_controller : entity work.axi_slave_interface(rtl)
                            port map(axi_write_addr_ch => write_addr_slave_chs(i),
                                     axi_write_data_ch => write_data_slave_chs(i),
                                     axi_write_resp_ch => write_resp_slave_chs(i),
                                     axi_read_addr_ch => read_addr_slave_chs(i),
                                     axi_read_data_ch => read_data_slave_chs(i),
                                     
                                     master_write_handshake => handshakes_write_masters_from_bus(i),
                                     master_read_handshake => handshakes_read_masters_from_bus(i),
                                     slave_write_handshake => handshakes_write_slaves_to_bus(i),
                                     slave_read_handshake => handshakes_read_slaves_to_bus(i),
                                     
                                     to_slave => to_slaves(i),
                                     from_slave => from_slaves(i),
                                     
                                     clk => clk,
                                     reset => reset);
    end generate; 

    write_bus_chs_master_proc : process(write_bus_master_sel, write_addr_master_chs, write_data_master_chs, write_resp_bus_ch, handshakes_write_masters_to_bus, handshake_write_slave)
    begin
        write_addr_bus_ch <= write_addr_master_chs(to_integer(unsigned(write_bus_master_sel)));
        write_data_bus_ch <= write_data_master_chs(to_integer(unsigned(write_bus_master_sel)));

        write_resp_master_chs(to_integer(unsigned(write_bus_master_sel))) <= write_resp_bus_ch;
        
        handshake_write_master <= handshakes_write_masters_to_bus(to_integer(unsigned(write_bus_master_sel)));
        handshakes_write_slaves_from_bus(to_integer(unsigned(write_bus_master_sel))) <= handshake_write_slave;
    end process;
    
    write_bus_chs_slave_proc : process(write_bus_slave_sel, write_resp_slave_chs, write_addr_bus_ch, write_data_bus_ch, handshakes_write_slaves_to_bus, handshake_write_master)
    begin
        write_resp_bus_ch <= write_resp_slave_chs(to_integer(unsigned(write_bus_slave_sel)));
        
        write_addr_slave_chs(to_integer(unsigned(write_bus_slave_sel))) <= write_addr_bus_ch;
        write_data_slave_chs(to_integer(unsigned(write_bus_slave_sel))) <= write_data_bus_ch;
        
        handshake_write_slave <= handshakes_write_slaves_to_bus(to_integer(unsigned(write_bus_slave_sel)));
        handshakes_write_masters_from_bus(to_integer(unsigned(write_bus_slave_sel))) <= handshake_write_master;
    end process;
    
    read_bus_chs_master_proc : process(read_bus_master_sel, read_addr_master_chs, read_data_bus_ch, handshakes_read_masters_to_bus, handshake_read_slave)
    begin
        read_addr_bus_ch <= read_addr_master_chs(to_integer(unsigned(read_bus_master_sel)));
        read_data_master_chs(to_integer(unsigned(read_bus_master_sel))) <= read_data_bus_ch;
        
        handshake_read_master <= handshakes_read_masters_to_bus(to_integer(unsigned(read_bus_master_sel)));
        handshakes_read_slaves_from_bus(to_integer(unsigned(read_bus_master_sel))) <= handshake_read_slave;
    end process;
    
    read_bus_chs_slave_proc : process(read_bus_slave_sel, read_data_slave_chs, read_addr_bus_ch, handshakes_read_slaves_to_bus, handshake_read_master)
    begin
        read_data_bus_ch <= read_data_slave_chs(to_integer(unsigned(read_bus_slave_sel)));
        read_addr_slave_chs(to_integer(unsigned(read_bus_slave_sel))) <= read_addr_bus_ch;
        
        handshake_read_slave <= handshakes_read_slaves_to_bus(to_integer(unsigned(read_bus_slave_sel)));
        handshakes_read_masters_from_bus(to_integer(unsigned(read_bus_slave_sel))) <= handshake_read_master;
    end process;
    
    write_bus_master_sel <= (others => '0');
    write_bus_slave_sel <= (others => '0');
    
    read_bus_master_sel <= (others => '0');
    read_bus_slave_sel <= (others => '0');

end rtl;
















