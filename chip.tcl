source init_tech.tcl
set design_name priority_encoder

read_verilog out/${design_name}.v
link_design $design_name

create_clock -name clk -period 10 {clk_i}
set_input_delay -clock clk 0 [delete_from_list [all_inputs] [get_ports clk_i]]
set_output_delay -clock clk 0 [all_outputs]
report_checks -path_delay min
report_checks -path_delay max

check_setup

ICeWall::load_footprint floorplan.strategy
initialize_floorplan \
  -die_area  [ICeWall::get_die_area] \
  -core_area [ICeWall::get_core_area] \
  -site      CoreSite


make_tracks Metal1 -x_offset 0.144 -x_pitch 0.288 -y_offset 0.144 -y_pitch 0.288
make_tracks Metal2 -x_offset 0.144 -x_pitch 0.288 -y_offset 0.144 -y_pitch 0.288

place_pins -hor_layers Metal1 -ver_layers Metal2 -min_distance_in_tracks -min_distance 8

add_global_connection -net VDD -inst_pattern .* -pin_pattern VDD -power
add_global_connection -net VSS -inst_pattern .* -pin_pattern VSS -ground

global_connect

set_voltage_domain -name CORE -power VDD -ground VSS
define_pdn_grid -name grid -voltage_domains CORE

add_pdn_ring -grid {grid}     \
    -layer {Metal1 Metal2}    \
    -widths {1.00 1.00}     \
    -spacings {0.50 0.50}     \
    -core_offsets {4.00 4.00 4.00 4.00} \
    -add_connect

add_pdn_strip -grid grid -layer Metal1 -width 0.25 -pitch 3.6 -followpins -extend_to_core_ring

pdngen

remove_buffers
repair_design

set_placement_padding -global -right 1 -left 1
global_placement -density 0.55

repair_design

gui::pause
detailed_placement

repair_clock_inverters
set ctsBuf [ list NOT_74LVC1G04 ]
clock_tree_synthesis -root_buf $ctsBuf -buf_list $ctsBuf \
                     -sink_clustering_enable \
                     -sink_clustering_size 30 \
                     -sink_clustering_max_diameter 100 \
                     -balance_levels

set_propagated_clock [all_clocks]
repair_clock_nets

detailed_placement

repair_timing

detailed_placement
check_placement -verbose

set_routing_layers -signal Metal1-Metal2 -clock Metal1-Metal2
gui::pause
global_route -verbose -allow_congestion

gui::pause
repair_design
repair_timing
repair_timing

detailed_placement
check_placement -verbose

global_route -verbose -allow_congestion

set_propagated_clock [all_clocks]

gui::pause
detailed_route -output_drc route_drc.rpt \
               -bottom_routing_layer Metal1 \
               -top_routing_layer Metal2 \
               -verbose 1