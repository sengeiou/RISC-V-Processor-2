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
        en : in std_logic;
        clk : in std_logic
    );
end rom_memory;

architecture rtl of rom_memory is
    type mem_type is array (2 ** ADDR_WIDTH_BITS - 1 downto 0) of std_logic_vector (DATA_WIDTH_BITS - 1 downto 0);
    
    signal mem : mem_type := (
        0 => "11111111111101000000010000010011",       -- ADDI x8, x0, 0xFFF
        4 => "00000000000101000000010000010011",        -- ADDI x8, x8, 1
        --8 => "00000000100001000010000000100011",       -- SW x8, x8(0)
        --12 => "00000000000000000010001110000011",       -- LW x7, x0(0)
    
        16 => "00000000000100000000000010010011",        -- ADDI x1, x0, 1 
        20 => "00000000000100000000000100010011",        -- ADDI x2, x0, 1
        24 => "00000000000100010000000110110011",        -- ADD x3, x1, x2
        
        28 => "00000111111100000110001000010011",       -- ORI x4, x0, 127 
        32 => "00000011001000000110001010010011",       -- ORI x5, x0, 50
        36 => "01000000010100100000001100110011",       -- SUB x6, x4, x5
        40 => "01010101010100000000000000010011",       -- ADDI x0, x0, 0x5AA
       
        
        others => (others => '0')
    );

--    signal mem : mem_type := (
--        0 => "11111111111100000000000100010011",         -- ADDI x2, 0xFFF
--        4 => "10101010101100000000000110010011",         -- ADDI x3, 0xFFF
--        8 => "00000000001000010010000010100011",        -- SW x2, x2(1)
--        12 => "00000000001100010010000010100011",        -- SW x3, x2(1)
--        16 => "00000000010000000010001000000011",       -- LW x4, x0(4)
--        20 => "00000000100000000010001010000011",       -- LW x5, x0(8)
       
--        others => (others => '0')
--    );
    
begin
    process (addr, en)
    begin
        if (en = '1') then
            data <= mem(to_integer(unsigned(addr)));
        else
            data <= (others => '0');
        end if;
    end process;

end rtl;
