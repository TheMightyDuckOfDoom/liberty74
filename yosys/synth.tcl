plugin -i systemverilog

read_systemverilog -defer examples/alu.sv

read_systemverilog -link

hierarchy -top alu
proc

#techmap -map add_reduce.v
stat -width
#show -format svg -prefix premap

# Map adders
#techmap -map 

opt_expr
opt_clean
opt -nodffe -nosdff
fsm
opt -full
wreduce
peepopt
opt_clean
alumacc
stat
opt -full
memory -nomap
opt_clean
opt -full
memory_map
opt -full
techmap
opt -full
#hierarchy -check
check
stat -width

#techmap -map +/pmux2mux.v


write_verilog out/synth_premap.v

#show -format svg -prefix opt
abc -liberty pdk/lib/liberty74_typ_5p00V_25C.lib
dfflibmap -liberty pdk/lib/liberty74_typ_5p00V_25C.lib
hilomap -hicell TIE_HI Y -locell TIE_LO Y -singleton
#stat -width -liberty lib/74LVC_typ.lib
#show -format svg -prefix dff
#abc -g NAND
#techmap -map not2nand.v
#techmap -map nand2lvc00.v
clean

stat -width -liberty pdk/lib/liberty74_typ_5p00V_25C.lib
write_verilog out/alu.v
#show -format svg -prefix show