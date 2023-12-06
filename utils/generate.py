# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Generates Library

from footprint import Footprint
from footprint import Rect

import datetime
import os
import json
import subprocess
from mako.template import Template
from kiutils.items.common import Position as KiPosition
from kiutils.footprint import Footprint as KiFootprint
from kiutils.footprint import DrillDefinition
from kiutils.footprint import Pad as KiPad
from kiutils.footprint import Model as KiModel
from kiutils.items.fpitems import FpRect
from kiutils.items.fpitems import FpLine

stamp = 'Generated by https://github.com/TheMightyDuckOfDoom/liberty74 ' + subprocess.check_output(['git', 'describe', '--always']).strip().decode()
stamp += ' ' + datetime.datetime.now().strftime('%Y/%m/%d %H:%M:%S')

config_folder = './config/'
library_path = config_folder + '/libraries/'
tech_file_name = config_folder + 'technology.json'
footprint_file_name = config_folder + 'footprints.json'

lef_name = 'liberty74'

pdk_path = './pdk/'
kicad_path = pdk_path + 'kicad/'
footprint_path = kicad_path + 'footprints/'
lef_path = pdk_path + 'lef/'
lib_path = pdk_path + 'lib/'
openroad_path = pdk_path + 'openroad/'
verilog_path = pdk_path + 'verilog/'
yosys_path = pdk_path + 'yosys/'

# Load Technology JSON
tech_file = open(tech_file_name)
tech_json = json.load(tech_file)

# Read Footprints
footprint_file = open(footprint_file_name)
footprint_json = json.load(footprint_file)

# Technology Info
technology = tech_json['technology']
if 'row_height_multiplier' in technology:
    technology['row_height'] = technology['row_height_multiplier'] * technology['y_wire_pitch']

tech_file.close()
new_fps = {}
footprints = {}
for footprint_data in footprint_json['footprints']:
    new_fps.update(Footprint.from_json(footprint_data, technology))

    for name in footprint_data['names']:
        footprints[name] = footprint_data

print("Test")
for fps in new_fps:
    print(new_fps[fps].get_model())

# Generate Footprints
for fp in footprints:
    print(f'Generating footprint {fp}')

    footprints[fp]['pin_lef_template'] = ['']
    footprints[fp]['power_pin_lef_template'] = ['']
    
    footprints[fp]['cell_height'] = new_fps[fp].get_cell_height()
    footprints[fp]['cell_width'] = new_fps[fp].get_cell_width()

    # Loop over pins
    for i in range(1, footprints[fp]['num_pins'] + 1):
        footprints[fp]['pin_lef_template'].append(new_fps[fp].get_pin_lef(i))
        footprints[fp]['power_pin_lef_template'].append(new_fps[fp].get_power_pin_lef(i))

print('Footprints generated')

# Load Tech LEF template
tech_lef_template = Template(filename='./templates/tech_lef.template')

tech_lef_context = {
    'stamp': stamp,
    'technology': technology
}

print('Generating Tech LEF...')

rendered_tech_lef = tech_lef_template.render(**tech_lef_context)

with open(lef_path + lef_name + '_tech.lef', 'w', encoding='utf-8') as tech_lef_file:
    tech_lef_file.write(rendered_tech_lef)

# Load Site LEF template
site_lef_template = Template(filename='./templates/site_lef.template')

site_lef_context = {
    'stamp': stamp,
    'site_width': technology['x_wire_pitch'],
    'row_height': technology['row_height']
}

print('Generating Site LEF...')

rendered_site_lef = site_lef_template.render(**site_lef_context)

with open(lef_path + lef_name + '_site.lef', 'w', encoding='utf-8') as site_lef_file:
    site_lef_file.write(rendered_site_lef)

# Load tcl template
make_tracks_template = Template(filename='./templates/make_tracks.tcl.template')

tech_context = {
    'stamp': stamp,
    'technology': technology
}

print('Generating make_tracks.tcl...')

rendered_make_tracks = make_tracks_template.render(**tech_context)

with open(openroad_path + 'make_tracks.tcl', 'w', encoding='utf-8') as tcl_file:
    tcl_file.write(rendered_make_tracks)

# Load Library JSONs
library_json = {}

for file_path in os.listdir(library_path):
    path = os.path.join(library_path, file_path)
    if os.path.isfile(path):
        with open(path) as lib:
            lj = json.load(lib)
            library_json[lj['library_name']] = lj
    
corner_groups = {}

for config_name in library_json:
    config_json = library_json[config_name]

    # Load Corners
    corners = {}
    for corner_data in config_json['corners']:
        cn = corner_data['name']
        corners[cn] = corner_data
        cg = corner_data['corner_group']
        if cg not in corner_groups:
            corner_groups[cg] = {}
        pn = corner_data['process_name']
        if pn not in corner_groups[cg]:
            corner_groups[cg][pn] = {}
        corner_groups[cg][pn][config_json['library_name'] + "_" + cn] = corner_data

    # Build internal connections
    cells = config_json['cells']
    for cell in cells:
        if 'internal_connections' in cell:
            cell['internal_connections_lef'] = []
            for connections in cell['internal_connections']:
                start_pin_number = connections[0]
                end_pin_number = connections[1]

                fp = new_fps[cell['footprint']]
                start_pin_rect = fp.get_pin(start_pin_number)
                end_pin_rect = fp.get_pin(end_pin_number)

                
                print("Start Pos: " + str(start_pin_rect.get_x()) + " " + str(start_pin_rect.get_y()))
                print("Start Pos2: " + str(start_pin_rect.get_x2()) + " " + str(start_pin_rect.get_y2()))
                print("Start Center: " + str(start_pin_rect.get_center_kiposition().X) + " " + str(start_pin_rect.get_center_kiposition().Y))
                print("End Center: " + str(end_pin_rect.get_center_kiposition().X) + " " + str(end_pin_rect.get_center_kiposition().Y))
                center = KiPosition((start_pin_rect.get_center_kiposition().X + end_pin_rect.get_center_kiposition().X) / 2,
                    (start_pin_rect.get_center_kiposition().Y + end_pin_rect.get_center_kiposition().Y) / 2)

                print("Center: " + str(center.X) + " " + str(center.Y))

                size = start_pin_rect.get_size_kiposition()
                if start_pin_rect.get_center_kiposition().Y == end_pin_rect.get_center_kiposition().Y:
                    # Horizontal Connection -> Make wider
                    size.X = abs(start_pin_rect.get_center_kiposition().X - end_pin_rect.get_center_kiposition().X)
                else:
                    # Vertical Connection -> Make taller
                    size.Y = abs(start_pin_rect.get_center_kiposition().Y - end_pin_rect.get_center_kiposition().Y)
                
                print("Size: " + str(size.X) + " " + str(size.Y))

                cell['internal_connections_lef'].append('      LAYER Metal1 ;\n        ' + Rect.from_center_size(center, size).to_lef())
                
    # Load liberty template
    lib_template = Template(filename='./templates/liberty.lib.template')

    bus_types = {}
    if 'bus_types' in config_json:
        for type in config_json['bus_types']:
            type['width'] = abs(type['from'] - type['to']) + 1 
            bus_types[type['name']] = type


    # Genereate Liberty Libraries
    for c in corners:
        lib_name = config_name + '_' + c

        print(f'Generating {lib_name}...')

        lib_context = {
            'stamp': stamp,
            'lib_name': lib_name,
            'corner': corners[c],
            'bus_types': bus_types,
            'cells': cells,
            'footprints': footprints
        }

        rendered_lib = lib_template.render(**lib_context)

        with open(lib_path + lib_name + '.lib', 'w', encoding='utf-8') as lib_file:
            lib_file.write(rendered_lib)
        
    # Load LEF template
    lef_template = Template(filename='./templates/lef.template')

    lef_context = {
        'stamp': stamp,
        'footprints': footprints,
        'cells': cells,
        'bus_types': bus_types,
        'site_width': technology['x_wire_pitch'],
        'row_height': technology['row_height']
    }

    print('Generating LEF...')

    rendered_lef = lef_template.render(**lef_context)

    with open(lef_path + config_json['library_name'] + '.lef', 'w', encoding='utf-8') as lef_file:
        lef_file.write(rendered_lef)
        
    # Load Verilog template
    verilog_template = Template(filename='./templates/verilog.template')

    verilog_context = {
        'stamp': stamp,
        'cells': cells,
        'bus_types': bus_types,
        'pwr_pins': False
    }

    print('Generating Verilog...')

    rendered_verilog = verilog_template.render(**verilog_context)

    with open(verilog_path + config_json['library_name'] + '.v', 'w', encoding='utf-8') as verilog_file:
        verilog_file.write(rendered_verilog)

    verilog_context['pwr_pins'] = True

    print('Generating Verilog with power pins...')

    rendered_verilog = verilog_template.render(**verilog_context)

    with open(verilog_path + config_json['library_name'] + '_pwr_pins.v', 'w', encoding='utf-8') as verilog_file:
        verilog_file.write(rendered_verilog)

    print('Generating Kicad Footprints')

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
        fp = new_fps[cell['footprint']]

        kifp = KiFootprint().create_new(library_id = 'liberty74:' + cell['name'] + '_N', value = cell['name'], type = 'smd')
        kifp.generator = 'liberty74'
        kifp.description = cell['desc']
        kifp.tags = cell['name']

        # Outline
        kifp.graphicItems.append(
            FpRect(
                start = KiPosition(X = 0, Y = 0),
                end = KiPosition(fp.get_cell_width(), -fp.get_cell_height()),
                layer = 'F.CrtYd',
                width = 0.05
            )
        )
        kifp.graphicItems.append(
            FpRect(
                start = KiPosition(X = 0, Y = 0),
                end = KiPosition(fp.get_cell_width(), -fp.get_cell_height()),
                layer = 'F.SilkS',
                width = 0.05
            )
        )
        kifp.graphicItems.append(
            FpRect(
                start = KiPosition(X = 0, Y = 0),
                end = KiPosition(fp.get_cell_width(), -fp.get_cell_height()),
                layer = 'B.SilkS',
                width = 0.05
            )
        )
        # Add diagonal to mark orientation
        kifp.graphicItems.append(
            FpLine(
                start = KiPosition(X = 0, Y = -1),
                end = KiPosition(X = 1, Y = 0),
                layer = 'F.SilkS',
                width = 0.05
            )
        )
        kifp.graphicItems.append(
            FpLine(
                start = KiPosition(X = 0, Y = -1),
                end = KiPosition(X = 1, Y = 0),
                layer = 'B.SilkS',
                width = 0.05
            )
        )

        # Power Pins -> Tie Pins not handled correctly :(
        if 'power' in cell:
            for power_pin in cell['power']:
                pin_function = power_pin['connect_to_net'] if 'connect_to_net' in power_pin else power_pin['name'] 
                
                pin_number = power_pin['pin_number']
                pin_rect = fp.get_pin(pin_number)
                power_pin_rect = fp.get_power_pin(pin_number)

                # Normal Pad for soldering
                kifp.pads.append(
                    KiPad(
                        number = pin_number,
                        type = 'smd',
                        shape = 'rect',
                        position = pin_rect.get_center_kiposition_inv_y(),
                        size = pin_rect.get_size_kiposition(),
                        layers = ['F.Cu', 'F.Paste', 'F.Mask'],
                        pinFunction = pin_function
                    )
                )

                # Connection to power rails
                kifp.pads.append(
                    KiPad(
                        number = pin_number,
                        type = 'smd',
                        shape = 'rect',
                        position = power_pin_rect.get_center_kiposition_inv_y(),
                        size = power_pin_rect.get_size_kiposition(),
                        layers = ['F.Cu'],
                        pinFunction = pin_function
                    )
                )

        # Pins
        pins = []
        if 'inputs' in cell:
            pins += cell['inputs']
        if 'inouts' in cell:
            pins += cell['inouts']
        if 'outputs' in cell:
            pins += cell['outputs']

        for pin in pins:
            if 'bus_name' in pin:
                type = bus_types[pin['bus_type']]
                for i in range(0, type['width']):
                    pin_number = pin['bus_pins'][i]
                    pin_rect = fp.get_pin(pin_number)

                    # Add SMD pad
                    kifp.pads.append(
                        KiPad(
                            number = pin_number,
                            type = 'smd',
                            shape = 'rect',
                            position = pin_rect.get_center_kiposition_inv_y(),
                            size = pin_rect.get_size_kiposition(),
                            layers = ['F.Cu', 'F.Paste', 'F.Mask'],
                            pinFunction = pin['bus_name'] + '[' + str(i + min(type['from'], type['to'])) + ']' 
                        )
                    )
            else:
                pin_number = pin['pin_number']
                pin_rect = fp.get_pin(pin_number)

                # Add SMD pad
                kifp.pads.append(
                    KiPad(
                        number = pin_number,
                        type = 'smd',
                        shape = 'rect',
                        position = pin_rect.get_center_kiposition_inv_y(),
                        size = pin_rect.get_size_kiposition(),
                        layers = ['F.Cu', 'F.Paste', 'F.Mask'],
                        pinFunction = pin['name']
                    )
                )
    
        # Internal Pins
        if 'internal_pins' in cell:
            for pin_number in cell['internal_pins']:
                pin_rect = fp.get_pin(pin_number)

                # Add SMD pad
                kifp.pads.append(
                    KiPad(
                        type = 'smd',
                        shape = 'rect',
                        position = pin_rect.get_center_kiposition_inv_y(),
                        size = pin_rect.get_size_kiposition(),
                        layers = ['F.Cu', 'F.Paste', 'F.Mask']
                    )
                )
        
        if 'internal_connections' in cell:
            for connections in cell['internal_connections']:
                start_pin_number = connections[0]
                end_pin_number = connections[1]

                start_pin_rect = fp.get_pin(start_pin_number)
                end_pin_rect = fp.get_pin(end_pin_number)
                center = KiPosition((start_pin_rect.get_center_kiposition_inv_y().X + end_pin_rect.get_center_kiposition_inv_y().X) / 2,
                    (start_pin_rect.get_center_kiposition_inv_y().Y + end_pin_rect.get_center_kiposition_inv_y().Y) / 2)

                size = start_pin_rect.get_size_kiposition()
                if start_pin_rect.get_center_kiposition_inv_y().Y == end_pin_rect.get_center_kiposition_inv_y().Y:
                    # Horizontal Connection -> Make wider
                    size.X = abs(start_pin_rect.get_center_kiposition_inv_y().X - end_pin_rect.get_center_kiposition_inv_y().X)
                else:
                    # Vertical Connection -> Make taller
                    size.Y = abs(start_pin_rect.get_center_kiposition_inv_y().Y - end_pin_rect.get_center_kiposition_inv_y().Y)
                
                # Add SMD pad
                kifp.pads.append(
                    KiPad(
                        type = 'smd',
                        shape = 'rect',
                        position = center,
                        size = pin_rect.get_size_kiposition(),
                        layers = ['F.Cu']
                    )
                )

        # Add 3D model
        if fp.get_model() != '':
            model = KiModel()
            model.path = '${KICAD7_3DMODEL_DIR}/' + fp.get_model() + '.wrl'
            model.rotate.Z = -90.0
            model.pos.X = fp.get_cell_width()  / 2
            model.pos.Y = fp.get_cell_height() / 2
            kifp.models.append(model)

        # Write to file
        kifp.to_file(footprint_path + cell['name'] + '_N.kicad_mod')

        # Generate rotated footprint
        for pad in kifp.pads:
            pad.position.X = fp.get_cell_width() - pad.position.X
            pad.position.Y = -pad.position.Y - fp.get_cell_height()

        for item in kifp.graphicItems:
            if isinstance(item, FpRect) or isinstance(item, FpLine):
                item.start.X = fp.get_cell_width() - item.start.X
                item.end.X   = fp.get_cell_width() - item.end.X
                item.start.Y = -item.start.Y - fp.get_cell_height()
                item.end.Y   = -item.end.Y   - fp.get_cell_height()

        for model in kifp.models:
            model.rotate.Z += 180.0

        kifp.entryName = cell['name'] + '_S'

        kifp.to_file(footprint_path + cell['name'] + '_S.kicad_mod')

# Generate init_tech.tcl
init_tech_template = Template(filename='./templates/init_tech.tcl.template')

init_tech_context = {
    'stamp': stamp,
    'corner_groups': corner_groups,
    'libraries': library_json,
    'lef_name': lef_name
}

print('Generating init_tech.tcl...')

rendered_init_tech = init_tech_template.render(**init_tech_context)

with open(openroad_path + 'init_tech.tcl', 'w', encoding='utf-8') as tcl_file:
    tcl_file.write(rendered_init_tech)

# Generate yosys_libs.tcl
yosys_libs_template = Template(filename='./templates/yosys_libs.tcl.template')

yosys_libs_context = {
    'stamp': stamp,
    'corner_groups': corner_groups,
    'libraries': library_json,
    'lef_name': lef_name
}

print('Generating yosys_libs.tcl...')

rendered_yosys_libs = yosys_libs_template.render(**yosys_libs_context)

with open(yosys_path + 'yosys_libs.tcl', 'w', encoding='utf-8') as tcl_file:
    tcl_file.write(rendered_yosys_libs)
    
print('Done!')
