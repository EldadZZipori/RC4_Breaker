/*
	SWITCHES FSM
	
	This module controlls the input from the 10 switches of the DE1 and displays them on the LEDS.
	
	In addition it provides the flag key_available when the key ready and key_change for one clock cycle when the key is changing.
*/

module switches_fsm(
	input  logic		CLOCK_50,
	input  logic		reset,
	input  logic[9:0] SW,
	
	output logic[9:0] LEDR,
	output logic[9:0]	secret_key,
	output logic		key_available,
	output logic		key_changed
);
	
	/*
		STATE CONTROL
		
		state is encoded as follows
		[0-1]		state number
		2			key_available flag
		3			key_change flag
	*/
	
	localparam IDLE 			=	4'b0000;
	localparam UPDATE_KEY	=	4'b1001;
	localparam OUTPUT_KEY	=	4'b0110;
	
	
	logic [3:0] current_state/*synthesis keep*/;
	logic [3:0] next_state;
	
	logic	[9:0] current_sw_position;
	assign current_sw_position = SW;
	
	assign key_available = current_state[2];
	assign key_changed 	= current_state[3];
	
	
	// Flip flop to register the current state
	always_ff @(posedge CLOCK_50) begin
		current_state <= next_state;
	end
	
	always_comb begin
		case (current_state)
			IDLE: begin
				next_state = UPDATE_KEY;
			end
			UPDATE_KEY: begin
				next_state = OUTPUT_KEY; 
			end
			OUTPUT_KEY: begin
				if (current_sw_position == secret_key) next_state = OUTPUT_KEY;	// only change the secret key when detecting that the SW positions has changed
				else												next_state = UPDATE_KEY;
			end
			default: next_state = IDLE;
		endcase
	end
	
	always_ff @(posedge CLOCK_50) begin
		if(current_state == UPDATE_KEY) secret_key <= current_sw_position;
	end
	
	assign LEDR = secret_key;
endmodule
