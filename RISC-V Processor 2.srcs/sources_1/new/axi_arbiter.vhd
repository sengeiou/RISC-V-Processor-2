library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.axi_interface_signal_groups.all;

package arbiter_pkg is 
    constant NUM_MASTERS : integer := 2;
    type write_addr_ch_master_array is array(0 to NUM_MASTERS - 1) of WriteAddressChannel; 
end package arbiter_pkg;

use work.arbiter_pkg.all;

entity axi_arbiter is
    port(
        axi_write_addr_ch_masters : in write_addr_ch_master_array
    );
end axi_arbiter;

architecture rtl of axi_arbiter is

begin
    

end rtl;
