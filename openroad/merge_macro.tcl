# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

set CORNER_GROUP CMOS_5V

source ../pdk/openroad/init_tech.tcl
set site CoreSite

set design_name en_ff
read_verilog ../yosys/$design_name.v
link_design $design_name

set block [ord::get_db_block]
set insts [odb::dbBlock_getInsts $block]

set width 0
set height 0
foreach inst $insts {
    set master [odb::dbInst_getMaster $inst]
    set inst_height [odb::dbMaster_getHeight $master]
    if {$inst_height > $height} {
        set height [expr {$inst_height / 1000.0}]
    }

    set inst_width [odb::dbMaster_getWidth $master]
    set width [expr {$width + $inst_width / 1000.0}]
}
initialize_floorplan -site $site -die_area "0 0 $width $height" -core_area "0 0 $width $height"
source ../pdk/openroad/make_tracks.tcl

set x 0.0
foreach inst $insts {
    set master [odb::dbInst_getMaster $inst]
    set inst_width [odb::dbMaster_getWidth $master]
    
    odb::dbInst_setLocation $inst [expr int($x)] [expr int(0)]
    odb::dbInst_setPlacementStatus $inst PLACED
    set x [expr {$x + $inst_width}]
}

# Create pins
foreach bterm [odb::dbBlock_getBTerms $block] {
    set name [odb::dbBTerm_getName $bterm]
    puts [odb::dbBTerm_getName $bterm]
    
    set net [odb::dbBlock_findNet $block $name]
    puts [odb::dbNet_getName $net]

    set iterm [odb::dbNet_get1stITerm $net]
    puts [odb::dbITerm_getName $iterm]

    set mterm [odb::dbITerm_getMTerm $iterm]
    puts [odb::dbMTerm_getName $mterm]

    set xy [odb::dbITerm_getAvgXY $iterm]

    set x [lindex $xy 1]
    set y [lindex $xy 2]

    set rect [odb::dbMTerm_getBBox $mterm]
    set width  [odb::Rect_dx $rect]
    set height [odb::Rect_dy $rect]

    set tech [ord::get_db_tech]
    set layer [odb::dbTech_findLayer $tech Metal1]
    
    puts "Pin: $name $x $y $width $height"

    #place_pin -pin_name $name -layer Metal1 -location {$x $y} -pin_size {$width $height}
    ppl::place_pin $bterm $layer $x $y $width $height 0
}
set_pin_thick_multiplier -ver_multiplier 2 -hor_multiplier 2
place_pins -hor_layers Metal1 -ver_layers Metal2

create_clock -name clk -period 10 {clk_i}
set_input_delay -clock clk 0 [delete_from_list [all_inputs] [get_ports clk_i]]
set_output_delay -clock clk 0 [all_outputs]

report_checks -corner Fast    -path_delay min
report_checks -corner Typical -path_delay max

set_routing_layers -signal Metal1-Metal2 -clock Metal1-Metal2
global_route -verbose -allow_congestion

detailed_route

# TODO: Add VIAs to obstructions

write_def out/$design_name.def
write_abstract_lef -bloat_factor 0 out/$design_name.lef
write_timing_model -corner Typical out/typ_$design_name.lib  -library_name typ_$design_name
write_timing_model -corner Fast    out/fast_$design_name.lib -library_name fast_$design_name
write_timing_model -corner Slow    out/slow_$design_name.lib -library_name slow_$design_name

#gui::show

#exit
