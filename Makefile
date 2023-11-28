all: pdk synth

pdk-setup:
	mkdir -p pdk
	mkdir -p pdk/lef
	mkdir -p pdk/lib
	mkdir -p pdk/verilog

pdk: pdk-setup config/* templates/*
	python3 utils/generate.py

synth: pdk
	yosys -s yosys/synth.tcl
	rm -rf slpp_all

openroad-setup:
	mkdir -p openroad/out

chip: openroad-setup pdk
	bash openroad/start.sh

pcb: pdk
	python3 utils/def2pcb.py openroad/out/alu.final.def

clean:
	rm -rf slpp_all && true
	rm -rf pdk      && true
	rm -rf utils/lef_def_parser/__pycache__ && true