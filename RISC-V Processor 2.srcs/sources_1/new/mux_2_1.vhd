library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux_2_1 is
    generic(
        WIDTH_BITS : integer
    );
    port(
        in_0, in_1 : in std_logic_vector(WIDTH_BITS - 1 downto 0);
        output : out std_logic_vector(WIDTH_BITS - 1 downto 0);
        sel : in std_logic
    );
end mux_2_1;

architecture rtl of mux_2_1 is

begin
    with sel select output <=
        in_0 when '0',
        in_1 when '1',
        (others => '0') when others;
end rtl;