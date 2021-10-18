library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_read_arbiter_tb is
--  Port ( );
end axi_read_arbiter_tb;

architecture Behavioral of axi_read_arbiter_tb is
    signal master_bus_req : std_logic_vector(3 downto 0);
    signal curr_master_sel : std_logic_vector(1 downto 0);
     
    signal clk, reset : std_logic;
    
    constant T : time := 20ns;
begin
    process
    begin
        clk <= '0';
        wait for T / 2;
        clk <= '1';
        wait for T / 2;
    end process;
    
    reset <= '0', '1' after 15ns;
    
    uut : entity work.axi_read_arbiter_simple(rtl)
          generic map(NUM_MASTERS => 4)
          port map(master_bus_requests => master_bus_req,
                   read_bus_master_sel => curr_master_sel,
                   clk => clk,
                   reset => reset);
    
    process
    begin
        master_bus_req <= "0000";
        wait for T * 50;
        master_bus_req <= "0100";
        wait for T * 20;
        master_bus_req <= "0101";
        wait for T * 20;
        master_bus_req <= "0001";
        wait for T * 20;
        master_bus_req <= "0000";
        wait for T * 20;
    end process;

end Behavioral;
