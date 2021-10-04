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
    
--    signal mem : mem_type := (
--        0 => "00000000000100001000000010010011",         -- ADDI x1, x1, 1
--        4 => "11111111111100010000000100010011",         -- ADDI x2, x2, 0xFFF
--        8 => "10000000000000011000000110010011",         -- ADDI x3, x3, 0x400
--        12 => "11111111111111111111111100010111",        -- AUIPC x30, 0xFFFFFF

--        32 => "00000000010100100000001000010011",         -- ADDI x4, x4, 5
--        36 => "00000000111100101000001010010011",         -- ADDI x5, x5, 15

--        60 => "00000000010100100000001100110011",         -- ADD x6, x4, x5
--        64 => "01000000010100100000001110110011",         -- SUB x7, x4, x5
--        68 => "00000000010000001001010000110011",         -- SLL x8, x1, x4
--        72 => "01000000010000011101010010110011",         -- SRA x9, x3, x4

--        96 => "10101010101010101010010100110111",         -- LUI x10, 0xAAAAA
        
--        --30 => "00000000000001010010010110000011",         -- LW x11, x10(0)
--        120 => "11111111111111111111010110110111",         -- LUI x11, 0xFFFFF
        
--        140 => "00000000101001011010000000100011",         -- SW x10, x11(0)
        
--        --160 => "00000000000101100000011000010011",         -- ADDI x12, x12, 1
--        --176 => "00000000110001011010000000100011",         -- SW x12, x11(0)
--        --180 => "11111110110111111111111111101111",         -- JAL x31, -20
--        --180 => "00000000010011111000111111100111",         -- JALR x31, x31(0)
        
--        others => (others => '0')
--    );
    
    -- FORWARDING TEST
--    signal mem : mem_type := (
--        0 => "00000000000100001000000010010011",         -- ADDI x1, x1, 1
--        4 => "00000000000100001000000010110011",         -- ADD x1, x1, x1
--        8 => "00000000000100001000000010110011",         -- ADD x1, x1, x1
--        12 => "00000000000100001000000010110011",        -- ADD x1, x1, x1
--        16 => "00000000000100001000000010110011",        -- ADD x1, x1, x1
--        20 => "00000000000100001000000010110011",        -- ADD x1, x1, x1
        
        
--        24 => "11111110001000001100100011100011",        -- BLT x1, x2, -16
--        28 => "00000000101000011000000110010011",        -- ADDI x3, x3, 10
        
--        others => (others => '0')
--    );

--    signal mem : mem_type := (
--        0 => "11111111111111111111001000110111",         -- LUI x4, 0xFFFFF
--        4 => "01000000100000010000000100010011",         -- ADDI x2, x2, 8
--        --4 => "00000000000000010000000100110111",         -- LUI x2, 65536 / 2
--        8 => "00000000000100001000000010010011",         -- ADDI x1, x1, 1
        
--        12 => "11111110001000001100111011100011",        -- BLT x1, x2, -4
--        16 => "00000000000100011000000110010011",        -- ADDI x3, x3, 1
--        20 => "00000000001100100010000000100011",        -- SW x3, x4(0)
--        24 => "00000000000000001111000010010011",        -- ANDI x1, x1, 0
--        28 => "11111110110111111111000001101111",        -- JAL x0, -20
        
--        others => (others => '0')
--    );

    -- ROM ACCESS TEST
    signal mem : mem_type := (
        0 => "00000000000000000000000010010011",         -- ADDI x1, x0, 0
        4 => "00000000000000001010000100000011",         -- LW x2, x1(0)
        
        8 => "00000000010000001000000010010011",         -- ADDI x1, x1, 4
        12 => "00000000000000001010000110000011",         -- LW x3, x1(0)
        
        16 => "00000000010000001000000010010011",         -- ADDI x1, x1, 4
        20 => "00000000000000001010001000000011",         -- LW x4, x1(0)
        
        24 => "00000000010000001000000010010011",         -- ADDI x1, x1, 4
        28 => "00000000000000001010001010000011",         -- LW x5, x1(0)
        
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
