import argparse
import json
from kiutils.board import Board
from kiutils.items.common import Net as KiNet
from kiutils.items.common import Position as KiPosition
from kiutils.items.brditems import LayerToken as BrdLayerToken
from kiutils.items.brditems import Segment as BrdSegment
from kiutils.items.brditems import Via as BrdVia
from kiutils.items.gritems import GrRect
import os
from lef_def_parser import DefParser

output_dir = './out/'

# Parse arguments
parser = argparse.ArgumentParser(
  prog='def2pcb',
  description='Generates a .kicad_pcb file from .def'
)
parser.add_argument('def_file', type=str)
args = parser.parse_args()

# Filenames
def_file_path = args.def_file
filename = os.path.splitext(os.path.basename(def_file_path))[0]
pcb_file_path = output_dir + filename + '.kicad_pcb'

# Parse DEF
print('Parsing ' + def_file_path + '...')
def_parser = DefParser(def_file_path)
def_parser.parse()

# Generate PCB
print('Generating ' + pcb_file_path + '...')
pcb = Board().create_new()
scale = float(def_parser.scale)

# General Information
pcb.version = 20221018
pcb.generator = 'def2pcb'

# Layers
pcb.layers = []
lef_json = json.load(open('./config/lef.json'))
technology = lef_json['technology']

num_metal_layers = technology['metal_layers']

# Metal Layers
metal_layers = []
for i in range(0, num_metal_layers):
    layer_name = 'Metal' + str(i + 1)
    metal_layers.append(layer_name)
    pcb.layers.append(
        BrdLayerToken(
            ordinal = i,
            name = layer_name,
            type = 'signal'
        )
    )

layer_num = num_metal_layers

# Edge.Cuts Layer
pcb.layers.append(
    BrdLayerToken(
        ordinal = layer_num,
        name = 'Edge.Cuts',
        type = 'user'
    )
)
layer_num += 1

# PCB outline
outline = GrRect(
    start = KiPosition(def_parser.diearea[0][0] / scale, def_parser.diearea[0][1] / scale),
    end = KiPosition(def_parser.diearea[1][0] / scale, def_parser.diearea[1][1] / scale),
    layer = 'Edge.Cuts',
    width = 0.2,
    fill = None,
    tstamp = 'edge_cuts_pcb_outline',
    locked = False,
)
pcb.traceItems.append(outline)

# Add nets
print('Adding nets...')
pcb.nets = list(map(lambda idx_net: KiNet(number = idx_net[0], name = idx_net[1].name), enumerate(def_parser.nets.nets)))

# Add routes
wire_width = technology['wire_width']
via_drill_size = technology['via_diameter']
via_size = via_drill_size + 2 * technology['via_annular_ring']

print("Generating net routing segments")
for net_idx, net in enumerate(def_parser.nets.nets):
    print(net.name)
    
    for route in net.routed:
        if route.end_via == None:
            # Segment
            prev_point = [0,0]
            for idx, point in enumerate(route.points):
                if idx == 0:
                    prev_point = point
                    continue

                segment = BrdSegment(
                    start = KiPosition(prev_point[0] / scale, prev_point[1] / scale),
                    end = KiPosition(point[0] / scale, point[1] / scale),
                    width = wire_width,
                    layer = route.layer,
                    locked = False,
                    net = net_idx,
                    tstamp = 'seg_' + route.layer + '_' + str(prev_point[0]) + '_' + str(prev_point[1]) + '_' + str(point[0]) + '_' + str(point[1])
                )
                pcb.traceItems.append(segment)

                prev_point = point
        else:
            # Via
            via = BrdVia(
                type = None,
                locked = False,
                position = KiPosition(route.end_via_loc[0] / scale, route.end_via_loc[1] / scale),
                size = via_size,
                drill = via_drill_size,
                layers = metal_layers,
                free = False,
                net = net_idx,
                tstamp = 'via_' + route.layer + '_' + str(route.end_via_loc[0]) + '_' + str(route.end_via_loc[1])
            )
            pcb.traceItems.append(via)
            continue

# Write generated PCB to file
pcb.to_file(pcb_file_path)
print('Done')