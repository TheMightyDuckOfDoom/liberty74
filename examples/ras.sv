module ras #(
    parameter NumRasEntries = 4,
    parameter NumTosCheckpoints = 2,
    parameter DatapathWidth = 32,

    // Dependent Paramters
    parameter RasPointerWidth = $clog2(NumRasEntries),
    parameter TosCheckpointsPointerWidth = $clog2(NumTosCheckpoints)
) (
    input logic clk_i,
    input logic rst_ni,

    input logic restore_checkpoint_i,
    input logic [DatapathWidth-1:0] restore_checkpoint_pc_i,

    input logic make_checkpoint_i,
    input logic [DatapathWidth-1:0] make_checkpoint_pc_i,

    input logic push_i,
    input logic pop_i,
    input logic [DatapathWidth-1:0] pc_i,

    output logic [DatapathWidth-1:0] pc_o,

    output logic [DatapathWidth-1:0] state_ras_entries_o[NumRasEntries-1:0],
    output logic [RasPointerWidth-1:0] state_ras_tos_pointer_o,
    output logic [DatapathWidth-1:0] state_ras_checkpoints_tos_pc_o[NumTosCheckpoints-1:0],
    output logic [DatapathWidth-1:0] state_ras_checkpoints_tos_value_o[NumTosCheckpoints-1:0],
    output logic [RasPointerWidth-1:0] state_ras_checkpoints_tos_pointer_o[NumTosCheckpoints-1:0],
    output logic [TosCheckpointsPointerWidth-1:0] state_ras_checkpoint_pointer_o
);
  localparam NumRasEntries_m1 = NumRasEntries - 1;
  localparam NumTosCheckpoints_m1 = NumTosCheckpoints - 1;

  //Actual RAS
  logic [DatapathWidth-1:0] ras_entries_d[NumRasEntries-1:0];
  logic [DatapathWidth-1:0] ras_entries_q[NumRasEntries-1:0];

  logic [RasPointerWidth-1:0] tos_pointer_d;
  logic [RasPointerWidth-1:0] tos_pointer_q;

  //TOS Pointer and Value checkpoints for branch recovery
  logic [DatapathWidth-1:0] checkpoints_tos_pc_d[NumTosCheckpoints-1:0];
  logic [DatapathWidth-1:0] checkpoints_tos_pc_q[NumTosCheckpoints-1:0];

  logic [DatapathWidth-1:0] checkpoints_tos_value_d[NumTosCheckpoints-1:0];
  logic [DatapathWidth-1:0] checkpoints_tos_value_q[NumTosCheckpoints-1:0];

  logic [RasPointerWidth-1:0] checkpoints_tos_pointer_d[NumTosCheckpoints-1:0];
  logic [RasPointerWidth-1:0] checkpoints_tos_pointer_q[NumTosCheckpoints-1:0];

  logic [TosCheckpointsPointerWidth-1:0] checkpoint_pointer_d;
  logic [TosCheckpointsPointerWidth-1:0] checkpoint_pointer_q;

  logic [TosCheckpointsPointerWidth-1:0] checkpoint_id;

  always_comb begin
    //Default
    ras_entries_d[NumRasEntries-1:0] = ras_entries_q[NumRasEntries-1:0];
    tos_pointer_d = tos_pointer_q;

    pc_o = 'd0;
    state_ras_entries_o[NumRasEntries-1:0] = ras_entries_q[NumRasEntries-1:0];
    state_ras_tos_pointer_o = tos_pointer_q;

    checkpoints_tos_pc_d[NumTosCheckpoints-1:0] = checkpoints_tos_pc_q[NumTosCheckpoints-1:0];
    checkpoints_tos_value_d[NumTosCheckpoints-1:0] = checkpoints_tos_value_q[NumTosCheckpoints-1:0];
    checkpoints_tos_pointer_d[NumTosCheckpoints-1:0] = checkpoints_tos_pointer_q[NumTosCheckpoints-1:0];

    checkpoint_pointer_d = checkpoint_pointer_q;
    checkpoint_id = 'd0;

    state_ras_checkpoints_tos_pc_o[NumTosCheckpoints-1:0] = checkpoints_tos_pc_q[NumTosCheckpoints-1:0];
    state_ras_checkpoints_tos_value_o[NumTosCheckpoints-1:0] = checkpoints_tos_value_q[NumTosCheckpoints-1:0];
    state_ras_checkpoints_tos_pointer_o[NumTosCheckpoints-1:0] = checkpoints_tos_pointer_q[NumTosCheckpoints-1:0];
    state_ras_checkpoint_pointer_o = checkpoint_pointer_q;

    //Make checkpoint
    if (make_checkpoint_i) begin
      checkpoints_tos_pc_d[checkpoint_pointer_q] = make_checkpoint_pc_i;
      checkpoints_tos_value_d[checkpoint_pointer_q] = ras_entries_q[tos_pointer_q];
      checkpoints_tos_pointer_d[checkpoint_pointer_q] = tos_pointer_q;

      if (checkpoint_pointer_q == NumTosCheckpoints_m1[TosCheckpointsPointerWidth-1:0])
        checkpoint_pointer_d = 'd0;
      else checkpoint_pointer_d = checkpoint_pointer_q + 'd1;
    end

    //Restore checkpoint
    if (restore_checkpoint_i) begin
      for (integer i = 0; i < NumTosCheckpoints; i = i + 1)
        if (checkpoints_tos_pc_q[i] == restore_checkpoint_pc_i)
          checkpoint_id = i[TosCheckpointsPointerWidth-1:0];

      tos_pointer_d = checkpoints_tos_pointer_q[checkpoint_id];
      ras_entries_d[tos_pointer_d] = checkpoints_tos_value_q[checkpoint_id];
    end else begin
      //Pop
      if (pop_i) begin
        pc_o = ras_entries_q[tos_pointer_d];
        if (tos_pointer_d == 'd0) tos_pointer_d = NumRasEntries_m1[RasPointerWidth-1:0];
        else tos_pointer_d = tos_pointer_d - 'd1;
      end

      //Push
      if (push_i) begin
        if (tos_pointer_d == NumRasEntries_m1[RasPointerWidth-1:0]) tos_pointer_d = 'd0;
        else tos_pointer_d = tos_pointer_d + 'd1;
        ras_entries_d[tos_pointer_d] = pc_i;
      end
    end
  end

  initial begin
    tos_pointer_q = 'd0;
    ras_entries_q[NumRasEntries-1:0] = '{NumRasEntries{'d0}};
    checkpoints_tos_pc_q[NumTosCheckpoints-1:0] = '{NumTosCheckpoints{'d0}};
    checkpoints_tos_value_q[NumTosCheckpoints-1:0] = '{NumTosCheckpoints{'d0}};
    checkpoints_tos_pointer_q[NumTosCheckpoints-1:0] = '{NumTosCheckpoints{'d0}};
    checkpoint_pointer_q = 'd0;
  end
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      tos_pointer_q <= 'd0;
      checkpoint_pointer_q <= 'd0;
    end else begin
      tos_pointer_q <= tos_pointer_d;
      ras_entries_q[NumRasEntries-1:0] <= ras_entries_d[NumRasEntries-1:0];
      checkpoints_tos_value_q[NumTosCheckpoints-1:0] <= checkpoints_tos_value_d[NumTosCheckpoints-1:0];
      checkpoints_tos_pointer_q[NumTosCheckpoints-1:0] <= checkpoints_tos_pointer_d[NumTosCheckpoints-1:0];
      checkpoints_tos_pc_q[NumTosCheckpoints-1:0] <= checkpoints_tos_pc_d[NumTosCheckpoints-1:0];
      checkpoint_pointer_q <= checkpoint_pointer_d;
    end
  end
endmodule
