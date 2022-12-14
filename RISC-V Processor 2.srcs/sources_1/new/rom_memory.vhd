library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use STD.TEXTIO.ALL;

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
    type ram_type is array (2 ** ADDR_WIDTH_BITS - 1 downto 0) of std_logic_vector (DATA_WIDTH_BITS - 1 downto 0);

    impure function init_ram_hex return ram_type is
        file text_file : text open read_mode is "C:\Vivado Projects\RISC-V Processor\RISC-V-Processor-2\firmware.hex";
        variable text_line : line;
        variable ram_content : ram_type;
        variable temp : std_logic_vector(31 downto 0);
        begin
            for i in 0 to 256 - 1 loop
                readline(text_file, text_line);
                hread(text_line, temp);

                ram_content(i) := temp;
				--for j in 0 to 3 loop
                --    ram_content(i)(8 * (j + 1) - 1 downto 8 * j) := temp(8 * (4 - j) - 1 downto 8 * (3 - j));
                --end loop;
            end loop;    
 
        return ram_content;
    end function;
    
    signal mem : ram_type := init_ram_hex;

begin
    process (addr, en)
    begin
        if (en = '1') then
            data <= mem(to_integer(unsigned(addr(ADDR_WIDTH_BITS - 1 downto 2))));
        else
            data <= (others => '0');
        end if;
    end process;

end rtl;
