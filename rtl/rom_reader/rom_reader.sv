/*
	ROM READER
*/

module rom_reader(
	input logic 		clk,
	input logic			reset,
	input	logic[7:0]	rom_q_data_in,
	
	output logic 		done,
	output logic[5:0]	address,
	output logic[7:0] rom_data[31:0]
);
	
	localparam IDLE = 3'b000;
	localparam WAIT = 3'b100;
	localparam READ = 3'b001;
	localparam INC  = 3'b010;
	localparam DONE = 3'b011;
	
	logic[2:0] state;
	
	logic [6:0] current_index;
	logic	[7:0] rom_data_register[31:0] /*synthesis keep*/;
	
	assign rom_data = rom_data_register;
	assign address = current_index[5:0];

	always_ff @(posedge clk) begin
		if (reset) begin
			current_index 	<= 0;
			state 			<= IDLE;
		end
		else begin
			case(state)
				IDLE:begin
					current_index 	<= 0;
					done 				<= 0;
					state 			<= WAIT;
				end
				WAIT: begin
					state <= READ;
				end
				READ: begin
					if(current_index == 32) state <= DONE;
					else begin
						rom_data_register[current_index] <= rom_q_data_in;
						state 									<= INC;
					end
				end
				INC: begin
					current_index	<= current_index + 1;
					state				<=	READ;
				end
				DONE: begin
					done 	<= 1'b1;
					state <= DONE;
				end
			endcase
		end
	end

endmodule
