# Generates Library

import json
from mako.template import Template

config_file_name = "./config/pdk.json"
config_file_name = "./config/footprint.json"
liberty_prefix = "liberty74_"
lib_path = "./lib/"

# Load JSON file
config_file = open(config_file_name)
config_json = json.load(config_file)

# Load Corners
corners = {}
for corner_data in config_json["corners"]:
    corners[corner_data["name"]] = corner_data

# Load Corners
cells = config_json["cells"]

config_file.close()

# Load liberty template
lib_template = Template(filename="./config/liberty.lib.template")

# Genereate Liberty Libraries
for c in corners:
    lib_name = liberty_prefix + c

    print(f"Generating {lib_name}...")

    lib_context = {
        "lib_name": lib_name,
        "corner": corners[c],
        "cells": cells
    }

    rendered_lib = lib_template.render(**lib_context)

    with open(lib_path + lib_name + ".lib", 'w', encoding='utf-8') as lib_file:
        lib_file.write(rendered_lib)
    
    print("Done!")

# Load Footprint JSON
footprint_file = open(footprint_file_name)
footprint_json = json.load(footprint_file)

# Read Footprints
footprints = {}
for footprint_data in footprint_json["footprints"]:
    for name in footprint_data["names"]:
        footprints[name] = footprint_data

footprint_file.close()

# Generate LEF
for cell in cells:
    
