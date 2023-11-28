module renaming #(
    parameter ArRegIDWidth = 5,
    parameter PhyRegIDWidth = 6,
    parameter CDBWidth = 1,
    parameter CommitWidth = 2,
    parameter BridWidth = 2
) (
    input logic clk_i,
    input logic rst_ni,

    input logic flush_i,

    input logic missprediction_i,
    input logic [BridWidth-1:0] missprediction_brid_i,

    //CDB
    input logic [CDBWidth-1:0] cdb_valid_i,
    input logic [PhyRegIDWidth-1:0] cdb_tag_i[CDBWidth-1:0],

    input logic bru_valid_i,
    input logic [BridWidth-1:0] bru_brid_i,
    input logic [PhyRegIDWidth-1:0] bru_tag_i,

    //From Decoder
    input logic valid_i,
    input logic is_fast_i,
    input logic needs_checkpoint_i,
    input logic [ArRegIDWidth-1:0] dst_ar_id_i,
    input logic [ArRegIDWidth-1:0] operand1_ar_id_i,
    input logic [ArRegIDWidth-1:0] operand2_ar_id_i,
    output logic ready_o,

    //From Reorder Buffer
    input logic commit_i[CommitWidth-1:0],
    input logic [ArRegIDWidth-1:0] commit_ar_id_i[CommitWidth-1:0],
    input logic [PhyRegIDWidth-1:0] commit_tag_i[CommitWidth-1:0],
    input logic [PhyRegIDWidth-1:0] commit_old_tag_i[CommitWidth-1:0],

    //To Scheduler/Load Store Queue
    output logic valid_o,
    output logic [PhyRegIDWidth-1:0] tag_o,
    output logic [PhyRegIDWidth-1:0] old_tag_o,
    output logic operands_ready_o[1:0],
    output logic operands_fast_o[1:0],
    output logic operands_zero_o[1:0],
    output logic [PhyRegIDWidth-1:0] operands_tag_o[1:0],
    output logic [BridWidth-1:0] brid_o,
    output logic [BridMaskWidth-1:0] brid_mask_o,
    input  logic ready_i
);
  localparam NumRegs = 2 ** ArRegIDWidth;
  localparam NumPhyRegs = 2 ** PhyRegIDWidth;
  localparam NumCheckpoints = 2 ** BridWidth;
  localparam BridMaskWidth = 2 ** BridWidth;

  logic register_allocator_full;

  logic [BridWidth-1:0] brid_counter_q  /* verilator public */;
  logic [BridWidth-1:0] brid_counter_d;

  register_allocator #(
      .PhyRegIDWidth(PhyRegIDWidth),
      .NumRegsAllocatedOnReset(NumRegs),
      .CommitWidth(CommitWidth),
      .BridWidth(BridWidth)
  ) renaming_register_allocator_inst (
      .clk_i (clk_i),
      .rst_ni(rst_ni),

      .flush_i(flush_i),
      .missprediction_i(missprediction_i),
      .missprediction_brid_i(missprediction_brid_i),

      .commit_i(commit_i[CommitWidth-1:0]),
      .commit_tag_i(commit_tag_i[CommitWidth-1:0]),
      .commit_old_tag_i(commit_old_tag_i[CommitWidth-1:0]),

      .allocate_i(valid_i && ready_o),
      .allocate_new_checkpoint_i(needs_checkpoint_i),
      .allocate_brid_i(brid_counter_d),
      .tag_o(tag_o),
      .full_o(register_allocator_full),

      .state_allocated_o  (),
      .state_speculative_o(),
      .state_checkpoint_o ()
  );

  //Register is ready
  logic is_ready_q[NumPhyRegs-1:0];
  logic is_ready_d[NumPhyRegs-1:0];

  //Operation that produces this register is fast
  logic is_fast_q[NumRegs-1:0];
  logic is_fast_d[NumRegs-1:0];

  //Architectural Register Id State
  logic [PhyRegIDWidth-1:0] architectural_tag_q[NumRegs-1:0];
  logic [PhyRegIDWidth-1:0] architectural_tag_d[NumRegs-1:0];

  //Speculative Register Id State
  logic [PhyRegIDWidth-1:0] speculative_tag_q[NumRegs-1:0];
  logic [PhyRegIDWidth-1:0] speculative_tag_d[NumRegs-1:0];

  //Checkpoints
  logic [PhyRegIDWidth-1:0] checkpoint_q[NumCheckpoints-1:0][NumRegs-1:0] /* verilator public */;
  logic [PhyRegIDWidth-1:0] checkpoint_d[NumCheckpoints-1:0][NumRegs-1:0];

  logic [BridMaskWidth-1:0] active_checkpoints_q  /* verilator public */;
  logic [BridMaskWidth-1:0] active_checkpoints_d;

  //Next State Logic
  always_comb begin
    //Default
    brid_counter_d = brid_counter_q;
    active_checkpoints_d = active_checkpoints_q;

    is_ready_d[NumPhyRegs-1:0] = is_ready_q[NumPhyRegs-1:0];

    is_fast_d[NumRegs-1:0] = is_fast_q[NumRegs-1:0];
    architectural_tag_d[NumRegs-1:0] = architectural_tag_q[NumRegs-1:0];
    speculative_tag_d[NumRegs-1:0] = speculative_tag_q[NumRegs-1:0];
    checkpoint_d[NumCheckpoints-1:0] = checkpoint_q[NumCheckpoints-1:0];

    //Next State logic
    //if (bru_free_branch_i) active_checkpoints_d[bru_free_branch_brid_i] = 1'b0;
    if (bru_valid_i) active_checkpoints_d[bru_brid_i] = 1'b0;

    ready_o = !(!ready_i || register_allocator_full || (needs_checkpoint_i && active_checkpoints_d[brid_counter_q + 'd1]));
    brid_o = 'd0;
    brid_mask_o = active_checkpoints_d;
    valid_o = 1'b0;

    // Commits happen before the flush finishes -> ROB needs to make sure that only the oldest instructions are comitted
    // 1) Normal inst -> has to commit before flush
    // 2) MOE -> causes flush, not commit
    // 3) Normal inst -> not allowed to commit
    for (integer i = 0; i < CommitWidth; i = i + 1)
      if (commit_i[i]) architectural_tag_d[commit_ar_id_i[i]] = commit_tag_i[i];

    if (flush_i) begin
      is_ready_d[NumPhyRegs-1:0] = '{NumPhyRegs{1'b1}};
      //Restore architectural state
      speculative_tag_d[NumRegs-1:0] = architectural_tag_d[NumRegs-1:0];
      active_checkpoints_d = 'd0;
    end else if (missprediction_i) begin
      //Restore checkpoint
      speculative_tag_d[NumRegs-1:0] = checkpoint_q[missprediction_brid_i];
      //Clear all active checkpoints between missprediction_brid_i(earlier) and brid_counter_q(latest branch)
      if (brid_counter_q >= missprediction_brid_i) begin
        for (integer i = 0; i < 2 ** BridWidth; i++)
          if ((i > missprediction_brid_i) && (i <= brid_counter_q)) active_checkpoints_d[i] = 1'b0;
      end else begin
        for (integer i = 0; i < 2 ** BridWidth; i++)
          if ((i > missprediction_brid_i) || (i <= brid_counter_q)) active_checkpoints_d[i] = 1'b0;
      end
      brid_counter_d = missprediction_brid_i;
    end else if (valid_i && ready_o) begin
      is_ready_d[tag_o] = 1'b0;
      is_fast_d[dst_ar_id_i] = is_fast_i;
      speculative_tag_d[dst_ar_id_i] = tag_o;

      //Create checkpoint
      if (needs_checkpoint_i) begin
        brid_counter_d = brid_counter_q + 'd1;
        checkpoint_d[brid_counter_d][NumRegs-1:0] = speculative_tag_d[NumRegs-1:0];
        active_checkpoints_d[brid_counter_d] = 1'b1;
      end

      brid_o  = brid_counter_d;

      valid_o = 1'b1;
    end

    for (integer i = 0; i < CDBWidth; i = i + 1)
      if (cdb_valid_i[i]) is_ready_d[cdb_tag_i[i]] = 1'b1;

    if (bru_valid_i) is_ready_d[bru_tag_i] = 1'b1;
  end

  //Flip Flop
  initial begin
    brid_counter_q = 'd0;
    active_checkpoints_q = 'd0;
    for (integer i = 0; i < NumRegs; i = i + 1) begin
      is_fast_q[i] = 1'b0;
      architectural_tag_q[i] = i[PhyRegIDWidth-1:0];
      speculative_tag_q[i] = i[PhyRegIDWidth-1:0];
      for (integer c = 0; c < NumCheckpoints; c = c + 1) checkpoint_q[c][i] = 'd0;
    end
    is_ready_d[NumPhyRegs-1:0] = '{NumPhyRegs{1'b1}};
    active_checkpoints_q = 'd0;
  end
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      brid_counter_q <= 'd0;
      active_checkpoints_q <= 'd0;
      for (integer i = 0; i < NumRegs; i = i + 1) begin
        is_fast_q[i] <= 1'b0;
        architectural_tag_q[i] <= i[PhyRegIDWidth-1:0];
        speculative_tag_q[i] <= i[PhyRegIDWidth-1:0];
        for (integer c = 0; c < NumCheckpoints; c = c + 1) checkpoint_q[c][i] <= 'd0;
      end
      is_ready_q[NumPhyRegs-1:0] <= '{NumPhyRegs{1'b1}};
    end else begin
      brid_counter_q <= brid_counter_d;
      active_checkpoints_q <= active_checkpoints_d;
      checkpoint_q[NumCheckpoints-1:0] <= checkpoint_d[NumCheckpoints-1:0];

      is_ready_q[NumPhyRegs-1:0] <= is_ready_d[NumPhyRegs-1:0];
      is_fast_q[NumRegs-1:0] <= is_fast_d[NumRegs-1:0];
      architectural_tag_q[NumRegs-1:0] <= architectural_tag_d[NumRegs-1:0];
      speculative_tag_q[NumRegs-1:0] <= speculative_tag_d[NumRegs-1:0];
    end
  end
endmodule
