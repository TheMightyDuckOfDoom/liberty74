# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

proc load_merge_cells {} {
    set db [ord::get_db]
    set lib [odb::dbDatabase_findLib $db "liberty74_site"]
    set site [odb::dbLib_findSite $lib "CoreSite"]

    set merge_cell_files [glob ../config/merge_cells/*.v]
    foreach cell_file_name $merge_cell_files {
        set cell [file rootname [file tail $cell_file_name]]
        puts "Reading Merge Cell $cell"
        read_liberty -corner Typical out/merge_cell_typ_$cell.lib
        read_liberty -corner Fast out/merge_cell_fast_$cell.lib
        read_liberty -corner Slow out/merge_cell_slow_$cell.lib
        read_lef out/merge_cell_$cell.lef

        set master [odb::dbDatabase_findMaster $db $cell]
        odb::dbMaster_setSite $master $site
        odb::dbMaster_setType $master "CORE"
    }
}

proc connect_scan_chain {} {
    # Get scan flip-flops
    set insts [odb::dbBlock_getInsts [ord::get_db_block]]

    set scan_ffs [list]
    foreach inst $insts {
        set name [odb::dbInst_getName $inst]
        if {[string match "scan_chain_*" $name]} {
            lappend scan_ffs $inst
        }
    }
    puts "Found [llength $scan_ffs] scan flip-flops"

    if {[llength $scan_ffs] == 0} {
        return
    }

    # Get x and y positions
    set x_pos [list]
    set y_pos [list]
    foreach inst $scan_ffs {
        set location [odb::dbInst_getLocation $inst]
        lappend x_pos [lindex $location 0]
        lappend y_pos [lindex $location 1]
    }

    # Get Scan Chain data pins
    set d_i_bterm [odb::dbBlock_findBTerm [ord::get_db_block] "scan_d_i"]
    set d_o_bterm [odb::dbBlock_findBTerm [ord::get_db_block] "scan_d_o"]

    set d_i_net [odb::dbBTerm_getNet $d_i_bterm]

    set d_i_pin [lindex [odb::dbBTerm_getBPins $d_i_bterm] 0]
    set d_i_rect [odb::dbBPin_getBBox $d_i_pin]

    set d_i_x_pos [odb::Rect_xCenter $d_i_rect]
    set d_i_y_pos [odb::Rect_yCenter $d_i_rect]

    puts "Scan Chain d_i at ($d_i_x_pos $d_i_y_pos)"

    # Nearest Neighbor
    set scan_chain [list]
    set last_x $d_i_x_pos
    set last_y $d_i_y_pos
    set num_ffs [llength $scan_ffs]
    for {set k 0} {$k < $num_ffs} {incr k} {
        puts "Iteration $k [llength $scan_ffs]"

        # Find closest scan flip-flop
        set min_dist 0
        set closest_i -1
        for {set i 0} {$i < [llength $scan_ffs]} {incr i} {
            set x [lindex $x_pos $i]
            set y [lindex $y_pos $i]
            set dist [expr {($x - $last_x) * ($x - $last_x) + ($y - $last_y) * \
                ($y - $last_y)}]
            if {$dist < $min_dist || $min_dist == 0} {
                set min_dist $dist
                set closest_i $i
            }
        }

        puts "Closest scan flip-flop $closest_i: [odb::dbInst_getName \
            [lindex $scan_ffs $closest_i]] at ([lindex $x_pos $closest_i] \
            [lindex $y_pos $closest_i])"

        # Add to scan chain
        lappend scan_chain [lindex $scan_ffs $closest_i]

        # Update last position
        set last_x [lindex $x_pos $closest_i]
        set last_y [lindex $y_pos $closest_i]

        # Remove from list
        set x_pos [lreplace $x_pos $closest_i $closest_i]
        set y_pos [lreplace $y_pos $closest_i $closest_i]
        set scan_ffs [lreplace $scan_ffs $closest_i $closest_i]
    }

    # Print scan chain
    puts "Scan Chain:"
    foreach inst $scan_chain {
        puts [odb::dbInst_getName $inst]
    }

    # Connect scan chain input
    odb::dbITerm_connect [odb::dbInst_findITerm [lindex $scan_chain 0] \
        "scan_d_i"] $d_i_net

    # Connect scan chain output
    odb::dbBTerm_connect $d_o_bterm [odb::dbITerm_getNet \
        [odb::dbInst_findITerm [lindex $scan_chain end] "q_o"]]

    # Connect scan chain FFs
    for {set i 0} {$i < [llength $scan_chain] - 1} {incr i} {
        puts "Connecting [odb::dbInst_getName [lindex $scan_chain $i]] to \
            [odb::dbInst_getName [lindex $scan_chain [expr {$i + 1}]]]"
        set dst_iterm [odb::dbInst_findITerm [lindex $scan_chain \
            [expr {$i + 1}]] "scan_d_i"]
        set src_iterm [odb::dbInst_findITerm [lindex $scan_chain $i] "q_o"]
        set src_net [odb::dbITerm_getNet $src_iterm]
        odb::dbITerm_connect $dst_iterm $src_net
    }
}

# Remove every second row to create routing channels
proc create_routing_channels {} {
    set rows [odb::dbBlock_getRows [ord::get_db_block]]
    set index 0
    foreach row $rows {
        if {$index} {
            odb::dbRow_destroy $row
        }
        set index [expr {!$index}]
    }
}

proc placeDetail {} {
    detailed_placement
    set block [ord::get_db_block]
    foreach inst [odb::dbBlock_getInsts $block] {
        set locked [odb::dbInst_getPlacementStatus $inst]
        odb::dbInst_setPlacementStatus $inst PLACED
        set orient [odb::dbInst_getOrient $inst]
        if {$orient == "MX"} {
            odb::dbInst_setLocationOrient $inst R180
        }
        odb::dbInst_setPlacementStatus $inst $locked
    }
}

proc place_macro_approx { name x y orient } {
    set inst [odb::dbBlock_findInst [ord::get_db_block] $name]
    odb::dbInst_setLocation $inst [expr {int($x * 1000)}] \
        [expr {int($y * 1000)}]
}

proc place_multirow_macros {} {
    set block [ord::get_db_block]
    set rows [odb::dbBlock_getRows $block]
    set first_row [lindex $rows 0]
    set site [odb::dbRow_getSite $first_row]
    set row_height [odb::dbSite_getHeight $site]
    set row_width [odb::dbSite_getWidth $site]
    set halo_width [expr {$row_width * 2}]

    set origin [odb::dbRow_getOrigin $first_row]
    set y_origin [lindex $origin 1]

    set insts_found [list]

    # Loop over instances
    foreach inst [odb::dbBlock_getInsts $block] {
        # If locked, skip
        if {[odb::dbInst_getPlacementStatus $inst] == "LOCKED"} {
            continue
        }

        set master [odb::dbInst_getMaster $inst]
        set type [odb::dbMaster_getType $master]

        # If type is not CORE, continue
        if {$type ne "CORE"} {
            continue
        }

        set width [odb::dbMaster_getWidth $master]
        set height [odb::dbMaster_getHeight $master]

        # Find instance that is heigher than a row
        if {$height <= $row_height} {
            continue
        }

        # Move it to nearest two rows -> Bottom is always GND
        set location [odb::dbInst_getLocation $inst]
        set x [lindex $location 0]
        set y [lindex $location 1]
        set new_row [expr {ceil(($y - $y_origin) / $row_height / 2)}]
        set new_y [expr {$new_row * $row_height * 2 + $y_origin}]
        set name [odb::dbInst_getName $inst]
        set master_name [odb::dbMaster_getName $master]

        puts "Placing $master_name $name"

        # Check if x overlaps with another macro
        foreach inst_found $insts_found {
            set location [odb::dbInst_getLocation $inst_found]
            set x_found [lindex $location 0]
            set y_found [lindex $location 1]

            set master_found [odb::dbInst_getMaster $inst_found]
            set height_found [odb::dbMaster_getHeight $master_found]
            set width_found [odb::dbMaster_getWidth $master_found]
            set name_found [odb::dbInst_getName $inst_found]
            set master_name_found [odb::dbMaster_getName $master_found]

            puts "Overlap check against $master_name_found $name_found at \
                ($x_found $y_found) with width $width_found and height \
                $height_found"

            if {($new_y >= $y_found && $new_y <= $y_found + $height_found) || \
                    ($new_y + $height >= $y_found && $new_y + $height <= \
                    $y_found + $height_found)} {
                puts "Y Overlap"

                if {$x >= $x_found && $x <= $x_found + $width_found} {
                    puts "Overlap Origin $x in \[$x_found, \
                        [expr {$x_found + $width_found}]\]: $master_name $name \
                        with $master_name_found $name_found"
                    set x [expr {$x_found + $width_found + $halo_width}]
                }

                if {$x + $width >= $x_found && $x + $width <= $x_found + \
                        $width_found} {
                    puts "Overlap [expr {$x + $width}] in \[$x_found, \
                        [expr {$x_found + $width_found}]\]: \
                        $master_name $name with $master_name_found $name_found"
                    set x [expr {$x_found - $width - $halo_width}]
                }
            }
        }

        puts "Moved $master_name $name to ($x $new_y)"

        odb::dbInst_setLocation $inst [expr {int($x)}] [expr {int($new_y)}]
        odb::dbInst_setPlacementStatus $inst "LOCKED"
        odb::dbMaster_setType $master "BLOCK"

        # Add inst to list
        lappend insts_found $inst
    }
}
