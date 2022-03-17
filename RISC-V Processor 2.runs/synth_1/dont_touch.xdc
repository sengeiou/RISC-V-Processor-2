# This file is automatically generated.
# It contains project source information necessary for synthesis and implementation.

# XDC: new/nexys_a7_constr.xdc

# IP: ip/clk_wiz_0/clk_wiz_0.xci
set_property KEEP_HIERARCHY SOFT [get_cells -hier -filter {REF_NAME==clk_wiz_0 || ORIG_REF_NAME==clk_wiz_0} -quiet] -quiet

# IP: ip/block_rom_memory/block_rom_memory.xci
set_property KEEP_HIERARCHY SOFT [get_cells -hier -filter {REF_NAME==block_rom_memory || ORIG_REF_NAME==block_rom_memory} -quiet] -quiet

# IP: ip/ila_reg_file/ila_reg_file.xci
set_property KEEP_HIERARCHY SOFT [get_cells -hier -filter {REF_NAME==ila_reg_file || ORIG_REF_NAME==ila_reg_file} -quiet] -quiet

# IP: ip/fifo_generator_1/fifo_generator_1.xci
set_property KEEP_HIERARCHY SOFT [get_cells -hier -filter {REF_NAME==fifo_generator_1 || ORIG_REF_NAME==fifo_generator_1} -quiet] -quiet

# XDC: e:/Vivado Projects/RISC-V-Processor-2/RISC-V Processor 2.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_board.xdc
set_property KEEP_HIERARCHY SOFT [get_cells [split [join [get_cells -hier -filter {REF_NAME==clk_wiz_0 || ORIG_REF_NAME==clk_wiz_0} -quiet] {/inst } ]/inst ] -quiet] -quiet

# XDC: e:/Vivado Projects/RISC-V-Processor-2/RISC-V Processor 2.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc
#dup# set_property KEEP_HIERARCHY SOFT [get_cells [split [join [get_cells -hier -filter {REF_NAME==clk_wiz_0 || ORIG_REF_NAME==clk_wiz_0} -quiet] {/inst } ]/inst ] -quiet] -quiet

# XDC: e:/Vivado Projects/RISC-V-Processor-2/RISC-V Processor 2.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_ooc.xdc

# XDC: e:/Vivado Projects/RISC-V-Processor-2/RISC-V Processor 2.gen/sources_1/ip/block_rom_memory/block_rom_memory_ooc.xdc

# XDC: e:/Vivado Projects/RISC-V-Processor-2/RISC-V Processor 2.gen/sources_1/ip/ila_reg_file/ila_v6_2/constraints/ila_impl.xdc
set_property KEEP_HIERARCHY SOFT [get_cells [split [join [get_cells -hier -filter {REF_NAME==ila_reg_file || ORIG_REF_NAME==ila_reg_file} -quiet] {/U0 } ]/U0 ] -quiet] -quiet

# XDC: e:/Vivado Projects/RISC-V-Processor-2/RISC-V Processor 2.gen/sources_1/ip/ila_reg_file/ila_v6_2/constraints/ila.xdc
#dup# set_property KEEP_HIERARCHY SOFT [get_cells [split [join [get_cells -hier -filter {REF_NAME==ila_reg_file || ORIG_REF_NAME==ila_reg_file} -quiet] {/U0 } ]/U0 ] -quiet] -quiet

# XDC: e:/Vivado Projects/RISC-V-Processor-2/RISC-V Processor 2.gen/sources_1/ip/ila_reg_file/ila_reg_file_ooc.xdc

# XDC: e:/Vivado Projects/RISC-V-Processor-2/RISC-V Processor 2.gen/sources_1/ip/fifo_generator_1/fifo_generator_1.xdc
set_property KEEP_HIERARCHY SOFT [get_cells [split [join [get_cells -hier -filter {REF_NAME==fifo_generator_1 || ORIG_REF_NAME==fifo_generator_1} -quiet] {/U0 } ]/U0 ] -quiet] -quiet
