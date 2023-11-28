# Generates Library

import json
from mako.template import Template
from kiutils.items.common import Position as KiPosition
from kiutils.footprint import Footprint as KiFootprint
from kiutils.footprint import DrillDefinition
from kiutils.footprint import Pad as KiPad
from kiutils.items.fpitems import FpRect

config_file_name = "./config/pdk.json"
tech_file_name = "./config/technology.json"
liberty_prefix = "liberty74_"
lef_name = "liberty74"
pdk_path = "./pdk/"
openroad_path = pdk_path + "openroad/"
kicad_path = pdk_path + "kicad/"
footprint_path = kicad_path + "footprints/"
lib_path = pdk_path + "lib/"
lef_path = pdk_path + "lef/"
verilog_path = pdk_path + "verilog/"

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
if 'row_height_multiplier' in technology:
    technology['row_height'] = technology['row_height_multiplier'] * technology['y_wire_pitch']

tech_file.close()

# Generate Footprints
for fp in footprints:
    print(f"Generating footprint {fp}")

    rotate = False
    if "rotate" in footprints[fp]:
        rotate = footprints[fp]["rotate"]

    footprints[fp]["cell_height"] = technology["row_height"]
    if rotate:
        footprints[fp]["cell_width"]  = footprints[fp]["pad_height"] * 2 + footprints[fp]["y_center_spacing"] * (footprints[fp]["num_pins"] / 2 - 1)
    else:
        footprints[fp]["cell_width"]  = footprints[fp]["pad_width"] * 2 + footprints[fp]["x_center_spacing"]

    r = technology["row_height"]
    s = footprints[fp]["y_center_spacing"]
    N = footprints[fp]["num_pins"]
    h = footprints[fp]["pad_height"]
    
    H = (N / 2 - 1) * s + h
    m = (r - H) / 2
    y_offset = m + (N / 2 - 1) * s

    x_start = footprints[fp]["pad_width"] / 2
    if rotate:
        x_start = (footprints[fp]['cell_height'] - footprints[fp]['pad_width'] - footprints[fp]['x_center_spacing']) / 2

    # Loop over pins
    pin_templates = [""]
    power_pin_templates = [""]
    x = x_start
    if rotate:
        y = footprints[fp]["pad_height"] / 2
    else:
        y = y_offset

    pin_dimensions = []
    power_pin_dimensions = []

    for i in range(1, footprints[fp]["num_pins"] + 1):
        temp = ""
        pin_dim = []
        for layer in range(1, technology["metal_layers"] + 1 if not footprints[fp]['single_layer_footprint'] else 2):
            # Pins on each layer
            temp +=  f"      LAYER Metal{layer} ;\n"
            if rotate:
                temp += f"        RECT {y} {x} {y + footprints[fp]['pad_height']} {x + footprints[fp]['pad_width']} ;"
                pin_dim.append([y, x])
            else:
                temp += f"        RECT {x} {y} {x + footprints[fp]['pad_width']} {y + footprints[fp]['pad_height']} ;"
                pin_dim.append([x, y])
            # Power pins only on Metal1
            if layer == 1:
                power_temp  = f"      LAYER Metal{layer} ;\n"
                power_temp += f"        RECT "
                dim_temp = []
                if i <= footprints[fp]["num_pins"] / 2:
                    if rotate:
                        power_temp += f"{y} 0"
                        dim_temp = [y, 0]
                    else:
                        power_temp += f"{x} 0"
                        dim_temp = [x, 0]
                else:
                    if rotate:
                        power_temp += f"{y} {x}"
                        dim_temp = [y, x]
                    else:
                        power_temp += f"{x} {y}"
                        dim_temp = [x, y]
                    
                if i > footprints[fp]["num_pins"] / 2:
                    if rotate:
                        power_temp += f" {y + footprints[fp]['pad_height']} {technology['row_height']} ;"
                        dim_temp.append(y + footprints[fp]['pad_height'])
                    else:
                        power_temp += f" {x + footprints[fp]['pad_width']} {technology['row_height']} ;" 
                        dim_temp.append(x + footprints[fp]['pad_width'])
                    dim_temp.append(technology['row_height'])
                else:
                    if rotate:
                        power_temp += f" {y + footprints[fp]['pad_height']} {x + footprints[fp]['pad_width']} ;"
                        dim_temp.append(y + footprints[fp]['pad_height'])
                        dim_temp.append(x + footprints[fp]['pad_width'])
                    else:
                        power_temp += f" {x + footprints[fp]['pad_width']} {y + footprints[fp]['pad_height']} ;"
                        dim_temp.append(x + footprints[fp]['pad_width'])
                        dim_temp.append(y + footprints[fp]['pad_height'])

                power_pin_dimensions.append(dim_temp)
                power_pin_templates.append(power_temp) 
            if layer < technology["metal_layers"]:
                temp += "\n"
        pin_dimensions.append(pin_dim)
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

    footprints[fp]["pin_dimensions"] = pin_dimensions
    footprints[fp]["power_pin_dimensions"] = power_pin_dimensions
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
    "cells": cells,
    "pwr_pins": False
}

print("Generating Verilog...")

rendered_verilog = verilog_template.render(**verilog_context)

with open(verilog_path + "verilog.sv", 'w', encoding='utf-8') as verilog_file:
    verilog_file.write(rendered_verilog)

verilog_context = {
    "cells": cells,
    "pwr_pins": True
}

print("Generating Verilog with power pins...")

rendered_verilog = verilog_template.render(**verilog_context)

with open(verilog_path + "verilog_pwr_pins.sv", 'w', encoding='utf-8') as verilog_file:
    verilog_file.write(rendered_verilog)
    
# Load tcl template
make_tracks_template = Template(filename="./templates/make_tracks.tcl.template")

tech_context = {
    "technology": technology
}

print("Generating make_tracks.tcl...")

rendered_make_tracks = make_tracks_template.render(**tech_context)

with open(openroad_path + "make_tracks.tcl", 'w', encoding='utf-8') as tcl_file:
    tcl_file.write(rendered_make_tracks)

print("Generating Kicad Footprints")

pcb_copper_layers = []
for i in range(0, tech_json['pcb_stackup']['copper_layers']):
    layer_name = ''
    ordinal = i
    if i == 0:
        layer_name = 'F'
    elif i == tech_json['pcb_stackup']['copper_layers'] - 1:
        layer_name = 'B'
        ordinal = 31
    else:
        layer_name = 'In' + str(i)
    
    layer_name += '.Cu'

    pcb_copper_layers.append(layer_name)

pcb_pad_layers = pcb_copper_layers
pcb_pad_layers.append('F.Paste')
pcb_pad_layers.append('F.Mask')

drill = DrillDefinition(
    oval = False,
    diameter = technology['via_diameter'],
    width = 0,
    offset = KiPosition(0, 0)
)
via_size = KiPosition(2 * technology['via_annular_ring'] + technology['via_diameter'], 2 * technology['via_annular_ring'] + technology['via_diameter'])

for cell in cells:
    fp = footprints[cell['footprint']]

    kifp = KiFootprint().create_new(library_id = "liberty74:" + cell['name'] + '_N', value = cell['name'], type = 'smd')
    kifp.generator = 'liberty74'
    kifp.description = cell['desc']
    kifp.tags = cell['name']

    # Outline
    kifp.graphicItems.append(
        FpRect(
            start = KiPosition(X = 0, Y = 0),
            end = KiPosition(fp['cell_width'], -fp['cell_height']),
            layer = 'F.CrtYd',
            width = 0.05
        )
    )
    kifp.graphicItems.append(
        FpRect(
            start = KiPosition(X = 0, Y = 0),
            end = KiPosition(fp['cell_width'], -fp['cell_height']),
            layer = 'F.SilkS',
            width = 0.05
        )
    )
    kifp.graphicItems.append(
        FpRect(
            start = KiPosition(X = 0, Y = 0),
            end = KiPosition(fp['cell_width'], -fp['cell_height']),
            layer = 'B.SilkS',
            width = 0.05
        )
    )

    pad_width = fp['pad_height'] if fp['rotate'] else fp['pad_width']
    pad_height = fp['pad_width'] if fp['rotate'] else fp['pad_height']

    # Power Pins -> Tie Pins not handled correctly :(
    for power_pin in cell['power']:
        pad_dim = fp['pin_dimensions'][power_pin['pin_number'] - 1][0]
        pin_function = power_pin['connect_to_net'] if 'connect_to_net' in power_pin else power_pin['name'] 
        
        kifp.pads.append(
            KiPad(
                number = power_pin['pin_number'],
                type = 'smd',
                shape = 'rect',
                position = KiPosition(pad_dim[0] + pad_width / 2, -(pad_dim[1] + pad_height / 2)),
                size = KiPosition(pad_width, pad_height),
                layers = ['F.Cu', 'F.Paste', 'F.Mask'],
                pinFunction = pin_function
            )
        )

        power_pad_dim = fp['power_pin_dimensions'][power_pin['pin_number'] - 1]

        start_pos = KiPosition(min(power_pad_dim[0], power_pad_dim[2]), min(-power_pad_dim[1], -power_pad_dim[3]))
        end_pos   = KiPosition(max(power_pad_dim[0], power_pad_dim[2]), max(-power_pad_dim[1], -power_pad_dim[3]))

        power_pad_width  = end_pos.X - start_pos.X
        power_pad_height = end_pos.Y - start_pos.Y

        kifp.pads.append(
            KiPad(
                number = power_pin['pin_number'],
                type = 'smd',
                shape = 'rect',
                position = KiPosition(start_pos.X + power_pad_width / 2, start_pos.Y + power_pad_height / 2),
                size = KiPosition(power_pad_width, power_pad_height),
                layers = ['F.Cu'],
                pinFunction = pin_function
            )
        )

    # Pins

    for pin in cell['inputs']:
        pad_dim = fp['pin_dimensions'][pin['pin_number'] - 1][0]

        # Add SMD pad
        kifp.pads.append(
            KiPad(
                number = pin['pin_number'],
                type = 'smd',
                shape = 'rect',
                position = KiPosition(pad_dim[0] + pad_width / 2, -(pad_dim[1] + pad_height / 2)),
                size = KiPosition(pad_width, pad_height),
                layers = ['F.Cu', 'F.Paste', 'F.Mask'] if fp['single_layer_footprint'] else pcb_pad_layers,
                pinFunction = pin['name']
            )
        )

        if not fp['single_layer_footprint']:
            # Add Via pad
            via_position = KiPosition(pad_dim[0], -pad_dim[1])
            via_position.X += pad_width / 2
            if pin['pin_number'] % 2 == 0:
                via_position.Y -= via_size.Y / 2
            else:
                via_position.Y -= pad_height - via_size.Y / 2

            kifp.pads.append(
                KiPad(
                    number = pin['pin_number'],
                    type = 'thru_hole',
                    shape = 'circle',
                    position = via_position,
                    size = via_size,
                    drill = drill,
                    layers = pcb_copper_layers,
                    pinFunction = pin['name']
                )
            )

    for pin in cell['outputs']:
        pad_dim = fp['pin_dimensions'][pin['pin_number'] - 1][0]

        # Add SMD pad
        kifp.pads.append(
            KiPad(
                number = pin['pin_number'],
                type = 'smd',
                shape = 'rect',
                position = KiPosition(pad_dim[0] + pad_width / 2, -(pad_dim[1] + pad_height / 2)),
                size = KiPosition(pad_width, pad_height),
                layers = ['F.Cu', 'F.Paste', 'F.Mask'] if fp['single_layer_footprint'] else pcb_pad_layers,
                pinFunction = pin['name']
            )
        )

        if not fp['single_layer_footprint']:
            # Add Via pad
            via_position = KiPosition(pad_dim[0], -pad_dim[1])
            via_position.X += pad_width / 2
            if pin['pin_number'] % 2 == 0:
                via_position.Y -= via_size.Y / 2
            else:
                via_position.Y -= pad_height - via_size.Y / 2

            kifp.pads.append(
                KiPad(
                    number = pin['pin_number'],
                    type = 'thru_hole',
                    shape = 'circle',
                    position = via_position,
                    size = via_size,
                    drill = drill,
                    layers = pcb_copper_layers,
                    pinFunction = pin['name']
                )
            )

    kifp.to_file(footprint_path + cell['name'] + '_N.kicad_mod')

    # Generate rotated footprint
    for pad in kifp.pads:
        pad.position.X = fp['cell_width'] - pad.position.X
        pad.position.Y = -pad.position.Y - fp['cell_height']

    for item in kifp.graphicItems:
        if isinstance(item, FpRect):
            item.start.X = fp['cell_width'] - item.start.X
            item.end.X   = fp['cell_width'] - item.end.X
            item.start.Y = -item.start.Y - fp['cell_height']
            item.end.Y   = -item.end.Y   - fp['cell_height']

    kifp.entryName = cell['name'] + '_S'

    kifp.to_file(footprint_path + cell['name'] + '_S.kicad_mod')
    
print("Done!")
