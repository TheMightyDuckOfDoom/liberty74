// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Testboard for Liberty74
module testboard (
    input wire clk_i
);
    // Gate results
    wire [15:0] result;

    // DIP switches
    wire [7:0] switch;

    SWPUP_DIP16 i_switch (
        .Y ( switch[7:0] )
    );

    // Switch Pulldowns
    PULLDOWN_R0603 i_switch_pulldown_0 (
        .Y ( switch[0] )
    );
    PULLDOWN_R0603 i_switch_pulldown_1 (
        .Y ( switch[1] )
    );
    PULLDOWN_R0603 i_switch_pulldown_2 (
        .Y ( switch[2] )
    );
    PULLDOWN_R0603 i_switch_pulldown_3 (
        .Y ( switch[3] )
    );
    PULLDOWN_R0603 i_switch_pulldown_4 (
        .Y ( switch[4] )
    );
    PULLDOWN_R0603 i_switch_pulldown_5 (
        .Y ( switch[5] )
    );
    PULLDOWN_R0603 i_switch_pulldown_6 (
        .Y ( switch[6] )
    );
    PULLDOWN_R0603 i_switch_pulldown_7 (
        .Y ( switch[7] )
    );

    // Result LEDs
    Led_Res_0603 i_result_led_clk (
        .I ( clk_i )
    );

    Led_Res_0603 i_result_led_0 (
        .I ( result[0] )
    );
    Led_Res_0603 i_result_led_1 (
        .I ( result[1] )
    );
    Led_Res_0603 i_result_led_2 (
        .I ( result[2] )
    );
    Led_Res_0603 i_result_led_3 (
        .I ( result[3] )
    );
    Led_Res_0603 i_result_led_4 (
        .I ( result[4] )
    );
    Led_Res_0603 i_result_led_5 (
        .I ( result[5] )
    );
    Led_Res_0603 i_result_led_6 (
        .I ( result[6] )
    );
    Led_Res_0603 i_result_led_7 (
        .I ( result[7] )
    );
    Led_Res_0603 i_result_led_8 (
        .I ( result[8] )
    );
    Led_Res_0603 i_result_led_9 (
        .I ( result[9] )
    );
    Led_Res_0603 i_result_led_10 (
        .I ( result[10] )
    );
    Led_Res_0603 i_result_led_11 (
        .I ( result[11] )
    );
    Led_Res_0603 i_result_led_12 (
        .I ( result[12] )
    );
    Led_Res_0603 i_result_led_13 (
        .I ( result[13] )
    );
    Led_Res_0603 i_result_led_14 (
        .I ( result[14] )
    );
    Led_Res_0603 i_result_led_15 (
        .I ( result[15] )
    );

    // Gates
    ZBUF_74LVC1G125 i_zbuf (
        .A ( switch[0] ),
        .Y ( result[0] )
    );

    BUF_74LVC1G125 i_buf (
        .A ( switch[0] ),
        .Y ( result[1] )
    );

    INV_74LVC1G04 i_inv (
        .A ( switch[0] ),
        .Y ( result[2] )
    );

    MUX2_74LVC1G157 i_mux (
        .I0 ( switch[0] ),
        .I1 ( switch[1] ),
        .S  ( switch[2] ),
        .Y  ( result[3] )
    );

    AND2_74LVC1G08 i_and (
        .A ( switch[0] ),
        .B ( switch[1] ),
        .Y ( result[4] )
    );

    AND3_74LVC1G11 i_and3 (
        .A ( switch[0] ),
        .B ( switch[1] ),
        .C ( switch[2] ),
        .Y ( result[5] )
    );

    NAND2_74LVC1G00 i_nand (
        .A ( switch[0] ),
        .B ( switch[1] ),
        .Y ( result[6] )
    );

    NAND3_74LVC1G10 i_nand3 (
        .A ( switch[0] ),
        .B ( switch[1] ),
        .C ( switch[2] ),
        .Y ( result[7] )
    );

    OR2_74LVC1G32 i_or (
        .A ( switch[0] ),
        .B ( switch[1] ),
        .Y ( result[8] )
    );

    OR3_74LVC1G332 i_or3 (
        .A ( switch[0] ),
        .B ( switch[1] ),
        .C ( switch[2] ),
        .Y ( result[9] )
    );

    NOR2_74LVC1G02 i_nor (
        .A ( switch[0]  ),
        .B ( switch[1]  ),
        .Y ( result[10] )
    );

    NOR3_74LVC1G27 i_nor3 (
        .A ( switch[0]  ),
        .B ( switch[1]  ),
        .C ( switch[2]  ),
        .Y ( result[11] )
    );

    AO21_74LVC1G0832 i_ao21 (
        .A ( switch[0]  ),
        .B ( switch[1]  ),
        .C ( switch[2]  ),
        .Y ( result[12] )
    );

    OA21_74LVC1G3208 i_oa21 (
        .A ( switch[0]  ),
        .B ( switch[1]  ),
        .C ( switch[2]  ),
        .Y ( result[13] )
    );

    XOR2_74LVC1G86 i_xor (
        .A ( switch[0]  ),
        .B ( switch[1]  ),
        .Y ( result[14] )
    );

    XOR3_74LVC1G386 i_xor3 (
        .A ( switch[0]  ),
        .B ( switch[1]  ),
        .C ( switch[2]  ),
        .Y ( result[15] )
    );
endmodule
