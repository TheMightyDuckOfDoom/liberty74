# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Parameters
#source pdk/yosys/yosys_libs.tcl
source yosys/yosys_libs.tcl
set OUT out/temp.v
set OUT_NO_MERGE out/${TOP}_no_merge.v

set MAIN_LIB [lindex $LIBS [lsearch $LIBS *$MAIN_LIB_NAME*]]

set REPORT_DIR yosys/reports

proc report_all {report_name} {
  global TOP
  global LIBS
  global REPORT_DIR
  global MAIN_LIB
  tee -q -o "$REPORT_DIR/${report_name}_synth.rpt" check
  tee -q -o "$REPORT_DIR/${report_name}_area.rpt"  stat -top $TOP -liberty $MAIN_LIB
}

#set ABC_AREA 0
#set CLOCK_PERIOD 100
#set ABC_DRIVER_CELL BUF_74LVC1G125
#set ABC_LOAD_IN_FF 1000

# Import yosys commands
yosys -import

# Read Liberty
foreach lib $LIBS {
  read_liberty -lib $lib
}

# Read and check rtl
read_verilog -defer $SRC
hierarchy -check -top $TOP
#show -prefix before_techmap -format pdf $TOP

flatten

# Generic Synthesis
if {0} {
  yosys proc
  opt_expr
  opt_clean
  check
  opt -nodffe -nosdff
  fsm -fm_set_fsm_file $REPORT_DIR/fsm_map.rpt
  opt -full
  wreduce
  wreduce
  peepopt
  opt_clean
  share
  opt
  booth
  yosys memory -nomap
  opt_clean

  memory_collect
  opt -fast
  memory_map
  opt -full

  opt_dff -sat -nodffe -nosdff
  share
  rmports
  clean -purge

  tee -q -o "$REPORT_DIR/abstract.rpt" stat -tech cmos

  show -prefix pre_map -format pdf $TOP
  techmap
  opt -fast
  clean -purge

  tee -q -o "$REPORT_DIR/generic.rpt" stat -tech cmos

  clean -purge
  opt_dff -nodffe -nosdff
  techmap
  clean -purge
} else {
  synth
}

tee -q -o "$REPORT_DIR/pre_map.rpt" stat -tech cmos

# Map Flip Flops
dfflibmap -liberty $MAIN_LIB

set constr [open out/abc.constr w]
puts $constr "set_driving_cell BUF_74LVC1G125"
puts $constr "set_load 0"
close $constr

#if {$ABC_AREA} {
#    set abc_script yosys/abc.area
#    abc -D [expr ($CLOCK_PERIOD * 1000)] -script $abc_script -liberty $LIB -constr out/abc.constr
#} else {
#}
set period_ps [expr (10 * 1000)]
set abc_comb_script yosys/abc-comb-iggy16.script
#set abc_comb_script yosys/abc.comb
set constr out/abc.constr
abc -liberty $MAIN_LIB -D $period_ps -script $abc_comb_script -constr $constr -showtmp -exe "yosys/abc.sh"

setundef -zero
splitnets
opt_clean -purge
hilomap -singleton -hicell TIE_HI Y -locell TIE_LO Y

#show -prefix final -format pdf $TOP
stat -width -liberty $MAIN_LIB

# Add clock gating -> convert all enable flip flops to clk-gated flip flops
extract -map yosys/en_dff_dummy.v
techmap -map yosys/en_dff_clk_gate.v
stat -width -liberty $MAIN_LIB
read_liberty -lib config/merge_cells/lib/$CORNER_GROUP/$PROCESS/clk_gate*.lib

# Merge clock gates
opt_merge -share_all

# Remap clock-gates that drive only a few flip flops back to muxed flip flops
extract -map yosys/en_dff_clk_gate.v
techmap -map yosys/en_dff_dummy.v

# Add leds
extract -map yosys/dff_led_dummy.v
extract -map yosys/dffr_led_dummy.v
techmap -map config/merge_cells/verilog/dff_led.v
techmap -map config/merge_cells/verilog/dffr_led.v

report_all "synth"
stat -width -liberty $MAIN_LIB

write_verilog -noattr -noexpr -nohex -nodec $OUT_NO_MERGE

# Add merge cells
set merge_cells [lsort [glob config/merge_cells/verilog/*.v]]
puts $merge_cells
foreach cell $merge_cells {
  extract -map $cell
}

stat -width -liberty $MAIN_LIB

report_all "merge"

write_verilog -noattr -noexpr -nohex -nodec $OUT
