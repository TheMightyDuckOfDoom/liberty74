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