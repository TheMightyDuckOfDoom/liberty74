# Generates Library

import json
from mako.template import Template

config_file_name = "./config/pdk.json"
tech_file_name = "./config/technology.json"
liberty_prefix = "liberty74_"
lef_name = "liberty74"
lib_path = "./pdk/lib/"
lef_path = "./pdk/lef/"
verilog_path = "./pdk/verilog/"

# Load Technology JSON
tech_file = open(tech_file_name)
tech_json = json.load(tech_file)

# Read Footprints
footprints = {}
for footprint_data in tech_json["footprints"]:
    for name in footprint_data["names"]:
        footprints[name] = footprint_data

# Technology Info
technology = tech_json["technology"]

tech_file.close()

# Generate Footprints
for fp in footprints:
    print(f"Generating footprint {fp}")

    rotate = False
    if "rotate" in footprints[fp]:
        rotate = footprints[fp]["rotate"]

    if rotate:
        footprints[fp]["cell_width"]  = footprints[fp]["pad_height"] * 2 + footprints[fp]["y_center_spacing"] * (footprints[fp]["num_pins"] / 2 - 1)
        footprints[fp]["cell_height"] = technology["row_height"]
    else:
        footprints[fp]["cell_width"]  = footprints[fp]["pad_width"] * 2 + footprints[fp]["x_center_spacing"]
        footprints[fp]["cell_height"] = technology["row_height"]

    r = technology["row_height"]
    s = footprints[fp]["y_center_spacing"]
    N = footprints[fp]["num_pins"]
    h = footprints[fp]["pad_height"]
    
    H = (N / 2 - 1) * s + h
    m = (r - H) / 2
    y_offset = m + (N / 2 - 1) * s

    x_start = footprints[fp]["pad_width"] / 2

    # Loop over pins
    pin_templates = [""]
    power_pin_templates = [""]
    x = x_start
    if rotate:
        y = footprints[fp]["pad_height"] / 2
    else:
        y = y_offset
    for i in range(1, footprints[fp]["num_pins"] + 1):
        temp = ""
        for layer in range(1, technology["metal_layers"] + 1):
            temp +=  f"      LAYER Metal{layer} ;\n"
            if rotate:
                temp += f"        RECT {y} {x} {y + footprints[fp]['pad_height']} {x + footprints[fp]['pad_width']} ;"
            else:
                temp += f"        RECT {x} {y} {x + footprints[fp]['pad_width']} {y + footprints[fp]['pad_height']} ;"
            if layer == 1:
                power_temp  = f"      LAYER Metal{layer} ;\n"
                power_temp += f"        RECT "
                if i <= footprints[fp]["num_pins"] / 2:
                    if rotate:
                        power_temp += f"{y} 0"
                    else:
                        power_temp += f"{x} 0"
                else:
                    if rotate:
                        power_temp += f"{y} {x}"
                    else:
                        power_temp += f"{x} {y}"
                    
                if i > footprints[fp]["num_pins"] / 2:
                    if rotate:
                        power_temp += f" {y + footprints[fp]['pad_height']} {technology['row_height']} ;" 
                    else:
                        power_temp += f" {x + footprints[fp]['pad_width']} {technology['row_height']} ;" 
                else:
                    if rotate:
                        power_temp += f" {y + footprints[fp]['pad_height']} {x + footprints[fp]['pad_width']} ;"
                    else:
                        power_temp += f" {x + footprints[fp]['pad_width']} {y + footprints[fp]['pad_height']} ;"

                power_pin_templates.append(power_temp) 
            if layer < technology["metal_layers"]:
                temp += "\n"

        pin_templates.append(temp)

        if i == footprints[fp]["num_pins"] / 2:
            x += footprints[fp]["x_center_spacing"]
        elif i > footprints[fp]["num_pins"] / 2:
            if rotate:
                y -= footprints[fp]["y_center_spacing"]
            else:
                y += footprints[fp]["y_center_spacing"]
        else:
            if rotate:
                y += footprints[fp]["y_center_spacing"]
            else:
                y -= footprints[fp]["y_center_spacing"]

    footprints[fp]["pin_lef_template"] = pin_templates
    footprints[fp]["power_pin_lef_template"] = power_pin_templates

print("Footprints generated")

# Load Tech LEF template
tech_lef_template = Template(filename="./templates/tech_lef.template")

tech_lef_context = {
    "technology": technology
}

print("Generating Tech LEF...")

rendered_tech_lef = tech_lef_template.render(**tech_lef_context)

with open(lef_path + lef_name + "_tech.lef", 'w', encoding='utf-8') as tech_lef_file:
    tech_lef_file.write(rendered_tech_lef)
    
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
lib_template = Template(filename="./templates/liberty.lib.template")

# Genereate Liberty Libraries
for c in corners:
    lib_name = liberty_prefix + c

    print(f"Generating {lib_name}...")

    lib_context = {
        "lib_name": lib_name,
        "corner": corners[c],
        "cells": cells,
        "footprints": footprints
    }

    rendered_lib = lib_template.render(**lib_context)

    with open(lib_path + lib_name + ".lib", 'w', encoding='utf-8') as lib_file:
        lib_file.write(rendered_lib)
    
# Load LEF template
lef_template = Template(filename="./templates/lef.template")

lef_context = {
    "footprints": footprints,
    "cells": cells,
    "site_width": technology["site_width"],
    "row_height": technology["row_height"]
}

print("Generating LEF...")

rendered_lef = lef_template.render(**lef_context)

with open(lef_path + lef_name + ".lef", 'w', encoding='utf-8') as lef_file:
    lef_file.write(rendered_lef)
    
# Load Verilog template
verilog_template = Template(filename="./templates/verilog.template")

verilog_context = {
    "cells": cells
}

print("Generating Verilog...")

rendered_verilog = verilog_template.render(**verilog_context)

with open(verilog_path + "verilog.sv", 'w', encoding='utf-8') as verilog_file:
    verilog_file.write(rendered_verilog)
    
print("Done!")
