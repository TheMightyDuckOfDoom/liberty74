// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module single_port_async_sram #(
  parameter integer ADDR_WIDTH = 8,
  parameter integer DATA_WIDTH = 8
) (
  input logic cs_i,
  input logic we_i,
  input logic oe_i,
  input logic [ADDR_WIDTH-1:0] addr_i,
  inout logic [DATA_WIDTH-1:0] data_io
);
  logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1] /* verilator public */;

  always @(cs_i or oe_i) begin
    // Delay by 35
    data_io = cs_i && oe_i ? mem[addr_i] : 'X;
  end

  always_comb begin
      if(we_i && oe_i) begin
        $fatal(1, "Warning: SRAM is in read and write mode at the same time");
      end
  end

  always @(cs_i) begin
    //$display("SRAM: addr: %d, io: %h, cs: %b, we: %b", addr_i, data_io, cs_i, we_i);
  end

  always_latch begin
    if(cs_i && we_i)
      mem[addr_i] = data_io;
  end
endmodule : single_port_async_sram
