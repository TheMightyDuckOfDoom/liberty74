all: pdk synth

python_setup:
	pip install -r requirements.txt --break-system-packages

pdk-setup:
	mkdir -p pdk
	mkdir -p pdk/lef
	mkdir -p pdk/lib
	mkdir -p pdk/verilog
	mkdir -p pdk/openroad
	mkdir -p pdk/kicad
	mkdir -p pdk/kicad/footprints

pdk: pdk-setup config/* templates/*
	python3 utils/generate.py

synth: pdk
	yosys yosys/synth.tcl
	rm -rf slpp_all

openroad-setup:
	mkdir -p openroad/out

chip: openroad-setup pdk
	cd openroad && openroad -threads max chip.tcl -log openroad.log

chip_gui: openroad-setup pdk
	cd openroad && openroad -threads max chip.tcl -gui -log openroad.log

pcb: pdk
	python3 utils/def2pcb.py openroad/out/servisia.final.def

clean:
	rm -rf slpp_all && true
	rm -rf pdk      && true
	rm -rf utils/lef_def_parser/__pycache__ && true