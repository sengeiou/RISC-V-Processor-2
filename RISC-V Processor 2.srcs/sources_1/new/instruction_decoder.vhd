library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.PKG_CPU.ALL;

entity instruction_decoder is
    port(
        instruction : in std_logic_vector(31 downto 0);
        instruction_ready : out std_logic; 
        pc : in std_logic_vector(31 downto 0);
        
        uop : out uop_type
    );
end instruction_decoder;

architecture rtl of instruction_decoder is
    signal branch_op_sel : std_logic_vector(3 downto 0);
begin
    process(instruction, branch_op_sel)
    begin
        uop.operation_type <= (others => '0');
        uop.operation_select <= (others => '0');
        uop.immediate <= (others => '0');
        
        uop.arch_src_reg_1 <= instruction(19 downto 15);
        uop.arch_src_reg_2 <= instruction(24 downto 20);
        uop.arch_dest_reg <= instruction(11 downto 7);
        uop.pc <= pc;
        
        branch_op_sel <= (others => '0');
        
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
        elsif (instruction(6 downto 0) = "1100011") then        -- BRANCHING
               case instruction(14 downto 13) is
                   when "00" => branch_op_sel <= ALU_OP_EQ;
                   when "10" => branch_op_sel <= ALU_OP_LESS;
                   when "11" => branch_op_sel <= ALU_OP_LESSU;
                   when others => branch_op_sel <= (others => '0');
               end case;
        
--            with instruction(14 downto 13) select branch_op_sel <=
--                ALU_OP_EQ when "00",
--                ALU_OP_LESS when "10",
--                ALU_OP_LESSU when "11",
--                "0000" when others;
        
            uop.operation_type <= OP_TYPE_INTEGER;
            uop.operation_select <= "011" & instruction(12) & branch_op_sel;
            uop.immediate <= "1111111111111111111" & instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & "0"; 
            
            uop.arch_dest_reg <= "00000";
            instruction_ready <= '1';
        end if;
    end process;

end rtl;
