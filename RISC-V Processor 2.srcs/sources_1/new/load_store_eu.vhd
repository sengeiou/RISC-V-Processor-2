library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_FU.ALL;
use WORK.PKG_AXI.ALL;

-- Potential problem: When pipeline registers 2 and 3 have valid data in them and this unit is stalled due to a read or write operation
-- pipeline register 3 could cause the execution to stall (or worse) due to requesting the CDB.

entity load_store_eu is
    port(
        to_master_interface : out ToMasterInterface; 
        from_master_interface : in FromMasterInterface; 
    
        operand_1 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        operand_2 : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        immediate : in std_logic_vector(OPERAND_BITS - 1 downto 0);
        operation_sel : in std_logic_vector(OPERATION_SELECT_BITS - 1 downto 0);
        rob_entry_tag : in std_logic_vector(integer(ceil(log2(real(REORDER_BUFFER_ENTRIES)))) - 1 downto 0);
        dispatch_ready : in std_logic;
        
        cdb : out cdb_type;
        cdb_request : out std_logic;
        cdb_granted : in std_logic;
        
        busy : out std_logic;
        reset : in std_logic;
        clk : in std_logic
    );
end load_store_eu;

architecture rtl of load_store_eu is
    type load_store_unit_state_type is (IDLE,
                                        LDST_BUSY);
                                        
    signal write_op_sel_delay : std_logic;
    signal read_op_sel_delay : std_logic;
                                        
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

    lsu_next_state_proc : process(pipeline_reg_1, from_master_interface)
    begin
        case load_store_unit_state_reg is
            when IDLE => 
                if (pipeline_reg_1.operation_sel(3) = '1' or pipeline_reg_2.operation_sel(4) = '1') then
                    load_store_unit_state_next <= LDST_BUSY;
                else
                    load_store_unit_state_next <= IDLE;
                end if;
            when LDST_BUSY => 
                if (from_master_interface.done_write = '1' or from_master_interface.done_read = '1') then
                    load_store_unit_state_next <= IDLE;
                else
                    load_store_unit_state_next <= LDST_BUSY;
                end if;
        end case;
    end process;
    
    lsu_state_machine_outputs : process(load_store_unit_state_reg, pipeline_reg_2, pipeline_reg_3, cdb_granted, from_master_interface)
    begin
        case load_store_unit_state_reg is
            when IDLE => 
                pipeline_enable <= ((not pipeline_reg_3.valid) or cdb_granted) and (not pipeline_reg_2.valid);
            when LDST_BUSY =>
                pipeline_enable <= from_master_interface.done_read;
        end case;
    end process;

    pipeline_reg_1_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_1 <= LS_PIPELINE_REG_1_ZERO;
            elsif (pipeline_enable = '1') then
                pipeline_reg_1.operand_1 <= operand_1;
                pipeline_reg_1.operand_2 <= operand_2;
                pipeline_reg_1.immediate <= immediate;
                pipeline_reg_1.operation_sel <= operation_sel;
                pipeline_reg_1.rob_entry_tag <= rob_entry_tag;
                pipeline_reg_1.valid <= dispatch_ready;
            end if;
        end if;
    end process;
    
    pipeline_reg_2_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_2 <= LS_PIPELINE_REG_2_ZERO;
            elsif (pipeline_enable = '1') then
                pipeline_reg_2.store_data <= pipeline_reg_1.operand_2;
                pipeline_reg_2.address <= calculated_address;
                pipeline_reg_2.operation_sel <= pipeline_reg_1.operation_sel;
                pipeline_reg_2.rob_entry_tag <= pipeline_reg_1.rob_entry_tag; 
                pipeline_reg_2.valid <= pipeline_reg_1.valid; 
            end if;
        end if;
    end process;
    
    pipeline_reg_3_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                pipeline_reg_3 <= LS_PIPELINE_REG_3_ZERO;
            elsif (pipeline_enable = '1') then
                pipeline_reg_3.load_data <= from_master_interface.data_read;
                pipeline_reg_3.rob_entry_tag <= pipeline_reg_2.rob_entry_tag; 
                pipeline_reg_3.valid <= pipeline_reg_2.valid; 
            end if;
        end if;
    end process;
    
    op_sel_delay_proc : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                write_op_sel_delay <= '0';
                read_op_sel_delay <= '0';
            else
                write_op_sel_delay <= pipeline_reg_2.operation_sel(3);
                read_op_sel_delay <= pipeline_reg_2.operation_sel(4);
            end if;
        end if;
    end process;
    
    to_master_interface.data_write <= pipeline_reg_2.store_data;
    to_master_interface.addr_write <= pipeline_reg_2.address;
    to_master_interface.addr_read <= pipeline_reg_2.address;
    to_master_interface.burst_len <= (others => '0');
    to_master_interface.burst_size <= (others => '0');
    to_master_interface.burst_type <= (others => '0');
    to_master_interface.execute_read <= pipeline_reg_2.operation_sel(4) and (not read_op_sel_delay);
    to_master_interface.execute_write <= pipeline_reg_2.operation_sel(3) and (not write_op_sel_delay);
    
    calculated_address <= std_logic_vector(unsigned(pipeline_reg_1.operand_1) + unsigned(pipeline_reg_1.immediate));
    
    cdb_request <= pipeline_reg_3.valid;
    
    cdb.data <= pipeline_reg_3.load_data;
    cdb.tag <= pipeline_reg_3.rob_entry_tag;
    
    busy <= not pipeline_enable;
end rtl;
