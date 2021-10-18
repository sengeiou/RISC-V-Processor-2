library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_read_arbiter_tb is
--  Port ( );
end axi_read_arbiter_tb;

architecture Behavioral of axi_read_arbiter_tb is
    signal addr : std_logic_vector(31 downto 0);
    signal master_bus_req : std_logic_vector(3 downto 0);
    
    signal curr_master_sel : std_logic_vector(1 downto 0);
    signal read_slave_sel : std_logic_vector(1 downto 0);
     
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
    
    uut : entity work.axi_bus_controller_simple(rtl)
          generic map(NUM_MASTERS => 4)
          port map(master_read_bus_requests => master_bus_req,
                   read_address => addr,
                   read_master_sel => curr_master_sel,
                   read_slave_sel => read_slave_sel,
                   clk => clk,
                   reset => reset);
    
    process
    begin
        addr <= X"0000_0000";
        master_bus_req <= "0000";
        wait for T * 50;
        addr <= X"0000_100C";
        master_bus_req <= "0100";
        wait for T * 20;
        master_bus_req <= "0111";
        wait for T * 20;
        addr <= X"0000_231C";
        master_bus_req <= "0011";
        wait for T * 20;
        master_bus_req <= "0010";
        wait for T * 20;
        master_bus_req <= "0000";
        wait for T * 20;
    end process;

end Behavioral;
