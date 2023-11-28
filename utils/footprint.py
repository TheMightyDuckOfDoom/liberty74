import math
from kiutils.items.common import Position as KiPosition

class Rect:
    def __init__(self, x, y, width, height):
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        
    def translate(self, x_offset, y_offset):
        self.x += x_offset
        self.y += y_offset

        return self

    def from_x1y1_x2y2(x, y, x2, y2):
        min_x = min(x, x2)
        min_y = min(y, y2)

        max_x = max(x, x2)
        max_y = max(y, y2)

        width = max_x - min_x
        height = max_y - min_y

        return Rect(min_x, min_y, width, height)

    def get_x(self):
        return self.x

    def get_y(self):
        return self.y

    def get_x2(self):
        return self.x + self.width

    def get_y2(self):
        return self.y + self.height

    def get_width(self):
        return self.width

    def get_height(self):
        return self.height
        
    # Makes Y coordinate negative
    def get_center_kiposition(self):
        return KiPosition(self.x + self.width / 2, -(self.y + self.height / 2))
    
    def get_size_kiposition(self):
        return KiPosition(self.width, self.height)

    def to_lef(self):
        return f'RECT {self.x:.3f} {self.y:.3f} {self.x + self.width:.3f} {self.y + self.height:.3f} ;'

class Footprint:
    # Init Footprint
    def __init__(self, footprint_json, technology_json, name):
        # Init Data
        self.name = name
        self.pad_width = footprint_json['pad_height']
        self.pad_height = footprint_json['pad_width']
        self.x_center_spacing = footprint_json['y_center_spacing']
        self.y_center_spacing = footprint_json['x_center_spacing']
        self.single_layer_footprint = footprint_json['single_layer_footprint']
        self.num_pins = footprint_json['num_pins']
        self.cell_height = technology_json['row_height']
        self.cell_width = (4 + math.ceil((self.num_pins / 2 - 1) * self.x_center_spacing / technology_json['x_wire_pitch'])) * technology_json['x_wire_pitch']

        # Init Pins
        self.pins = []
        self.pins_lef = []
        self.power_pins = []
        self.power_pins_lef = []

        num_metal_layers = 1 if self.single_layer_footprint else technology_json['metal_layers']

        self.__create_pins(technology_json)
        self.__gen_pin_lefs(num_metal_layers)

    # Init Multiple Footprints
    def from_json(footprint_json, technology_json):
        fps = {}
        for name in footprint_json['names']:
            fps[name] = Footprint(footprint_json, technology_json, name)
        return fps

    # Creates Pads
    def __create_pins(self, technology_json):
        # Verticaly center
        y_offset = (technology_json['row_height'] - self.pad_height - self.y_center_spacing) / 2
        
        # Align pad center with vertical tracks
        x = 2 * technology_json['x_wire_pitch'] - self.pad_width / 2

        # Loop over pins
        for i in range(0, int(self.num_pins / 2)):
            self.pins.append(Rect(x, y_offset, self.pad_width, self.pad_height))
            self.power_pins.append(Rect.from_x1y1_x2y2(x, 0, x + self.pad_width, y_offset + self.pad_height))
            x += self.x_center_spacing

        x -= self.x_center_spacing
        for i in range(0, int(self.num_pins / 2)):
            self.pins.append(Rect(x, y_offset + self.y_center_spacing, self.pad_width, self.pad_height))
            self.power_pins.append(Rect.from_x1y1_x2y2(x, y_offset + self.y_center_spacing, x + self.pad_width, self.cell_height))
            x -= self.x_center_spacing

    # Create Pin lef
    def __gen_pin_lefs(self, num_metal_layers):
        for pin in self.pins:
            lef = ''
            for layer in range(1, num_metal_layers + 1):
                lef += f'      LAYER Metal{layer} ;\n'
                lef += f'        ' + pin.to_lef()

            self.pins_lef.append(lef)

        for pin in self.power_pins:
            lef = ''
            for layer in range(1, num_metal_layers + 1):
                lef += f'      LAYER Metal{layer} ;\n'
                lef += f'        ' + pin.to_lef()

            self.power_pins_lef.append(lef)

    def get_pin_lef(self, pin_num):
        return self.pins_lef[pin_num - 1]

    def get_power_pin_lef(self, pin_num):
        return self.power_pins_lef[pin_num - 1]

    def get_cell_height(self):
        return self.cell_height

    def get_cell_width(self):
        return self.cell_width

    def get_pin(self, pin_num):
        return self.pins[pin_num - 1]

    def get_power_pin(self, pin_num):
        return self.power_pins[pin_num - 1]

    def is_single_layer_footprint(self):
        return self.single_layer_footprint
