module de_data_writer(
	input logic clk,
	input logic reset,
	input logic	start,
	input logic[7:0] 	decrypted_data[31:0],
	
	output logic done
);

	decrypted_data_memory de_memory_controller(
		.address	(address),
		.clock	(clk),
		.data		(data),
		.wren		(write_enable_out),				
		.q			()									
	);
	
	localparam IDLE 		= 0;
	localparam FIRST		= 1;
	localparam ASSIGN 	= 2;
	localparam WAIT		= 3;
	localparam DISEBLE	= 4;
	localparam FINISH 	= 5;
	
	logic [7:0] current_state, next_state;
	
	logic write_enable_out;
	
	always_ff @(posedge clk) begin
		current_state <= next_state;
	end
	
	always_comb begin
		if(reset) begin
			next_state = IDLE;
		end
		else begin
			case (current_state) 
				IDLE: begin
					if(start) 	next_state = FIRST;
					else 			next_state = IDLE;
				end
				FIRST: begin
					next_state = WAIT;
				end
				ASSIGN: begin
					if (address < 255) 		next_state = WAIT;
					else						next_state = FINISH;
				end
				WAIT: begin
					next_state = DISEBLE;
				end
				DISEBLE: begin
					next_state = ASSIGN;
				end
				FINISH: begin
						next_state = FINISH;
				end
				default: next_state = IDLE;
			endcase
		end
	end
	

	logic	[8:0] address;
	logic [7:0] data;
	logic 		write_enable;
	

	
	always_ff @(posedge clk) begin
		if (reset) begin
			address <= 0;
			done	  <= 1'b0;
		end
		else if (current_state == ASSIGN) begin
				address 					<= address + 1;
		end
		else if (current_state == WAIT) begin
				data						<= decrypted_data[address];
				write_enable_out 		<= 1'b1;
		end	
		else if (current_state == DISEBLE) begin
				write_enable_out 		<= 1'b0;
		end
		else if (current_state == FINISH) begin	
				write_enable_out		<= 1'b0;
				done						<= 1'b1;
		end		
	end
endmodule
