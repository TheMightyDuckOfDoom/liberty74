# Liberty74: An Open-Source Verilog-to-PCB Flow

[![Lint status](https://github.com/TheMightyDuckOfDoom/liberty74/actions/workflows/lint.yml/badge.svg)](https://github.com/TheMightyDuckOfDoom/liberty74/actions)
[![SHL-0.51 License](https://img.shields.io/badge/license-SHL--0.51-blue)](LICENSE)
[![Apache-2.0 License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Liberty74 is a fully open-source Verilog-to-PCB Flow.

## Disclaimer

This project is still under active development;
 some parts may not yet be fully functional, and existing interfaces,
 toolflows, and conventions may be broken without prior notice.

## Dependencies

Liberty74 makes use of the following open-source projects:

### Synthesis and Layout

- [Yosys](https://https://github.com/YosysHQ/yosys): Synthesis
- [OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD): Layout
- [KiCad](https://www.kicad.org/): PCB
- [Basilisk](https://github.com/pulp-platform/cheshire-ihp130-o/tree/basilisk-dev):
 Synthesis Strategy

### PDK Generator and other utilities

- [lef def parser library](https://github.com/trimcao/lef-parser): modified,
 see [`utils/lef_def_parser`](utils/lef_def_parser/)
- [KiUtils](https://pypi.org/project/kiutils/): KiCad File Parser Library
- [Mako](https://pypi.org/project/Mako/): Template Library
- [Bender](https://github.com/pulp-platform/bender): HW Dependency Manager

### Linters

- [tcllint](https://pypi.org/project/tclint/): TCL Linter
- [pylint](https://pypi.org/project/pylint/): Python Linter
- [yamllint](https://pypi.org/project/yamllint/): YAML Linter
- [mdl](https://github.com/markdownlint/markdownlint): Markdown Linter
- [Verible](https://github.com/chipsalliance/verible): Verilog Linter
- [JSON lint](https://github.com/zaach/jsonlint): JSON Linter
- [pulp actions](https://github.com/pulp-platform/pulp-actions): CI License Linter

## Documentation - Basic Usage

### Generate PDK

To generate the PDK files use:

```bash
make gen-pdk
```

### Synthesis

To synthesize your RTL into a netlist use:

```bash
make synth
```

### Layout

To layout your design use:

```bash
make chip
```

### Convert to PDK

To convert your layout to a KiCad-PCB use:

```bash
make pcb
```

### Linting

To lint all languages use:

```bash
make lint-all
```

You can also lint each language seperately:

```bash
make lint-yaml
make lint-tcl
make lint-python
make lint-json
make lint-verilog
make lint-markdown
```

### Clean

To clean use:

```bash
make clean
```

## License

Liberty74 is released under a permissive license.\
All hardware sources and tool scripts are licensed under Solderpad v0.51 (SHL-0.51)
 see [`LICENSE`](LICENSE)\
All software sources are licensed under Apache 2.0 (Apache-2.0) see [`Apache-2.0`](https://opensource.org/license/apache-2-0)

Exceptions:

- `utils/lef_def_parser` is licensed under MIT (MIT) see [`utils/lef_der_parser`](utils/lef_def_parser/)\
  Original Author &copy;Tri Minh Cao, see [https://github.com/trimcao/lef-parser](https://github.com/trimcao/lef-parser)

## Contributing

We are happy to accept pull requests and issues from any contributors.\
See [`CONTRIBUTING.md`](CONTRIBUTING.md)
for additional information.
