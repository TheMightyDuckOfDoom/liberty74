// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module DS9809PRSS3 #(
    parameter time DELAY = 20
) (
    `ifdef PWR_PINS
    input  logic GND,
    `endif
    input  logic IN,
    output logic RESET_N
);

    initial begin
        RESET_N = 1'b0;
        @( posedge IN )
        #DELAY
        RESET_N = 1'b1;
    end

endmodule : DS9809PRSS3

module POR_DS9809PRSS3 (
    `ifdef PWR_PINS
    input  logic VDD,
    input  logic GND,
    `endif
    output logic RESET_N
);

    // Instantiate the power-on reset circuit
    DS9809PRSS3 i_por (
        `ifdef PWR_PINS
        .GND ( GND ),
        .IN  ( VDD ),
        `else
        .IN      ( 1'b1    ),
        `endif
        .RESET_N ( RESET_N )
    );

endmodule : POR_DS9809PRSS3
