library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pkg_pipeline.all;

entity pipeline is
    port(
        instruction_debug : in std_logic_vector(31 downto 0);
    
        clk : in std_logic;
        reset : in std_logic
    );
end pipeline;

architecture structural of pipeline is
signal de_ex_register_next : de_ex_register_type;
signal de_ex_register : de_ex_register_type;
signal de_ex_register_en : std_logic;

signal ex_mem_register_next : ex_mem_register_type;
signal ex_mem_register : ex_mem_register_type;
signal ex_mem_register_en : std_logic;

signal mem_wb_register_next : mem_wb_register_type;
signal mem_wb_register : mem_wb_register_type;
signal mem_wb_register_en : std_logic;

begin
    -- ========== STAGES ==========
    stage_decode : entity work.stage_decode(structural)
                   generic map(CPU_DATA_WIDTH_BITS => 32)
                   port map(-- DATA SIGNALS
                            instruction_bus => instruction_debug,
                            reg_1_data => de_ex_register_next.reg_1_data,
                            reg_2_data => de_ex_register_next.reg_2_data,
                            immediate_data => de_ex_register_next.immediate_data,
                            
                            reg_wr_data => mem_wb_register.mem_data,
                            
                            -- CONTROL SIGNALS
                            reg_1_addr => de_ex_register_next.reg_1_addr,
                            reg_2_addr => de_ex_register_next.reg_2_addr,
                            reg_1_used => de_ex_register_next.reg_1_used,
                            reg_2_used => de_ex_register_next.reg_2_used,
                            alu_op_sel => de_ex_register_next.alu_op_sel,
                            immediate_used => de_ex_register_next.immediate_used,
                            
                            reg_wr_addr => de_ex_register_next.reg_wr_addr,
                            reg_wr_en => de_ex_register_next.reg_wr_en,
                            
                            reg_wr_addr_in => mem_wb_register.reg_wr_addr,
                            reg_wr_en_in => mem_wb_register.reg_wr_en,
                            
                            reset => reset,
                            clk => clk
                            );
                            
    stage_execute : entity work.stage_execute(structural)
                    generic map(CPU_DATA_WIDTH_BITS => 32)
                    port map(-- DATA SIGNALS
                             reg_1_data => de_ex_register.reg_1_data,
                             reg_2_data => de_ex_register.reg_2_data,
                             immediate_data => de_ex_register.immediate_data,
                             alu_result => ex_mem_register_next.alu_result,
                                
                             -- CONTROL SIGNALS
                             alu_op_sel => de_ex_register.alu_op_sel,
                             reg_1_used => de_ex_register.reg_1_used,
                             reg_2_used => de_ex_register.reg_2_used,
                             immediate_used => de_ex_register.immediate_used);
                             
    stage_memory : entity work.stage_memory(structural)
                   port map(data_in => ex_mem_register.alu_result,
                            data_out => mem_wb_register_next.mem_data);

    -- ========== PIPELINE REGISTERS ==========
--    reg_de_ex : entity work.register_var(rtl)
--                generic map(WIDTH_BITS => 119)
--                port map(-- ===== DATA =====
--                         d(31 downto 0) => dec_reg_1_data,
--                         d(63 downto 32) => dec_reg_2_data,
--                         d(95 downto 64) => dec_immediate_data,
                         
--                         -- ===== CONTROL (REGISTERS) =====
--                         d(100 downto 96) => dec_reg_1_addr,
--                         d(105 downto 101) => dec_reg_2_addr,
--                         d(106) => dec_reg_1_used,
--                         d(107) => dec_reg_2_used,
                         
--                         -- ===== CONTROL (EXECUTE) =====
--                         d(111 downto 108) => dec_alu_op_sel,
--                         d(112) => dec_immediate_used,
                         
--                         -- ===== CONTROL (WRITEBACK) =====
--                         d(117 downto 113) => dec_reg_wr_addr,
--                         d(118) => dec_reg_wr_en, 
                         
--                         -- =================================================================
                         
--                         -- ===== DATA =====
--                         q(31 downto 0) => exe_reg_1_data,
--                         q(63 downto 32) => exe_reg_2_data,
--                         q(95 downto 64) => exe_immediate_data,
                         
--                         -- ===== CONTROL (REGISTERS) =====
--                         q(100 downto 96) => exe_reg_1_addr,
--                         q(105 downto 101) => exe_reg_2_addr,
--                         q(106) => exe_reg_1_used,
--                         q(107) => exe_reg_2_used, 
                         
--                         -- ===== CONTROL (EXECUTE) =====
--                         q(111 downto 108) => exe_alu_op_sel,
--                         q(112) => exe_immediate_used,
                         
--                         -- ===== CONTROL (WRITEBACK) =====
--                         q(117 downto 113) => exe_reg_wr_addr,
--                         q(118) => exe_reg_wr_en,
                         
--                         -- ===== PIPELINE REGISTER CONTROL =====
--                         clk => clk,
--                         reset => reset,
--                         en => '1'
--                         );

-- ===================== DECODE / EXECUTE REGISTER ===================== 
    de_ex_register_control : process(clk, reset)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then 
                de_ex_register <= DE_EX_REGISTER_CLEAR;
            elsif (de_ex_register_en = '1') then
                de_ex_register <= de_ex_register_next;
            end if;
        end if;
    end process;

-- ===================== EXECUTE / MEMORY REGISTER ===================== 
    ex_mem_register_next.reg_wr_addr <= de_ex_register.reg_wr_addr;
    ex_mem_register_next.reg_wr_en <= de_ex_register.reg_wr_en;
                         
    ex_mem_register_control : process(clk, reset)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                ex_mem_register <= EX_MEM_REGISTER_CLEAR;
            elsif (ex_mem_register_en = '1') then
                ex_mem_register <= ex_mem_register_next;
            end if;
        end if;
    end process;
    
-- ===================== MEMORY / WRITEBACK REGISTER ===================== 
    mem_wb_register_next.reg_wr_addr <= ex_mem_register.reg_wr_addr;
    mem_wb_register_next.reg_wr_en <= ex_mem_register.reg_wr_en;
           
    mem_wb_register_control : process(clk, reset)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                mem_wb_register <= MEM_WB_REGISTER_CLEAR;
            elsif (mem_wb_register_en = '1') then
                mem_wb_register <= mem_wb_register_next;
            end if;
        end if;
    end process;             
                         
--    reg_ex_mem : entity work.register_var(rtl)
--                 generic map(WIDTH_BITS => 38)
--                 port map(-- ===== DATA =====
--                          d(31 downto 0) => exe_alu_result,
                          
--                          -- ===== CONTROL (WRITEBACK) =====
--                          d(36 downto 32) => exe_reg_wr_addr,
--                          d(37) => exe_reg_wr_en,
                          
--                          -- =================================================================
                          
--                          -- ===== DATA =====
--                          q(31 downto 0) => mem_data_in,
                          
--                          -- ===== CONTROL (WRITEBACK) =====
--                          q(36 downto 32) => mem_reg_wr_addr,
--                          q(37) => mem_reg_wr_en,
                          
--                          -- ===== PIPELINE REGISTER CONTROL =====
--                          clk => clk,
--                          reset => reset,
--                          en => '1'
--                 );

--    reg_mem_wb : entity work.register_var(rtl)
--                 generic map(WIDTH_BITS => 38)
--                 port map(-- ===== DATA =====
--                          d(31 downto 0) => mem_data_out,
                          
--                          -- ===== CONTROL (WRITEBACK) =====
--                          d(36 downto 32) => mem_reg_wr_addr,
--                          d(37) => mem_reg_wr_en,
                          
--                          -- =================================================================
                          
--                          -- ===== DATA =====
--                          q(31 downto 0) => wb_reg_wr_data,
                          
--                          -- ===== CONTROL (WRITEBACK) =====
--                          q(36 downto 32) => wb_reg_wr_addr,
--                          q(37) => wb_reg_wr_en,
                          
--                          -- ===== PIPELINE REGISTER CONTROL =====
--                          clk => clk,
--                          reset => reset,
--                          en => '1'
--                 );

    de_ex_register_en <= '1';
    ex_mem_register_en <= '1';
    mem_wb_register_en <= '1';

end structural;















