`default_nettype none


module decryption_fsm
# (parameter MSG_DEP = 32, parameter S_DEP = 256, parameter MSG_WIDTH = 8)
(
	input logic							clk,
	input logic							reset,
	input logic [MSG_WIDTH-1:0]	encrypted_input[MSG_DEP-1:0],
	input logic [MSG_WIDTH-1:0]	s_data[S_DEP-1:0],
	input logic							start,
	
	output logic [S_DEP-1:0]		address_out,
	output logic [MSG_WIDTH-1:0]	data_out,	
	output logic 						enable_write,
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
	localparam IDLE 					= 4'b0000;
	localparam ASSIGN_F				= 4'b0001;
	localparam DECRYPT				= 4'b0010;
	localparam INCREMENT_INDEX_I	= 4'b0011;
	localparam INCREMENT_INDEX_J	= 4'b0100;
	localparam I_TO_J					= 4'b0111;
	localparam WAIT_I_TO_J			= 4'b1001;
	localparam DIS_I_TO_J			= 4'b1011;
	localparam J_TO_I					= 4'b1000;
	localparam WAIT_J_TO_I			= 4'b1010;
	localparam DIS_J_TO_I			= 4'b1100;
	localparam DETERMINE				= 4'b0101;
	localparam DONE					= 4'b0110;
	
	
	logic [4:0] current_state/*synthesis keep*/;
	logic [4:0] next_state;
	
	logic [MSG_WIDTH-1:0] 	f;	
	logic	[7:0]					index_i, index_j;
	
	logic [MSG_WIDTH] temp_i;
	
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
				I_TO_J: begin
					next_state = WAIT_I_TO_J;
				end
				WAIT_I_TO_J: begin
					next_state = DIS_I_TO_J;
				end
				DIS_I_TO_J: begin
					next_state = J_TO_I;
				end
				J_TO_I: begin
					next_state = WAIT_J_TO_I;
				end
				WAIT_J_TO_I: begin
					next_state = DIS_J_TO_I;
				end
				DIS_J_TO_I: begin
					next_state = ASSIGN_F;
				end
				ASSIGN_F: begin
					next_state = DECRYPT;
				end
				DECRYPT: begin
					next_state = DETERMINE;
				end
				DETERMINE: begin
					if (index_i == ({MSG_WIDTH{1'b1}}))  	next_state = DONE;					// when all data is read stop 
					else												next_state = INCREMENT_INDEX_I;	
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
				index_i 			<= 0;																									
				index_j			<= 0;
				enable_write 	<= 1'b0;
				done 				<= 1'b0;
			end
			INCREMENT_INDEX_I: begin
				index_i <= index_i + 1;													 // i = i + 1 in the begining of the loop. i.e. i starts at 1
			end
			INCREMENT_INDEX_J: begin
				index_j <= index_j + s_data[index_i];
			end
			I_TO_J: begin
				address_out 	<= index_j;
				data_out			<= s_data[index_i];
				enable_write 	<= 1'b0;
			end
			WAIT_I_TO_J: begin	
				// just letting it settle
				enable_write 	<= 1'b1;
			end
			DIS_I_TO_J: begin
				enable_write 	<= 1'b0;
			end
			J_TO_I: begin
				enable_write 	<= 1'b0;
				address_out 	<= index_i;
				data_out			<= s_data[index_j];
			end
			WAIT_J_TO_I: begin
				enable_write 	<= 1'b1;
			end
			DIS_J_TO_I: begin
				enable_write 	<= 1'b0;
			end
			ASSIGN_F: begin
				f <= s_data[s_data[index_i] +s_data[index_j]];
			end
			DECRYPT: begin
				decrypted_output[index_i-1] <= f ^ encrypted_input[index_i-1]; // k = i -1 always
			end
			DONE: begin
				done <= 1'b1;
			end

		endcase
	end
	
endmodule
