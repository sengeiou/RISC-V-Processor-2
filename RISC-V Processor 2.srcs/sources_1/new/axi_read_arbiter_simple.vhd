library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi_read_arbiter_simple is
    generic(
        NUM_MASTERS : integer  
    );
    port(
        -- SIGNALS FROM MASTERS
        master_bus_requests : in std_logic_vector(3 downto 0);
        
        -- SIGNALS FROM AND TO INTERCONNECT
        read_bus_master_sel : out std_logic_vector(1 downto 0);
        
        -- OTHER SIGNALS
        clk : in std_logic;
        reset : in std_logic
    );
end axi_read_arbiter_simple;

architecture rtl of axi_read_arbiter_simple is
    type arbiter_state_type is (IDLE,
                                BUS_GRANTED);

    signal curr_master_counter_reg : unsigned(1 downto 0);
    signal curr_master_counter_next : unsigned(1 downto 0);
    signal curr_master_counter_en : std_logic;
    
    signal arbiter_state_reg : arbiter_state_type;
    signal arbiter_state_reg_next : arbiter_state_type;
begin
    counter_update : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                curr_master_counter_reg <= (others => '0');
            elsif (curr_master_counter_en = '1') then
                curr_master_counter_reg <= curr_master_counter_next;
            end if;
        end if;
    end process;
    
    curr_master_counter_next <= curr_master_counter_reg + 1;

    state_reg_update : process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then  
                arbiter_state_reg <= IDLE;
            else
                arbiter_state_reg <= arbiter_state_reg_next;
            end if;
        end if;
    end process;

    next_state_proc : process(arbiter_state_reg, master_bus_requests, curr_master_counter_reg)
    begin
        if (arbiter_state_reg = IDLE) then
            if (master_bus_requests(to_integer(curr_master_counter_reg + 1)) = '1') then
                arbiter_state_reg_next <= BUS_GRANTED;
            else
                arbiter_state_reg_next <= IDLE;
            end if;
        elsif (arbiter_state_reg = BUS_GRANTED) then
            if (master_bus_requests(to_integer(curr_master_counter_reg)) = '0') then
                arbiter_state_reg_next <= IDLE;
            else
                arbiter_state_reg_next <= BUS_GRANTED;
            end if;
        end if;
    end process;
    
    state_outputs_proc : process(arbiter_state_reg, curr_master_counter_reg)
    begin
        curr_master_counter_en <= '0';
        if (arbiter_state_reg = IDLE) then
            read_bus_master_sel <= (others => '1');
            curr_master_counter_en <= '1';
        elsif (arbiter_state_reg = BUS_GRANTED) then
            read_bus_master_sel <= std_logic_vector(curr_master_counter_reg);
        end if;
    end process;

end rtl;
