module mult #(
  parameter int unsigned DataWidth = 16
) (
  input  logic [DataWidth-1:0] a_i,
  input  logic [DataWidth-1:0] b_i,
  output logic [DataWidth-1:0] r_o
);

  assign r_o = a_i * b_i;

endmodule : mult
