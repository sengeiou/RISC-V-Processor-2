
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.axi_interface_signal_groups.all;

package interconnect_pkg is 
    constant NUM_MASTERS : integer := 2;
    type write_addr_ch_master_array is array(0 to NUM_MASTERS - 1) of WriteAddressChannel;
    type write_data_ch_master_array is array(0 to NUM_MASTERS - 1) of WriteDataChannel; 
    type write_resp_ch_master_array is array(0 to NUM_MASTERS - 1) of WriteResponseChannel; 
    type read_addr_ch_master_array is array(0 to NUM_MASTERS - 1) of ReadAddressChannel; 
    type read_data_ch_master_array is array(0 to NUM_MASTERS - 1) of ReadDataChannel; 
    
    constant NUM_SLAVES : integer := 2;
    type write_addr_ch_slave_array is array(0 to NUM_SLAVES - 1) of WriteAddressChannel;
    type write_data_ch_slave_array is array(0 to NUM_SLAVES - 1) of WriteDataChannel; 
    type write_resp_ch_slave_array is array(0 to NUM_SLAVES - 1) of WriteResponseChannel; 
    type read_addr_ch_slave_array is array(0 to NUM_SLAVES - 1) of ReadAddressChannel; 
    type read_data_ch_slave_array is array(0 to NUM_SLAVES - 1) of ReadDataChannel; 
end package interconnect_pkg;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.axi_interface_signal_groups.all;
use work.interconnect_pkg.all;

entity axi_interconnect_simple is
    port(
        -- Master I/O
        write_addr_master_chs : in write_addr_ch_master_array;
        write_data_master_chs : in write_data_ch_master_array;
        write_resp_master_chs : out write_resp_ch_master_array;
        read_addr_master_chs : in read_addr_ch_master_array;
        read_data_master_chs : out read_data_ch_master_array;
        
        -- Slave I/O
        write_addr_slave_chs : out write_addr_ch_slave_array;
        write_data_slave_chs : out write_data_ch_slave_array;
        write_resp_slave_chs : in write_resp_ch_slave_array;
        read_addr_slave_chs : out read_addr_ch_slave_array;
        read_data_slave_chs : in read_data_ch_slave_array
        
        -- Control Signals
        
    );
end axi_interconnect_simple;

architecture rtl of axi_interconnect_simple is
    signal write_addr_bus_ch : WriteAddressChannel;
    signal write_data_bus_ch : WriteDataChannel;
    signal write_resp_bus_ch : WriteResponseChannel;
    signal read_addr_bus_ch : ReadAddressChannel;
    signal read_data_bus_ch : ReadDataChannel;
    
    signal write_bus_slave_sel : std_logic_vector(integer(ceil(log2(real(NUM_MASTERS)))) - 1 downto 0);
    signal write_bus_master_sel : std_logic_vector(integer(ceil(log2(real(NUM_MASTERS)))) - 1 downto 0);
    
    signal read_bus_slave_sel : std_logic_vector(integer(ceil(log2(real(NUM_MASTERS)))) - 1 downto 0);
    signal read_bus_master_sel : std_logic_vector(integer(ceil(log2(real(NUM_MASTERS)))) - 1 downto 0);
begin
    

    write_bus_chs_master_proc : process(write_bus_master_sel)
    begin
        write_addr_bus_ch <= write_addr_master_chs(to_integer(unsigned(write_bus_master_sel)));
        write_data_bus_ch <= write_data_master_chs(to_integer(unsigned(write_bus_master_sel)));

        write_resp_master_chs(to_integer(unsigned(write_bus_master_sel))) <= write_resp_bus_ch;
    end process;
    
    write_bus_chs_slave_proc : process(write_bus_slave_sel)
    begin
        write_resp_bus_ch <= write_resp_slave_chs(to_integer(unsigned(write_bus_slave_sel)));
        
        write_addr_slave_chs(to_integer(unsigned(write_bus_slave_sel))) <= write_addr_bus_ch;
        write_data_slave_chs(to_integer(unsigned(write_bus_slave_sel))) <= write_data_bus_ch;
    end process;
    
    read_bus_chs_master_proc : process(read_bus_master_sel)
    begin
        read_addr_bus_ch <= read_addr_master_chs(to_integer(unsigned(read_bus_master_sel)));
        read_data_master_chs(to_integer(unsigned(read_bus_master_sel))) <= read_data_bus_ch;
    end process;
    
    read_bus_chs_slave_proc : process(read_bus_slave_sel)
    begin
        read_data_bus_ch <= read_data_slave_chs(to_integer(unsigned(read_bus_slave_sel)));
        read_addr_slave_chs(to_integer(unsigned(read_bus_slave_sel))) <= read_addr_bus_ch;
    end process;
    
    write_bus_master_sel <= (others => '0');
    write_bus_slave_sel <= (others => '0');
    
    read_bus_master_sel <= (others => '0');
    read_bus_slave_sel <= (others => '0');

end rtl;
















