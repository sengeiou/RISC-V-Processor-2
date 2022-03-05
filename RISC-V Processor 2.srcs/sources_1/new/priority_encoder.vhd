library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity priority_encoder is
    generic(
        NUM_INPUTS : integer range 1 to 8192
    );
    port(
        d : in std_logic_vector(NUM_INPUTS - 1 downto 0);
        q : out std_logic_vector(integer(ceil(log2(real(NUM_INPUTS)))) - 1 downto 0)
    );
end priority_encoder;

architecture rtl of priority_encoder is

begin
    process(d)
        variable max : integer;
    begin
        for k in 0 to NUM_INPUTS - 1 loop
            if (d(k) = '1') then
                max := k;
            end if;
        end loop;
        
        q <= std_logic_vector(to_unsigned(max, integer(ceil(log2(real(NUM_INPUTS))))));
    end process;

end rtl;
