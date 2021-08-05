library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity rom_memory is
    generic(
        DATA_WIDTH_BITS : integer := 8;
        ADDR_WIDTH_BITS : integer := 8
    );
    port(
        data : out std_logic_vector(DATA_WIDTH_BITS - 1 downto 0);
        addr : in std_logic_vector(ADDR_WIDTH_BITS - 1 downto 0);
        clk : in std_logic
    );
end rom_memory;

architecture rtl of rom_memory is
    type mem_type is array (2 ** ADDR_WIDTH_BITS - 1 downto 0) of std_logic_vector (DATA_WIDTH_BITS - 1 downto 0);
    
    signal mem : mem_type := (
        0 => "00000000000100001000000010010011",
        others => (others => '0')
    );
begin
    process (clk, addr)
    begin
        if (rising_edge(clk)) then
            data <= mem(to_integer(unsigned(addr)));
        end if;
    end process;

end rtl;
