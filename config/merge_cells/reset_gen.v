// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module reset_gen (
  input  clk_i,
  input  rst_ni,
  output rst_no
);
  wire internal_rst_n, one, rst_0;

  DS9809PRSS3 por (
      .IN      ( rst_ni         ),
      .RESET_N ( internal_rst_n )
  );
  
  TIE_HI a_one (
    .Y ( one )
  );
  
  DFFR_74LVC1G175 dffr_0 (
    .CLK   ( clk_i          ),
    .RST_N ( internal_rst_n ),
    .D     ( one           ),
    .Q     ( rst_0          )
  );
  
  DFFR_74LVC1G175 dffr_1 (
    .CLK   ( clk_i          ),
    .RST_N ( internal_rst_n ),
    .D     ( rst_0          ),
    .Q     ( rst_no         )
  );
endmodule
