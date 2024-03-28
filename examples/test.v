module test(
    input clk_i,
    input en_ni,
    input d_i,
    output q_o
);
    wire clk_n, en_q, en_clk, dl_oen;

    INV_74LVC1G04 i_inv (
        .A(clk_i),
        .Y(clk_n)
    );

    TIE_HI i_tie (
        .Y(dl_oen)
    );

    DLZ_74LVC1G373 i_dl (
        .LE(clk_n),
        .OE_N(dl_oen),
        .D(en_i),
        .Q(en_q)
    );

    AND2_74LVC1G08 i_and (
        .A(en_q),
        .B(clk_i),
        .Y(en_clk)
    );

    DFF_74LVC1G175 i_ff (
        .CLK(en_clk),
        .D(d_i),
        .Q(q_o)
    );

endmodule
