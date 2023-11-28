plugin -i systemverilog

read_systemverilog -defer examples/register_allocator.sv
read_systemverilog -defer examples/renaming.sv

read_systemverilog -link

hierarchy -top renaming
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
opt
wreduce
peepopt
opt_clean
alumacc
stat
share
opt
memory -nomap
opt_clean
opt -fast -full
memory_map
opt -full
techmap
opt -fast
abc -fast
opt -fast
#hierarchy -check
check
stat -width

#techmap -map +/pmux2mux.v


write_verilog out/synth_premap.v

#show -format svg -prefix opt
dfflibmap -liberty lib/74LVC_typ.lib
#stat -width -liberty lib/74LVC_typ.lib
#show -format svg -prefix dff
abc -liberty lib/74LVC_typ.lib
clean

stat -width -liberty lib/74LVC_typ.lib
write_verilog out/renaming.v
read_liberty -lib lib/74LVC_typ.lib
stat -width -liberty lib/74LVC_typ.lib
#show -format svg -prefix show