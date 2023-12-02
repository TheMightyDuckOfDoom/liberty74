# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

PROJECT := sram_read

all: synth

.python_setup:
	pip install -r requirements.txt --break-system-packages
	touch .python_setup

pdk/.pdk: .python_setup utils/*.py config/*.json config/libraries/*.json templates/*.template
	mkdir -p pdk
	mkdir -p pdk/lef
	mkdir -p pdk/lib
	mkdir -p pdk/verilog
	mkdir -p pdk/openroad
	mkdir -p pdk/kicad
	mkdir -p pdk/kicad/footprints
	touch pdk/.pdk
	python3 utils/generate.py

gen_pdk: pdk/.pdk

synth: gen_pdk
	mkdir -p out
	yosys yosys/synth.tcl
	rm -rf slpp_all

openroad-setup:
	mkdir -p openroad/out

chip: openroad-setup gen_pdk
	cd openroad && openroad -threads max chip.tcl -log openroad.log

chip_gui: openroad-setup gen_pdk
	cd openroad && openroad -threads max chip.tcl -gui -log openroad.log

pcb: gen_pdk
	python3 utils/def2pcb.py openroad/out/${PROJECT}.final.def

open_pcb:
	pcbnew out/${PROJECT}.final.kicad_pcb

clean:
	rm -rf slpp_all && true
	rm -rf pdk      && true
	rm -rf utils/lef_def_parser/__pycache__ && true