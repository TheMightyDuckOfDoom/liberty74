# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Design Setup
set design_name servisia
set CORNER_GROUP "CMOS_5V"

source ../pdk/openroad/init_tech.tcl
source util.tcl

read_verilog ../out/${design_name}.v
link_design $design_name

gui::pause

create_clock -name clk -period 10 {clk_i}
set_input_delay -clock clk 1 [delete_from_list [all_inputs] [get_ports clk_i]]
set_output_delay -clock clk 1 [all_outputs]
report_checks -path_delay min
report_checks -path_delay max

check_setup

ICeWall::load_footprint floorplan.strategy
initialize_floorplan \
  -die_area  [ICeWall::get_die_area] \
  -core_area [ICeWall::get_core_area] \
  -site      CoreSite

source ../pdk/openroad/make_tracks.tcl

place_pins -hor_layers Metal1 -ver_layers Metal2 -min_distance_in_tracks -min_distance 8

add_global_connection -net VDD -inst_pattern .* -pin_pattern VDD -power
add_global_connection -net GND -inst_pattern .* -pin_pattern GND -ground
add_global_connection -net VDD -inst_pattern .* -pin_pattern TIE_HI
add_global_connection -net GND -inst_pattern .* -pin_pattern TIE_LO
add_global_connection -net GND -inst_pattern .* -pin_pattern NC

global_connect

set_voltage_domain -name CORE -power VDD -ground GND
define_pdn_grid -name grid -voltage_domains CORE

add_pdn_ring -grid {grid}     \
    -layer {Metal1 Metal2}    \
    -widths {1.00 1.00}     \
    -spacings {0.50 0.50}     \
    -core_offsets {4.00 4.00 4.00 4.00} \
    -add_connect

add_pdn_strip -grid grid -layer Metal1 -width 1.00 -followpins -extend_to_core_ring

pdngen

set die_area [ord::get_die_area]
set die_width [expr [lindex $die_area 3] - [lindex $die_area 0]]

set cap_distance [expr $die_width / 3]

#tapcell -tapcell_master PWR_CAP -distance $cap_distance

set rows [odb::dbBlock_getRows [ord::get_db_block]]

#set index 0
#foreach row $rows {
#  if $index {
#    odb::dbRow_destroy $row
#  }
#  set index [expr !$index] 
#}

remove_buffers

#buffer_ports
repair_tie_fanout TIE_HI/Y
repair_tie_fanout TIE_LO/Y

repair_design

set_placement_padding -global -right 3 -left 3
global_placement -density 0.36

repair_design
improve_placement
placeDetail

repair_clock_inverters
placeDetail
set ctsBuf [ list BUF_74LVC1G125 ]
clock_tree_synthesis -root_buf $ctsBuf -buf_list $ctsBuf \
                     -balance_levels -clk_nets clk_i

set_propagated_clock [all_clocks]
repair_clock_nets

placeDetail

repair_timing -hold

placeDetail
check_placement -verbose

set_routing_layers -signal Metal1-Metal2 -clock Metal1-Metal2
global_route -verbose -allow_congestion

repair_design
repair_timing

placeDetail
check_placement -verbose

global_route -verbose -allow_congestion

pin_access

global_connect

gui::pause

set_propagated_clock [all_clocks]

detailed_route -output_drc route_drc.rpt \
               -bottom_routing_layer Metal1 \
               -top_routing_layer Metal2 \
               -verbose 1

write_verilog -include_pwr_gnd out/$design_name.final.v
write_def out/$design_name.final.def

report_checks -path_delay min
report_checks -path_delay max

if ![gui::enabled] {
  exit
}
