# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Parameters
set ADD_LEDS 0
set SCAN_CHAIN 1

# Load Tech
source ../pdk/openroad/init_tech.tcl

source util.tcl
load_merge_cells

# Read netlist
read_verilog ../out/temp.v
link_design $design_name

# Rename instances -> Remove '.' from names
set block [ord::get_db_block]
set insts [odb::dbBlock_getInsts $block]
foreach inst $insts {
    set name [odb::dbInst_getName $inst]
    set new_name [string map {. __} $name]
    odb::dbInst_rename $inst $new_name
}
puts "Renamed instances"

# Rename nets -> Remove '.' from names
foreach net [odb::dbBlock_getNets $block] {
    set name [odb::dbNet_getName $net]
    set new_name [string map {. __} $name]
    odb::dbNet_rename $net $new_name
}
puts "Renamed nets"

if {$ADD_LEDS} {
    # Add leds to flip flops
    set led_master [odb::dbDatabase_findMaster [ord::get_db] "Led_Res_0603"]
    foreach inst $insts {
        set master [odb::dbInst_getMaster $inst]
        set name [odb::dbMaster_getName $master]
        if {[string match *FF* $name]} {
            set pins [odb::dbInst_getITerms $inst]
            foreach pin $pins {
                if {[odb::dbITerm_isOutputSignal $pin] && \
                        [odb::dbITerm_isConnected $pin]} {
                    set inst_name [odb::dbInst_getName $inst]
                    set inst_net [odb::dbITerm_getNet $pin]
                    set net_name [odb::dbNet_getName $inst_net]
                    append inst_name "_led"
                    set led [odb::dbInst_create $block $led_master $inst_name]
                    foreach led_input [odb::dbInst_getITerms $led] {
                        if {[odb::dbITerm_isInputSignal $led_input]} {
                            odb::dbITerm_connect $led_input $inst_net
                        }
                    }
                }
            }
        }
    }
}

if {$SCAN_CHAIN} {
    # Find scan chain enable net
    set scan_enable_name "scan_en_i"
    set scan_chain_enable_net [odb::dbBlock_findNet $block $scan_enable_name]

    if {$scan_chain_enable_net == "NULL"} {
        puts "No '${scan_enable_name}' found"
    } else {
        # Add scan chain to flip flops
        foreach inst [odb::dbBlock_getInsts $block] {
            set master [odb::dbInst_getMaster $inst]
            set master_name [odb::dbMaster_getName $master]
            if {[string match *dff* $master_name]} {
                set inst_name [odb::dbInst_getName $inst]
                #puts "Adding scan chain to $inst_name"

                # Create scan chain instance
                set scan_chain_master [odb::dbDatabase_findMaster \
                    [ord::get_db] "s${master_name}"]
                set scan_chain_inst_name "scan_chain_${inst_name}"
                set scan_chain_inst [odb::dbInst_create $block \
                    $scan_chain_master $scan_chain_inst_name]

                # Connect scan chain instance
                foreach pin [odb::dbInst_getITerms $inst] {
                    set iterm_name [odb::dbITerm_getName $pin]
                    #puts "Connecting $iterm_name"
                    set net [odb::dbITerm_getNet $pin]
                    set net_name [odb::dbNet_getName $net]
                    #puts "Net: $net_name"

                    set scan_iterm_name "scan_chain_${iterm_name}"

                    foreach scan_pin [odb::dbInst_getITerms $scan_chain_inst] {
                        set scan_pin_name [odb::dbITerm_getName $scan_pin]
                        if {[string match *$iterm_name* $scan_pin_name]} {
                            odb::dbITerm_connect $scan_pin $net
                            break
                        }
                    }
                }

                # Delete original flip flop
                odb::dbInst_destroy $inst

                # Connect scan chain enable
                foreach pin [odb::dbInst_getITerms $scan_chain_inst] {
                    set iterm_name [odb::dbITerm_getName $pin]
                    if {[string match *scan_en_i $iterm_name]} {
                        set net [odb::dbITerm_getNet $pin]
                        odb::dbITerm_connect $pin $scan_chain_enable_net
                        break
                    }
                }
            }
        }
    }
}

# Write final netlist
write_verilog ../out/$design_name.v
puts "$design_name.v written"

exit
