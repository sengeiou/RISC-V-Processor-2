library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- ================ NOTES ================ 
-- Possible optimization (?): Do reads on falling edge and writes on rising edge (or vise versa)
-- =======================================

use work.pkg_cpu.all;

entity reservation_station is
    generic(
        NUM_ENTRIES : integer range 1 to 1024;
        OPCODE_BITS : integer range 0 to 32;
        OPERAND_BITS : integer range 0 to 64
    );
    port(
        -- INPUTS
        i1_opcode_bits : in std_logic_vector(OPCODE_BITS - 1 downto 0);
        i1_res_stat_1 : in std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
        i1_res_stat_2 : in std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
        i1_operand_1 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        i1_operand_2 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        
        -- OUTPUTS
        o1_opcode_bits : out std_logic_vector(OPCODE_BITS - 1 downto 0);
        o1_res_stat_1 : out std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
        o1_res_stat_2 : out std_logic_vector(integer(ceil(log2(real(NUM_ENTRIES)))) - 1 downto 0);
        o1_operand_1 : out std_logic_vector(OPERAND_BITS - 1 downto 0);
        o1_operand_2 : out std_logic_vector(OPERAND_BITS - 1 downto 0); 
        
        write_en : in std_logic;
        read_en : in std_logic;
        
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
            rs_busy_bits(i) <= not rs_entries(i)(0);
        end loop;
    end process;
    
    process(rs_entries)
    begin
        for i in 0 to NUM_ENTRIES - 1 loop
            if (rs_entries(i)(ENTRY_LEN_BITS - OPCODE_BITS - 1 downto ENTRY_LEN_BITS - OPCODE_BITS - RS_SEL_ENTRY_BITS) = RS_SEL_ZERO and
                rs_entries(i)(ENTRY_LEN_BITS - OPCODE_BITS - 1 - RS_SEL_ENTRY_BITS downto ENTRY_LEN_BITS - OPCODE_BITS - 2 * RS_SEL_ENTRY_BITS) = RS_SEL_ZERO and
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
                               
    reservation_station_write_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                for i in 0 to NUM_ENTRIES - 1 loop
                    rs_entries(i) <= (others => '0');
                end loop;
            else
                if (write_en = '1') then
                    rs_entries(to_integer(unsigned(rs_sel_write_1))) <= i1_opcode_bits & i1_res_stat_1 & i1_res_stat_2 & i1_operand_1 & i1_operand_2 & '1';
                end if;
                
                if (read_en = '1') then
                    rs_entries(to_integer(unsigned(rs_sel_read_1)))(0) <= '0';
                end if;
            end if;
        end if;
    end process;
    
    reservation_station_read_proc : process(read_en, rs_entries)
    begin
        if (read_en = '1') then
            o1_opcode_bits <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - 1 downto ENTRY_LEN_BITS - OPCODE_BITS);
            o1_res_stat_1 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - OPCODE_BITS - 1 downto ENTRY_LEN_BITS - OPCODE_BITS - RS_SEL_ENTRY_BITS);
            o1_res_stat_2 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - OPCODE_BITS - RS_SEL_ENTRY_BITS - 1 downto ENTRY_LEN_BITS - OPCODE_BITS - 2 * RS_SEL_ENTRY_BITS);
            o1_operand_1 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - OPCODE_BITS - 2 * RS_SEL_ENTRY_BITS - 1 downto ENTRY_LEN_BITS - OPCODE_BITS - 2 * RS_SEL_ENTRY_BITS - OPERAND_BITS);
            o1_operand_2 <= rs_entries(to_integer(unsigned(rs_sel_read_1)))(ENTRY_LEN_BITS - OPCODE_BITS - 2 * RS_SEL_ENTRY_BITS - OPERAND_BITS - 1 downto ENTRY_LEN_BITS - OPCODE_BITS - 2 * RS_SEL_ENTRY_BITS - 2 * OPERAND_BITS);
                
            --rs_entries(to_integer(unsigned(rs_sel_read_1)))(0) <= '0';
        else
            o1_opcode_bits <= (others => '0');
            o1_res_stat_1 <= (others => '0');
            o1_res_stat_2 <= (others => '0');
            o1_operand_1 <= (others => '0');
            o1_operand_2 <= (others => '0');
        end if;
    end process;

end rtl;












