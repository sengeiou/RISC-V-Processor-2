library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;

-- Implements the Tomasulo algorithm with unified reservation station. Might get broken up into multiple modules
-- in the future

entity execution_unit is
    port(
        decoded_instruction : in std_logic_vector(53 downto 0);     -- OPCODE | REG_S1 | REG_S2 | REG_DST | IMMEDIATE 
        
        instr_ready : in std_logic;
        
        reset : in std_logic;
        clk : in std_logic
    );
end execution_unit;

architecture rtl of execution_unit is
    COMPONENT fifo_generator_1
        PORT (
          clk : IN STD_LOGIC;
          srst : IN STD_LOGIC;
          din : IN STD_LOGIC_VECTOR(53 DOWNTO 0);
          wr_en : IN STD_LOGIC;
          rd_en : IN STD_LOGIC;
          dout : OUT STD_LOGIC_VECTOR(53 DOWNTO 0);
          full : OUT STD_LOGIC;
          empty : OUT STD_LOGIC
        );
    END COMPONENT;
    
    -- ========== 
    
    signal rf_wr_addr : std_logic_vector(4 downto 0) := "00000";
    signal rf_wr_data : std_logic_vector(31 downto 0) := X"00000000";
    signal rf_rd_data_1 : std_logic_vector(31 downto 0);
    signal rf_rd_data_2 : std_logic_vector(31 downto 0);
    
    -- ========== RESERVATION STATION PORT 0 ==========
    signal p0_operand_1 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal p0_operand_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal p0_operation : std_logic_vector(6 downto 0);
    -- ================================================
    
    signal next_instruction : std_logic_vector(53 downto 0);
    
    signal iq_full : std_logic;
    signal iq_empty : std_logic;
    signal iq_empty_n : std_logic;
    signal iq_issue_ready : std_logic;
begin
    instruction_queue : fifo_generator_1
      port map (
        clk => clk,
        srst => reset,
        din => decoded_instruction,
        wr_en => instr_ready,
        rd_en => iq_issue_ready,
        dout => next_instruction,
        full => iq_full,
        empty => iq_empty
      );
      iq_empty_n <= not iq_empty;
      
    register_file : entity work.register_file(rtl)
                    generic map(REG_DATA_WIDTH_BITS => CPU_DATA_WIDTH_BITS,
                                REGFILE_SIZE => 4 + ENABLE_BIG_REGFILE)
                    port map(-- ADDRESSES
                             rd_1_addr => decoded_instruction(46 downto 42),
                             rd_2_addr => decoded_instruction(41 downto 37),
                             wr_addr => rf_wr_addr,
                             
                             -- DATA
                             wr_data => rf_wr_data,
                             rd_1_data => rf_rd_data_1,
                             rd_2_data => rf_rd_data_2,
                             
                             -- CONTROL
                             wr_en => '0',
                             reset => reset,
                             clk => clk,
                             clk_dbg => '0');
      
    reservation_station : entity work.reservation_station(rtl)
                          generic map(NUM_ENTRIES => RESERVATION_STATION_ENTRY_CNT,
                                      REG_ADDR_BITS => integer(ceil(log2(real(REGFILE_SIZE)))),
                                      OPCODE_BITS => 7,
                                      OPERAND_BITS => CPU_DATA_WIDTH_BITS)
                          port map(i1_opcode_bits => decoded_instruction(53 downto 47),
                                   i1_reg_src_1 => decoded_instruction(46 downto 42),
                                   i1_reg_src_2 => decoded_instruction(41 downto 37),
                                   i1_operand_1 => rf_rd_data_1,
                                   i1_operand_2 => rf_rd_data_2,
                                   i1_dest_reg => decoded_instruction(36 downto 32),
                                   
                                   o1_operand_1 => p0_operand_1,
                                   o1_operand_2 => p0_operand_2,
                                   o1_opcode_bits => p0_operation,
                                   
                                   write_en => instr_ready,
                                   rs_dispatch_1_en => '1',
                                   
                                   clk => clk,
                                   reset => reset);
      
    integer_branch_func_unit : entity work.integer_branch_fu(structural)
                               generic map(OPERAND_BITS => CPU_DATA_WIDTH_BITS)
                               port map(operand_1 => p0_operand_1,
                                        operand_2 => p0_operand_2,
                                        --result => ,
                                        operation_sel => p0_operation(3 downto 0));

end rtl;
