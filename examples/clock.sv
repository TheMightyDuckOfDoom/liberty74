module clock (
  input logic clk_i,
  input logic rst_ni,

  output logic [3:0] hours_high_o,
  output logic [3:0] hours_low_o,
  output logic [3:0] minutes_high_o, 
  output logic [3:0] minutes_low_o, 
  output logic [3:0] seconds_high_o, 
  output logic [3:0] seconds_low_o
);

  logic [3:0] hours_high_d, hours_low_d, minutes_high_d, minutes_low_d, seconds_high_d, seconds_low_d;

  always_comb begin
    // Default
    hours_high_d   = hours_high_o;
    hours_low_d    = hours_low_o;
    minutes_high_d = minutes_high_o;
    minutes_low_d  = minutes_low_o;
    seconds_high_d = seconds_high_o;
    seconds_low_d  = seconds_low_o + 'd1;

    if (seconds_low_d == 'd10) begin
      seconds_low_d = '0;
      seconds_high_d = seconds_high_d + 'd1;
    end
    if (seconds_high_d == 'd6) begin
      seconds_high_d = '0;
      minutes_low_d = minutes_low_d + 'd1;
    end
    if (minutes_low_d == 'd10) begin
      minutes_low_d = '0;
      minutes_high_d = minutes_high_d + 'd1;
    end
    if (minutes_high_d == 'd6) begin
      minutes_high_d = '0;
      hours_low_d = hours_low_d + 'd1;
    end
    if (hours_low_d == 'd10) begin
      hours_low_d = '0;
      hours_high_d = hours_high_d + 'd1;
    end
    if ((hours_high_d == 'd2) && (hours_low_d == 'd4)) begin
      hours_low_d = 'd0;
      hours_high_d = 'd0;
    end 
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      hours_high_o   <= '0;
      hours_low_o    <= '0;
      minutes_high_o <= '0;
      minutes_low_o  <= '0;
      seconds_high_o <= '0;
      seconds_low_o  <= '0;
    end else begin
      hours_high_o   <= hours_high_d;
      hours_low_o    <= hours_low_d;
      minutes_high_o <= minutes_high_d;
      minutes_low_o  <= minutes_low_d;
      seconds_high_o <= seconds_high_d;
      seconds_low_o  <= seconds_low_d;
    end
  end

endmodule : clock
