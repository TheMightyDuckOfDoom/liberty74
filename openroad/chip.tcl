source init_tech.tcl
set design_name clock

proc placeDetail {} {
  detailed_placement
  set block [ord::get_db_block]
  foreach inst [odb::dbBlock_getInsts $block] {
    set orient [odb::dbInst_getOrient $inst]
    if {$orient == "MX"} {
      odb::dbInst_setLocationOrient $inst R180
    }
  }
}

read_verilog ../out/${design_name}.v
link_design $design_name

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


make_tracks Metal1 -x_offset 0.1 -x_pitch 0.325 -y_offset 0 -y_pitch 0.3
make_tracks Metal2 -x_offset 0.1 -x_pitch 0.325 -y_offset 0 -y_pitch 0.3

place_pins -hor_layers Metal1 -ver_layers Metal2 -min_distance_in_tracks -min_distance 8

add_global_connection -net VDD -inst_pattern .* -pin_pattern VDD -power
add_global_connection -net GND -inst_pattern .* -pin_pattern GND -ground

global_connect

set_voltage_domain -name CORE -power VDD -ground GND
define_pdn_grid -name grid -voltage_domains CORE

add_pdn_ring -grid {grid}     \
    -layer {Metal1 Metal2}    \
    -widths {1.00 1.00}     \
    -spacings {0.50 0.50}     \
    -core_offsets {4.00 4.00 4.00 4.00} \
    -add_connect

add_pdn_strip -grid grid -layer Metal1 -width 0.25 -pitch 3.6 -followpins -extend_to_core_ring

pdngen

set rows [odb::dbBlock_getRows [ord::get_db_block]]

set index 0
foreach row $rows {
  if $index {
    odb::dbRow_destroy $row
  }
  set index [expr !$index] 
}

remove_buffers
repair_design

set_placement_padding -global -right 2
global_placement -density 1

repair_design
improve_placement
placeDetail

repair_clock_inverters
placeDetail
set ctsBuf [ list INV_74LVC1G04 ]
clock_tree_synthesis -root_buf $ctsBuf -buf_list $ctsBuf \
                     -balance_levels -clk_nets clk_i

set_propagated_clock [all_clocks]
repair_clock_nets

placeDetail

repair_timing

placeDetail
check_placement -verbose

set_routing_layers -signal Metal1-Metal2 -clock Metal1-Metal2
global_route -verbose -allow_congestion

repair_design
repair_timing

placeDetail
check_placement -verbose

global_route -verbose -allow_congestion

gui::pause

set_propagated_clock [all_clocks]

detailed_route -output_drc route_drc.rpt \
               -bottom_routing_layer Metal1 \
               -top_routing_layer Metal2 \
               -verbose 1

write_verilog out/$design_name.final.v
write_def out/$design_name.final.def