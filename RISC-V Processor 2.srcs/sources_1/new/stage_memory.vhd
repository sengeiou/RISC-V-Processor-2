library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pkg_cpu.all;

entity stage_memory is
    port(
        data_in : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        
        data_out : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0)
    );
end stage_memory;

architecture structural of stage_memory is

begin
    data_out <= data_in;

end structural;











