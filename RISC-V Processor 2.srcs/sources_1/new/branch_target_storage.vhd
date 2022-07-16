-- Holds calculated branch target addresses that the CPU will jump to in case the branch is taken.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.PKG_CPU.ALL;

entity branch_target_storage is
    generic(
        BRANCH_TARGET_STORAGE_ENTRIES : natural
    );
    port(
        branch_tag : in std_logic_vector(BRANCH_TAG_BITS - 1 downto 0);
        
    );
end branch_target_storage;

architecture rtl of branch_target_storage is

begin


end rtl;
