library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity priority_encoder_2_4 is
    port(
        d : in std_logic_vector(3 downto 0);
        q : out std_logic_vector(1 downto 0);
        v : out std_logic
    );
end priority_encoder_2_4;

architecture rtl of priority_encoder_2_4 is

begin
    q(0) <= d(3) or (not d(2) and d(1));
    q(1) <= d(3) or d(2);
    v <= d(0) or d(1) or d(2) or d(3);

end rtl;
