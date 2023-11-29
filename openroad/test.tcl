# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

source init_tech.tcl
read_verilog out/servisia.final.v
read_def out/servisia.final.def

optimize_net_routing -net q_o
