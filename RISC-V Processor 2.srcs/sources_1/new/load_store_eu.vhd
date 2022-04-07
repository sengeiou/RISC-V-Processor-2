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
        tag : in std_logic_vector(PHYS_REGFILE_ADDR_BITS - 1 downto 0);
        valid : in std_logic;
        
        cdb : out cdb_type;
        cdb_request : out std_logic;
        cdb_granted : in std_logic;
        
        busy : out std_logic;
        reset : in std_logic;
        clk : in std_logic
    );
end load_store_eu;

architecture rtl of load_store_eu is

begin
   
end rtl;
