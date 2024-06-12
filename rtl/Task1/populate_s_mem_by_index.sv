/*
	POPULATE S MEMORY BY INDEX
	
	Assigns each memory address in the s memory instance a value equal to its address
	
	for (i in 255) s[i] = i
*/
module populate_s_mem_by_index(
	input 	logic 	clk,
	input 	logic		reset,
	
	output	logic[7:0]		address_out,
	output	logic[7:0]		data_out,
	output	logic				write_enable_out,
	output 	logic 			assign_by_index_done
);

	logic	[8:0] address;						// data_in and address_in is going to be exactlly the same s[i] = i
	logic 		write_enable;
	
	assign address_out 		= 	address[7:0];
	assign data_out			=	address[7:0];
	assign write_enable_out	= 	write_enable_out;

	always_ff @(posedge clk) begin
		if (reset) address <= 0;
		else if (address != 256) begin
				address 					<= address + 1;
				write_enable_out 		<= 1'b1;
				assign_by_index_done <= 1'b0;
		end
		else 	begin	
			write_enable_out		<= 1'b0;
			assign_by_index_done <= 1'b1;
		end		
	end
endmodule
