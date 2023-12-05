# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

source ../pdk/openroad/init_tech.tcl

read_verilog ../out/temp.v
link_design $design_name

set block [ord::get_db_block]
foreach inst [odb::dbBlock_getInsts $block] {
    set name [odb::dbInst_getName $inst]
    set new_name [string map {. __} $name]
    odb::dbInst_rename $inst $new_name
}

puts "Renamed instances"

foreach net [odb::dbBlock_getNets $block] {
    set name [odb::dbNet_getName $net]
    set new_name [string map {. __} $name]
    odb::dbNet_rename $net $new_name
}
puts "Renamed nets"

write_verilog ../out/$design_name.v
puts "$design_name.v written"

exit
