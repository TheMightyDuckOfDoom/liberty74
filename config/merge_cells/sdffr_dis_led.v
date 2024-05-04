// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module sdffr_dis_led (
  input  dis_i,
  input  clk_i,
  input  rst_ni,
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

  DFFR_74LVC1G175 dffr (
    .CLK   ( clk_i         ),
    .D     ( scan_mux_data ),
    .RST_N ( rst_ni        ),
    .Q     ( q_o           )
  );

  Led_Res_0603 led (
    .I   ( q_o )
  );
endmodule
