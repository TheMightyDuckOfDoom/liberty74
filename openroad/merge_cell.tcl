# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

set open_results 0

source ../pdk/openroad/init_tech.tcl
set site CoreSite

read_verilog ../config/merge_cells/$design_name.v
link_design $design_name

set block [ord::get_db_block]
set insts [odb::dbBlock_getInsts $block]

# Determine die size -> Put all instances next to each other
set width 0
set height 0
set inst_names [list]
foreach inst $insts {
    set master [odb::dbInst_getMaster $inst]
    set inst_height [odb::dbMaster_getHeight $master]
    if {$inst_height > $height} {
        set height [expr {$inst_height / 1000.0}]
    }

    set inst_width [odb::dbMaster_getWidth $master]
    set width [expr {$width + $inst_width / 1000.0}]

    lappend inst_names [odb::dbInst_getName $inst]
}

# Initialize floorplan and make tracks
initialize_floorplan -site $site -die_area "0 0 $width $height" -core_area "0 0 $width $height"
source ../pdk/openroad/make_tracks.tcl

# Sort instance names
set inst_names [lsort $inst_names]

# Place instances
set x 0.0
foreach inst_name $inst_names {
    set inst [odb::dbBlock_findInst $block $inst_name]

    set master [odb::dbInst_getMaster $inst]
    set inst_width [odb::dbMaster_getWidth $master]
    
    odb::dbInst_setLocation $inst [expr int($x)] [expr int(0)]
    odb::dbInst_setPlacementStatus $inst PLACED
    set x [expr {$x + $inst_width}]
}

# Place pins on top of the instance pins
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

# Constraints -> only if clock exists
if {[get_ports clk_i] != ""} {
    create_clock -name clk -period 10 {clk_i}
    set_input_delay -clock clk 0 [delete_from_list [all_inputs] [get_ports clk_i]]
    set_output_delay -clock clk 0 [all_outputs]
}

report_checks -corner Fast    -path_delay min
report_checks -corner Typical -path_delay max

# Global route
set_routing_layers -signal Metal1-Metal2 -clock Metal1-Metal2
global_route -verbose -allow_congestion

# Detailed route
detailed_route -output_drc merge_macros_route_drc.rpt

# Write def, lef and libs
write_def out/merge_cell_$design_name.def
write_abstract_lef -bloat_factor 0 out/merge_cell_$design_name.lef
write_timing_model -corner Typical out/merge_cell_typ_$design_name.lib  -library_name merge_cell_typ_$design_name
write_timing_model -corner Fast    out/merge_cell_fast_$design_name.lib -library_name merge_cell_fast_$design_name
write_timing_model -corner Slow    out/merge_cell_slow_$design_name.lib -library_name merge_cell_slow_$design_name

# Open Results
if {$open_results} {
    gui::show
}

exit
