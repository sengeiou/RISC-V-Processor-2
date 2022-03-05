library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.pkg_cpu.all;

entity reservation_station is
    generic(
        NUM_ENTRIES : integer range 1 to 1024;
        OPCODE_BITS : integer range 0 to 32;
        OPERAND_BITS : integer range 0 to 64
    );
    port(
        cdb_opcode_bits : in std_logic_vector(OPCODE_BITS - 1 downto 0);
        cdb_res_stat_1 : in std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
        cdb_res_stat_2 : in std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
        cdb_operand_1 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        cdb_operand_2 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        
        write_en : in std_logic;
        
        clk : in std_logic;
        reset : in std_logic
    );
end reservation_station;

architecture rtl of reservation_station is
    -- Reservation station format [OPCODE | RES_STAT_1 | RES_STAT_2 | OPERAND_1 | OPERAND_2 | BUSY]
    constant RS_SEL_ENTRY_BITS : integer := integer(ceil(log2(real(NUM_ENTRIES))));
    constant ENTRY_LEN_BITS : integer := OPCODE_BITS + 2 * RS_SEL_ENTRY_BITS + 2 * OPERAND_BITS + 1;
    constant RS_SEL_ZERO : std_logic_vector(RS_SEL_ENTRY_BITS - 1 downto 0) := (others => '0');
    
    type reservation_station_entries is array(NUM_ENTRIES - 1 downto 0) of std_logic_vector(ENTRY_LEN_BITS - 1 downto 0);  -- Number of bits in one entry of the reservation station
    
    signal rs_entries : reservation_station_entries;
    signal rs_busy_bits : std_logic_vector(NUM_ENTRIES - 1 downto 0);
    signal rs_ready_bits : std_logic_vector(NUM_ENTRIES - 1 downto 0);
    
    signal rs_sel_write_1 : std_logic_vector(RS_SEL_ENTRY_BITS - 1 downto 0);
    signal rs_sel_read_1 : std_logic_vector(RS_SEL_ENTRY_BITS - 1 downto 0);
begin
    process(rs_entries)
    begin
        for i in 0 to NUM_ENTRIES - 1 loop
            rs_busy_bits(i) <= not rs_entries(i)(ENTRY_LEN_BITS - 1);
        end loop;
    end process;
    
    process(rs_entries)
    begin
        for i in 0 to NUM_ENTRIES - 1 loop
            if (rs_entries(i)(ENTRY_LEN_BITS - 1 - OPCODE_BITS downto ENTRY_LEN_BITS - 1 - OPCODE_BITS - RS_SEL_ENTRY_BITS + 1) = RS_SEL_ZERO and
                rs_entries(i)(ENTRY_LEN_BITS - 1 - OPCODE_BITS downto ENTRY_LEN_BITS - 1 - OPCODE_BITS - 2 * RS_SEL_ENTRY_BITS + 1) = RS_SEL_ZERO and
                rs_entries(i)(0) = '1') then
                rs_ready_bits(i) <= '1';
            else
                rs_ready_bits(i) <= '0';
            end if;
        end loop;
    end process;

    prio_enc_write_1 : entity work.priority_encoder(rtl)
                       generic map(NUM_INPUTS => NUM_ENTRIES)
                       port map(d => rs_busy_bits,
                                q => rs_sel_write_1);
                                
    prio_enc_read_1 : entity work.priority_encoder(rtl)
                      generic map(NUM_INPUTS => NUM_ENTRIES)
                      port map(d => rs_ready_bits,
                               q => rs_sel_read_1);
                               
    reservation_station_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to NUM_ENTRIES - 1 loop
                    rs_entries(i) <= (others => '0');
                end loop;
            elsif (write_en = '1') then
                rs_entries(to_integer(unsigned(rs_sel_write_1))) <= cdb_opcode_bits & cdb_res_stat_1 & cdb_res_stat_2 & cdb_operand_1 & cdb_operand_2 & '1';
            end if;
        end if;
    end process;

end rtl;












