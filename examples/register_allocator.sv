module register_allocator #(
    parameter PhyRegIDWidth = 5,
    parameter NumRegsAllocatedOnReset = 16,
    parameter CommitWidth = 1,
    parameter BridWidth = 2
) (
    input logic clk_i,
    input logic rst_ni,

    input logic flush_i,

    input logic missprediction_i,
    input logic [BridWidth-1:0] missprediction_brid_i,

    input logic commit_i[CommitWidth-1:0],
    input logic [PhyRegIDWidth-1:0] commit_tag_i[CommitWidth-1:0],  //Register to mark as nonspeculative
    input logic [PhyRegIDWidth-1:0] commit_old_tag_i[CommitWidth-1:0],  //Register to deallocate

    input logic allocate_i,
    input logic allocate_new_checkpoint_i,
    input logic [BridWidth-1:0] allocate_brid_i,
    output logic [PhyRegIDWidth-1:0] tag_o,
    output logic full_o

    //output logic state_allocated_o[NumRegs-1:0],
    //output logic state_speculative_o[NumRegs-1:0],
    //output logic [NumRegs-1:0] state_checkpoint_o[NumCheckpoints-1:0]
);
  localparam NumRegs = 2 ** PhyRegIDWidth;
  localparam NumCheckpoints = 2 ** BridWidth;

  logic allocated_q[NumRegs-1:0];
  logic allocated_d[NumRegs-1:0];

  logic speculative_q[NumRegs-1:0];
  logic speculative_d[NumRegs-1:0];

  logic [NumRegs-1:0] checkpoint_q[NumCheckpoints-1:0];
  logic [NumRegs-1:0] checkpoint_d[NumCheckpoints-1:0];

  //assign state_checkpoint_o[NumCheckpoints-1:0] = checkpoint_q[NumCheckpoints-1:0];

  //Entry logic
  always_comb begin
    checkpoint_d[NumCheckpoints-1:0] = checkpoint_q[NumCheckpoints-1:0];

    for (integer i = 0; i < NumRegs; i = i + 1) begin
      //Default
      allocated_d[i]   = allocated_q[i];
      speculative_d[i] = speculative_q[i];

      //Commit
      if (!flush_i) begin
        for (integer c = 0; c < CommitWidth; c = c + 1) begin
          if (commit_i[c]) begin
            if (commit_tag_i[c] == i[PhyRegIDWidth-1:0]) speculative_d[i] = 1'b0;
            if (commit_old_tag_i[c] == i[PhyRegIDWidth-1:0]) begin
              allocated_d[i]   = 1'b0;
              speculative_d[i] = 1'b0;
            end
          end
        end
      end

      //Restore Checkpoint upon a missprediction -> free registers allocated since last checkpoint
      if (missprediction_i) begin
        allocated_d[i]   = allocated_d[i] & (~checkpoint_q[missprediction_brid_i][i]);
        //This might not be needed
        speculative_d[i] = speculative_d[i] & (~checkpoint_q[missprediction_brid_i][i]);
      end else if (!flush_i) begin
        //Allocate
        if (allocate_i) begin
          if (tag_o == i[PhyRegIDWidth-1:0]) begin
            allocated_d[i]   = 1'b1;
            speculative_d[i] = 1'b1;

            //Mark as allocated in every checkpoint
            for (integer c = 0; c < NumCheckpoints; c = c + 1) checkpoint_d[c][i] = 1'b1;
          end

          //Create checkpoint -> clear allocated register list
          if (allocate_new_checkpoint_i) checkpoint_d[allocate_brid_i][i] = 1'b0;
        end
      end

      //Flush
      if (flush_i) begin
        if (speculative_q[i]) begin
          allocated_d[i]   = 1'b0;
          speculative_d[i] = 1'b0;
        end

        // Flush and Commit happened at same time
        for (integer c = 0; c < CommitWidth; c = c + 1) begin
          if (commit_i[c]) begin
            // Allocate new register
            if (commit_tag_i[c] == i[PhyRegIDWidth-1:0]) begin
              allocated_d[i] = 1'b1;
              speculative_d[i] = 1'b0;
            end
            //Dealocate old register
            if (commit_old_tag_i[c] == i[PhyRegIDWidth-1:0]) begin
              allocated_d[i]   = 1'b0;
              speculative_d[i] = 1'b0;
            end
          end
        end
      end

      //Outputs
      //state_allocated_o[i]   = allocated_q[i];
      //state_speculative_o[i] = speculative_q[i];
    end
  end

  //Allocate Priority encoder
  always_comb begin
    full_o = 1'b1;
    tag_o  = 'd0;
    for (integer i = NumRegs - 1; i >= 0; i = i - 1) begin
      if (!allocated_q[i]) begin
        tag_o  = i[PhyRegIDWidth-1:0];
        full_o = 1'b0;
      end
    end
  end

  //Flip Flop
  initial begin
    for (integer i = 0; i < NumRegs; i = i + 1) allocated_q[i] = i < NumRegsAllocatedOnReset;
    speculative_q[NumRegs-1:0] = '{NumRegs{1'b0}};

    checkpoint_q[NumCheckpoints-1:0] = '{NumCheckpoints{'d0}};
  end
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (integer i = 0; i < NumRegs; i = i + 1) allocated_q[i] <= i < NumRegsAllocatedOnReset;
      speculative_q[NumRegs-1:0] <= '{NumRegs{1'b0}};
    end else begin
      allocated_q[NumRegs-1:0] <= allocated_d[NumRegs-1:0];
      speculative_q[NumRegs-1:0] <= speculative_d[NumRegs-1:0];

      checkpoint_q[NumCheckpoints-1:0] <= checkpoint_d[NumCheckpoints-1:0];
    end
  end
endmodule
