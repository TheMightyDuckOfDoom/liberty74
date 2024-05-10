# Liberty74: An Open-Source Verilog-to-PCB Flow

[![Lint status](https://github.com/TheMightyDuckOfDoom/liberty74/actions/workflows/lint.yml/badge.svg)](https://github.com/TheMightyDuckOfDoom/liberty74/actions)
[![SHL-0.51 License](https://img.shields.io/badge/license-SHL--0.51-green)](LICENSE)

Liberty74 is a fully open-source Verilog-to-PCB Flow.

## Disclaimer

This project is still under active development;
 some parts may not yet be fully functional, and existing interfaces,
 toolflows, and conventions may be broken without prior notice.

## Dependencies

Liberty74 makes use of the following open-source projects:

### Synthesis and Layout

- [Yosys - Synthesis](https://https://github.com/YosysHQ/yosys)
- [OpenROAD - Layout](https://github.com/The-OpenROAD-Project/OpenROAD)
- [KiCad - PCB](https://www.kicad.org/)
- [Basilisk - synthesis strategy](https://github.com/pulp-platform/cheshire-ihp130-o/tree/basilisk-dev)

### PDK Generator and other utilities

- [lef def parser library - modified](https://github.com/trimcao/lef-parser)
- [KiUtils - KiCad file parser library](https://pypi.org/project/kiutils/)
- [Mako - template library](https://pypi.org/project/Mako/)
- [Bender - hw dependency managment tool](https://github.com/pulp-platform/bender)

### Linters

- [tcllint - tcl lint tool](https://pypi.org/project/tclint/)
- [pylint - python lint tool](https://pypi.org/project/pylint/)
- [yamllint - yml lint tool](https://pypi.org/project/yamllint/)
- [mdl - Markdown lint tool](https://github.com/markdownlint/markdownlint)
- [Verible - verilog lint tool](https://github.com/chipsalliance/verible)
- [JSON lint - json lint tool](https://github.com/zaach/jsonlint)

## Documentation

TODO

## License

Liberty74 is released under a permissive license.\
All hardware sources and tool scripts are licensed under Solderpad v0.51 (SHL-0.51)
 see [`LICENSE`](LICENSE)\
All software sources are licensed under Apache 2.0 (Apache-2.0) see [`Apache-2.0`](https://opensource.org/license/apache-2-0)\
Exception: `utils/lef_def_parser` is licensed under MIT (MIT) see [`utils/lef_der_parser`]
(utils/lef_def_parser/),\
 Original Author and Repo [&copy; Tri Minh Cao](https://github.com/trimcao/lef-parser)

## Contributing

We are happy to accept pull requests and issues from any contributors. See [`CONTRIBUTING.md`](CONTRIBUTING.md)
for additional information.
