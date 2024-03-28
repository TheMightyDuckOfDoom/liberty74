// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module dis_dffr_led (
  `ifdef PWR_PINS
  input  VDD,
  input  GND,
  `endif
  input  dis_i,
  input  clk_i,
  input  rst_ni,
  input  d_i,
  output q_o
);
  wire d_selected;

  MUX2_74LVC1G157 mux (
  `ifdef PWR_PINS
    .VDD ( VDD ),
    .GND ( GND ),
  `endif
    .I0 ( d_i        ),
    .I1 ( q_o        ),
    .S  ( dis_i      ),
    .Y  ( d_selected )
  );

  DFFR_74LVC1G175 dffr (
  `ifdef PWR_PINS
    .VDD ( VDD ),
    .GND ( GND ),
  `endif
    .CLK   ( clk_i      ),
    .D     ( d_selected ),
    .RST_N ( rst_ni     ),
    .Q     ( q_o        )
  );

  Led_Res_0603 led (
  `ifdef PWR_PINS
    .GND ( GND ),
  `endif
    .I   ( q_o )
  );
endmodule
