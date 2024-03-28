// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module dffr_led (
  input  clk_i,
  input  rst_ni,
  input  d_i,
  output q_o
);
  DFFR_74LVC1G175 dffr (
    .CLK   ( clk_i  ),
    .D     ( d_i    ),
    .RST_N ( rst_ni ),
    .Q     ( q_o    )
  );

  Led_Res_0603 led (
    .I   ( q_o )
  );
endmodule
