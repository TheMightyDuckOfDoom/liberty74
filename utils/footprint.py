# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

"""Module for footprint generation."""

import math
from kiutils.items.common import Position as KiPosition

class Rect:
    """Class representing a rectangle."""

    def __init__(self, x, y, width, height):
        self.x = x
        self.y = y
        self.width = width
        self.height = height

    @staticmethod
    def from_center_size(center: KiPosition, size: KiPosition):
        """Create a rectangle from a center position and a size."""
        return Rect(center.X - size.X / 2, center.Y - size.Y / 2, size.X, size.Y)

    def translate(self, x_offset, y_offset):
        """Translate the rectangle by given offsets."""
        self.x += x_offset
        self.y += y_offset

        return self

    @staticmethod
    def from_x1y1_x2y2(x, y, x2, y2):
        """Create a rectangle from two points."""
        min_x = min(x, x2)
        min_y = min(y, y2)

        max_x = max(x, x2)
        max_y = max(y, y2)

        width = max_x - min_x
        height = max_y - min_y

        return Rect(min_x, min_y, width, height)

    def get_x(self):
        """Return the x coordinate."""
        return self.x

    def get_y(self):
        """Return the y coordinate."""
        return self.y

    def get_x2(self):
        """Return the x2 coordinate."""
        return self.x + self.width

    def get_y2(self):
        """Return the y2 coordinate."""
        return self.y + self.height

    def get_width(self):
        """Return the width."""
        return self.width

    def get_height(self):
        """Return the height."""
        return self.height

    def get_center_kiposition_inv_y(self):
        """Return the center position with inverted y coordinate."""
        return KiPosition(self.x + self.width / 2, -(self.y + self.height / 2))

    def get_center_kiposition(self):
        """Return the center position."""
        return KiPosition(self.x + self.width / 2, self.y + self.height / 2)

    def get_size_kiposition(self):
        """Return the size as a KiPosition."""
        return KiPosition(self.width, self.height)

    def to_lef(self):
        """Return the LEF string representation."""
        return f'RECT {self.x:.3f} {self.y:.3f} {self.x + self.width:.3f} \
            {self.y + self.height:.3f} ;'

class Footprint:
    """Class representing a footprint."""

    # pylint: disable=too-many-instance-attributes

    # Init Footprint
    def __init__(self, footprint_json, technology_json, name):
        # Init Data
        self.name = name
        self.pad_width = footprint_json['pad_width']
        self.pad_height = footprint_json['pad_height']
        if 'through_hole' in footprint_json:
            self.through_hole = footprint_json['through_hole']
            self.hole_diameter = footprint_json['hole_diameter']
        else:
            self.through_hole = False
            self.hole_diameter = 0
        if 'single_row' in footprint_json:
            self.single_row = footprint_json['single_row']
        else:
            self.single_row = False
        self.x_center_spacing = footprint_json['x_center_spacing']
        self.y_center_spacing = footprint_json['y_center_spacing']
        self.num_pins = footprint_json['num_pins']
        row_height = technology_json['row_height']
        required_height = self.y_center_spacing + self.pad_height + 0.5
        self.cell_height_in_rows = math.ceil(required_height / row_height)
        self.cell_height = self.cell_height_in_rows * row_height
        width_offset = math.ceil(self.pad_width / 2.0 / technology_json['x_wire_pitch'] ) + 1
        self.x_offset = width_offset * technology_json['x_wire_pitch']
        self.cell_width = (2 * width_offset + math.ceil((self.num_pins / (1 if self.single_row \
            else 2) - 1) * self.x_center_spacing / technology_json['x_wire_pitch'])) * \
            technology_json['x_wire_pitch']
        if 'model' in footprint_json:
            self.model = footprint_json['model']
        else:
            self.model = ''

        # Init Pins
        self.pins = []
        self.pins_lef = []
        self.power_pins = []
        self.power_pins_lef = []
        self.obstruction_lef = ''

        self.__create_pins(technology_json)
        self.__gen_pin_lefs(technology_json)
        self.__gen_obstructions(technology_json)

    # Init Multiple Footprints
    @staticmethod
    def from_json(footprint_json, technology_json):
        """Create multiple footprints from a JSON object for each name in the names list."""
        fps = {}
        for name in footprint_json['names']:
            if 'models' in footprint_json:
                if name in footprint_json['models']:
                    footprint_json['model'] = footprint_json['models'][name]
                else:
                    footprint_json['model'] = ''
            fps[name] = Footprint(footprint_json, technology_json, name)
        return fps

    # Creates Pads
    def __create_pins(self, technology_json):
        # Verticaly center
        y_offset = (self.cell_height - self.pad_height - self.y_center_spacing) / 2

        # Align pad center with vertical tracks
        x = self.x_offset - self.pad_width / 2

        if self.single_row:
            # Single row footprint
            for _ in range(0, self.num_pins):
                self.pins.append(Rect(x, y_offset, self.pad_width, self.pad_height))
                # Add both bottom and top power pin connections
                self.power_pins.append(Rect.from_x1y1_x2y2(x + self.pad_width * 0.25, 0, \
                    x + self.pad_width * 0.75, y_offset + self.pad_height))
                self.power_pins.append(Rect.from_x1y1_x2y2(x + self.pad_width * 0.25, y_offset + \
                    self.y_center_spacing, x + self.pad_width * 0.75, self.cell_height))
                x += self.x_center_spacing
        else:
            # Multi row footprint
            # Create bottom row
            for _ in range(0, int(self.num_pins / 2)):
                self.pins.append(Rect(x, y_offset, self.pad_width, self.pad_height))
                self.power_pins.append(Rect.from_x1y1_x2y2(x + self.pad_width * 0.25, 0, \
                    x + self.pad_width * 0.75, y_offset + self.pad_height))
                self.power_pins.append(Rect.from_x1y1_x2y2(x + self.pad_width * 0.25, y_offset, \
                    x + self.pad_width * 0.75, technology_json['row_height']))
                x += self.x_center_spacing

            # Create top row
            x -= self.x_center_spacing
            for _ in range(0, int(self.num_pins / 2)):
                self.pins.append(Rect(x, y_offset + self.y_center_spacing, self.pad_width, \
                    self.pad_height))
                if self.cell_height_in_rows % 2 == 1:
                    # Odd number of rows
                    self.power_pins.append(Rect.from_x1y1_x2y2(x + self.pad_width * 0.25, \
                        y_offset + self.y_center_spacing + self.pad_height, x + self.pad_width * \
                        0.75, self.cell_height - technology_json['row_height']))
                    self.power_pins.append(Rect.from_x1y1_x2y2(x + self.pad_width * 0.25, y_offset \
                        + self.y_center_spacing, x + self.pad_width * 0.75, self.cell_height))
                else:
                    # Even number of rows -> Flip power pins
                    self.power_pins.append(Rect.from_x1y1_x2y2(x + self.pad_width * 0.25, y_offset \
                        + self.y_center_spacing, x + self.pad_width * 0.75, self.cell_height))
                    self.power_pins.append(Rect.from_x1y1_x2y2(x + self.pad_width * 0.25, y_offset \
                        + self.y_center_spacing + self.pad_height, x + self.pad_width * 0.75, \
                        self.cell_height - technology_json['row_height']))
                x -= self.x_center_spacing

    # Create Pin lef
    def __gen_pin_lefs(self, technology_json):
        for i in range(0, int(self.num_pins)):
            if self.through_hole:
                print(i)
                lef = ''
                for layer in range(1, technology_json['metal_layers'] + 1):
                    if layer > 1:
                        lef += '\n'
                    lef += f'      LAYER Metal{layer} ;\n'
                    lef += '        ' + self.pins[i].to_lef()
                print(lef)
                self.pins_lef.append(lef)
            else:
                lef = ''
                lef += '      LAYER Metal1 ;\n'
                lef += '        ' + self.pins[i].to_lef()
                self.pins_lef.append(lef)

        for i in range(0, int(self.num_pins)):
            for k in range(0, 2):
                if self.through_hole:
                    print(i)
                    lef = ''
                    for layer in range(1, technology_json['metal_layers'] + 1):
                        if layer > 1:
                            lef += '\n'
                        lef += f'      LAYER Metal{layer} ;\n'
                        lef += '        ' + self.pins[i].to_lef()
                        if layer == 1:
                            lef += '\n        ' + self.power_pins[i * 2 + k].to_lef()
                    print(lef)
                    self.power_pins_lef.append(lef)
                else:
                    lef = ''
                    lef += '      LAYER Metal1 ;\n'
                    lef += '        ' + self.pins[i].to_lef()
                    lef += '\n        ' + self.power_pins[i * 2 + k].to_lef()
                    self.power_pins_lef.append(lef)

    # Generate Obstructions
    def __gen_obstructions(self, technology_json):
        if self.through_hole:
            for via_layer in range(1, int(technology_json['metal_layers'] / 2) + 1):
                if via_layer > 1:
                    self.obstruction_lef += '\n'
                self.obstruction_lef += f'    LAYER Via{via_layer} ;'
                for i in range(0, int(self.num_pins)):
                    self.obstruction_lef += '\n      ' + self.pins[i].to_lef()

    def get_obstruction_lef(self):
        """Return the obstruction LEF string."""
        return self.obstruction_lef

    def get_pin_lef(self, pin_num):
        """Return the pin LEF string for the given pin number."""
        return self.pins_lef[pin_num - 1]

    def get_power_pin_lef(self, pin_num):
        """
        Return the power pin LEF string for the given pin number.
        Indexing starts at 1 and each pin has two power pins(North and South).
        """
        return self.power_pins_lef[pin_num - 1]

    def get_cell_height(self):
        """Return the height of the cell."""
        return self.cell_height

    def get_cell_width(self):
        """Return the width of the cell."""
        return self.cell_width

    def get_pin(self, pin_num):
        """Return the pin rectangle for the given pin number."""
        return self.pins[pin_num - 1]

    def get_power_pin(self, pin_num):
        """Get the power pin rectangle for the given pin number."""
        return self.power_pins[pin_num - 1]

    def get_model(self):
        """Return the model string."""
        return self.model

    def is_single_row(self):
        """Return True if the footprint is a single row."""
        return self.single_row

    def is_through_hole(self):
        """Return True if the footprint is through hole."""
        return self.through_hole
