source init_tech.tcl
read_verilog out/servisia.final.v
read_def out/servisia.final.def

optimize_net_routing -net q_o
