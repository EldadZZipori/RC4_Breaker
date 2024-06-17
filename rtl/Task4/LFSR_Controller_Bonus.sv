`default_nettype none

/*
	LFSR_CONTROLLER_BONUS
	
	This module creates an LFSR used instead of a counter for brute forcing decryption. (NEW INPUT: initial_value)
	
	It has three operation modes controlled by OP_MODE
		0 				-	counter output has 22 bits 
		1			 	- 	counter output has 24 bits
		otherwise	-	counter output has 4 bits (for testing)
	Note that since this is an LFSR there is always one state missing - all 0s.
*/

module LFSR_Controller_Bonus
# (
	parameter OP_MODE = 2
)
(
	input		logic										clk,
	input 	logic										reset,
	input 	logic 									counter_read,
	input 	logic [(COUNTER_WIDTH-1):0]		initial_value,
	output 	logic [(COUNTER_WIDTH-1):0]		counter,
	output	logic										available,
	output	logic										counter_finished
);
	
	// Setting the counter to the correct width based on OP_MODE
	localparam COUNTER_WIDTH = (OP_MODE == 0)	?	22 :	
										(OP_MODE == 1) ?  24 : 4;
	// localparam SEED = {COUNTER_WIDTH{1'b1}};
										
	/* 
			TAP SELECTION TABLE 
			
			# Bits	|	Taps
				4			[2,3]
				22			[0,21]
				24			[0,2,3,23]
			
			Taken from LFSR_Lecture 3 Slide 7
	*/
	localparam BITS_4		=	4'b1001;
	localparam BITS_22	=	22'b10_0000_0000_0000_0000_0001;
	localparam BITS_24	=	24'b1000_0000_0000_0000_0000_1101;
	localparam TAPS 		=  (OP_MODE == 0)	?	BITS_22 : 
									(OP_MODE == 1) ? 	BITS_24 : BITS_4;
	
	
	/*
		STATE CONTROL
		
		state is encoded as follows
		[0-2]		state number
		3			available flag
		4			counter_finished flag
	*/
	localparam IDLE 		= 5'b00_000;
	localparam WAIT_READ	= 5'b01_010;
	localparam INCREMENT	= 5'b00_011;
	localparam LAST		= 5'b10_100;
	
	logic [4:0] current_state/*synthesis keep*/;
	logic [4:0] next_state;
	logic can_finish;
	
	assign available 			= current_state[3];
	assign counter_finished = current_state[4];
	
	// Flip flop to register the current state
	always_ff @(posedge clk) begin
		current_state <= next_state;
	end
	
	// Mux control to determine next state
	always_comb begin
		if (reset) next_state = IDLE;
		else begin
			case(current_state) 
				IDLE: begin
					next_state = WAIT_READ;
				end
				WAIT_READ: begin
					if ((counter == initial_value) & can_finish) 	next_state = LAST;			// when the counter reached the initial value assert counter_finished
					else if (!counter_read)			next_state = WAIT_READ;	// only increment to the next value when it was read by Master machine
					else next_state = INCREMENT;		
				end
				INCREMENT: begin
					next_state = WAIT_READ;
				end
				LAST: begin
					next_state = LAST;
				end
				default: next_state = IDLE;
			endcase
		end
	end
	
	always_ff @(posedge clk) begin
		if (reset | current_state == IDLE) begin
			counter <= initial_value;
			can_finish <= 0;
		end
		else if (current_state == INCREMENT) begin
			counter <= {counter[COUNTER_WIDTH-2:0],  ^(counter & TAPS)};	// Performs a many to one LFSR operation
		end
		else if ((current_state == WAIT_READ) & (counter != initial_value)) begin  // Allow counter to finish only when out of all 1's state
			can_finish <= 1;
		end
	end

endmodule