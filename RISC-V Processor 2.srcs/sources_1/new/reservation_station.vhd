library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;

use work.pkg_cpu.all;

entity reservation_station is
    generic(
        NUM_ENTRIES : integer range 1 to 1024;
        OPCODE_BITS : integer range 0 to 32;
        OPERAND_BITS : integer range 0 to 64
    );
    port(
        cdb_opcode_bits : std_logic_vector(OPCODE_BITS - 1 downto 0);
        cdb_res_stat_1 : std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
        cdb_res_stat_2 : std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
        cdb_operand_1 : std_logic_vector(OPERAND_BITS - 1 downto 0);
        cdb_operand_2 : std_logic_vector(OPERAND_BITS - 1 downto 0)
    );
end reservation_station;

architecture rtl of reservation_station is
    -- Reservation station format [OPCODE | RES_STAT_1 | RES_STAT_2 | OPERAND_1 | OPERAND_2 | READY | BUSY]
    type reservation_station_entries is array(NUM_ENTRIES - 1 downto 0) of std_logic_vector(OPCODE_BITS + 2 * integer(ceil(log2(real(NUM_ENTRIES)))) + 2 * OPERAND_BITS + 1 downto 0);  -- Number of bits in one entry of the reservation station
begin
    

end rtl;
