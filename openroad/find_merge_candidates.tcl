# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

set CORNER_GROUP CMOS_5V

source ../pdk/openroad/init_tech.tcl
read_verilog ../out/extract.v
link_design servisia

set block [ord::get_db_block]
set insts [odb::dbBlock_getInsts $block]

set merge_candidates [list]
set nets [odb::dbBlock_getNets $block]
foreach net $nets {
    set num_inputs 0
    set num_outputs 0

    set iterms [odb::dbNet_getITerms $net]
    foreach iterm $iterms {
        if {[odb::dbITerm_isInput $iterm]} {
            incr num_inputs
        }
        if {[odb::dbITerm_isOutput $iterm]} {
            incr num_outputs
        }
    }

    if {$num_inputs == 1 && $num_outputs == 1} {
        set iterms [odb::dbNet_getITerms $net]
        foreach iterm $iterms {
            if {[odb::dbITerm_isOutput $iterm]} {
                set driver_iterm $iterm
            }
            if {[odb::dbITerm_isInput $iterm]} {
                set sink_iterm $iterm
            }
        }

        set driver_inst [odb::dbITerm_getInst $driver_iterm]
        set sink_inst [odb::dbITerm_getInst $sink_iterm]

        set driver_mterm [odb::dbITerm_getMTerm $driver_iterm]
        set sink_mterm [odb::dbITerm_getMTerm $sink_iterm]

        set driver_pin_name [odb::dbMTerm_getName $driver_mterm]
        set sink_pin_name [odb::dbMTerm_getName $sink_mterm]

        set driver_master [odb::dbInst_getMaster $driver_inst]
        set sink_master [odb::dbInst_getMaster $sink_inst]

        set driver_master_name [odb::dbMaster_getName $driver_master]
        set sink_master_name [odb::dbMaster_getName $sink_master]

        set net_name [odb::dbNet_getName $net]
        puts "Candidate Net: $net_name"
        puts "\tDriver: $driver_master_name/$driver_pin_name Sink: $sink_master_name/$sink_pin_name"

        lappend merge_candidates "$driver_master_name/$driver_pin_name $sink_master_name/$sink_pin_name"
    }
}

# Uniquify the list and count occurances
set unique_merge_candidates [lsort -unique $merge_candidates]
set merge_candidates_dict [dict create]
foreach merge_candidate $unique_merge_candidates {
    # Count number of occurances
    set all_occurances [lsearch -all $merge_candidates $merge_candidate]
    set num_occurances [llength $all_occurances]

    dict set merge_candidates_dict $merge_candidate $num_occurances
}

# Sort by number of occurances
set sorted_merge_candidates [lsort -decreasing -stride 2 -index 1 -integer $merge_candidates_dict]

dict for {candidate num_occurances} $sorted_merge_candidates {
    set driver_sink [split $candidate " "]
    set driver [lindex $driver_sink 0]
    set sink [lindex $driver_sink 1]

    set driver_master [lindex [split $driver "/"] 0]
    set driver_pin [lindex [split $driver "/"] 1]

    set sink_master [lindex [split $sink "/"] 0]
    set sink_pin [lindex [split $sink "/"] 1]
    puts "Merge Pair, $num_occurances times: $driver_master/$driver_pin\t\t$sink_master/$sink_pin"
}

exit
