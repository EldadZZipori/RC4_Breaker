/*
	POPULATE S MEMORY BY INDEX
	
	Assigns each memory address in the s memory instance a value equal to its address
	
	for (i in 255) s[i] = i
*/
module populate_s_mem_by_index(
	input 	logic 	clk,
	input 	logic		reset,
	input		logic		start,
	
	output	logic[7:0]		address_out,
	output	logic[7:0]		data_out,
	output	logic				write_enable_out,
	output 	logic 			assign_by_index_done
);

	localparam IDLE 		= 0;
	localparam FIRST		= 1;
	localparam ASSIGN 	= 2;
	localparam WAIT		= 3;
	localparam DISEBLE	= 4;
	localparam FINISH 	= 5;
	
	logic [7:0] current_state, next_state;
	
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
	

	logic	[8:0] address;								// data_in and address_in is going to be exactlly the same s[i] = i
	logic 		write_enable;
	
	assign address_out 		= 	address[7:0];
	assign data_out			=	address[7:0];
	assign write_enable_out	= 	write_enable_out;
	
	always_ff @(posedge clk) begin
		if (reset) begin
			address <= 0;
			assign_by_index_done <= 1'b0;
		end
		else if (current_state == ASSIGN) begin
				address 					<= address + 1;
				assign_by_index_done <= 1'b0;
		end
		else if (current_state == WAIT) begin
			write_enable_out 		<= 1'b1;
		end
		else if (current_state == DISEBLE) begin
				write_enable_out 		<= 1'b0;
		end
		else if (current_state == FINISH) begin	
				write_enable_out		<= 1'b0;
				assign_by_index_done <= 1'b1;
		end		
	end
endmodule
