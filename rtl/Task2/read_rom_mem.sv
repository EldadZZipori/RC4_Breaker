/*
	ROM READER
	
	This module reads the data from of the encrypted message from ROM memory (D)
	
	It takes the following parameters
	DEP	- The amount of words in the memory
	WID	- The number of bits in each word
*/

module read_rom_mem
# (parameter DEP = 32, parameter WID = 8)
(
	input logic 		clk,
	input logic			reset,
	input logic			start,
	input	logic[WID-1:0]	rom_q_data_in,
	
	output logic 		done,
	output logic[7:0]	address,
	output logic		enable_output,
	output logic[WID-1:0] rom_data
);
	
	localparam IDLE = 3'b000;
	localparam WAIT = 3'b100;
	localparam READ = 3'b001;
	localparam INC  = 3'b010;
	localparam DONE = 3'b011;
	
	logic[2:0] state;
	
	logic [8:0] current_index;
	//logic	[WID-1:0] rom_data_register[DEP-1:0] /*synthesis keep*/;
	
	//assign rom_data = rom_data_register;
	assign address = current_index[8:0];

	always_ff @(posedge clk) begin
		if (reset) begin
			current_index 	<= 0;
			state 			<= IDLE;
			done 				<= 1'b0;
			enable_output	<= 1'b0;
		end
		else begin
			case(state)
				IDLE:begin
					current_index 	<= 0;
					done 				<= 0;
					if(start) state 			<= WAIT;							// Only move out of ideal state when start is asserted by Master
				end
				WAIT: begin
					state <= READ;
				end
				READ: begin
					rom_data 								<= rom_q_data_in;
					enable_output							<= 1'b1;
					state 									<= INC;
					
					if(current_index == (DEP-1))		done 	<= 1'b1;		// Asserted FSM has finished opertation when all words are read
				end
				INC: begin
					enable_output							<= 1'b0;
					if (!done) begin												// Read ROM data into register until reaches number of words defined by module parameter
						current_index	<= current_index + 1;
						state				<=	WAIT;
					end
					else begin
						state <= DONE;
					end
				end
				DONE: begin
					state <= DONE;
				end
			endcase
		end
	end

endmodule
