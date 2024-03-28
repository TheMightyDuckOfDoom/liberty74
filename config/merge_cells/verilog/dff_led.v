// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module dff_led (
  `ifdef PWR_PINS
  input  VDD,
  input  GND,
  `endif
  input  clk_i,
  input  d_i,
  output q_o
);
  DFF_74LVC1G175 dff (
  `ifdef PWR_PINS
    .VDD    ( VDD ),
    .TIE_HI ( VDD ),
    .GND    ( GND ),
  `endif
    .CLK ( clk_i ),
    .D   ( d_i   ),
    .Q   ( q_o   )
  );

  Led_Res_0603 led (
  `ifdef PWR_PINS
    .GND ( GND ),
  `endif
    .I   ( q_o )
  );
endmodule
