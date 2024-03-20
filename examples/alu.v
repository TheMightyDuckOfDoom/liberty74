module alu (
	clk_i,
	rst_ni,
	operation_i,
	operand1_i,
	operand2_i,
	immediate_i,
	pc_i,
	result_o,
	branch_taken_o
);
	reg _sv2v_0;
	parameter DatapathWidth = 64;
	parameter AluOperationWidth = 5;
	input wire clk_i;
	input wire rst_ni;
	input wire [AluOperationWidth - 1:0] operation_i;
	input wire [DatapathWidth - 1:0] operand1_i;
	input wire [DatapathWidth - 1:0] operand2_i;
	input wire [DatapathWidth - 1:0] immediate_i;
	input wire [DatapathWidth - 1:0] pc_i;
	output reg [DatapathWidth - 1:0] result_o;
	output reg branch_taken_o;
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
	reg [DatapathWidth - 1:0] result_d;
	reg branch_taken_d;
	always @(*) begin
		if (_sv2v_0)
			;
		result_d = 'd0;
		branch_taken_d = 1'b0;
		(* full_case, parallel_case *)
		case (operation_i)
			ADD: result_d = operand1_i + operand2_i;
			SLT: result_d = ($signed(operand1_i) < $signed(operand2_i) ? 'd1 : 'd0);
			SLTU: result_d = ($unsigned(operand1_i) < $unsigned(operand2_i) ? 'd1 : 'd0);
			XOR: result_d = operand1_i ^ operand2_i;
			OR: result_d = operand1_i | operand2_i;
			AND: result_d = operand1_i & operand2_i;
			SLL: result_d = $unsigned(operand1_i) << operand2_i[$clog2(DatapathWidth) - 1:0];
			SRL: result_d = $unsigned(operand1_i) >> operand2_i[$clog2(DatapathWidth) - 1:0];
			SRA: result_d = $signed(operand1_i) >>> operand2_i[$clog2(DatapathWidth) - 1:0];
			SUB: result_d = operand1_i - operand2_i;
			ADDI: result_d = operand1_i + immediate_i;
			SLTI: result_d = ($signed(operand1_i) < $signed(immediate_i) ? 'd1 : 'd0);
			SLTIU: result_d = ($unsigned(operand1_i) < $unsigned(immediate_i) ? 'd1 : 'd0);
			XORI: result_d = operand1_i ^ immediate_i;
			ORI: result_d = operand1_i | immediate_i;
			ANDI: result_d = operand1_i & immediate_i;
			SLLI: result_d = $unsigned(operand1_i) << immediate_i[$clog2(DatapathWidth) - 1:0];
			SRLI: result_d = $unsigned(operand1_i) >> immediate_i[$clog2(DatapathWidth) - 1:0];
			SRAI: result_d = $signed(operand1_i) >>> immediate_i[$clog2(DatapathWidth) - 1:0];
			BEQ: begin
				branch_taken_d = operand1_i == operand2_i;
				result_d = pc_i + (branch_taken_d ? immediate_i : 'd4);
			end
			BNE: begin
				branch_taken_d = operand1_i != operand2_i;
				result_d = pc_i + (branch_taken_d ? immediate_i : 'd4);
			end
			BLT: begin
				branch_taken_d = $signed(operand1_i) < $signed(operand2_i);
				result_d = pc_i + (branch_taken_d ? immediate_i : 'd4);
			end
			BGE: begin
				branch_taken_d = $signed(operand1_i) >= $signed(operand2_i);
				result_d = pc_i + (branch_taken_d ? immediate_i : 'd4);
			end
			BLTU: begin
				branch_taken_d = $unsigned(operand1_i) < $unsigned(operand2_i);
				result_d = pc_i + (branch_taken_d ? immediate_i : 'd4);
			end
			BGEU: begin
				branch_taken_d = $unsigned(operand1_i) >= $unsigned(operand2_i);
				result_d = pc_i + (branch_taken_d ? immediate_i : 'd4);
			end
			JALR: begin
				branch_taken_d = 1'b1;
				result_d = operand1_i + immediate_i;
			end
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			result_o <= 1'sb0;
			branch_taken_o <= 1'sb0;
		end
		else begin
			result_o <= result_d;
			branch_taken_o <= branch_taken_d;
		end
	initial _sv2v_0 = 0;
endmodule
