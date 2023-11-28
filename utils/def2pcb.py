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
def_parser.write_def(output_dir + filename + '_parsed.def')

# Generate PCB
print('Generating ' + pcb_file_path + '...')
pcb = Board().create_new()


# General Information
pcb.version = 20221018
pcb.generator = 'def2pcb'

# Layers
pcb.layers = []
lef_json = json.load(open('./config/lef.json'))
technology = lef_json['technology']

scale = float(def_parser.scale)
wire_width = technology['wire_width']
via_drill_size = technology['via_diameter']
via_size = via_drill_size + 2 * technology['via_annular_ring']
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

# Add special nets
print('Adding special nets...')
pcb.nets = []
for idx, net in enumerate(def_parser.specialnets):
    pcb.nets.append(KiNet(number = idx + 1, name = net.name))

def trimSegment(segment: BrdSegment):
    if segment.start.X == segment.end.X:
        if segment.start.Y > segment.end.Y:
            segment.start.Y -= segment.width / 2
            segment.end.Y   += segment.width / 2
        if segment.start.Y < segment.end.Y:
            segment.start.Y += segment.width / 2
            segment.end.Y   -= segment.width / 2
    if segment.start.Y == segment.end.Y:
        if segment.start.X > segment.end.X:
            segment.start.X -= segment.width / 2
            segment.end.X   += segment.width / 2
        if segment.start.X < segment.end.X:
            segment.start.X += segment.width / 2
            segment.end.X   -= segment.width / 2
    return segment

def find_intercept(start1: KiPosition, end1: KiPosition, start2: KiPosition, end2: KiPosition):
    # Check if orthogonal to each other
    if start1.X == end1.X and start2.X == end2.X:
        return None
    if start1.Y == end1.Y and start2.Y == end2.Y:
        return None

    # One is horizontal and the other one is vertical
    if start2.X == end2.X:
        # Make start1-end1 vrtical
        temp = start1
        start1 = start2
        start2 = temp

        temp = end1
        end1 = end2
        end2 = temp

    # start1-end1 is vertical
    # start2-end2 is horizontal

    # Make start always smaller
    if start1.Y > end1.Y:
        temp = start1.Y 
        start1.Y = end1.Y
        end1.Y = temp

    if start2.X > end2.X:
        temp = start2.X 
        start2.X = end2.X
        end2.X = temp

    # Check if Y of horizontal line is within bounds of vertical line
    if start2.Y < start1.Y or start2.Y > end1.Y:
        return None

    # Check if X of vertical line is within bounds of horizontal line
    if start1.X < start2.X or start1.X > end2.X:
        return None
    
    # They have to intercept at Y of horizontal line and X of vertical line

    return KiPosition(X = start1.X, Y = start2.Y)

# Add special nets routing
print('Generating power grid...')

for net in def_parser.specialnets:
    print(net.name)

    ring_shapes = list(filter(lambda x: x.shape_type == 'RING' and x.end_via == None, net.shapes))

    for shape in net.shapes:
        net_idx = next((x.number for x in pcb.nets if x.name == net.name), 0)
        
        if shape.end_via == None:
            start = KiPosition(shape.points[0][0] / scale, shape.points[0][1] / scale)
            end   = KiPosition(shape.points[1][0] / scale, shape.points[1][1] / scale)

            # Generate Via at end of segment
            if shape.shape_type == 'FOLLOWPIN':
                # Find intercept with rings
                for ring in ring_shapes:
                    interception = find_intercept(start, end, KiPosition(ring.points[0][0] / scale, ring.points[0][1] / scale), KiPosition(ring.points[1][0] / scale, ring.points[1][1] / scale))

                    if interception == None:
                        continue
                    
                    via = BrdVia(
                        type = None,
                        locked = False,
                        position = interception,
                        size = via_size,
                        drill = via_drill_size,
                        layers = metal_layers,
                        free = False,
                        net = net_idx,
                        tstamp = 'via_powergrid_interception_' + shape.layer
                    )
                    pcb.traceItems.append(via)
                
            # Segment
            segment = BrdSegment(
                start = start,
                end = end,
                width = float(shape.width) / scale,
                layer = shape.layer,
                locked = False,
                net = net_idx,
                tstamp = 'seg_powergrid_' + shape.layer + '_' + str(shape.points[0][0]) + '_' + str(shape.points[0][1]) + '_' + str(shape.points[1][0]) + '_' + str(shape.points[1][1])
            )
            segment = trimSegment(segment)
            pcb.traceItems.append(segment)
        else:
            # Via
            via = BrdVia(
                type = None,
                locked = False,
                position = KiPosition(shape.end_via_loc[0] / scale, shape.end_via_loc[1] / scale),
                size = via_size,
                drill = via_drill_size,
                layers = metal_layers,
                free = False,
                net = net_idx,
                tstamp = 'via_powergrid_' + shape.shape_type.lower() + '_' + shape.layer + '_' + str(shape.end_via_loc[0]) + '_' + str(shape.end_via_loc[1])
            )
            pcb.traceItems.append(via)


# Add nets
print('Adding nets...')
offset = pcb.nets[-1].number + 1
for idx, net in enumerate(def_parser.nets):
    pcb.nets.append(KiNet(number = idx + offset, name = net.name))


# Add net routing

print("Generating net routing...")


for net in def_parser.nets:
    print(net.name)
    
    for route in net.routed:
        if route.end_via == None:
            # Segment
            segment = BrdSegment(
                start = KiPosition(route.points[0][0] / scale, route.points[0][1] / scale),
                end = KiPosition(route.points[1][0] / scale, route.points[1][1] / scale),
                width = wire_width,
                layer = route.layer,
                locked = False,
                net = next((x.number for x in pcb.nets if x.name == net.name), 0),
                tstamp = 'seg_' + route.layer + '_' + str(route.points[0][0]) + '_' + str(route.points[0][1]) + '_' + str(route.points[1][0]) + '_' + str(route.points[1][1])
            )
            pcb.traceItems.append(segment)
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
                net = next((x.number for x in pcb.nets if x.name == net.name), 0),
                tstamp = 'via_' + route.layer + '_' + str(route.end_via_loc[0]) + '_' + str(route.end_via_loc[1])
            )
            pcb.traceItems.append(via)

# Write generated PCB to file
pcb.to_file(pcb_file_path)
print('Done')