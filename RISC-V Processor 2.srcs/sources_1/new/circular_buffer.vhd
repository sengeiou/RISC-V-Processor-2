library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

entity circular_buffer is
    generic(
        ENTRY_BITS : integer;
        BUFFER_ENTRIES : integer
    );
    port(
        data_write : in std_logic_vector(ENTRY_BITS - 1 downto 0);      -- Data to be put at the tail of the buffer
        data_read : out std_logic_vector(ENTRY_BITS - 1 downto 0);      -- Data at the head of the buffer
        
        read_en : in std_logic;
        write_en : in std_logic;
        
        full : out std_logic;
        empty : out std_logic;
        
        reset : in std_logic;
        clk : in std_logic
    );
end circular_buffer;

architecture rtl of circular_buffer is
    type circular_buffer_type is array(BUFFER_ENTRIES - 1 downto 0) of std_logic_vector(ENTRY_BITS - 1 downto 0);
    signal circular_buffer : circular_buffer_type;
    
    signal i_empty : std_logic;
    signal i_full : std_logic;

    signal head_counter_reg : unsigned(integer(ceil(log2(real(BUFFER_ENTRIES)))) - 1 downto 0); 
    signal tail_counter_reg : unsigned(integer(ceil(log2(real(BUFFER_ENTRIES)))) - 1 downto 0);
    
    signal head_counter_next : unsigned(integer(ceil(log2(real(BUFFER_ENTRIES)))) - 1 downto 0); 
    signal tail_counter_next : unsigned(integer(ceil(log2(real(BUFFER_ENTRIES)))) - 1 downto 0); 
begin
    buffer_cntr_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                tail_counter_reg <= (others => '0');
                head_counter_reg <= (others => '0');
            else
                if (write_en = '1' and i_full = '0') then
                    tail_counter_reg <= tail_counter_next;
                    circular_buffer(to_integer(tail_counter_reg)) <= data_write;
                end if;
                
                if (read_en = '1' and i_empty = '0') then
                    head_counter_reg <= head_counter_next;
                end if;
            end if;
        end if;
    end process;

    counters_next_proc : process(head_counter_reg, tail_counter_reg)
    begin
        if (head_counter_reg = BUFFER_ENTRIES - 1) then
            head_counter_next <= (others => '0');
        else
            head_counter_next <= head_counter_reg + 1;
        end if;
        
        if (tail_counter_reg = BUFFER_ENTRIES - 1) then
            tail_counter_next <= (others => '0');
        else
            tail_counter_next <= tail_counter_reg + 1;
        end if;
    end process;

    data_read <= circular_buffer(to_integer(head_counter_reg));

    i_full <= '1' when tail_counter_next = head_counter_reg else '0';
    i_empty <= '1' when head_counter_reg = tail_counter_reg else '0';
    
    full <= i_full;
    empty <= i_empty;

end rtl;
