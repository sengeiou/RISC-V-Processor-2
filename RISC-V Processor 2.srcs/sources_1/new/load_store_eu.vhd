library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_FU.ALL;
use WORK.PKG_AXI.ALL;

entity load_store_eu is
    port(
        from_master : out FromMaster; 
        to_master : in ToMaster; 
    
        operand_1 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        operand_2 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        immediate : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        operation_sel : in std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        rs_entry_tag : in std_logic_vector(integer(ceil(log2(real(RESERVATION_STATION_ENTRIES)))) - 1 downto 0);
        
        cdb : out cdb_type;
        
        reset : in std_logic;
        clk : in std_logic
    );
end load_store_eu;

architecture rtl of load_store_eu is
    type load_store_unit_state_type is (IDLE,
                                        BUSY);
                                        
    signal op_sel_delay_temp : std_logic;
                                        
    signal load_store_unit_state_reg : load_store_unit_state_type;
    signal load_store_unit_state_next : load_store_unit_state_type;

    signal pipeline_reg_1 : lsu_pipeline_reg_1_type;
    signal pipeline_reg_2 : lsu_pipeline_reg_2_type;
    signal pipeline_reg_3 : lsu_pipeline_reg_3_type;
    
    signal pipeline_enable : std_logic;
    signal calculated_address : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
begin
    lsu_state_reg_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                load_store_unit_state_reg <= IDLE;
            else
                load_store_unit_state_reg <= load_store_unit_state_next;
            end if;
        end if;
    end process;

    lsu_next_state_proc : process(pipeline_reg_1, to_master)
    begin
        case load_store_unit_state_reg is
            when IDLE => 
                if (pipeline_reg_1.operation_sel(3) = '1') then
                    load_store_unit_state_next <= BUSY;
                else
                    load_store_unit_state_next <= IDLE;
                end if;
            when BUSY => 
                if (to_master.done_write = '1') then
                    load_store_unit_state_next <= IDLE;
                else
                    load_store_unit_state_next <= BUSY;
                end if;
        end case;
    end process;
    
    lsu_state_machine_outputs : process(load_store_unit_state_reg)
    begin
        case load_store_unit_state_reg is
            when IDLE => 
                pipeline_enable <= '1';
            when BUSY =>
                pipeline_enable <= '0';
        end case;
    end process;

    pipeline_reg_1_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_1 <= (others => (others => '0'));
            elsif (pipeline_enable = '1') then
                pipeline_reg_1.operand_1 <= operand_1;
                pipeline_reg_1.operand_2 <= operand_2;
                pipeline_reg_1.immediate <= immediate;
                pipeline_reg_1.operation_sel <= operation_sel;
                pipeline_reg_1.rs_entry_tag <= rs_entry_tag;
            end if;
        end if;
    end process;
    
    pipeline_reg_2_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_2 <= (others => (others => '0'));
            elsif (pipeline_enable = '1') then
                pipeline_reg_2.store_data <= pipeline_reg_1.operand_2;
                pipeline_reg_2.store_addr <= calculated_address;
                pipeline_reg_2.operation_sel <= pipeline_reg_1.operation_sel;
                pipeline_reg_2.rs_entry_tag <= pipeline_reg_1.rs_entry_tag; 
            end if;
        end if;
    end process;
    
    pipeline_reg_3_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_3 <= (others => (others => '0'));
            elsif (pipeline_enable = '1') then
                pipeline_reg_3.load_data <= (others => '0');
                pipeline_reg_3.rs_entry_tag <= pipeline_reg_2.rs_entry_tag; 
            end if;
        end if;
    end process;
    
    op_sel_delay_temp_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                op_sel_delay_temp <= '0';
            else
                op_sel_delay_temp <= pipeline_reg_2.operation_sel(3);
            end if;
        end if;
    end process;
    
    from_master.data_write <= pipeline_reg_2.store_data;
    from_master.addr_write <= pipeline_reg_2.store_addr;
    from_master.addr_read <= (others => '0');
    from_master.burst_len <= (others => '0');
    from_master.burst_size <= (others => '0');
    from_master.burst_type <= (others => '0');
    from_master.execute_read <= '0';
    from_master.execute_write <= pipeline_reg_2.operation_sel(3) and (not op_sel_delay_temp);
    
    calculated_address <= std_logic_vector(unsigned(pipeline_reg_1.operand_1) + unsigned(pipeline_reg_1.immediate));
    
    --cdb.data <= pipeline_reg_3.load_data;
    --cdb.rs_entry_tag <= pipeline_reg_3.rs_entry_tag;

end rtl;
