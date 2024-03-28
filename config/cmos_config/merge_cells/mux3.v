// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module mux3 (
  input [2:0] i_i,
  input [1:0] s_i,
  output      y_o
);
  wire mux1_data;

  MUX2_74LVC1G157 mux1 (
    .I0 ( i_i[0]    ),
    .I1 ( i_i[1]    ),
    .S  ( s_i[0]    ),
    .Y  ( mux1_data )
  );

  MUX2_74LVC1G157 mux2 (
    .I0 ( mux1_data ),
    .I1 ( i_i[2]    ),
    .S  ( s_i[1]    ),
    .Y  ( y_o       )
  );

endmodule
