# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Load Tech
source ../pdk/openroad/init_tech.tcl

# Read netlist
read_verilog ../out/temp.v
link_design $design_name

# Rename instances -> Remove '.' from names
set block [ord::get_db_block]
set insts [odb::dbBlock_getInsts $block]
foreach inst $insts {
    set name [odb::dbInst_getName $inst]
    set new_name [string map {. __} $name]
    odb::dbInst_rename $inst $new_name
}
puts "Renamed instances"

# Rename nets -> Remove '.' from names
foreach net [odb::dbBlock_getNets $block] {
    set name [odb::dbNet_getName $net]
    set new_name [string map {. __} $name]
    odb::dbNet_rename $net $new_name
}
puts "Renamed nets"

# Add leds to flip flops
set led_master [odb::dbDatabase_findMaster [ord::get_db] "Led_Res_0603"]
foreach inst $insts {
    set master [odb::dbInst_getMaster $inst]
    set name [odb::dbMaster_getName $master]
    if {[string match *FF* $name]} {
        set pins [odb::dbInst_getITerms $inst]
        foreach pin $pins {
            if {[odb::dbITerm_isOutputSignal $pin] && [odb::dbITerm_isConnected $pin]} {
                set inst_name [odb::dbInst_getName $inst]
                set inst_net [odb::dbITerm_getNet $pin]
                set net_name [odb::dbNet_getName $inst_net]
                append inst_name "_led"
                set led [odb::dbInst_create $block $led_master $inst_name]
                foreach led_input [odb::dbInst_getITerms $led] {
                    if {[odb::dbITerm_isInputSignal $led_input]} {
                        odb::dbITerm_connect $led_input $inst_net
                    }
                }
            }
        }
    }
}

# Write final netlist
write_verilog ../out/$design_name.v
puts "$design_name.v written"

exit
