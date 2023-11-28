module reorder_buffer #(
    parameter ArRegIDWidth = 5,
    parameter PhyRegIDWidth = 6,
    parameter NumROBEntries = 8,
    parameter DatapathWidth = 32,
    parameter CDBWidth = 2,
    parameter CommitWidth = 1
) (
    input logic clk_i,
    input logic rst_ni,

    input logic stall_insert_i,
    input logic stall_commit_i,

    //Flush
    output logic flush_o,
    output logic reexecute_o,
    output logic [DatapathWidth-1:0] reexecute_pc_o,

    //Insert
    input logic insert_i,
    input logic [ArRegIDWidth-1:0] insert_ar_id_i,
    input logic [PhyRegIDWidth-1:0] insert_tag_i,
    input logic [PhyRegIDWidth-1:0] insert_old_tag_i,
    input logic [DatapathWidth-1:0] insert_pc_i,
    input logic [DatapathWidth-1:0] insert_predicted_pc_i,
    input logic insert_is_branch_i,
    input logic insert_is_load_i,
    input logic insert_is_store_i,
    output logic full_o,

    //CDB
    input logic [CDBWidth-1:0] cdb_valid_i,
    input logic [PhyRegIDWidth-1:0] cdb_tag_i[CDBWidth-1:0],
    input logic [DatapathWidth-1:0] cdb_data_i[CDBWidth-1:0],

    input logic bru_valid_i,
    input logic [PhyRegIDWidth-1:0] bru_tag_i,
    input logic bru_misspredicted_i,

    //Commit
    output logic commit_o[CommitWidth-1:0],
    output logic [ArRegIDWidth-1:0] commit_ar_id_o[CommitWidth-1:0],
    output logic [PhyRegIDWidth-1:0] commit_tag_o[CommitWidth-1:0],
    output logic [PhyRegIDWidth-1:0] commit_old_tag_o[CommitWidth-1:0],

    input logic memory_order_exception_valid_i[CommitWidth-1:0],
    input logic memory_order_exception_i[CommitWidth-1:0]
);
  localparam ROBCounterWidth = $clog2(NumROBEntries);
  localparam NumROBEntries_min_1 = NumROBEntries - 1;

  logic ready_q[NumROBEntries-1:0];
  logic [ArRegIDWidth-1:0] ar_id_q[NumROBEntries-1:0];
  logic [PhyRegIDWidth-1:0] tag_q[NumROBEntries-1:0];
  logic [PhyRegIDWidth-1:0] old_tag_q[NumROBEntries-1:0];
  logic [DatapathWidth-1:0] pc_q[NumROBEntries-1:0];
  logic [DatapathWidth-1:0] predicted_pc_q[NumROBEntries-1:0];
  logic [DatapathWidth-1:0] data_q[NumROBEntries-1:0];
  logic is_load_q[NumROBEntries-1:0];
  logic is_store_q[NumROBEntries-1:0];
  logic is_branch_q[NumROBEntries-1:0];
  logic misspredicted_q[NumROBEntries-1:0];

  logic ready_d[NumROBEntries-1:0];
  logic [ArRegIDWidth-1:0] ar_id_d[NumROBEntries-1:0];
  logic [PhyRegIDWidth-1:0] tag_d[NumROBEntries-1:0];
  logic [PhyRegIDWidth-1:0] old_tag_d[NumROBEntries-1:0];
  logic [DatapathWidth-1:0] pc_d[NumROBEntries-1:0];
  logic [DatapathWidth-1:0] predicted_pc_d[NumROBEntries-1:0];
  logic [DatapathWidth-1:0] data_d[NumROBEntries-1:0];
  logic is_load_d[NumROBEntries-1:0];
  logic is_store_d[NumROBEntries-1:0];
  logic is_branch_d[NumROBEntries-1:0];
  logic misspredicted_d[NumROBEntries-1:0];

  logic [ROBCounterWidth-1:0] insert_pointer_q;
  logic [ROBCounterWidth-1:0] commit_pointer_q;

  logic [ROBCounterWidth-1:0] insert_pointer_d;
  logic [ROBCounterWidth-1:0] commit_pointer_d;

  //Was there any memory ordering exception?
  logic had_memory_order_exception_d;
  logic had_memory_order_exception_q;

  //How many stores still need to be checked for load alias
  logic [ROBCounterWidth-1:0] store_match_counter_d;
  logic [ROBCounterWidth-1:0] store_match_counter_q;

  logic missprediction;

  //Next State Logic
  always_comb begin
    //Default
    ready_d[NumROBEntries-1:0] = ready_q[NumROBEntries-1:0];
    ar_id_d[NumROBEntries-1:0] = ar_id_q[NumROBEntries-1:0];
    tag_d[NumROBEntries-1:0] = tag_q[NumROBEntries-1:0];
    old_tag_d[NumROBEntries-1:0] = old_tag_q[NumROBEntries-1:0];
    pc_d[NumROBEntries-1:0] = pc_q[NumROBEntries-1:0];
    predicted_pc_d[NumROBEntries-1:0] = predicted_pc_q[NumROBEntries-1:0];
    data_d[NumROBEntries-1:0] = data_q[NumROBEntries-1:0];
    is_load_d[NumROBEntries-1:0] = is_load_q[NumROBEntries-1:0];
    is_store_d[NumROBEntries-1:0] = is_store_q[NumROBEntries-1:0];
    is_branch_d[NumROBEntries-1:0] = is_branch_q[NumROBEntries-1:0];
    misspredicted_d[NumROBEntries-1:0] = misspredicted_q[NumROBEntries-1:0];

    had_memory_order_exception_d = had_memory_order_exception_q;
    store_match_counter_d = store_match_counter_q;

    insert_pointer_d = insert_pointer_q;
    commit_pointer_d = commit_pointer_q;

    flush_o = 1'b0;
    reexecute_o = 1'b0;
    reexecute_pc_o = 'd0;

    missprediction = 1'b0;

    commit_o = '{CommitWidth{1'b0}};
    commit_ar_id_o = '{CommitWidth{'d0}};
    commit_tag_o = '{CommitWidth{'d0}};
    commit_old_tag_o = '{CommitWidth{'d0}};

    //CDB Logic
    for (integer cdb = 0; cdb < CDBWidth; cdb = cdb + 1) begin
      if (cdb_valid_i[cdb]) begin
        for (integer i = 0; i < NumROBEntries; i = i + 1) begin
          if (!ready_q[i] && (tag_q[i] == cdb_tag_i[cdb])) begin
            ready_d[i] = 1'b1;
            data_d[i]  = cdb_data_i[cdb];
          end
        end
      end
    end

    if (bru_valid_i) begin
      if (commit_pointer_q < insert_pointer_q) begin
        for (integer i = 0; i < NumROBEntries; i = i + 1) begin
          if (i >= commit_pointer_q && i < insert_pointer_q) begin
            if (!ready_q[i] && (tag_q[i] == bru_tag_i)) begin
              ready_d[i] = 1'b1;
              misspredicted_d[i] = bru_misspredicted_i;

              if (bru_misspredicted_i) begin
                missprediction   = 1'b1;
                insert_pointer_d = i[ROBCounterWidth-1:0] + 'd1;
                if (insert_pointer_d == NumROBEntries[ROBCounterWidth-1:0]) insert_pointer_d = 'd0;
              end
            end
          end
        end
      end else begin
        for (integer i = 0; i < NumROBEntries; i = i + 1) begin
          if (i >= commit_pointer_q || i < insert_pointer_q) begin
            if (!ready_q[i] && (tag_q[i] == bru_tag_i)) begin
              ready_d[i] = 1'b1;
              misspredicted_d[i] = bru_misspredicted_i;

              if (bru_misspredicted_i) begin
                missprediction   = 1'b1;
                insert_pointer_d = i[ROBCounterWidth-1:0] + 'd1;
                if (insert_pointer_d == NumROBEntries[ROBCounterWidth-1:0]) insert_pointer_d = 'd0;
              end
            end
          end
        end
      end
    end

    full_o = stall_insert_i;
    if (insert_pointer_q == (commit_pointer_q - 'd1)) full_o = 1'b1;
    if ((commit_pointer_q == 'd0) && (insert_pointer_q == NumROBEntries_min_1[ROBCounterWidth-1:0]))
      full_o = 1'b1;

    //Insert Logic
    if (insert_i && !full_o && !missprediction) begin
      ready_d[insert_pointer_q] = 1'b0;
      ar_id_d[insert_pointer_q] = insert_ar_id_i;
      tag_d[insert_pointer_q] = insert_tag_i;
      old_tag_d[insert_pointer_q] = insert_old_tag_i;
      pc_d[insert_pointer_q] = insert_pc_i;
      predicted_pc_d[insert_pointer_q] = insert_predicted_pc_i;
      data_d[insert_pointer_q] = 'd0;
      is_load_d[insert_pointer_q] = insert_is_load_i;
      is_store_d[insert_pointer_q] = insert_is_store_i;
      is_branch_d[insert_pointer_q] = insert_is_branch_i;
      misspredicted_d[insert_pointer_q] = 1'b0;

      insert_pointer_d = insert_pointer_d + 'd1;
      if (insert_pointer_d == NumROBEntries[ROBCounterWidth-1:0]) insert_pointer_d = 'd0;
    end

    //Exception handling
    for (integer c = 0; c < CommitWidth; c = c + 1) begin
      if (memory_order_exception_valid_i[c]) begin
        store_match_counter_d = store_match_counter_d - 'd1;
        if (memory_order_exception_i[c]) had_memory_order_exception_d = 1'b1;
      end
    end

    //Commit Logic
    if (ready_q[commit_pointer_q] && (commit_pointer_q != insert_pointer_q) && !stall_commit_i) begin
      if (misspredicted_q[commit_pointer_q] && 1'b0) begin
        //Handle missprediction -> flush
        //flush_o = 1'b1;

        commit_o[0] = 1'b1;
        commit_ar_id_o[0] = ar_id_q[commit_pointer_q];
        commit_tag_o[0] = tag_q[commit_pointer_q];
        commit_old_tag_o[0] = old_tag_q[commit_pointer_q];

        //Clear ROB
        insert_pointer_d = commit_pointer_q;
        ready_d[NumROBEntries-1:0] = '{NumROBEntries{1'b0}};
      end else begin
        if (is_load_q[commit_pointer_q] && (store_match_counter_d == 0) && had_memory_order_exception_q) begin
          //Had a memory order exception -> flush and reexecute instruction, do not commit any more instructions
          had_memory_order_exception_d = 1'b0;

          flush_o = 1'b1;
          reexecute_o = 1'b1;
          reexecute_pc_o = pc_q[commit_pointer_q];

          //Clear ROB
          insert_pointer_d = commit_pointer_q;
          ready_d[NumROBEntries-1:0] = '{NumROBEntries{1'b0}};
        end else if (!(is_load_q[commit_pointer_q] && (store_match_counter_q != 0)) && !(is_store_q[commit_pointer_q] && (store_match_counter_q == '1))) begin
          //Commit 1st instruction
          if (is_store_q[commit_pointer_q]) store_match_counter_d = store_match_counter_d + 'd1;
          commit_o[0] = 1'b1;
          commit_ar_id_o[0] = ar_id_q[commit_pointer_q];
          commit_tag_o[0] = tag_q[commit_pointer_q];
          commit_old_tag_o[0] = old_tag_q[commit_pointer_q];

          ready_d[commit_pointer_q] = 1'b0;

          commit_pointer_d = commit_pointer_d + 'd1;
          if (commit_pointer_d == NumROBEntries[ROBCounterWidth-1:0]) commit_pointer_d = 'd0;

          //Commit of 1st instruction has to happen before a flush by 2nd instruction
          //Only one branch 1.840
          if (CommitWidth == 2 && ready_q[commit_pointer_d] && (commit_pointer_d != insert_pointer_q) && !misspredicted_q[commit_pointer_d]) begin
            if (is_load_q[commit_pointer_d] && (store_match_counter_d == 0) && had_memory_order_exception_q) begin
              //Had a memory order exception -> flush and reexecute instruction
              had_memory_order_exception_d = 1'b0;

              flush_o = 1'b1;
              reexecute_o = 1'b1;
              reexecute_pc_o = pc_q[commit_pointer_d];

              //Clear ROB
              insert_pointer_d = commit_pointer_d;
              ready_d[NumROBEntries-1:0] = '{NumROBEntries{1'b0}};
            end else if (!(is_load_q[commit_pointer_d] && (store_match_counter_d != 0)) && !(is_store_q[commit_pointer_q] && (store_match_counter_d == '1))) begin
              //Commit 2nd instruction
              if (is_store_q[commit_pointer_d]) store_match_counter_d = store_match_counter_d + 'd1;
              commit_o[1] = 1'b1;
              commit_ar_id_o[1] = ar_id_q[commit_pointer_d];
              commit_tag_o[1] = tag_q[commit_pointer_d];
              commit_old_tag_o[1] = old_tag_q[commit_pointer_d];

              ready_d[commit_pointer_d] = 1'b0;

              commit_pointer_d = commit_pointer_d + 'd1;
              if (commit_pointer_d == NumROBEntries[ROBCounterWidth-1:0]) commit_pointer_d = 'd0;
            end
          end
        end
      end
    end

  end

  //Flip Flop
  initial begin
    ready_q[NumROBEntries-1:0] = '{NumROBEntries{1'b0}};
    ar_id_q[NumROBEntries-1:0] = '{NumROBEntries{'d0}};
    tag_q[NumROBEntries-1:0] = '{NumROBEntries{'d0}};
    old_tag_q[NumROBEntries-1:0] = '{NumROBEntries{'d0}};
    pc_q[NumROBEntries-1:0] = '{NumROBEntries{'d0}};
    predicted_pc_q[NumROBEntries-1:0] = '{NumROBEntries{'d0}};
    data_q[NumROBEntries-1:0] = '{NumROBEntries{'d0}};
    is_load_q[NumROBEntries-1:0] = '{NumROBEntries{1'b0}};
    is_store_q[NumROBEntries-1:0] = '{NumROBEntries{1'b0}};
    is_branch_q[NumROBEntries-1:0] = '{NumROBEntries{1'b0}};
    misspredicted_q[NumROBEntries-1:0] = '{NumROBEntries{1'b0}};

    insert_pointer_q = 'd0;
    commit_pointer_q = 'd0;

    had_memory_order_exception_q = 1'b0;
    store_match_counter_q = 'd0;
  end
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      ready_q[NumROBEntries-1:0] <= '{NumROBEntries{1'b0}};
      ar_id_q[NumROBEntries-1:0] <= '{NumROBEntries{'d0}};
      tag_q[NumROBEntries-1:0] <= '{NumROBEntries{'d0}};
      old_tag_q[NumROBEntries-1:0] <= '{NumROBEntries{'d0}};
      pc_q[NumROBEntries-1:0] <= '{NumROBEntries{'d0}};
      predicted_pc_q[NumROBEntries-1:0] <= '{NumROBEntries{'d0}};
      data_q[NumROBEntries-1:0] <= '{NumROBEntries{'d0}};
      is_load_q[NumROBEntries-1:0] <= '{NumROBEntries{1'b0}};
      is_store_q[NumROBEntries-1:0] <= '{NumROBEntries{1'b0}};
      is_branch_q[NumROBEntries-1:0] <= '{NumROBEntries{1'b0}};
      misspredicted_q[NumROBEntries-1:0] <= '{NumROBEntries{1'b0}};

      insert_pointer_q <= 'd0;
      commit_pointer_q <= 'd0;

      had_memory_order_exception_q <= 1'b0;
      store_match_counter_q <= 'd0;
    end else begin
      ready_q[NumROBEntries-1:0] <= ready_d[NumROBEntries-1:0];
      ar_id_q[NumROBEntries-1:0] <= ar_id_d[NumROBEntries-1:0];
      tag_q[NumROBEntries-1:0] <= tag_d[NumROBEntries-1:0];
      old_tag_q[NumROBEntries-1:0] <= old_tag_d[NumROBEntries-1:0];
      pc_q[NumROBEntries-1:0] <= pc_d[NumROBEntries-1:0];
      predicted_pc_q[NumROBEntries-1:0] <= predicted_pc_d[NumROBEntries-1:0];
      data_q[NumROBEntries-1:0] <= data_d[NumROBEntries-1:0];
      is_load_q[NumROBEntries-1:0] <= is_load_d[NumROBEntries-1:0];
      is_store_q[NumROBEntries-1:0] <= is_store_d[NumROBEntries-1:0];
      is_branch_q[NumROBEntries-1:0] <= is_branch_d[NumROBEntries-1:0];
      misspredicted_q[NumROBEntries-1:0] <= misspredicted_d[NumROBEntries-1:0];

      insert_pointer_q <= insert_pointer_d;
      commit_pointer_q <= commit_pointer_d;

      had_memory_order_exception_q <= had_memory_order_exception_d;
      store_match_counter_q <= store_match_counter_d;
    end
  end
endmodule
