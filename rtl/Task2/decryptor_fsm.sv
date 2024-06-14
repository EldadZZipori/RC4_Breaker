`default_nettype none


module decryptor_fsm
# (parameter MSG_DEP = 32, parameter S_DEP = 256, parameter MSG_WIDTH = 8)
(
	input logic							clk,
	input logic							reset,
	input logic [MSG_WIDTH-1:0]	encrypted_input[MSG_DEP-1:0],
	input logic [MSG_WIDTH-1:0]	s_data[S_DEP-1:0],
	input logic							start,
	
	output logic [MSG_WIDTH-1:0]	decrypted_output[MSG_DEP-1:0],	
	output logic						done
);

	/*
		STATE CONTROL
		
		state is encoded as follows
		[0-2]		state number
		3			available flag
		4			counter_finished flag
	*/
	localparam IDLE 					= 3'b000;
	localparam ASSIGN_F				= 3'b001;
	localparam DECRYPT				= 3'b010;
	localparam INCREMENT_INDEX_I	= 3'b011;
	localparam INCREMENT_INDEX_J	= 3'b100;
	localparam DETERMINE				= 3'b101;
	localparam DONE					= 3'b110;
	
	
	logic [4:0] current_state/*synthesis keep*/;
	logic [4:0] next_state;
	
	logic [MSG_WIDTH-1:0] 	f;	
	logic	[7:0]					index_i, index_j;
	
	// Flip flop to register the current state
	always_ff @(posedge clk) begin
		current_state <= next_state;
	end
	
	always_comb begin
		if(reset) next_state <= IDLE;
		else begin
			case (current_state)
				IDLE: begin
					if (start) 	next_state <= INCREMENT_INDEX_I;
					else 			next_state <= IDLE;
					
				end
				INCREMENT_INDEX_I: begin
					next_state = INCREMENT_INDEX_J;
				end
				INCREMENT_INDEX_J: begin
					next_state = ASSIGN_F;
				end
				ASSIGN_F: begin
					next_state = DECRYPT;
				end
				DECRYPT: begin
					next_state = DETERMINE;
				end
				DETERMINE: begin
					if (index_i == ({MSG_WIDTH{1'b1}}))  			next_state = DONE;					// when all data is read stop 
					else															next_state = INCREMENT_INDEX_I;	
				end
				DONE: begin
					next_state = DONE;
				end
				default: next_state = IDLE;
			endcase
		end
	end
		
	always_ff @ (posedge clk) begin
		case (current_state)
			IDLE: begin
				index_i 	<= 0;
				index_j	<= 0;
				done 		<= 1'b0;
			end
			INCREMENT_INDEX_I: begin
				index_i <= index_i + 1;
			end
			INCREMENT_INDEX_J: begin
				index_j <= index_j + s_data[index_i];
			end
			ASSIGN_F: begin
				f <= s_data[s_data[index_i] +s_data[index_j]];
			end
			DECRYPT: begin
				decrypted_output[index_i] <= f ^ encrypted_input[index_i];
			end
			DONE: begin
				done <= 1'b1;
			end

		endcase
	end
	
endmodule
