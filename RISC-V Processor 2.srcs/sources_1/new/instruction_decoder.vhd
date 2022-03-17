library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.PKG_CPU.ALL;

entity instruction_decoder is
    port(
        instruction : in std_logic_vector(31 downto 0);
        instruction_ready : out std_logic; 
        
        decoded_instruction : out decoded_instruction_type
    );
end instruction_decoder;

architecture rtl of instruction_decoder is

begin
    process(instruction)
    begin
        decoded_instruction.operation_type <= (others => '0');
        decoded_instruction.operation_select <= (others => '0');
        decoded_instruction.immediate <= (others => '0');
        
        decoded_instruction.reg_src_1 <= instruction(19 downto 15);
        decoded_instruction.reg_src_2 <= instruction(24 downto 20);
        decoded_instruction.reg_dest <= instruction(11 downto 7);
        
        instruction_ready <= '0';
        
        if (instruction(6 downto 0) = "0010011") then
            decoded_instruction.operation_type <= OP_TYPE_INTEGER;      
            decoded_instruction.operation_select <= '1' & instruction(30) & instruction(14 downto 12);
            
            decoded_instruction.immediate <= X"00000" & instruction(31 downto 20);
            
            instruction_ready <= '1';
        elsif (instruction(6 downto 0) = "0110011") then
            decoded_instruction.operation_type <= OP_TYPE_INTEGER;      
            decoded_instruction.operation_select <= '0' & instruction(30) & instruction(14 downto 12);
            
            instruction_ready <= '1';
        elsif (instruction(6 downto 0) = "0100011") then
            decoded_instruction.operation_type <= OP_TYPE_STORE;
            decoded_instruction.operation_select <= "01" & instruction(14 downto 12);
            
            decoded_instruction.immediate <= X"00000" & instruction(31 downto 25) & instruction(11 downto 7);
            
            instruction_ready <= '1';
        end if;
    end process;

end rtl;
