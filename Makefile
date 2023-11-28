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

clean:
	rm -rf slpp_all && true
	rm -rf pdk      && true