# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Parameters
set LIBS [list "pdk/lib/74lvc1g_typ_5p00V_25C.lib" "pdk/lib/W24129A_typ_5p00V_25C.lib"]
#set SRC ../servisia/out/servisia.v
set TOP sram_rw
set SRC examples/$TOP.v
set OUT out/$TOP.v

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

flatten

# Generic Synthesis
synth -top $TOP

# Map Flip Flops
dfflibmap -liberty [lindex $LIBS 0]

opt

#set constr [open out/abc.constr w]
#puts $constr "set_driving_cell $ABC_DRIVER_CELL)"
#puts $constr "set_load $ABC_LOAD_IN_FF"
#close $constr

#if {$ABC_AREA} {
#    set abc_script yosys/abc.area
#    abc -D [expr ($CLOCK_PERIOD * 1000)] -script $abc_script -liberty $LIB -constr out/abc.constr
#} else {
#}
abc -liberty [lindex $LIBS 0] -dff

setundef -zero
splitnets
opt_clean -purge
hilomap -singleton -hicell TIE_HI Y -locell TIE_LO Y

stat -width -liberty [lindex $LIBS 0]

write_verilog -noattr -noexpr -nohex -nodec $OUT