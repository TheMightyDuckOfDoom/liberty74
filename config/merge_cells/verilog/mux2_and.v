// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module mux2_and (
  `ifdef PWR_PINS
  input  VDD,
  input  GND,
  `endif
  input [1:0] i_i,
  input       s_i,
  input       b_i,
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
    .S  ( s_i       ),
    .Y  ( mux1_data )
  );

  AND2_74LVC1G08 and_gate (
  `ifdef PWR_PINS
    .VDD ( VDD ),
    .GND ( GND ),
  `endif
    .A ( mux1_data ),
    .B ( b_i       ),
    .Y ( y_o       )
  );

endmodule
