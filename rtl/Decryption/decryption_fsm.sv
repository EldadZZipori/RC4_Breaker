`default_nettype none


module decryption_fsm
# (parameter MSG_DEP = 32, parameter MSG_WIDTH = 8)
(
	input logic							clk,
	input logic							reset,
	input logic [MSG_WIDTH-1:0]	encrypted_input[MSG_DEP-1:0],
	input logic [MSG_WIDTH-1:0] 	s_i,
	input	logic	[MSG_WIDTH-1:0]	s_j,
	input logic							s_j_available,
	input logic [MSG_WIDTH-1:0]	s_data_in,
	
	output logic [MSG_WIDTH-1:0]	decrypted_output[MSG_DEP-1:0],
	output logic [MSG_WIDTH:0]		current_index,
	
	output logic [MSG-WIDTH-1:0] 	address_out,
	output logic						wn_en,
	output logic						done
);

	/*
		STATE CONTROL
		
		state is encoded as follows
		[0-2]		state number
		3			available flag
		4			counter_finished flag
	*/
	localparam IDLE 				= 0;
	localparam WAIT_AVAIL		= 1;
	localparam SEND_S_ADDR		= 10;
	localparam WAIT_S_DATA		= 11;
	localparam ASSIGN_F			= 100;
	localparam DECRYPT			= 101;
	localparam INCREMENT_INDEX	= 110;
	localparam DETERMINE			= 111;
	localparam DONE				= 1000;
	
	
	logic [4:0] current_state/*synthesis keep*/;
	logic [4:0] next_state;
	
	logic [MSG_WIDTH-1:0] 	f;	
	
	// Flip flop to register the current state
	always_ff @(posedge clk) begin
		current_state <= next_state;
	end
	
	always_comb begin
		if(reset) next_state <= IDLE
		else begin
			case (current_state)
				IDLE: begin
					next_state <= WAIT_AVAIL;
				end
				WAIT_AVAIL: begin
					if(s_j_available)	next_state = SEND_S_ADDR; 	// Only register s[i] and s[j] when they are available
					else 					next_state = IDLE;
				end
				SEND_S_ADDR: begin
					next_state = WAIT_S_DATA;
				end
				WAIT_S_DATA: begin
					next_state = ASSIGN_F;
				end
				ASSIGN_F: begin
					next_state = DECRYPT;
				end
				DECRYPT: begin
					next_state = INCREMENT_INDEX;
				end
				INCREMENT_INDEX: begin
					next_state = DETERMINE;
				end
				DETEMINE: begin
					if (current_index == ({MSG_WIDTH,1'b1} + 1))  	next_state = DONE;
					else															next_state = WAIT_AVAIL;	
				end
				DONE: begin
					next_state = DONE;
				end
			endcase
		end
	end
	
	assign wn_en = 1'b0;					 				// Should never write into S
	
	always_ff @ (posedge clk) begin
		case (current_state)
			IDLE: begin
				current_index <= 0;
			end
			SEND_S_ADDR: begin
				address_out <= s_i + s_j;
			end
			ASSIGN_F: begin
				f <= s_data_in;
			end
			DECRYPT: begin
				decrypted_output[current_index] = f ^ encrypted_input[current_i];
			end
			INCREMENT_INDEX: begin
				current_index <= current_index + 1;
			end
		endcase
	end
	
endmodule
