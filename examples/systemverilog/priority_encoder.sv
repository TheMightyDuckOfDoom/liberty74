// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module priority_encoder #(
  parameter int unsigned Width = 16,

  parameter int unsigned IDWidth = $clog2(Width)
) (
  input logic clk_i,
  input logic rst_ni,
  input logic sub_i,
  input logic [Width-1:0] input_i,

  output logic [IDWidth-1:0] output_o,
  output logic [Width / 2 -1:0] o2
);

  always_ff @(posedge clk_i
   or negedge rst_ni) begin
    if (!rst_ni)
      o2 <= '0;
    else
      o2 <= o2 + sub_i ? (input_i[Width /2 -1:0] - input_i[Width-1:Width/2]) : (input_i[Width /2 -1:0] + input_i[Width-1:Width/2]);
  end

  always_comb begin
    output_o = '0; 
    for (int i = Width-1; i >= 0; i--)
      if (input_i[i])
        output_o = i[IDWidth-1:0];
  end

endmodule