// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module ff_led (
  input  clk_i,
  input  d_i,
  output q_o
);
  DFF_74LVC1G175 ff (
    .CLK ( clk_i ),
    .D   ( d_i   ),
    .Q   ( q_o   )
  );
endmodule
