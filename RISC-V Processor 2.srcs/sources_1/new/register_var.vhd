library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity register_var is
    generic(
        WIDTH_BITS : integer
    );
    port(
            d : in std_logic_vector(WIDTH_BITS - 1 downto 0);
            q : out std_logic_vector(WIDTH_BITS - 1 downto 0);
            clk : in std_logic;
            reset, en : in std_logic
    );
end register_var;

architecture rtl of register_var is

begin

    process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                q <= (others => '0');
            elsif (en = '1') then
                q <= d;
            end if;
        end if;
    end process;

end rtl;