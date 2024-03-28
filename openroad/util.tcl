# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

proc load_merge_cells {} {
  global CONFIG

  set db [ord::get_db]
  set lib [odb::dbDatabase_findLib $db "liberty74_site"]
  set site [odb::dbLib_findSite $lib "CoreSite"]

  set merge_cell_files [glob -nocomplain ../${CONFIG}/merge_cells/*]
  foreach cell_file_name $merge_cell_files {
    set cell [file rootname [file tail $cell_file_name]]
    puts "Reading Merge Cell $cell"
    read_liberty -corner Typical out/merge_cell_typ_$cell.lib
    read_liberty -corner Fast    out/merge_cell_fast_$cell.lib
    read_liberty -corner Slow    out/merge_cell_slow_$cell.lib
    read_lef out/merge_cell_$cell.lef

    set master [odb::dbDatabase_findMaster $db $cell]
    odb::dbMaster_setSite $master $site
    odb::dbMaster_setType $master "CORE"
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
  odb::dbInst_setLocation $inst [expr int($x * 1000)] [expr int($y * 1000)]
}

proc place_multirow_macros {} {

  set block [ord::get_db_block]
  set rows [odb::dbBlock_getRows $block]
  set first_row [lindex $rows 0]
  set site [odb::dbRow_getSite $first_row]
  set row_height [odb::dbSite_getHeight $site]
  set row_width  [odb::dbSite_getWidth  $site]
  set halo_width [expr $row_width * 2]

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
    
    set width  [odb::dbMaster_getWidth  $master]
    set height [odb::dbMaster_getHeight $master]

    # Find instance that is heigher than a row
    if {$height <= $row_height} {
      continue
    }

    # Move it to nearest two rows -> Bottom is always GND
    set location [odb::dbInst_getLocation $inst]
    set x [lindex $location 0]
    set y [lindex $location 1]
    set new_row [expr ceil(($y - $y_origin) / $row_height / 2)]
    set new_y [expr $new_row * $row_height * 2 + $y_origin]
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

      puts "Overlap check against $master_name_found $name_found at ($x_found $y_found) with width $width_found and height $height_found"

      if {($new_y >= $y_found && $new_y <= $y_found + $height_found) || ($new_y + $height >= $y_found && $new_y + $height <= $y_found + $height_found)} {
        puts "Y Overlap"

        if {$x >= $x_found && $x <= $x_found + $width_found} {
          puts "Overlap Origin $x in \[$x_found, [expr $x_found + $width_found]\]: $master_name $name with $master_name_found $name_found"
          set x [expr $x_found + $width_found + $halo_width]
        }

        if {$x + $width >= $x_found && $x + $width <= $x_found + $width_found} {
          puts "Overlap [expr $x + $width] in \[$x_found, [expr $x_found + $width_found]\]: $master_name $name with $master_name_found $name_found"
          set x [expr $x_found - $width - $halo_width]
        }
      }
    }

    puts "Moved $master_name $name to ($x $new_y)"

    odb::dbInst_setLocation $inst [expr int($x)] [expr int($new_y)]
    odb::dbInst_setPlacementStatus $inst "LOCKED"
    odb::dbMaster_setType $master "BLOCK"

    # Add inst to list
    lappend insts_found $inst
  }
}
