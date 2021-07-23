----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/23/2021 02:28:31 PM
-- Design Name: 
-- Module Name: barrel_shifter - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity barrel_shifter is
    port(
        data_in : in std_logic_vector(31 downto 0);
        data_out : out std_logic_vector(31 downto 0);
        
        shift_amount : in std_logic_vector(4 downto 0);
        shift_arith : in std_logic;
        shift_direction : in std_logic                              -- 0 = RIGHT | 1 = LEFT
    );
end barrel_shifter;

architecture rtl of barrel_shifter is
    signal shift_1_out : std_logic_vector(31 downto 0);
    signal shift_2_out : std_logic_vector(31 downto 0);
    signal shift_4_out : std_logic_vector(31 downto 0);
    signal shift_8_out : std_logic_vector(31 downto 0);
    signal shift_16_out : std_logic_vector(31 downto 0);
begin
    process(all)
    begin
        if (shift_amount(0) = '1') then
            if (shift_direction = '0') then
                if (shift_arith = '0') then
                    shift_1_out <= "0" & data_in(31 downto 1);
                else
                    shift_1_out <= data_in(31) & data_in(31 downto 1);
                end if;
            else
                shift_1_out <= data_in(30 downto 0) & "0";
            end if;
        else
            shift_1_out <= data_in;
        end if;
            
        if (shift_amount(1) = '1') then
            if (shift_direction = '0') then
                if (shift_arith = '0') then
                    shift_2_out <= "00" & shift_1_out(31 downto 2);
                else
                    shift_2_out <= shift_1_out(31) &
                                   shift_1_out(31) & 
                                   shift_1_out(31 downto 2);
                end if;
            else
                shift_2_out <= shift_1_out(29 downto 0) & "00";
            end if; 
        else
            shift_2_out <= shift_1_out;
        end if;
        
        if (shift_amount(2) = '1') then
            if (shift_direction = '0') then
                if (shift_arith = '0') then
                    shift_4_out <= "0000" & shift_2_out(31 downto 4);
                else
                    shift_4_out <= shift_2_out(31) &
                                   shift_2_out(31) & 
                                   shift_2_out(31) & 
                                   shift_2_out(31) & 
                                   shift_2_out(31 downto 4);
                end if;
            else
                shift_4_out <= shift_2_out(27 downto 0) & "0000";
            end if; 
        else
            shift_4_out <= shift_2_out;
        end if;
        
        if (shift_amount(3) = '1') then
            if (shift_direction = '0') then
                if (shift_arith = '0') then
                    shift_8_out <= "00000000" & shift_4_out(31 downto 8);
                else
                    shift_8_out <= shift_4_out(31) &
                                   shift_4_out(31) & 
                                   shift_4_out(31) & 
                                   shift_4_out(31) & 
                                   shift_4_out(31) & 
                                   shift_4_out(31) & 
                                   shift_4_out(31) & 
                                   shift_4_out(31) & 
                                   shift_4_out(31 downto 8);
                end if;
            else
                shift_8_out <= shift_4_out(23 downto 0) & "00000000";
            end if; 
        else
            shift_8_out <= shift_4_out;
        end if;
        
        if (shift_amount(4) = '1') then
            if (shift_direction = '0') then
                if (shift_arith = '0') then
                    shift_16_out <= "0000000000000000" & shift_8_out(31 downto 16);
                else
                    shift_16_out <= shift_8_out(31) &
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31) & 
                                   shift_8_out(31 downto 16);
                end if;
            else
                shift_16_out <= shift_8_out(15 downto 0) & "0000000000000000";
            end if; 
        else
            shift_16_out <= shift_8_out;
        end if;
    end process;
    
    data_out <= shift_16_out;

end rtl;