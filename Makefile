# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

PROJECT 		:= servisia
SRC    		  	:= ../servisia/out/servisia.v
CORNER_GROUP  	:= CMOS_5V
SYNTH_PROCESS 	:= Typical

all: synth

.python_setup:
	pip install -r requirements.txt --break-system-packages
	touch .python_setup

pdk/.pdk: .python_setup utils/*.py config/*.json config/libraries/*.json templates/*.template
	mkdir -p pdk
	mkdir -p pdk/kicad
	mkdir -p pdk/kicad/footprints
	mkdir -p pdk/lef
	mkdir -p pdk/lib
	mkdir -p pdk/openroad
	mkdir -p pdk/verilog
	mkdir -p pdk/yosys
	touch pdk/.pdk
	python3 utils/generate.py

gen_pdk: pdk/.pdk

synth: gen_pdk
	mkdir -p out
	echo "set TOP "${PROJECT}"\nset SRC "${SRC}"\nset CORNER_GROUP "${CORNER_GROUP}"\nset PROCESS "${SYNTH_PROCESS}"\nsource yosys/synth.tcl" | yosys -C
	cd openroad && (echo "set design_name ${PROJECT}\nset CORNER_GROUP "${CORNER_GROUP}"\nsource rename.tcl" | openroad)
	rm -rf slpp_all
	rm -f temp.v

openroad-setup:
	mkdir -p openroad/out

chip: openroad-setup gen_pdk
	cd openroad && (echo "set design_name ${PROJECT}\nset CORNER_GROUP "${CORNER_GROUP}"\nsource chip.tcl" | openroad -threads max -log openroad.log)

chip_gui: openroad-setup gen_pdk
	cd openroad && (echo "set design_name ${PROJECT}\nset CORNER_GROUP "${CORNER_GROUP}"\nsource chip.tcl" | openroad -threads max -gui -log openroad.log)

pcb: gen_pdk
	python3 utils/def2pcb.py openroad/out/${PROJECT}.final.def

open_pcb:
	pcbnew out/${PROJECT}.final.kicad_pcb

clean:
	rm -rf slpp_all && true
	rm -rf pdk      && true
	rm -rf utils/lef_def_parser/__pycache__ && true
