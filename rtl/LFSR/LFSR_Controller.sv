/*
	LFSR_CONTOLEER
	
	This module creates an LFSR used instead of a counter for brute forcing decryption.
	
	It has three operation modes controled by OP_MODE
		0 				-	counter output has 22 bits 
		1			 	- 	counter output has 24 bits
		otherwise	-	counter output has 4 bits (for testing)
	Note that since this is an LFSR there is always one state missing - all 0s.
*/

module LFSR_Controller
# (
	parameter OP_MODE = 2
)
(
	input		logic										clk,
	input 	logic										reset,
	input 	logic 									counter_read,
	output 	logic [(COUNTER_WIDTH-1):0]		counter,
	output	logic										available,
	output	logic										counter_finished
);
	
	// Setting the counter to the currect width based on OP_MODE
	localparam COUNTER_WIDTH = (OP_MODE == 0)	?	22 :	
										(OP_MODE == 1) ?  24 : 4;
	localparam SEED = {COUNTER_WIDTH{1'b1}};
										
										
	/* 
			TAP SELECTION TABLE 
			
			# Bits	|	Taps
				4			[2,3]
				22			[0,21]
				24			[0,2,3,23]
			
			Taken from LFSR_Lecutre 3 Slide 7
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
	localparam FIRST 		= 5'b00_001;
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
					next_state = FIRST;
				end
				FIRST: begin
					next_state = WAIT_READ;
				end
				WAIT_READ: begin
					if (!counter_read)			next_state = WAIT_READ;	// only increment to the next value when it was read by Master machine
					else begin
						if ((counter == SEED) & can_finish) 	next_state = LAST;			// when the counter reached the SEED value assert counter_finished
						else 												next_state = INCREMENT;
					end					
				end
				INCREMENT: begin
					next_state = WAIT_READ;
				end
				LAST: begin
					next_state = IDLE;
				end
				default: next_state = IDLE;
			endcase
		end
	end
	
	always_ff @(posedge clk) begin
		if (reset | current_state == IDLE) begin
			counter <= SEED;
			can_finish <= 0;
		end
		else if (current_state == INCREMENT) begin
			counter <= {counter[COUNTER_WIDTH-2:0],  ^(counter & TAPS)};	// Preformes a many to one LFSR operation
		end
		else if ((current_state == WAIT_READ) & (counter != SEED)) begin  // Allow counter to finish only when out of FIRST state
			can_finish <= 1;
		end
	end
	


endmodule	
