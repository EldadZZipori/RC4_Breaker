module time_machine(
	input logic CLOCK_50,
	input logic reset,
	input logic key_from_switches_changed,
	input logic key_from_switches_available,
	input logic shuffle_mem_finished,
	input logic assign_by_index_done,
	input logic sec_shuffle_done,
	input logic s_data_read_done,
	input logic decrypt_done,
	
	output logic reset_all,
	output logic start_shuffle,
	output logic start_s_i_i,
	output logic start_sec_shuffle,
	output logic s_data_read_start,
	output logic start_decrypt,
	output logic[7:0] current_state
);

	localparam IDLE 					= 7'b0000_000;
	localparam RESET					= 7'b0001_001;
	localparam START_S_I_I 			= 7'b0100_010;
	localparam S_I_I					= 7'b0100_011;
	localparam START_SHUFFLE		= 7'b0010_100;
	localparam SHUFFLE				= 7'b0010_101;
	localparam STRAT_SEC_SHUFFLE	= 7'b1000_111;
	localparam SEC_SHUFFLE			= 7'b1000_000; 
	localparam FINAL					= 7'b0000_110;
	localparam READ_S_DATA			= 7'b1111_000;
	localparam DECRYPT				= 7'b1111_111;
	
	logic [7:0] next_state;
	
	assign reset_all 				= (current_state == RESET);
	assign start_shuffle 		= (current_state == START_SHUFFLE) | (current_state == SHUFFLE);
	assign start_s_i_i			= (current_state == START_S_I_I) | (current_state == S_I_I);
	assign start_sec_shuffle 	= (current_state == STRAT_SEC_SHUFFLE) | (current_state == SEC_SHUFFLE);
	assign s_data_read_start	= (current_state == READ_S_DATA);
	assign start_decrypt			= (current_state == DECRYPT);
	
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
				S_I_I: begin
					if (assign_by_index_done) 			next_state = START_SHUFFLE;
					else 										next_state = S_I_I;
					//next_state = S_I_I;
				end
				RESET: begin
					if(key_from_switches_available) 	next_state = IDLE;
					else										next_state = RESET;
				end
				START_S_I_I: begin
																next_state = S_I_I;
				end
				START_SHUFFLE: begin
																next_state = SHUFFLE;
				end
				SHUFFLE: begin
					if (shuffle_mem_finished) 			next_state = STRAT_SEC_SHUFFLE;
					else										next_state = SHUFFLE;
				end
				STRAT_SEC_SHUFFLE: begin
																next_state = SEC_SHUFFLE;
				end
				SEC_SHUFFLE: begin
					if (sec_shuffle_done)				next_state = READ_S_DATA;
					else										next_state = SEC_SHUFFLE;
				end
				READ_S_DATA: begin
					if(s_data_read_done)					next_state = DECRYPT;
					else										next_state = READ_S_DATA;
				end
				DECRYPT: begin
					if (decrypt_done)						next_state = FINAL;
					else										next_state = DECRYPT;
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
	/*always_ff @(posedge CLOCK_50) begin
		if(reset) begin
			start_s_i_i <= 1'b0;
			start_shuffle <= 1'b0;
			reset_all <= 1'b0;
		end
		/*else begin
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
	end*/

endmodule
