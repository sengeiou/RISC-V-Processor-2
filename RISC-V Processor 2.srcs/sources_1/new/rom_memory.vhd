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
        0 => "00000000000100000000000010010011",        -- ADDI x1, x0, 1 
        4 => "00000000000100000000000100010011",        -- ADDI x2, x0, 1
        8 => "00000000000100010000000110110011",        -- ADD x3, x1, x2
        
        12 => "00000111111100000110001000010011",       -- ORI x4, x0, 127 
        16 => "00000011001000000110001010010011",       -- ORI x5, x0, 50
        20 => "01000000010100100000001100110011",       -- SUB x6, x4, x5
        
        --24 => "00000000011000000010000000100011",       -- SW x6, x0(0)
        28 => "00000000000000000010001110000011",       -- LW x7, x0(0)
        
        others => (others => '0')
    );
    
begin
    process (addr)
    begin
        data <= mem(to_integer(unsigned(addr)));
    end process;

end rtl;
