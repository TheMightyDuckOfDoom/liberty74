// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module sram_rw (
    input wire clk_i,
    input wire rst_ni,

    input wire        read_i,
    input wire [13:0] addr_i,
    input wire  [7:0] wdata_i,
    
    output reg       read_valid_o,
    output reg [7:0] rdata_o
);
    wire [7:0] rdata_d, data_z;
    reg read_q;
    reg [7:0]  wdata_q;
    reg [13:0] addr_q;

    // Instantiate Tristate Buffers
    generate
        genvar i;
        for(i = 0; i < 8; i = i + 1) begin
            ZBUF_74LVC1G125 i_zbuf(
                .A(wdata_q[i]),
                .EN_N(read_q),
                .Y(data_z[i])
            );
        end
    endgenerate

    // Instantiate SRAM
    (* keep *) W24129A_35 i_sram (
        .CS_N ( clk_i   ),
        .WE_N ( read_q  ),
        .OE_N ( !read_q ),
        .A    ( addr_q  ),
        .IO   ( data_z  )
    );

    // Flip Flops
    always @(posedge clk_i) begin
        addr_q <= addr_i;
        wdata_q <= wdata_i;
        read_q <= read_i;
        read_valid_o <= read_q;
        rdata_o <= data_z;
    end
endmodule
