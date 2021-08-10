library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pkg_cpu.all;

entity stage_execute is
    port(
        -- ========== DATA SIGNALS ==========
        reg_1_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        reg_2_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        immediate_data : in std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        
        alu_result : out std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
        
        -- ========== CONTROL SIGNALS ==========
        pc : in std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        
        alu_op_sel : in std_logic_vector(3 downto 0);
        reg_1_used : in std_logic;
        reg_2_used : in std_logic;
        immediate_used : in std_logic;
        
        prog_flow_cntrl : in std_logic_vector(2 downto 0);
        branch_target_addr : out std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
        branch_taken : out std_logic
    );
end stage_execute;

architecture structural of stage_execute is
    signal alu_op_sel_i : std_logic_vector(3 downto 0);
    
    -- ALU Operands
    signal alu_oper_1 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal alu_oper_2 : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    
    -- MUX Select Signals
    signal mux_alu_oper_1_sel : std_logic_vector(1 downto 0);
    signal mux_alu_oper_2_sel : std_logic_vector(1 downto 0);
begin
    branching_unit : entity work.branching_unit(rtl)
                     port map(pc => pc,
                              immediate => immediate_data,
                              prog_flow_cntrl => prog_flow_cntrl,
                              branch_target_addr => branch_target_addr,
                              branch_taken => branch_taken);

    alu : entity work.arithmetic_logic_unit(rtl)
          generic map(OPERAND_WIDTH_BITS => CPU_DATA_WIDTH_BITS)
          port map(operand_1 => alu_oper_1,
                   operand_2 => alu_oper_2,
                   result => alu_result,
                   alu_op_sel => alu_op_sel);
                   
    mux_alu_op_1 : entity work.mux_4_1(rtl)
                   generic map(WIDTH_BITS => CPU_DATA_WIDTH_BITS)
                   port map(in_0 => reg_1_data,
                            in_1 => (others => '0'),            -- This will later select PC as operand
                            in_2 => (others => '0'),
                            in_3 => (others => '0'),
                            output => alu_oper_1,
                            sel => mux_alu_oper_1_sel);
                   
    mux_alu_op_2 : entity work.mux_4_1(rtl)
                   generic map(WIDTH_BITS => CPU_DATA_WIDTH_BITS)
                   port map(in_0 => reg_2_data,
                            in_1 => immediate_data,
                            in_2 => (others => '0'),
                            in_3 => (others => '0'),
                            output => alu_oper_2,
                            sel => mux_alu_oper_2_sel);
                            
    mux_alu_oper_1_sel(0) <= '0';
    mux_alu_oper_1_sel(1) <= '0';
                            
    mux_alu_oper_2_sel(0) <= immediate_used;
    mux_alu_oper_2_sel(1) <= '0';     
end structural;











