module alu #(
    parameter DatapathWidth = 32,
    parameter AluOperationWidth = 5
) (
    //From register file
    input logic [AluOperationWidth-1:0] operation_i,
    input logic [DatapathWidth-1:0] operand1_i,
    input logic [DatapathWidth-1:0] operand2_i,
    input logic [DatapathWidth-1:0] immediate_i,
    input logic [DatapathWidth-1:0] pc_i,

    //To CDB Arbiter
    output logic [DatapathWidth-1:0] result_o,
    output logic branch_taken_o
);
  localparam ADD = 'd0;
  localparam SLT = 'd1;
  localparam SLTU = 'd2;
  localparam XOR = 'd3;
  localparam OR = 'd4;
  localparam AND = 'd5;
  localparam SLL = 'd6;
  localparam SRL = 'd7;
  localparam SRA = 'd8;
  localparam SUB = 'd9;

  localparam BEQ = 'd10;
  localparam BNE = 'd11;
  localparam BLT = 'd12;
  localparam BGE = 'd13;
  localparam BLTU = 'd14;
  localparam BGEU = 'd15;

  localparam ADDI = 'd16;
  localparam SLTI = 'd17;
  localparam SLTIU = 'd18;
  localparam XORI = 'd19;
  localparam ORI = 'd20;
  localparam ANDI = 'd21;
  localparam SLLI = 'd22;
  localparam SRLI = 'd23;
  localparam SRAI = 'd24;

  localparam JALR = 'd25;

  always_comb begin
    result_o = 'd0;
    branch_taken_o = 1'b0;

    unique case (operation_i)
      ADD:  result_o = operand1_i + operand2_i;
      SLT:  result_o = ($signed(operand1_i) < $signed(operand2_i)) ? 'd1 : 'd0;
      SLTU: result_o = ($unsigned(operand1_i) < $unsigned(operand2_i)) ? 'd1 : 'd0;
      XOR:  result_o = operand1_i ^ operand2_i;
      OR:   result_o = operand1_i | operand2_i;
      AND:  result_o = operand1_i & operand2_i;
      SLL:  result_o = $unsigned(operand1_i) << operand2_i[$clog2(DatapathWidth)-1:0];
      SRL:  result_o = $unsigned(operand1_i) >> operand2_i[$clog2(DatapathWidth)-1:0];
      SRA:  result_o = $signed(operand1_i) >>> operand2_i[$clog2(DatapathWidth)-1:0];
      SUB:  result_o = operand1_i - operand2_i;

      ADDI:  result_o = operand1_i + immediate_i;
      SLTI:  result_o = ($signed(operand1_i) < $signed(immediate_i)) ? 'd1 : 'd0;
      SLTIU: result_o = ($unsigned(operand1_i) < $unsigned(immediate_i)) ? 'd1 : 'd0;
      XORI:  result_o = operand1_i ^ immediate_i;
      ORI:   result_o = operand1_i | immediate_i;
      ANDI:  result_o = operand1_i & immediate_i;
      SLLI:  result_o = $unsigned(operand1_i) << immediate_i[$clog2(DatapathWidth)-1:0];
      SRLI:  result_o = $unsigned(operand1_i) >> immediate_i[$clog2(DatapathWidth)-1:0];
      SRAI:  result_o = $signed(operand1_i) >>> immediate_i[$clog2(DatapathWidth)-1:0];

      BEQ: begin
        branch_taken_o = operand1_i == operand2_i;
        result_o = pc_i + (branch_taken_o ? immediate_i : 'd4);
      end
      BNE: begin
        branch_taken_o = operand1_i != operand2_i;
        result_o = pc_i + (branch_taken_o ? immediate_i : 'd4);
      end
      BLT: begin
        branch_taken_o = $signed(operand1_i) < $signed(operand2_i);
        result_o = pc_i + (branch_taken_o ? immediate_i : 'd4);
      end
      BGE: begin
        branch_taken_o = $signed(operand1_i) >= $signed(operand2_i);
        result_o = pc_i + (branch_taken_o ? immediate_i : 'd4);
      end
      BLTU: begin
        branch_taken_o = $unsigned(operand1_i) < $unsigned(operand2_i);
        result_o = pc_i + (branch_taken_o ? immediate_i : 'd4);
      end
      BGEU: begin
        branch_taken_o = $unsigned(operand1_i) >= $unsigned(operand2_i);
        result_o = pc_i + (branch_taken_o ? immediate_i : 'd4);
      end

      JALR: begin
        branch_taken_o = 1'b1;
        result_o = operand1_i + immediate_i;
      end
    endcase
  end
endmodule
