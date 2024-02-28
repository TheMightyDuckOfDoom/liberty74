# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Load Tech
source ../pdk/openroad/init_tech.tcl

# Read netlist
read_verilog ../out/$design_name.v
link_design $design_name

set cells [get_cells Led]

set block [ord::get_db_block]
set insts [odb::dbBlock_getInsts $block]
set blackboxes {Led_Res_0603 LCD_16x2 W24129A_35 AM29F080B_90SF ZBUF_74LVC1G125}
foreach inst $insts {
    set master [odb::dbInst_getMaster $inst]
    set name [odb::dbMaster_getName $master]

    if {[lsearch -exact $blackboxes $name] != -1} {
        puts $name
        odb::dbInst_destroy $inst
    }
}

write_verilog ../out/dft/$design_name.dft.v
puts "$design_name.dft.v written"
