library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.PKG_CPU.ALL;
use WORK.PKG_AXI.ALL;

entity load_store_unit_tb is

end load_store_unit_tb;

architecture Behavioral of load_store_unit_tb is
    constant SQ_ENTRIES : integer := 8;
    constant LQ_ENTRIES : integer := 8;

    signal sq_calc_addr : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0);
    signal sq_calc_addr_tag : std_logic_vector(integer(ceil(log2(real(SQ_ENTRIES)))) - 1 downto 0);
    signal sq_calc_addr_valid : std_logic;
    signal lq_calc_addr : std_logic_vector(CPU_ADDR_WIDTH_BITS - 1 downto 0); 
    signal lq_calc_addr_tag : std_logic_vector(integer(ceil(log2(real(LQ_ENTRIES)))) - 1 downto 0); 
    signal lq_calc_addr_valid : std_logic;
      
    -- Store data fetch results bus
    signal sq_store_data : std_logic_vector(CPU_DATA_WIDTH_BITS - 1 downto 0);
    signal sq_store_data_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
    signal sq_store_data_valid : std_logic;
        
    -- Tag of a newly allocated queue entry
    signal sq_alloc_tag : std_logic_vector(integer(ceil(log2(real(SQ_ENTRIES)))) - 1 downto 0);
    signal lq_alloc_tag : std_logic_vector(integer(ceil(log2(real(LQ_ENTRIES)))) - 1 downto 0);
        
    signal sq_data_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);       
    signal lq_dest_tag : std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
       
    signal sq_enqueue_en : std_logic;
    signal sq_retire_tag : std_logic_vector(integer(ceil(log2(real(SQ_ENTRIES)))) - 1 downto 0);
    signal sq_retire_tag_valid : std_logic;
    signal lq_enqueue_en : std_logic;
    signal lq_dequeue_en : std_logic;

    signal fmi : FromMasterInterface;

    signal clk : std_logic;
    signal reset : std_logic;

    constant T : time := 20ns;
begin
    reset <= '1', '0' after T * 2;

    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    uut : entity work.load_store_eu(rtl)
          generic map(SQ_ENTRIES => SQ_ENTRIES,
                      LQ_ENTRIES => LQ_ENTRIES)
          port map(from_master_interface => fmi,
                   
                   sq_calc_addr => sq_calc_addr,
                   sq_calc_addr_tag => sq_calc_addr_tag,
                   sq_calc_addr_valid => sq_calc_addr_valid,
                   lq_calc_addr => lq_calc_addr,
                   lq_calc_addr_tag => lq_calc_addr_tag,
                   lq_calc_addr_valid => lq_calc_addr_valid,
                   
                   sq_store_data => sq_store_data,
                   sq_store_data_tag => sq_store_data_tag,
                   sq_store_data_valid => sq_store_data_valid,
                   
                   sq_alloc_tag => sq_alloc_tag,
                   lq_alloc_tag => lq_alloc_tag,
                   
                   sq_data_tag => sq_data_tag,
                   lq_dest_tag => lq_dest_tag,
                   
                   sq_enqueue_en => sq_enqueue_en,
                   sq_retire_tag => sq_retire_tag,
                   sq_retire_tag_valid => sq_retire_tag_valid,
                   
                   lq_enqueue_en => lq_enqueue_en,
                   lq_dequeue_en => lq_dequeue_en,
                   
                   cdb_granted => '1',
                   
                   reset => reset,
                   clk => clk);
                   
    process
    begin
        fmi <= FROM_MASTER_CLEAR;
    
        sq_calc_addr <= (others => '0');
        sq_calc_addr_tag <= (others => '0');
        sq_calc_addr_valid <= '0';
        lq_calc_addr <= (others => '0');
        lq_calc_addr_tag <= (others => '0');
        lq_calc_addr_valid <= '0';
                   
        sq_store_data <= (others => '0');
        sq_store_data_tag <= (others => '0');
        sq_store_data_valid <= '0';
                   
        sq_data_tag <= (others => '0');
        lq_dest_tag <= (others => '0');
                   
        sq_enqueue_en <= '0';
        sq_retire_tag <= (others => '0');
        sq_retire_tag_valid <= '0';
        lq_enqueue_en <= '0';
        lq_dequeue_en <= '0';
        
        wait for T * 10;
        -- FILL STORE QUEUE ENTRIES

        sq_data_tag <= "1010101";
        lq_dest_tag <= (others => '0');
                   
        sq_enqueue_en <= '1';

        wait for T * 20;
        
        wait for T;
        -- ADDRESS GENERATED TEST
        sq_calc_addr <= X"AAAA_AAAA";
        sq_calc_addr_tag <= "000";
        sq_calc_addr_valid <= '1';
        
        sq_data_tag <= (others => '0');
        lq_dest_tag <= (others => '0');
                   
        sq_enqueue_en <= '0';
        
        wait for T;
        
        sq_calc_addr <= X"CCCC_CCCC";
        sq_calc_addr_tag <= "010";
        sq_calc_addr_valid <= '1';
        
        wait for T;
        -- DATA GENERATED TEST
        
        sq_calc_addr_valid <= '0';
        sq_store_data <= X"FFFF_FFFF";
        sq_store_data_tag <= "1010101";
        sq_store_data_valid <= '1';

        wait for T;
        
        sq_store_data_valid <= '0';

        wait for T * 50;
        
        wait for T;
        -- RETIRE THE FIRST STORE UOP
        sq_retire_tag <= "000";
        sq_retire_tag_valid <= '1';
        
        wait for T;
        
        sq_retire_tag <= "001";
        
        wait for T;
        
        sq_retire_tag_valid <= '0';
        
        wait for T * 50;
        
        fmi.done_write <= '1';
        
        wait for T;
        
        fmi.done_write <= '0';
        
        wait for T;
    end process;

end Behavioral;
