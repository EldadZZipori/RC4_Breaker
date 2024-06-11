/*
	LFSR_CONTOLEER
	
	This module creates an LFSR used instead of a counter for brute forcing decryption.
	
	It has three operation modes controled by OP_MODE
		0 				-	counter output has 22 bits 
		1 				- 	counter output has 24 bits
		2				-	counter output has 8 bits
		otherwise	- 	counter output has 6 bits
	Note that since this is an LFSR there is always one state missing - all 0s.
*/

module LFSR_Controller
# (
	parameter OP_MODE = 0
)
(
	input		logic										clk,
	input 	logic										reset,
	input 	logic 									enable,
	output 	logic [(COUNTER_WIDTH-1):0]		counter
);
	
	// Setting the counter to the currect width based on OP_MODE
	localparam COUNTER_WIDTH = (OP_MODE == 0)	?	22 :			
										(OP_MODE == 1) ? 	24	:
										(OP_MODE == 2)	? 	8	:	6;
										
										
	/* 
			TAP SELECTION TABLE 
			
			# Bits	|	Taps
				6			[0,5]
				8			[1,2,3,7]
				22			[0,21]
				24			[0,2,3,23]
			
			Taken from LFSR_Lecutre 3 Slide 7
	*/
	localparam bits_6		=	6'b10_0001;
	localparam bits_8		=	8'b1000_1110;
	localparam bits_22	=	22'b10_0000_0000_0000_0000_0001;
	localparam bits_24	=	24'b1000_0000_0000_0000_0000_1101;
	
	always_ff @(posedge clk) begin
	
		if (reset) begin
			counter	<=	{COUNTER_WIDTH{1'b1}};										// Setting the initial value to be all 1's as it is the simplest
		end
		else if (enable) begin															// Only change counter when enable is high
			counter	<=	{counter[COUNTER_WIDTH-2:0], ^(counter & TAPS)};
		end
		
	end
endmodule
