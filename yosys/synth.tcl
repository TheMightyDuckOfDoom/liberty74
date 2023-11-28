# Parameters
set LIB pdk/lib/liberty74_typ_5p00V_25C.lib
set SRC ../serv/out/servisia.v
set TOP servisia
set OUT out/$TOP.v

#set ABC_AREA 0
#set CLOCK_PERIOD 100
#set ABC_DRIVER_CELL BUF_74LVC1G125
#set ABC_LOAD_IN_FF 1000

# Import yosys commands
yosys -import

# Read Liberty
read_liberty -lib $LIB

# Read and check rtl
read_verilog -defer $SRC
hierarchy -check -top $TOP

# Generic Synthesis
synth -top $TOP

# Map Flip Flops
dfflibmap -liberty $LIB

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
abc -liberty $LIB -dff

setundef -zero
splitnets
opt_clean -purge
hilomap -singleton -hicell TIE_HI Y -locell TIE_LO Y

stat -width -liberty $LIB

write_verilog -noattr -noexpr -nohex -nodec $OUT