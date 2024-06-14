/*
	ROM READER
	
	Reads data from a memory location into a local register that can be changed.
	
	Can be used both for ROM and RAM. If used for RAM make sure to set enable to LOW when using this FSM.
	
	The parameters for this FSM are
	DEP	the amount of words in the memory
	WID	amount of bits in each word
*/

module read_rom_mem
# (parameter DEP = 32, parameter WID = 8)
(
	input logic 				clk,
	input logic					reset,
	input logic					start,					// FSM will only start when start is asserted
	input	logic[WID-1:0]		rom_q_data_in,			// The external data from the memory
	
	output logic 				done,						// done is asserted when all data was read into rom_data
	output logic[8:0]			address,					// address to be read from the external memory 
	output logic[WID-1:0] 	rom_data[DEP-1:0]
);
	
	localparam IDLE = 3'b000;
	localparam WAIT = 3'b100;
	localparam READ = 3'b001;
	localparam INC  = 3'b010;
	localparam DONE = 3'b011;
	
	logic[2:0] state;
	
	logic [8:0] current_index;
	logic	[WID-1:0] rom_data_register[DEP-1:0] /*synthesis keep*/;
	assign rom_data = rom_data_register;
	
	
	assign address = current_index[8:0];										// address is just the current index as this FSM reads the whole memory(defined by the modules parameters)

	always_ff @(posedge clk) begin
		if (reset) begin
			current_index 	<= 0;
			done 				<= 1'b0;
			state 			<= IDLE;
		end
		else begin
			case(state)
				IDLE:begin
					current_index 	<= 0;
					done 				<= 0;
					if(start) 
						state 		<= WAIT;											// Only starts FSM when start is asserted from Master	
				end
				WAIT: begin
					state <= READ;														// Every time address/index is changed, wait one clock cycle to ensure signal settles in memory 
				end
				READ: begin

					rom_data_register[current_index] <= rom_q_data_in;
					state 									<= INC;
					
					if(current_index == (DEP-1))		done 	<= 1'b1;			// When last address is read assert done
				end
				INC: begin
					if (!done) begin													// when FSM is done it goes to an idle state -> DONE until it is reset.
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
