library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rom_memory_2 is
    port(
        addr_bus : in std_logic_vector(9 downto 0);
        data_bus : out std_logic_vector(31 downto 0);

        data_ready : out std_logic;
        
        clk : in std_logic
    );
end rom_memory_2;

architecture structural of rom_memory_2 is
    COMPONENT block_rom_memory
      PORT (
        clka : IN STD_LOGIC;
        addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
      );
    END COMPONENT;
    
    signal addr_old_reg : std_logic_vector(9 downto 0);
begin
    block_ram_instance : block_rom_memory
    PORT MAP (
        clka => clk,
        addra => addr_bus,
        douta => data_bus
    );
    
    addr_old_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            addr_old_reg <= addr_bus;
        end if;
    end process;
    
    data_ready <= '1' when addr_bus = addr_old_reg else '0'; 

end structural;
