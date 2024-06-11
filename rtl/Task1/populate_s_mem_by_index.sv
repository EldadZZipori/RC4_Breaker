/*
	POPULATE S MEMORY BY INDEX
	
	Assigns each memory address in the s memory instance a value equal to its address
	
	for (i in 255) s[i] = i
*/
module populate_s_mem_by_index(
	input logic CLOCK_50
);

	logic	[7:0] memory [255:0]; 				// For storing the memory from s_memory
	logic	[7:0] current_q;
	logic	[8:0] address_in;						// data_in and address_in is going to be exactlly the same s[i] = i
	logic 		write_enable;
	
	s_memory s_memory_controller(
		.address	(address_in[7:0]),
		.clock	(CLOCK_50),
		.data		(address_in[7:0]),
		.wren		(write_enable),				// write enable
		.q			()									// 8 bits output at a time
	);

	always_ff @(posedge CLOCK_50) begin
		if (address_in != 256) begin
				address_in 		<= address_in + 1;
				write_enable 	<= 1'b1;
		end
		else 	write_enable	<= 1'b0;
	end
	
endmodule
