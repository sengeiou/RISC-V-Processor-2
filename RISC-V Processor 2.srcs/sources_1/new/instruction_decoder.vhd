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
        
        uop.arch_src_reg_1 <= instruction(19 downto 15);
        uop.arch_src_reg_2 <= instruction(24 downto 20);
        uop.arch_dest_reg <= instruction(11 downto 7);
        
        instruction_ready <= '0';
        
        if (instruction(6 downto 0) = "0010011") then
            uop.operation_type <= OP_TYPE_INTEGER;      
            uop.operation_select <= "10000" & instruction(14 downto 12);
            
            uop.immediate <= X"00000" & instruction(31 downto 20);
            
            instruction_ready <= '1';
        elsif (instruction(6 downto 0) = "0110011") then
            uop.operation_type <= OP_TYPE_INTEGER;      
            uop.operation_select <= "0000" & instruction(30) & instruction(14 downto 12);
            
            instruction_ready <= '1';
        elsif (instruction(6 downto 0) = "0100011") then        -- STORE
            uop.operation_type <= OP_TYPE_LOAD_STORE;
            uop.operation_select <= "10000" & instruction(14 downto 12);
            
            uop.arch_dest_reg <= (others => '0');        -- HAS TO BE 0 SO THAT IS DOESN'T GET RENAMED SINCE SW DOESN'T USE A DESTINATION REGISTER!!!
            uop.immediate <= X"00000" & instruction(31 downto 25) & instruction(11 downto 7);
            
            instruction_ready <= '1';
        elsif (instruction(6 downto 0) = "0000011") then        -- LOAD
            uop.operation_type <= OP_TYPE_LOAD_STORE;
            uop.operation_select <= "01000" & instruction(14 downto 12);
            
            uop.immediate <= X"00000" & instruction(31 downto 20);
            
            instruction_ready <= '1';
        elsif (instruction(6 downto 0) = "0110111") then        -- LUI
            uop.operation_type <= OP_TYPE_INTEGER;
            uop.operation_select <= "10000000";
            uop.immediate <= instruction(31 downto 12) & X"000";
            
            uop.arch_src_reg_1 <= "00000";
            
            instruction_ready <= '1';
        elsif (instruction(6 downto 0) = "1100011") then
            uop.operation_type <= OP_TYPE_COND_BRANCH;
            uop.operation_select <= "00000" & instruction(14 downto 12);
            uop.immediate <= "1111111111111111111" & instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & "0"; 
            
            --uop.reg_dest <= "00000";
        end if;
    end process;

end rtl;
