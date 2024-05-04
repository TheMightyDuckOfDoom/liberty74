// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module sdff_dis_led (
  input  dis_i,
  input  clk_i,
  input  scan_en_i,
  input  scan_d_i,
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

  wire scan_mux_data;

  MUX2_74LVC1G157 scan_mux (
    .I0 ( d_selected    ),
    .I1 ( scan_d_i      ),
    .S  ( scan_en_i     ),
    .Y  ( scan_mux_data )
  );

  DFF_74LVC1G175 dff (
    .CLK ( clk_i         ),
    .D   ( scan_mux_data ),
    .Q   ( q_o           )
  );

  Led_Res_0603 led (
    .I   ( q_o )
  );
endmodule
