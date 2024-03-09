# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

set CORNER_GROUP CMOS_5V

source ../pdk/openroad/init_tech.tcl

read_lef out/en_ff.lef
read_lef out/dis_ff.lef
read_lef out/ao32.lef

#read_def -incremental out/en_ff.def
read_def out/servisia.final.def
read_def -incremental out/en_ff.def