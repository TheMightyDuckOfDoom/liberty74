all: pdk synth

pdk-setup:
	mkdir -p lef
	mkdir -p lib

pdk: pdk-setup config/*
	python3 config/generate.py

synth: pdk
	yosys -s yosys/synth.tcl
	rm -rf slpp_all

openroad-setup:
	mkdir -p openroad/out

chip: openroad-setup pdk
	bash openroad/start.sh

clean:
	rm -rf slpp_all && true
	rm -rf lib      && true
	rm -rf lef      && true