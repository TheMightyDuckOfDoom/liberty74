# Copyright 2024 Tobias Senti
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

PROJECT 			?= servisia
SRC						?= ../servisia/out/servisia.v
PCB_WIDTH			?= 300
PCB_HEIGHT		?= 300
CORNER_GROUP 	?= CMOS_5V
SYNTH_PROCESS	?= Typical
SCAN_CHAIN   	?= 1

# Verible Flags
VERIBLE_FLAGS := --rules=-module-filename,-line-length

# Find Source Files
TCL_FILES := $(shell find ./ -name '*.tcl')
PY_FILES := $(shell find ./ ! -path "*/lef_def_parser/*" -name '*.py')
YAML_FILES := $(shell find ./ -name '*.yml')
JSON_FILES := $(shell find ./ -name '*.json')
VERILOG_FILES := $(shell find ./ -name '*.v')
SVERILOG_FILES := $(shell find ./ -name '*.sv')
MARKDOWN_FILES := $(shell find ./ -name '*.md')

# Get File Names
TCL_FILE_NAME := $(basename $(TCL_FILES))
PY_FILE_NAME := $(basename $(PY_FILES))
YAML_FILE_NAME := $(basename $(YAML_FILES))
JSON_FILE_NAME := $(basename $(JSON_FILES))
VERILOG_FILE_NAME := $(basename $(VERILOG_FILES))
SVERILOG_FILE_NAME := $(basename $(SVERILOG_FILES))
MARKDOWN_FILE_NAME := $(basename $(MARKDOWN_FILES))

.PHONY: all clean lint-all lint-yaml lint-tcl lint-python lint-json lint-verilog lint-markdown

all: gen-pdk

out/testboard.v: examples/testboard.v
	cp $^ $@

testboard: PROJECT := testboard
testboard: SRC := out/testboard.v
testboard: PCB_WIDTH := 100
testboard: PCB_HEIGHT := 100
testboard: out/testboard.v chip pcb

.setup:
	pip install -r requirements.txt --break-system-packages
	touch .setup

pdk/.pdk: .setup utils/*.py config/*.json config/libraries/*.json templates/*.template
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

gen-pdk: pdk/.pdk openroad/out

synth: gen-pdk
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

chip: gen-pdk
	cd openroad && (echo "set design_name ${PROJECT}\nset CORNER_GROUP "${CORNER_GROUP}"\nset PCB_WIDTH "${PCB_WIDTH}"\nset PCB_HEIGHT "${PCB_HEIGHT}"\nset SCAN_CHAIN "${SCAN_CHAIN}"\nsource chip.tcl" | openroad -threads max -log openroad.log)

chip_gui: gen-pdk
	echo "set design_name ${PROJECT}\nset CORNER_GROUP "${CORNER_GROUP}"\nset PCB_WIDTH "${PCB_WIDTH}"\nset PCB_HEIGHT "${PCB_HEIGHT}"\nset SCAN_CHAIN "${SCAN_CHAIN}"\nsource chip.tcl" > openroad/start.tcl
	cd openroad && openroad -threads max -gui -log openroad.log start.tcl

pcb: gen-pdk
	python3 utils/def2pcb.py openroad/out/${PROJECT}.final.def openroad/out/merge_cell_*.def

open_pcb:
	pcbnew out/${PROJECT}.final.kicad_pcb

lint-all: lint-yaml lint-tcl lint-python lint-json lint-verilog lint-markdown

lint-yaml: $(YAML_FILE_NAME)
lint-tcl: $(TCL_FILE_NAME)
lint-python: $(PY_FILE_NAME)
lint-json: $(JSON_FILE_NAME)
lint-verilog: $(VERILOG_FILE_NAME) $(SVERILOG_FILE_NAME)
lint-markdown: $(MARKDOWN_FILE_NAME)

$(YAML_FILE_NAME): $(YAML_FILES)
	yamllint --no-warnings $@.yml

$(TCL_FILE_NAME): $(TCL_FILES)
	tclint $@.tcl

$(PY_FILE_NAME): $(PY_FILES)
	./utils/pylint.sh $@.py

$(JSON_FILE_NAME): $(JSON_FILES)
	jsonlint -q $@.json

$(VERILOG_FILE_NAME): $(VERILOG_FILES)
	verible-verilog-lint $(VERIBLE_FLAGS) $@.v

$(SVERILOG_FILE_NAME): $(SVERILOG_FILES)
	verible-verilog-lint $(VERIBLE_FLAGS) $@.sv

$(MARKDOWN_FILE_NAME): $(MARKDOWN_FILES)
	mdl $@.md

clean:
	rm -rf .setup
	rm -rf out
	rm -rf slpp_all
	rm -rf pdk
	rm -rf openroad/out
	rm -rf openroad/*.log
	rm -rf openroad/*.rpt
	rm -rf openroad/start.tcl
	rm -rf utils/lef_def_parser/__pycache__
	rm -rf yosys/reports
