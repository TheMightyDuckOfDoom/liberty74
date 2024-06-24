# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

set CORNER_GROUP CMOS_5V

source ../pdk/openroad/init_tech.tcl
source util.tcl

load_merge_cells

read_def out/servisia.final.def

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
