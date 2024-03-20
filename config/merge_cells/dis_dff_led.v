// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module dis_dff_led (
  input  dis_i,
  input  clk_i,
  input  d_i,
  output q_o
);
  wire d_selected;

  MUX2_74LVC1G157 mux (
    .I0 ( d_i        ),
    .I1 ( q_o        ),
    .S  ( dis_i      ),
    .Y  ( d_selected )
  );

  DFF_74LVC1G175 dff (
    .CLK ( clk_i      ),
    .D   ( d_selected ),
    .Q   ( q_o        )
  );

  Led_Res_0603 led (
    .I   ( q_o )
  );
endmodule
