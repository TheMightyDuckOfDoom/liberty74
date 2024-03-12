// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module mux2_and (
  input [1:0] i_i,
  input       s_i,
  input       b_i,
  output      y_o
);
  wire mux1_data;

  MUX2_74LVC1G157 mux1 (
    .I0 ( i_i[0]    ),
    .I1 ( i_i[1]    ),
    .S  ( s_i       ),
    .Y  ( mux1_data )
  );

  AND2_74LVC1G08 and_gate (
    .A ( mux1_data ),
    .B ( b_i       ),
    .Y ( y_o       )
  );

endmodule
