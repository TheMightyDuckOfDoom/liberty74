// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module en_dff (
  input  en_i,
  input  clk_i,
  input  d_i,
  output q_o
);
  wire clk;

  clk_gate i_clk_gate (
    .clk_i ( clk_i ),
    .en_i  ( en_i  ),
    .clk_o ( clk   )
  );

  DFF_74LVC1G175 dff (
    .CLK ( clk ),
    .D   ( d_i ),
    .Q   ( q_o )
  );
endmodule
