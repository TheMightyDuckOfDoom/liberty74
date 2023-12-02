module sram_read (
    input wire clk_i,
    input wire rst_ni,

    input  wire [13:0] addr_i,
    output reg  [7:0]  data_o
);
    // Instantiate SRAM
    W24129A_35 i_sram (
        .CS_N ( 1'b0   ),
        .WE_N ( 1'b1   ),
        .OE_N ( 1'b0   ),
        .A    ( addr_q ),
        .IO   ( data_d )
    );

    wire [7:0]  data_d;
    reg  [13:0] addr_q;

    always @(posedge clk_i) begin
        addr_q <= addr_i;
        data_o <= data_d;
    end
endmodule
