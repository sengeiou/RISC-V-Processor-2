library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port(
        LED : out std_logic_vector(15 downto 0);
        CLK100MHZ : in std_logic;
        BTNC : in std_logic
    );
end top;

architecture strucutral of top is
    component clk_wiz_0
    port
     (-- Clock in ports
      -- Clock out ports
      clk_cpu          : out    std_logic;
      -- Status and control signals
      reset             : in     std_logic;
      clk_in1           : in     std_logic
     );
    end component;
    
    signal clk_cpu : std_logic;
begin
    

    cpu : entity work.cpu(structural)
          port map(led_out_debug => LED,
                   clk_cpu => clk_cpu,
                   reset_cpu => BTNC);
                   
    your_instance_name : clk_wiz_0
        port map ( 
       -- Clock out ports  
        clk_cpu => clk_cpu,
       -- Status and control signals                
        reset => BTNC,
        -- Clock in ports
        clk_in1 => CLK100MHZ);

end strucutral;
