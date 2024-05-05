// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module DS9809PRSS3 #(
    parameter time DELAY = 20
) (
    `ifdef TARGET_SIM_LAYOUT
    input  logic GND,
    `endif
    input  logic IN,
    output logic RESET_N
);

    initial begin
        RESET_N = 1'b0;
        /* verilator lint_off WAITCONST */
        wait(IN);
        /* verilator lint_on WAITCONST */
        #DELAY
        RESET_N = 1'b1;
    end

endmodule : DS9809PRSS3

module POR_DS9809PRSS3 (
    `ifdef TARGET_SIM_LAYOUT
    input  logic VDD,
    input  logic GND,
    `endif
    output logic RESET_N
);

    // Instantiate the power-on reset circuit
    DS9809PRSS3 i_por (
        `ifdef TARGET_SIM_LAYOUT
        .GND ( GND ),
        .IN  ( VDD ),
        `else
        .IN      ( 1'b1    ),
        `endif
        .RESET_N ( RESET_N )
    );

endmodule : POR_DS9809PRSS3
