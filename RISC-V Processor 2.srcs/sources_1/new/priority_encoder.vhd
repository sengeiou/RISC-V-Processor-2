library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity priority_encoder is
    generic(
        NUM_INPUTS : integer range 1 to 8192;
        HIGHER_INPUT_HIGHER_PRIO : boolean
    );
    port(
        d : in std_logic_vector(NUM_INPUTS - 1 downto 0);
        q : out std_logic_vector(integer(ceil(log2(real(NUM_INPUTS)))) - 1 downto 0);
        valid : out std_logic
    );
end priority_encoder;

architecture rtl of priority_encoder is
    constant D_ZERO : std_logic_vector(NUM_INPUTS - 1 downto 0) := (others => '0');
begin
    process(d)
        variable output_value : integer;
    begin
        if (d = D_ZERO) then
            q <= (others => '0');
            valid <= '0';
        else
            if (HIGHER_INPUT_HIGHER_PRIO = true) then
                for k in 0 to NUM_INPUTS - 1 loop
                    if (d(k) = '1') then
                        output_value := k;
                    end if;
                end loop;
            else
                for k in NUM_INPUTS - 1 downto 0 loop
                    if (d(k) = '1') then
                        output_value := k;
                    end if;
                end loop;
            end if;
        
            q <= std_logic_vector(to_unsigned(output_value, integer(ceil(log2(real(NUM_INPUTS))))));
            valid <= '1';
        end if;
    end process;

end rtl;
