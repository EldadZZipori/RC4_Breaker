/*
	ROM READER
*/

module read_rom_mem
# (parameter DEP = 32, parameter WID = 8)
(
	input logic 		clk,
	input logic			reset,
	input logic			start,
	input	logic[WID-1:0]	rom_q_data_in,
	
	output logic 		done,
	output logic[8:0]	address,
	output logic[WID-1:0] rom_data[DEP-1:0]
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
	assign address = current_index[8:0];

	always_ff @(posedge clk) begin
		if (reset) begin
			current_index 	<= 0;
			state 			<= IDLE;
			done 				<= 1'b0;
		end
		else begin
			case(state)
				IDLE:begin
					current_index 	<= 0;
					done 				<= 0;
					if(start) state 			<= WAIT;
				end
				WAIT: begin
					state <= READ;
				end
				READ: begin

					rom_data_register[current_index] <= rom_q_data_in;
					state 									<= INC;
					
					if(current_index == (DEP-1))		done 	<= 1'b1;
				end
				INC: begin
					if (!done) begin
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
