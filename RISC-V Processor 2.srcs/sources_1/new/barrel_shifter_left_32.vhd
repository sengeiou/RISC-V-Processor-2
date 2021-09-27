library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity barrel_shifter_left_32 is
    port(
        data_in : in std_logic_vector(31 downto 0);
        data_out : out std_logic_vector(31 downto 0);
        
        shift_amount : in std_logic_vector(4 downto 0)
    );
end barrel_shifter_left_32;

architecture rtl of barrel_shifter_left_32 is
    signal shift_1_out : std_logic_vector(31 downto 0);
    signal shift_2_out : std_logic_vector(31 downto 0);
    signal shift_4_out : std_logic_vector(31 downto 0);
    signal shift_8_out : std_logic_vector(31 downto 0);
    signal shift_16_out : std_logic_vector(31 downto 0);
begin
    process(all)
    begin
        if (shift_amount(0) = '1') then
            shift_1_out <= data_in(30 downto 0) & "0";
        else
            shift_1_out <= data_in;
        end if;
            
        if (shift_amount(1) = '1') then
            shift_2_out <= shift_1_out(29 downto 0) & "00";
        else
            shift_2_out <= shift_1_out;
        end if;
        
        if (shift_amount(2) = '1') then
            shift_4_out <= shift_2_out(27 downto 0) & "0000";
        else
            shift_4_out <= shift_2_out;
        end if;
        
        if (shift_amount(3) = '1') then
            shift_8_out <= shift_4_out(23 downto 0) & "00000000";
        else
            shift_8_out <= shift_4_out;
        end if;
        
        if (shift_amount(4) = '1') then
            shift_16_out <= shift_8_out(15 downto 0) & "0000000000000000";
        else
            shift_16_out <= shift_8_out;
        end if;
        
    data_out <= shift_16_out;
    end process;
    
end rtl;