library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;

entity barrel_shifter_2 is
    generic(
        DATA_WIDTH : integer
    );
    port(
        data_in : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        
        shift_amount : in std_logic_vector(integer(ceil(log2(real(DATA_WIDTH)))) - 1 downto 0);
        shift_arith : in std_logic;
        shift_direction : in std_logic
    );
end barrel_shifter_2;

architecture rtl of barrel_shifter_2 is
    type intermediate_results_type is array (integer(ceil(log2(real(DATA_WIDTH)))) - 1 downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    signal intermediate_results : intermediate_results_type;
begin
    process(all)
    begin
        if (shift_amount(0) = '1') then
            if (shift_direction = '0') then
                if (shift_arith = '0') then
                    intermediate_results(0)(DATA_WIDTH - 1) <= '0';
                    intermediate_results(0)(DATA_WIDTH - 2 downto 0) <= data_in(DATA_WIDTH - 1 downto 1);
                else
                    intermediate_results(0)(DATA_WIDTH - 1) <= data_in(DATA_WIDTH - 1);
                    intermediate_results(0)(DATA_WIDTH - 2 downto 0) <= data_in(DATA_WIDTH - 1 downto 1);
                end if;
            else
                intermediate_results(0)(DATA_WIDTH - 1 downto 1) <= data_in(DATA_WIDTH - 2 downto 0);
                intermediate_results(0)(0) <= '0';
            end if;
        else
            intermediate_results(0) <= data_in;
        end if;
        
        
    
        for i in 1 to integer(ceil(log2(real(DATA_WIDTH)))) - 1 loop
            if (shift_amount(i) = '1') then
                if (shift_direction = '0') then
                    if (shift_arith = '0') then
                        intermediate_results(i)(DATA_WIDTH - 1 downto DATA_WIDTH - 2 ** i) <= (others => '0');
                        intermediate_results(i)(DATA_WIDTH - 1 - 2 ** i downto 0) <= intermediate_results(i - 1)(DATA_WIDTH - 1 downto 2 ** i);
                    else
                        intermediate_results(i)(DATA_WIDTH - 1 downto DATA_WIDTH - 2 ** i) <= (others => intermediate_results(i - 1)(DATA_WIDTH - 1));
                        intermediate_results(i)(DATA_WIDTH - 1 - 2 ** i downto 0) <= intermediate_results(i - 1)(DATA_WIDTH - 1 downto 2 ** i);
                    end if;
                else
                    intermediate_results(i)(DATA_WIDTH - 1 downto 2 ** i) <= intermediate_results(i - 1)(DATA_WIDTH - 1 - 2 ** i downto 0);
                    intermediate_results(i)(2 ** i - 1 downto 0) <= (others => '0');
                end if;
            else
                intermediate_results(i) <= intermediate_results(i - 1);
            end if;
        end loop;
    end process;
    
    data_out <= intermediate_results(integer(ceil(log2(real(DATA_WIDTH)))) - 1);

end rtl;
