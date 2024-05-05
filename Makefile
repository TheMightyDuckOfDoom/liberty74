# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

PROJECT 			?= servisia
SRC						?= ../servisia/out/servisia.v
PCB_WIDTH			?= 300
PCB_HEIGHT		?= 300
CORNER_GROUP 	?= CMOS_5V
SYNTH_PROCESS	?= Typical
SCAN_CHAIN   	?= 1

all: gen_pdk

out/*.v: examples/*.v
	cp $^ $@

testboard: PROJECT := testboard
testboard: SRC := out/testboard.v
testboard: PCB_WIDTH := 100
testboard: PCB_HEIGHT := 100
testboard: out/testboard.v chip pcb

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

openroad/out: config/merge_cells/*.v pdk/.pdk
	mkdir -p openroad/out
	cd openroad && ./merge_cells.sh ${CORNER_GROUP}

openroad-setup: openroad/out

gen_pdk: pdk/.pdk openroad/out

synth: gen_pdk
	mkdir -p out
	mkdir -p yosys/reports
	echo "set TOP "${PROJECT}"\nset SRC "${SRC}"\nset CORNER_GROUP "${CORNER_GROUP}"\nset PROCESS "${SYNTH_PROCESS}"\nsource yosys/synth.tcl" | yosys -C
	cd openroad && (echo "set design_name ${PROJECT}\nset CORNER_GROUP "${CORNER_GROUP}"\nset SCAN_CHAIN ${SCAN_CHAIN}\nsource post_synth.tcl" | openroad)
	rm -rf slpp_all
#rm -rf out/temp.v

dft:
	rm -rf out/dft
	mkdir -p out/dft
	cd openroad && (echo "set design_name ${PROJECT}\nset CORNER_GROUP "${CORNER_GROUP}"\nsource dft_prepare.tcl" | openroad)
	fault cut -d DFF_74LVC1G175 out/dft/${PROJECT}.dft.v -o out/dft/${PROJECT}.cut.v
	cd out/dft && cat ../../pdk/verilog/74lvc1g.v > cells.sv
	cd out/dft && cat ../../verilog_models/DS9808.sv >> cells.sv
	cd out/dft && fault -c cells.sv -v 1 -r 1 -m 95 --ceiling 1 --clock clk_i ${PROJECT}.cut.v

chip: gen_pdk
	cd openroad && (echo "set design_name ${PROJECT}\nset CORNER_GROUP "${CORNER_GROUP}"\nset PCB_WIDTH "${PCB_WIDTH}"\nset PCB_HEIGHT "${PCB_HEIGHT}"\nset SCAN_CHAIN "${SCAN_CHAIN}"\nsource chip.tcl" | openroad -threads max -log openroad.log)

chip_gui: gen_pdk
	echo "set design_name ${PROJECT}\nset CORNER_GROUP "${CORNER_GROUP}"\nset PCB_WIDTH "${PCB_WIDTH}"\nset PCB_HEIGHT "${PCB_HEIGHT}"\nset SCAN_CHAIN "${SCAN_CHAIN}"\nsource chip.tcl" > openroad/start.tcl
	cd openroad && openroad -threads max -gui -log openroad.log start.tcl

pcb: gen_pdk
	python3 utils/def2pcb.py openroad/out/${PROJECT}.final.def openroad/out/merge_cell_*.def

open_pcb:
	pcbnew out/${PROJECT}.final.kicad_pcb

clean:
	rm -rf .python_setup
	rm -rf out      && true
	rm -rf slpp_all && true
	rm -rf pdk      && true
	rm -rf openroad/out && true
	rm -rf openroad/*.log && true
	rm -rf openroad/*.rpt && true
	rm -rf openroad/start.tcl && true
	rm -rf utils/lef_def_parser/__pycache__ && true
	rm -rf yosys/reports && true
