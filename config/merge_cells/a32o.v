// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module a32o (
  input [2:0] a_i,
  input [1:0] b_i,
  output y_o
);
  wire a_and;

  AND3_74LVC1G11 and_gate (
    .A ( a_i[0] ),
    .B ( a_i[1] ),
    .C ( a_i[2] ),
    .Y ( a_and  )
  );

  AO21_74LVC1G0832 and_or (
    .A ( b_i[0] ),
    .B ( b_i[1] ),
    .C ( a_and  ),
    .Y ( y_o    )
  );
endmodule
