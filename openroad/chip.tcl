# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

################################################################################
# Design Setup
################################################################################

# General settings
set routing_channels 1
set drt_end_iter 60
set open_results 1
set PCB_TILES 0
set endcap 1

# PCB Tile config
set PCB_EDGE_MARGIN 5
set PCB_TILE_SIZE 100
set PCB_TILE_PLACEMENT_MARGIN 7.5
set PCB_TILE_ROUTING_MARGIN 5

# Calculate number of tiles
if {$PCB_TILES} {
    set NUM_X_PCB_TILES [expr {floor(double($PCB_WIDTH) / \
        double($PCB_TILE_SIZE))}]
    set NUM_Y_PCB_TILES [expr {floor(double($PCB_HEIGHT) / \
        double($PCB_TILE_SIZE))}]
} else {
    set NUM_X_PCB_TILES 0
    set NUM_Y_PCB_TILES 0
}

# Placment density
if {$routing_channels} {
    if {$PCB_TILES} {
        if {$endcap} {
            set density 0.70
        } else {
            set density 0.78
        }
    } else {
        if {$endcap} {
            set density 0.59
        } else {
            set density 0.78
        }
    }

    set padding 0
} else {
    set density 0.56
    set padding 5
}

################################################################################
# Load technology and utillity script
################################################################################

source ../pdk/openroad/init_tech.tcl
source util.tcl

################################################################################
# Load merged cells and design netlist
################################################################################

load_merge_cells

read_verilog ../out/${design_name}.v
link_design $design_name

################################################################################
# Constraints
################################################################################

create_clock -name clk -period 10 {i_clk_mux/Y}
set_input_delay -clock clk 0 {*/FROM_HEADER}
set_output_delay -clock clk 0 {*/TO_HEADER}

foreach pin [delete_from_list [get_pins i_servisia_mem__i_sram/*] [get_pins \
    i_servisia_mem__i_sram/CS_N]] {
    set_data_check -fall_from [get_pins i_servisia_mem__i_sram/CS_N] -to $pin \
        -setup 0
    set_data_check -rise_from [get_pins i_servisia_mem__i_sram/CS_N] -to $pin \
        -hold 0
}

set_false_path -through [get_pins i_servisia_mem__i_flash/A*] -to [get_pins \
    i_servisia_mem__i_sram/DQ*]

check_setup -verbose

report_checks -path_delay min -corner Fast
report_checks -path_delay max -corner Typical

################################################################################
# PCB Tile placement blockages
################################################################################

for {set y 1} {$y < $NUM_Y_PCB_TILES} {incr y} {
    # Create Horizontal Placement Blockages
    set x0 [ord::microns_to_dbu 0]
    set x1 [ord::microns_to_dbu $PCB_WIDTH]
    set y0 [ord::microns_to_dbu [expr {$y * $PCB_TILE_SIZE - \
        $PCB_TILE_ROUTING_MARGIN / 2.0}]]
    set y1 [ord::microns_to_dbu [expr {$y * $PCB_TILE_SIZE + \
        $PCB_TILE_ROUTING_MARGIN / 2.0}]]

    set obstruction [odb::dbBlockage_create [ord::get_db_block] $x0 $y0 $x1 $y1]
    puts "Horizontal Blockage: $x0 $y0 $x1 $y1"
}


################################################################################
# Initial Floorplan, make tracks and place pins
################################################################################

# Floorplan
initialize_floorplan \
    -die_area [list 0 0 $PCB_WIDTH $PCB_HEIGHT] \
    -core_area [list $PCB_EDGE_MARGIN $PCB_EDGE_MARGIN [expr {$PCB_WIDTH - \
    $PCB_EDGE_MARGIN}] [expr {$PCB_HEIGHT - $PCB_EDGE_MARGIN}]] \
    -site CoreSite

# Make tracks
source ../pdk/openroad/make_tracks.tcl

# Place Pins
if {[llength [all_inputs]] > 0 || [llength [all_outputs]] > 0} {
    place_io_pins -hor_layers Metal1 -ver_layers Metal2 \
        -min_distance_in_tracks -min_distance 8
}

################################################################################
# Global Power Connections
################################################################################

add_global_connection -net VDD -inst_pattern .* -pin_pattern VDD -power
add_global_connection -net GND -inst_pattern .* -pin_pattern GND -ground
add_global_connection -net VDD -inst_pattern .* -pin_pattern TIE_HI
add_global_connection -net GND -inst_pattern .* -pin_pattern TIE_LO
add_global_connection -net VDD -inst_pattern .* -pin_pattern NC_VDD
add_global_connection -net GND -inst_pattern .* -pin_pattern NC

global_connect

################################################################################
# Power Grid
################################################################################

set_voltage_domain -name CORE -power VDD -ground GND
define_pdn_grid -name grid -voltage_domains CORE -obstructions {Metal1 Metal2}

add_pdn_ring -grid {grid} \
    -layer {Metal1 Metal2} \
    -widths {1.00 1.00} \
    -spacings {0.50 0.50} \
    -pad_offsets {1.0 1.0 1.0 1.0}
add_pdn_strip -grid grid -layer Metal1 -width 0.5 -followpins \
    -extend_to_core_ring
if {$NUM_X_PCB_TILES > 1} {
    add_pdn_strip -grid grid -layer Metal2 -width 1.0 -pitch 100 \
        -extend_to_core_ring \
        -offset [expr {$PCB_TILE_SIZE - $PCB_EDGE_MARGIN - \
        ($PCB_TILE_ROUTING_MARGIN / 2)}] \
        -spacing [expr {$PCB_TILE_ROUTING_MARGIN / 2}]
}
#add_pdn_strip -grid grid -layer Metal2 -width 1.0 -pitch 200 \
#   -extend_to_core_ring -offset [expr -0.25 * $PCB_TILE_PLACEMENT_MARGIN - \
#   1.0] -starts_with GROUND
add_pdn_connect -layers {Metal1 Metal2} -fixed_vias {Via1_Power} -max_rows 1 \
    -max_columns 1

pdngen

# Add power pin header
set pwr_header_master [odb::dbDatabase_findMaster [ord::get_db] "PWR_HEADER"]
odb::dbInst_create [ord::get_db_block] $pwr_header_master "PWR_HEADER"


################################################################################
# Create routing channels and add capacitors
################################################################################

# Routing channels
if {$routing_channels} {
    create_routing_channels
}

# Capacitors at the end of the rows
if {$endcap} {
    tapcell -endcap_master PWR_CAP
}

################################################################################
# PCB Tile handling
################################################################################

set pwr_cap_master [odb::dbDatabase_findMaster [ord::get_db] "PWR_CAP"]
odb::dbMaster_setType $pwr_cap_master "BLOCK"
#cut_rows -halo_width_x 0 -halo_width_y 0
#odb::dbMaster_setType $master "CORE"

#gui::show

set tech [ord::get_db_tech]
set layer1 [odb::dbTech_findLayer $tech Metal1]
set via1 [odb::dbTech_findLayer $tech Via1]
set layer2 [odb::dbTech_findLayer $tech Metal2]

set master [odb::dbDatabase_findMaster [ord::get_db] "TIE_HI"]
set master_width [odb::dbMaster_getWidth $master]
set master_height [odb::dbMaster_getHeight $master]
odb::dbMaster_setType $master "BLOCK"

set inst [odb::dbInst_create [ord::get_db_block] $master "PCB_TILE"]
odb::dbInst_setPlacementStatus $inst "PLACED"

odb::dbMaster_setHeight $master [ord::microns_to_dbu $PCB_HEIGHT]
odb::dbMaster_setWidth $master [ord::microns_to_dbu $PCB_TILE_PLACEMENT_MARGIN]

for {set x 1} {$x < $NUM_X_PCB_TILES} {incr x} {
    # Create Vertical Placement Blockages
    set x0 [ord::microns_to_dbu [expr {$x * $PCB_TILE_SIZE - \
        $PCB_TILE_PLACEMENT_MARGIN / 2.0}]]

    odb::dbInst_setLocation $inst $x0 0
    cut_rows -halo_width_x 0 -halo_width_y 0

    # Create Vertical Routing Obstructions
    set x0 [ord::microns_to_dbu [expr {$x * $PCB_TILE_SIZE - \
        $PCB_TILE_ROUTING_MARGIN / 2.0}]]
    set x1 [ord::microns_to_dbu [expr {$x * $PCB_TILE_SIZE + \
        $PCB_TILE_ROUTING_MARGIN / 2.0}]]
    set y0 [ord::microns_to_dbu 0]
    set y1 [ord::microns_to_dbu $PCB_HEIGHT]

    set obstruction [odb::dbObstruction_create [ord::get_db_block] $layer2 $x0 \
        $y0 $x1 $y1]
    set obstruction [odb::dbObstruction_create [ord::get_db_block] $via1 $x0 \
        $y0 $x1 $y1]
    set bbox [list $x0 $y0 $x1 $y1]
    puts "Vertical Obstruction: $x0 $y0 $x1 $y1"
}

odb::dbMaster_setHeight $master [ord::microns_to_dbu $PCB_TILE_PLACEMENT_MARGIN]
odb::dbMaster_setWidth $master [ord::microns_to_dbu $PCB_WIDTH]

for {set y 1} {$y < $NUM_Y_PCB_TILES} {incr y} {
    # Create Horizontal Placement Blockages
    set y0 [ord::microns_to_dbu [expr {$y * $PCB_TILE_SIZE - \
        $PCB_TILE_PLACEMENT_MARGIN / 2.0}]]

    odb::dbInst_setLocation $inst 0 $y0
    cut_rows -halo_width_x 0 -halo_width_y 0

    # Create Horizontal Routing Obstructions
    set x0 [ord::microns_to_dbu 0]
    set x1 [ord::microns_to_dbu $PCB_WIDTH]
    set y0 [ord::microns_to_dbu [expr {$y * $PCB_TILE_SIZE - \
        $PCB_TILE_ROUTING_MARGIN / 2.0}]]
    set y1 [ord::microns_to_dbu [expr {$y * $PCB_TILE_SIZE + \
        $PCB_TILE_ROUTING_MARGIN / 2.0}]]

    set obstruction [odb::dbObstruction_create [ord::get_db_block] $layer1 $x0 \
        $y0 $x1 $y1]
    set obstruction [odb::dbObstruction_create [ord::get_db_block] $via1 $x0 \
        $y0 $x1 $y1]
    puts "Horizontal Obstruction: $x0 $y0 $x1 $y1"
}

odb::dbMaster_setHeight $master $master_height
odb::dbMaster_setWidth $master $master_width
odb::dbMaster_setType $master "CORE"

odb::dbInst_destroy $inst

################################################################################
# Initial repairs and placement
################################################################################

# Initial repairs
remove_buffers
repair_tie_fanout TIE_HI/Y
repair_tie_fanout TIE_LO/Y
repair_design

# Initial placement to see where cells cluster together
set_placement_padding -global -right $padding -left $padding
global_placement -density $density

# Snap multirow macros in place
place_multirow_macros

# Second placement
global_placement -density $density

# Detailed placement
repair_design
improve_placement
placeDetail

write_def out/$design_name.placed.def

################################################################################
# Connect scan chain
################################################################################

if {$SCAN_CHAIN} {
    set scanchain_default [odb::dbBlock_findInst [ord::get_db_block] "SCANCHAIN_OUT_DEFAULT"]
    if {$scanchain_default != "NULL"} {
        odb::dbInst_destroy $scanchain_default
    }
    write_verilog -include_pwr_gnd out/$design_name.pre_scanchain.v

    connect_scan_chain
    write_verilog -include_pwr_gnd out/$design_name.post_scanchain.v
}

gui::pause

################################################################################
# Clock Tree Synthesis
################################################################################

# Clock tree synthesis
repair_clock_inverters
placeDetail
set ctsBuf [ list BUF_74LVC1G125 ]
clock_tree_synthesis -root_buf $ctsBuf -buf_list $ctsBuf \
    -balance_levels -clk_nets clk_i

# Repair and place newly inserted cells
set_propagated_clock [all_clocks]
repair_clock_nets
placeDetail

# Repair and place newly inserted cells
repair_timing -hold
placeDetail

# Check placement
check_placement -verbose

################################################################################
# Global Route
################################################################################

# First global route
set_routing_layers -signal Metal1-Metal2 -clock Metal1-Metal2
global_route -verbose -allow_congestion -critical_nets_percentage 0

# Repairs
repair_design
repair_timing

# Place newly inserted cells
placeDetail
check_placement -verbose

# Second global route
global_route -verbose -allow_congestion -critical_nets_percentage 0

################################################################################
# PCB Tile routing obstructions
################################################################################

set track_reduction 3
for {set i 0} {$i < $track_reduction} {incr i} {
    for {set x 1} {$x < $NUM_X_PCB_TILES} {incr x} {
        # Create Horizontal Routing Obstructions
        for {set y [expr {$i * 0.26}]} {$y < $PCB_HEIGHT} \
            {set y [expr {$y + ($track_reduction + 1) * 0.26}]} {
            set x0 [ord::microns_to_dbu [expr {$x * $PCB_TILE_SIZE - \
                $PCB_TILE_ROUTING_MARGIN / 2.0}]]
            set x1 [ord::microns_to_dbu [expr {$x * $PCB_TILE_SIZE + \
                $PCB_TILE_ROUTING_MARGIN / 2.0}]]
            set y0 [ord::microns_to_dbu [expr {$y - 0.13 / 2}]]
            set y1 [ord::microns_to_dbu [expr {$y + 0.13 / 2}]]

            set obstruction [odb::dbObstruction_create [ord::get_db_block] \
                $layer1 $x0 $y0 $x1 $y1]
        }
    }

    for {set y 1} {$y < $NUM_Y_PCB_TILES} {incr y} {
        # Create Vertical Routing Obstructions
        for {set x [expr {$i * 0.325}]} {$x < $PCB_WIDTH} \
            {set x [expr {$x + ($track_reduction + 1) * 0.325}]} {
            set x0 [ord::microns_to_dbu [expr {$x - 0.13 / 2}]]
            set x1 [ord::microns_to_dbu [expr {$x + 0.13 / 2}]]
            set y0 [ord::microns_to_dbu [expr {$y * $PCB_TILE_SIZE - \
                $PCB_TILE_ROUTING_MARGIN / 2.0}]]
            set y1 [ord::microns_to_dbu [expr {$y * $PCB_TILE_SIZE + \
                $PCB_TILE_ROUTING_MARGIN / 2.0}]]

            set obstruction [odb::dbObstruction_create [ord::get_db_block] \
                $layer2 $x0 $y0 $x1 $y1]
        }
    }
}


# Check pin acces
pin_access

# Connect inserted cells to power and ground
global_connect

# Save the design
write_def out/$design_name.pre_route.def
gui::pause

################################################################################
# Detail Route
################################################################################

set_propagated_clock [all_clocks]

detailed_route -output_drc route_drc.rpt \
    -bottom_routing_layer Metal1 \
    -top_routing_layer Metal2 \
    -droute_end_iter $drt_end_iter \
    -verbose 1

################################################################################
# Finish
################################################################################

write_verilog -include_pwr_gnd out/$design_name.final.v
write_def out/$design_name.final.def

report_checks -path_delay min -corner Fast
report_checks -path_delay max -corner Typical

if {$open_results} {
    gui::show
}
if {![gui::enabled]} {
    exit
}
