module clock (
	clk_i,
	rst_ni,
	hours_high_o,
	hours_low_o,
	minutes_high_o,
	minutes_low_o,
	seconds_high_o,
	seconds_low_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	output reg [3:0] hours_high_o;
	output reg [3:0] hours_low_o;
	output reg [3:0] minutes_high_o;
	output reg [3:0] minutes_low_o;
	output reg [3:0] seconds_high_o;
	output reg [3:0] seconds_low_o;
	reg [3:0] hours_high_d;
	reg [3:0] hours_low_d;
	reg [3:0] minutes_high_d;
	reg [3:0] minutes_low_d;
	reg [3:0] seconds_high_d;
	reg [3:0] seconds_low_d;
	always @(*) begin
		if (_sv2v_0)
			;
		hours_high_d = hours_high_o;
		hours_low_d = hours_low_o;
		minutes_high_d = minutes_high_o;
		minutes_low_d = minutes_low_o;
		seconds_high_d = seconds_high_o;
		seconds_low_d = seconds_low_o + 'd1;
		if (seconds_low_d == 'd10) begin
			seconds_low_d = 1'sb0;
			seconds_high_d = seconds_high_d + 'd1;
		end
		if (seconds_high_d == 'd6) begin
			seconds_high_d = 1'sb0;
			minutes_low_d = minutes_low_d + 'd1;
		end
		if (minutes_low_d == 'd10) begin
			minutes_low_d = 1'sb0;
			minutes_high_d = minutes_high_d + 'd1;
		end
		if (minutes_high_d == 'd6) begin
			minutes_high_d = 1'sb0;
			hours_low_d = hours_low_d + 'd1;
		end
		if (hours_low_d == 'd10) begin
			hours_low_d = 1'sb0;
			hours_high_d = hours_high_d + 'd1;
		end
		if ((hours_high_d == 'd2) && (hours_low_d == 'd4)) begin
			hours_low_d = 'd0;
			hours_high_d = 'd0;
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			hours_high_o <= 1'sb0;
			hours_low_o <= 1'sb0;
			minutes_high_o <= 1'sb0;
			minutes_low_o <= 1'sb0;
			seconds_high_o <= 1'sb0;
			seconds_low_o <= 1'sb0;
		end
		else begin
			hours_high_o <= hours_high_d;
			hours_low_o <= hours_low_d;
			minutes_high_o <= minutes_high_d;
			minutes_low_o <= minutes_low_d;
			seconds_high_o <= seconds_high_d;
			seconds_low_o <= seconds_low_d;
		end
	initial _sv2v_0 = 0;
endmodule
