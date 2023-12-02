# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

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

  set origin [odb::dbRow_getOrigin $first_row]
  set y_origin [lindex $origin 1]

  set masters_found [list]
  
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
    
    set height [odb::dbMaster_getHeight $master]

    # Find instance that is heigher than a row
    if {$height <= $row_height} {
      continue
    }

    # Add master to list
    lappend masters_found $master

    # Move it to nearest two rows -> Bottom is always GND
    set location [odb::dbInst_getLocation $inst]
    set x [lindex $location 0]
    set y [lindex $location 1]
    set new_row [expr ceil(($y - $y_origin) / $row_height / 2)]
    set new_y [expr $new_row * $row_height * 2 + $y_origin]
    set name [odb::dbInst_getName $inst]

    puts "Moved $name to ($x $new_y)"

    odb::dbInst_setLocation $inst [expr int($x)] [expr int($new_y)]
    odb::dbInst_setPlacementStatus $inst "LOCKED"
  }

  # Set type of each found master to BLOCK
  foreach master $masters_found {
    odb::dbMaster_setType $master "BLOCK"
  }
}
