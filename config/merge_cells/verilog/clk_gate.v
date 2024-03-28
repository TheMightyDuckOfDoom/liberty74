// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module clk_gate (
  `ifdef PWR_PINS
  input  VDD,
  input  GND,
  `endif
  input  clk_i,
  input  en_i,
  output clk_o
);
  wire clk_n, dl_oen;
  wire en_q;

  INV_74LVC1G04 i_inv (
  `ifdef PWR_PINS
    .VDD ( VDD ),
    .GND ( GND ),
  `endif
    .A ( clk_i ),
    .Y ( clk_n )
  );

  TIE_LO i_tie (
    .Y ( dl_oen )
  );

  DLZ_74LVC1G373 i_dl (
  `ifdef PWR_PINS
    .VDD ( VDD ),
    .GND ( GND ),
  `endif
    .LE   ( clk_n  ),
    .OE_N ( dl_oen ),
    .D    ( en_i   ),
    .Q    ( en_q   )
  );

  AND2_74LVC1G08 i_and (
  `ifdef PWR_PINS
    .VDD ( VDD ),
    .GND ( GND ),
  `endif
    .A ( en_q  ),
    .B ( clk_i ),
    .Y ( clk_o )
  );
endmodule
