// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module clkdiv (
  input  wire clk_i,
  output wire clk_o
);
  wire inv_clk_o;

  DFF_74LVC1G175 div_dff (
    .CLK ( clk_i     ),
    .D   ( inv_clk_o ),
    .Q   ( clk_o     )
  );

  INV_74LVC1G04 inv_clk (
    .A ( clk_o     ),
    .Y ( inv_clk_o )
  );

endmodule
