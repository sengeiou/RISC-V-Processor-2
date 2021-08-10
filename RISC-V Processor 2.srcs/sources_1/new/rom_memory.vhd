library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity rom_memory is
    generic(
        DATA_WIDTH_BITS : integer := 32;
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
        0 => "00000000000100001000000010010011",         -- ADDI x1, x1, 1
        4 => "11111111111100010000000100010011",         -- ADDI x2, x2, 0xFFF
        8 => "10000000000000011000000110010011",         -- ADDI x3, x3, 0x400

        32 => "00000000010100100000001000010011",         -- ADDI x4, x4, 5
        36 => "00000000111100101000001010010011",         -- ADDI x5, x5, 15

        60 => "00000000010100100000001100110011",         -- ADD x6, x4, x5
        64 => "01000000010100100000001110110011",         -- SUB x7, x4, x5
        68 => "00000000010000001001010000110011",         -- SLL x8, x1, x4
        72 => "01000000010000011101010010110011",         -- SRA x9, x3, x4

        96 => "10101010101010101010010100110111",         -- LUI x10, 0xAAAAA
        
        --30 => "00000000000001010010010110000011",         -- LW x11, x10(0)
        120 => "11111111111111111111010110110111",         -- LUI x11, 0xFFFFF
        
        140 => "00000000101001011010000000100011",         -- SW x10, x11(0)
        
        160 => "00000000000101100000011000010011",         -- ADDI x12, x12, 1
        180 => "11111110110111111111111111101111",         -- JAL x31, -20
        
        
        others => (others => '0')
    );
begin
    process (clk, addr)
    begin
        if (falling_edge(clk)) then
            data <= mem(to_integer(unsigned(addr)));
        end if;
    end process;

end rtl;
