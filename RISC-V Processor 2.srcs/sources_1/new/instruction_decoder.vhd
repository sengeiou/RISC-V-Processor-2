library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.PKG_CPU.ALL;

entity instruction_decoder is
    port(
        instruction : in std_logic_vector(31 downto 0);
        instruction_ready : out std_logic; 
        
        uop : out uop_type
    );
end instruction_decoder;

architecture rtl of instruction_decoder is

begin
    process(instruction)
    begin
        uop.operation_type <= (others => '0');
        uop.operation_select <= (others => '0');
        uop.immediate <= (others => '0');
        
        uop.reg_src_1 <= instruction(19 downto 15);
        uop.reg_src_2 <= instruction(24 downto 20);
        uop.reg_dest <= instruction(11 downto 7);
        
        instruction_ready <= '0';
        
        if (instruction(6 downto 0) = "0010011") then
            uop.operation_type <= OP_TYPE_INTEGER;      
            uop.operation_select <= "10" & instruction(14 downto 12);
            
            uop.immediate <= X"00000" & instruction(31 downto 20);
            
            instruction_ready <= '1';
        elsif (instruction(6 downto 0) = "0110011") then
            uop.operation_type <= OP_TYPE_INTEGER;      
            uop.operation_select <= '0' & instruction(30) & instruction(14 downto 12);
            
            instruction_ready <= '1';
        elsif (instruction(6 downto 0) = "0100011") then
            uop.operation_type <= OP_TYPE_LOAD_STORE;
            uop.operation_select <= "01" & instruction(14 downto 12);
            
            uop.immediate <= X"00000" & instruction(31 downto 25) & instruction(11 downto 7);
            
            instruction_ready <= '1';
        elsif (instruction(6 downto 0) = "0000011") then
            uop.operation_type <= OP_TYPE_LOAD_STORE;
            uop.operation_select <= "10" & instruction(14 downto 12);
            
            uop.immediate <= X"00000" & instruction(31 downto 20);
            
            instruction_ready <= '1';
        end if;
    end process;

end rtl;
