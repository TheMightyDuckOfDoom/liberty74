// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module mux3s (
  `ifdef PWR_PINS
  input  VDD,
  input  GND,
  `endif
  input [2:0] i_i,
  input [1:0] s_i,
  output      y_o
);
  wire mux1_data;

  MUX2_74LVC1G157 mux1 (
  `ifdef PWR_PINS
    .VDD ( VDD ),
    .GND ( GND ),
  `endif
    .I0 ( i_i[0]    ),
    .I1 ( i_i[1]    ),
    .S  ( s_i[0]    ),
    .Y  ( mux1_data )
  );

  MUX2_74LVC1G157 mux2 (
  `ifdef PWR_PINS
    .VDD ( VDD ),
    .GND ( GND ),
  `endif
    .I0 ( i_i[2]    ),
    .I1 ( mux1_data ),
    .S  ( s_i[1]    ),
    .Y  ( y_o       )
  );

endmodule
