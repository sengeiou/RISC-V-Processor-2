library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- Holds information on which PRF entries correspond to architectural registers

entity register_status_vector is
    generic(
        PHYS_REGFILE_ENTRIES : integer range 1 to 1024;
        ARCH_REGFILE_ENTRIES : integer range 1 to 1024
    );
    port(
        set_bit : in std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        unset_bit : in std_logic_vector(integer(ceil(log2(real(PHYS_REGFILE_ENTRIES)))) - 1 downto 0);
        
        write_en : in std_logic;
        
        register_status_vector : out std_logic_vector(PHYS_REGFILE_ENTRIES - 1 downto 0);

        clk : in std_logic;
        reset : in std_logic
    );
end register_status_vector;

architecture rtl of register_status_vector is
    --signal i_register_status_vector : std_logic_vector(PHYS_REGFILE_ENTRIES - 1 downto 0);
begin
    process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                reg_status_vector_rst : for i in 0 to PHYS_REGFILE_ENTRIES - 1 loop
                    if (i < ARCH_REGFILE_ENTRIES) then
                        register_status_vector(i) <= '1';
                    else
                        register_status_vector(i) <= '0';
                    end if;
                end loop;
            else
                if (write_en = '1') then
                    register_status_vector(to_integer(unsigned(set_bit))) <= '1';
                    register_status_vector(to_integer(unsigned(unset_bit))) <= '0';
                end if;
            end if;
        end if;
    end process;

end rtl;
