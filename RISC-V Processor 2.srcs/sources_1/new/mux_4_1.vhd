----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/23/2021 12:49:42 PM
-- Design Name: 
-- Module Name: mux_4_1 - rtl
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

entity mux_4_1 is
    generic(
        WIDTH_BITS : integer
    );
    port(
        in_0, in_1, in_2, in_3 : in std_logic_vector(WIDTH_BITS - 1 downto 0);
        output : out std_logic_vector(WIDTH_BITS - 1 downto 0);
        sel : in std_logic_vector(1 downto 0)
    );
end mux_4_1;

architecture rtl of mux_4_1 is
begin
    with sel select output <=
        in_0 when "00",
        in_1 when "01",
        in_2 when "10",
        in_3 when "11",
        (others => '0') when others;    
end rtl;