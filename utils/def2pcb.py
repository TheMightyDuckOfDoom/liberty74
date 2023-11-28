import argparse
from kiutils.board import Board
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

# Write generated PCB to file
pcb.to_file(pcb_file_path)
print('Done')