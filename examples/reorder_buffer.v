module reorder_buffer (
	clk_i,
	rst_ni,
	stall_insert_i,
	stall_commit_i,
	flush_o,
	reexecute_o,
	reexecute_pc_o,
	insert_i,
	insert_ar_id_i,
	insert_tag_i,
	insert_old_tag_i,
	insert_pc_i,
	insert_predicted_pc_i,
	insert_is_branch_i,
	insert_is_load_i,
	insert_is_store_i,
	full_o,
	cdb_valid_i,
	cdb_tag_i,
	cdb_data_i,
	bru_valid_i,
	bru_tag_i,
	bru_misspredicted_i,
	commit_o,
	commit_ar_id_o,
	commit_tag_o,
	commit_old_tag_o,
	memory_order_exception_valid_i,
	memory_order_exception_i
);
	reg _sv2v_0;
	parameter ArRegIDWidth = 5;
	parameter PhyRegIDWidth = 6;
	parameter NumROBEntries = 8;
	parameter DatapathWidth = 32;
	parameter CDBWidth = 2;
	parameter CommitWidth = 1;
	input wire clk_i;
	input wire rst_ni;
	input wire stall_insert_i;
	input wire stall_commit_i;
	output reg flush_o;
	output reg reexecute_o;
	output reg [DatapathWidth - 1:0] reexecute_pc_o;
	input wire insert_i;
	input wire [ArRegIDWidth - 1:0] insert_ar_id_i;
	input wire [PhyRegIDWidth - 1:0] insert_tag_i;
	input wire [PhyRegIDWidth - 1:0] insert_old_tag_i;
	input wire [DatapathWidth - 1:0] insert_pc_i;
	input wire [DatapathWidth - 1:0] insert_predicted_pc_i;
	input wire insert_is_branch_i;
	input wire insert_is_load_i;
	input wire insert_is_store_i;
	output reg full_o;
	input wire [CDBWidth - 1:0] cdb_valid_i;
	input wire [(CDBWidth * PhyRegIDWidth) - 1:0] cdb_tag_i;
	input wire [(CDBWidth * DatapathWidth) - 1:0] cdb_data_i;
	input wire bru_valid_i;
	input wire [PhyRegIDWidth - 1:0] bru_tag_i;
	input wire bru_misspredicted_i;
	output reg [CommitWidth - 1:0] commit_o;
	output reg [(CommitWidth * ArRegIDWidth) - 1:0] commit_ar_id_o;
	output reg [(CommitWidth * PhyRegIDWidth) - 1:0] commit_tag_o;
	output reg [(CommitWidth * PhyRegIDWidth) - 1:0] commit_old_tag_o;
	input wire [CommitWidth - 1:0] memory_order_exception_valid_i;
	input wire [CommitWidth - 1:0] memory_order_exception_i;
	localparam ROBCounterWidth = $clog2(NumROBEntries);
	localparam NumROBEntries_min_1 = NumROBEntries - 1;
	reg [NumROBEntries - 1:0] ready_q;
	reg [(NumROBEntries * ArRegIDWidth) - 1:0] ar_id_q;
	reg [(NumROBEntries * PhyRegIDWidth) - 1:0] tag_q;
	reg [(NumROBEntries * PhyRegIDWidth) - 1:0] old_tag_q;
	reg [(NumROBEntries * DatapathWidth) - 1:0] pc_q;
	reg [(NumROBEntries * DatapathWidth) - 1:0] predicted_pc_q;
	reg [(NumROBEntries * DatapathWidth) - 1:0] data_q;
	reg [NumROBEntries - 1:0] is_load_q;
	reg [NumROBEntries - 1:0] is_store_q;
	reg [NumROBEntries - 1:0] is_branch_q;
	reg [NumROBEntries - 1:0] misspredicted_q;
	reg [NumROBEntries - 1:0] ready_d;
	reg [(NumROBEntries * ArRegIDWidth) - 1:0] ar_id_d;
	reg [(NumROBEntries * PhyRegIDWidth) - 1:0] tag_d;
	reg [(NumROBEntries * PhyRegIDWidth) - 1:0] old_tag_d;
	reg [(NumROBEntries * DatapathWidth) - 1:0] pc_d;
	reg [(NumROBEntries * DatapathWidth) - 1:0] predicted_pc_d;
	reg [(NumROBEntries * DatapathWidth) - 1:0] data_d;
	reg [NumROBEntries - 1:0] is_load_d;
	reg [NumROBEntries - 1:0] is_store_d;
	reg [NumROBEntries - 1:0] is_branch_d;
	reg [NumROBEntries - 1:0] misspredicted_d;
	reg [ROBCounterWidth - 1:0] insert_pointer_q;
	reg [ROBCounterWidth - 1:0] commit_pointer_q;
	reg [ROBCounterWidth - 1:0] insert_pointer_d;
	reg [ROBCounterWidth - 1:0] commit_pointer_d;
	reg had_memory_order_exception_d;
	reg had_memory_order_exception_q;
	reg [ROBCounterWidth - 1:0] store_match_counter_d;
	reg [ROBCounterWidth - 1:0] store_match_counter_q;
	reg missprediction;
	always @(*) begin
		if (_sv2v_0)
			;
		ready_d[NumROBEntries - 1:0] = ready_q[NumROBEntries - 1:0];
		ar_id_d[ArRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:ArRegIDWidth * NumROBEntries] = ar_id_q[ArRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:ArRegIDWidth * NumROBEntries];
		tag_d[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries] = tag_q[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries];
		old_tag_d[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries] = old_tag_q[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries];
		pc_d[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] = pc_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries];
		predicted_pc_d[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] = predicted_pc_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries];
		data_d[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] = data_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries];
		is_load_d[NumROBEntries - 1:0] = is_load_q[NumROBEntries - 1:0];
		is_store_d[NumROBEntries - 1:0] = is_store_q[NumROBEntries - 1:0];
		is_branch_d[NumROBEntries - 1:0] = is_branch_q[NumROBEntries - 1:0];
		misspredicted_d[NumROBEntries - 1:0] = misspredicted_q[NumROBEntries - 1:0];
		had_memory_order_exception_d = had_memory_order_exception_q;
		store_match_counter_d = store_match_counter_q;
		insert_pointer_d = insert_pointer_q;
		commit_pointer_d = commit_pointer_q;
		flush_o = 1'b0;
		reexecute_o = 1'b0;
		reexecute_pc_o = 'd0;
		missprediction = 1'b0;
		commit_o = {CommitWidth {1'b0}};
		commit_ar_id_o = {CommitWidth {'d0}};
		commit_tag_o = {CommitWidth {'d0}};
		commit_old_tag_o = {CommitWidth {'d0}};
		begin : sv2v_autoblock_1
			integer cdb;
			for (cdb = 0; cdb < CDBWidth; cdb = cdb + 1)
				if (cdb_valid_i[cdb]) begin : sv2v_autoblock_2
					integer i;
					for (i = 0; i < NumROBEntries; i = i + 1)
						if (!ready_q[i] && (tag_q[i * PhyRegIDWidth+:PhyRegIDWidth] == cdb_tag_i[cdb * PhyRegIDWidth+:PhyRegIDWidth])) begin
							ready_d[i] = 1'b1;
							data_d[i * DatapathWidth+:DatapathWidth] = cdb_data_i[cdb * DatapathWidth+:DatapathWidth];
						end
				end
		end
		if (bru_valid_i) begin
			if (commit_pointer_q < insert_pointer_q) begin : sv2v_autoblock_3
				integer i;
				for (i = 0; i < NumROBEntries; i = i + 1)
					if ((i >= commit_pointer_q) && (i < insert_pointer_q)) begin
						if (!ready_q[i] && (tag_q[i * PhyRegIDWidth+:PhyRegIDWidth] == bru_tag_i)) begin
							ready_d[i] = 1'b1;
							misspredicted_d[i] = bru_misspredicted_i;
							if (bru_misspredicted_i) begin
								missprediction = 1'b1;
								insert_pointer_d = i[ROBCounterWidth - 1:0] + 'd1;
								if (insert_pointer_d == NumROBEntries[ROBCounterWidth - 1:0])
									insert_pointer_d = 'd0;
							end
						end
					end
			end
			else begin : sv2v_autoblock_4
				integer i;
				for (i = 0; i < NumROBEntries; i = i + 1)
					if ((i >= commit_pointer_q) || (i < insert_pointer_q)) begin
						if (!ready_q[i] && (tag_q[i * PhyRegIDWidth+:PhyRegIDWidth] == bru_tag_i)) begin
							ready_d[i] = 1'b1;
							misspredicted_d[i] = bru_misspredicted_i;
							if (bru_misspredicted_i) begin
								missprediction = 1'b1;
								insert_pointer_d = i[ROBCounterWidth - 1:0] + 'd1;
								if (insert_pointer_d == NumROBEntries[ROBCounterWidth - 1:0])
									insert_pointer_d = 'd0;
							end
						end
					end
			end
		end
		full_o = stall_insert_i;
		if (insert_pointer_q == (commit_pointer_q - 'd1))
			full_o = 1'b1;
		if ((commit_pointer_q == 'd0) && (insert_pointer_q == NumROBEntries_min_1[ROBCounterWidth - 1:0]))
			full_o = 1'b1;
		if ((insert_i && !full_o) && !missprediction) begin
			ready_d[insert_pointer_q] = 1'b0;
			ar_id_d[insert_pointer_q * ArRegIDWidth+:ArRegIDWidth] = insert_ar_id_i;
			tag_d[insert_pointer_q * PhyRegIDWidth+:PhyRegIDWidth] = insert_tag_i;
			old_tag_d[insert_pointer_q * PhyRegIDWidth+:PhyRegIDWidth] = insert_old_tag_i;
			pc_d[insert_pointer_q * DatapathWidth+:DatapathWidth] = insert_pc_i;
			predicted_pc_d[insert_pointer_q * DatapathWidth+:DatapathWidth] = insert_predicted_pc_i;
			data_d[insert_pointer_q * DatapathWidth+:DatapathWidth] = 'd0;
			is_load_d[insert_pointer_q] = insert_is_load_i;
			is_store_d[insert_pointer_q] = insert_is_store_i;
			is_branch_d[insert_pointer_q] = insert_is_branch_i;
			misspredicted_d[insert_pointer_q] = 1'b0;
			insert_pointer_d = insert_pointer_d + 'd1;
			if (insert_pointer_d == NumROBEntries[ROBCounterWidth - 1:0])
				insert_pointer_d = 'd0;
		end
		begin : sv2v_autoblock_5
			integer c;
			for (c = 0; c < CommitWidth; c = c + 1)
				if (memory_order_exception_valid_i[c]) begin
					store_match_counter_d = store_match_counter_d - 'd1;
					if (memory_order_exception_i[c])
						had_memory_order_exception_d = 1'b1;
				end
		end
		if ((ready_q[commit_pointer_q] && (commit_pointer_q != insert_pointer_q)) && !stall_commit_i) begin
			if (misspredicted_q[commit_pointer_q] && 1'b0) begin
				commit_o[0] = 1'b1;
				commit_ar_id_o[0+:ArRegIDWidth] = ar_id_q[commit_pointer_q * ArRegIDWidth+:ArRegIDWidth];
				commit_tag_o[0+:PhyRegIDWidth] = tag_q[commit_pointer_q * PhyRegIDWidth+:PhyRegIDWidth];
				commit_old_tag_o[0+:PhyRegIDWidth] = old_tag_q[commit_pointer_q * PhyRegIDWidth+:PhyRegIDWidth];
				insert_pointer_d = commit_pointer_q;
				ready_d[NumROBEntries - 1:0] = {NumROBEntries {1'b0}};
			end
			else if ((is_load_q[commit_pointer_q] && (store_match_counter_d == 0)) && had_memory_order_exception_q) begin
				had_memory_order_exception_d = 1'b0;
				flush_o = 1'b1;
				reexecute_o = 1'b1;
				reexecute_pc_o = pc_q[commit_pointer_q * DatapathWidth+:DatapathWidth];
				insert_pointer_d = commit_pointer_q;
				ready_d[NumROBEntries - 1:0] = {NumROBEntries {1'b0}};
			end
			else if (!(is_load_q[commit_pointer_q] && (store_match_counter_q != 0)) && !(is_store_q[commit_pointer_q] && (store_match_counter_q == {ROBCounterWidth {1'sb1}}))) begin
				if (is_store_q[commit_pointer_q])
					store_match_counter_d = store_match_counter_d + 'd1;
				commit_o[0] = 1'b1;
				commit_ar_id_o[0+:ArRegIDWidth] = ar_id_q[commit_pointer_q * ArRegIDWidth+:ArRegIDWidth];
				commit_tag_o[0+:PhyRegIDWidth] = tag_q[commit_pointer_q * PhyRegIDWidth+:PhyRegIDWidth];
				commit_old_tag_o[0+:PhyRegIDWidth] = old_tag_q[commit_pointer_q * PhyRegIDWidth+:PhyRegIDWidth];
				ready_d[commit_pointer_q] = 1'b0;
				commit_pointer_d = commit_pointer_d + 'd1;
				if (commit_pointer_d == NumROBEntries[ROBCounterWidth - 1:0])
					commit_pointer_d = 'd0;
				if ((((CommitWidth == 2) && ready_q[commit_pointer_d]) && (commit_pointer_d != insert_pointer_q)) && !misspredicted_q[commit_pointer_d]) begin
					if ((is_load_q[commit_pointer_d] && (store_match_counter_d == 0)) && had_memory_order_exception_q) begin
						had_memory_order_exception_d = 1'b0;
						flush_o = 1'b1;
						reexecute_o = 1'b1;
						reexecute_pc_o = pc_q[commit_pointer_d * DatapathWidth+:DatapathWidth];
						insert_pointer_d = commit_pointer_d;
						ready_d[NumROBEntries - 1:0] = {NumROBEntries {1'b0}};
					end
					else if (!(is_load_q[commit_pointer_d] && (store_match_counter_d != 0)) && !(is_store_q[commit_pointer_q] && (store_match_counter_d == {ROBCounterWidth {1'sb1}}))) begin
						if (is_store_q[commit_pointer_d])
							store_match_counter_d = store_match_counter_d + 'd1;
						commit_o[1] = 1'b1;
						commit_ar_id_o[ArRegIDWidth+:ArRegIDWidth] = ar_id_q[commit_pointer_d * ArRegIDWidth+:ArRegIDWidth];
						commit_tag_o[PhyRegIDWidth+:PhyRegIDWidth] = tag_q[commit_pointer_d * PhyRegIDWidth+:PhyRegIDWidth];
						commit_old_tag_o[PhyRegIDWidth+:PhyRegIDWidth] = old_tag_q[commit_pointer_d * PhyRegIDWidth+:PhyRegIDWidth];
						ready_d[commit_pointer_d] = 1'b0;
						commit_pointer_d = commit_pointer_d + 'd1;
						if (commit_pointer_d == NumROBEntries[ROBCounterWidth - 1:0])
							commit_pointer_d = 'd0;
					end
				end
			end
		end
	end
	initial begin
		ready_q[NumROBEntries - 1:0] = {NumROBEntries {1'b0}};
		ar_id_q[ArRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:ArRegIDWidth * NumROBEntries] = {NumROBEntries {'d0}};
		tag_q[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries] = {NumROBEntries {'d0}};
		old_tag_q[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries] = {NumROBEntries {'d0}};
		pc_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] = {NumROBEntries {'d0}};
		predicted_pc_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] = {NumROBEntries {'d0}};
		data_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] = {NumROBEntries {'d0}};
		is_load_q[NumROBEntries - 1:0] = {NumROBEntries {1'b0}};
		is_store_q[NumROBEntries - 1:0] = {NumROBEntries {1'b0}};
		is_branch_q[NumROBEntries - 1:0] = {NumROBEntries {1'b0}};
		misspredicted_q[NumROBEntries - 1:0] = {NumROBEntries {1'b0}};
		insert_pointer_q = 'd0;
		commit_pointer_q = 'd0;
		had_memory_order_exception_q = 1'b0;
		store_match_counter_q = 'd0;
	end
	always @(posedge clk_i)
		if (!rst_ni) begin
			ready_q[NumROBEntries - 1:0] <= {NumROBEntries {1'b0}};
			ar_id_q[ArRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:ArRegIDWidth * NumROBEntries] <= {NumROBEntries {'d0}};
			tag_q[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries] <= {NumROBEntries {'d0}};
			old_tag_q[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries] <= {NumROBEntries {'d0}};
			pc_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] <= {NumROBEntries {'d0}};
			predicted_pc_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] <= {NumROBEntries {'d0}};
			data_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] <= {NumROBEntries {'d0}};
			is_load_q[NumROBEntries - 1:0] <= {NumROBEntries {1'b0}};
			is_store_q[NumROBEntries - 1:0] <= {NumROBEntries {1'b0}};
			is_branch_q[NumROBEntries - 1:0] <= {NumROBEntries {1'b0}};
			misspredicted_q[NumROBEntries - 1:0] <= {NumROBEntries {1'b0}};
			insert_pointer_q <= 'd0;
			commit_pointer_q <= 'd0;
			had_memory_order_exception_q <= 1'b0;
			store_match_counter_q <= 'd0;
		end
		else begin
			ready_q[NumROBEntries - 1:0] <= ready_d[NumROBEntries - 1:0];
			ar_id_q[ArRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:ArRegIDWidth * NumROBEntries] <= ar_id_d[ArRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:ArRegIDWidth * NumROBEntries];
			tag_q[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries] <= tag_d[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries];
			old_tag_q[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries] <= old_tag_d[PhyRegIDWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:PhyRegIDWidth * NumROBEntries];
			pc_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] <= pc_d[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries];
			predicted_pc_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] <= predicted_pc_d[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries];
			data_q[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries] <= data_d[DatapathWidth * ((NumROBEntries - 1) - (NumROBEntries - 1))+:DatapathWidth * NumROBEntries];
			is_load_q[NumROBEntries - 1:0] <= is_load_d[NumROBEntries - 1:0];
			is_store_q[NumROBEntries - 1:0] <= is_store_d[NumROBEntries - 1:0];
			is_branch_q[NumROBEntries - 1:0] <= is_branch_d[NumROBEntries - 1:0];
			misspredicted_q[NumROBEntries - 1:0] <= misspredicted_d[NumROBEntries - 1:0];
			insert_pointer_q <= insert_pointer_d;
			commit_pointer_q <= commit_pointer_d;
			had_memory_order_exception_q <= had_memory_order_exception_d;
			store_match_counter_q <= store_match_counter_d;
		end
	initial _sv2v_0 = 0;
endmodule
