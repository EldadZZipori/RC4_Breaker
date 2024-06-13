module time_machine(
	input logic CLOCK_50,
	input logic key_from_switches_changed,
	input logic key_from_switches_available,
	input logic shuffle_mem_finished,
	input logic assign_by_index_done,
	
	output logic reset_all,
	output logic start_shuffle,
	output logic start_s_i_i,
	output logic[7:0] current_state
);

	localparam IDLE 				= 0;
	localparam RESET				= 1;
	localparam START_S_I_I 		= 2;
	localparam S_I_I				= 3;
	localparam START_SHUFFLE	= 4;
	localparam SHUFFLE			= 5;
	localparam FINAL				= 6;
	
	logic [7:0] next_state;
	
	always_ff @(posedge CLOCK_50) begin
		current_state <= next_state;
	end
	
	always_comb begin
		if (key_from_switches_changed) begin
			next_state = RESET;
		end
		else begin
			case (current_state)
				IDLE: begin
																next_state = START_S_I_I;
				end
				RESET: begin
					if(key_from_switches_available) 	next_state = IDLE;
					else										next_state = RESET;
				end
				START_S_I_I: begin
																next_state = S_I_I;
				end
				S_I_I: begin
					//if (assign_by_index_done) 			next_state = START_SHUFFLE;
					//else 										next_state = S_I_I;
					next_state = S_I_I;
				end
				START_SHUFFLE: begin
																next_state = SHUFFLE;
				end
				SHUFFLE: begin
					if (shuffle_mem_finished) 			next_state = FINAL;
					else										next_state = SHUFFLE;
				end
				FINAL: begin
																next_state = FINAL;
				end
				default: next_state = FINAL;
			endcase
		end
	end
	/*
		Register control to start FSM's
	*/
	always_ff @(posedge CLOCK_50) begin
		if(reset_all) begin
			start_s_i_i <= 1'b0;
			start_shuffle <= 1'b0;
		end
		else begin
			case(current_state)
				IDLE: begin
					reset_all <= 1'b0;
				end
				S_I_I: begin									// indicates s[i] = i is done
					start_shuffle <= 1'b0;
				end
				SHUFFLE: begin									// indicates j = (j + s[i] + secret_key[i mod keylength]) and swap s[i[ and s[j] done
					start_s_i_i <= 1'b0;
				end
				START_S_I_I: begin
					start_s_i_i 	<= 1'b1;
					start_shuffle	<= 1'b0;
				end
				START_SHUFFLE: begin
					start_shuffle 	<= 1'b1;
					start_s_i_i		<= 1'b0;
				end
				RESET: begin
					reset_all <= 1'b1;
				end
				default: begin
					start_s_i_i <= 1'b0;
					start_shuffle <= 1'b0;
				end
			endcase
		end
	end

endmodule
