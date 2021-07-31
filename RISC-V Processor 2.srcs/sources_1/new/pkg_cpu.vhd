package pkg_cpu is
    constant CPU_DATA_WIDTH_BITS : integer := 64;
    constant ENABLE_BIG_REGFILE : integer range 0 to 1 := 1;        -- Selects between 16 entry register file and the 32 entry one (RV32E and RV32I)
end pkg_cpu;