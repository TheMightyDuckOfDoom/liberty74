all: pdk synth

pdk-setup:
	mkdir -p lef
	mkdir -p lib

pdk: pdk-setup config/*
	python3 config/generate.py

synth:
	yosys -s yosys/synth.tcl
