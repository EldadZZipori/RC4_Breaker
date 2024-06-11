`default_nettype none
/*
	KSA
*/

module ksa
(
	input logic CLOCK_50

);

	/*
		S Memory Instance Controls
	*/
	logic	[7:0]	s_memory_address_in;
	logic [7:0] s_memory_data_in;
	logic			s_memory_data_enable;
	logic			s_memory_q_data_out;
	
	s_memory s_memory_controller(
		.address	(s_memory_address_in),
		.clock	(CLOCK_50),
		.data		(s_memory_data_in),
		.wren		(s_memory_data_enable),				
		.q			(s_memory_q_data_out)									
	);
	
	
	/*
		Task 1 
		Populating the S memory location by the address
	*/
	logic	[7:0]	by_index_address_out;
	logic [7:0] by_index_data_out;
	logic			by_index_data_enable;
	logic 		assign_by_index_done;
	
	populate_s_mem_by_index task1(
		.clk						(CLOCK_50),	
		.address_out			(by_index_address_out),
		.data_out				(by_index_data_out),
		.write_enable_out		(by_index_data_enable),
		.assign_by_index_done(assign_by_index_done)
		
	);
	
	
	/*
		MUX to control which signals conrtol the S memory
		[*] Move to module at the end
	*/
	always_comb begin
		if(!assign_by_index_done) begin
			s_memory_address_in	=	by_index_address_out;
			s_memory_data_in		=	by_index_data_out;
			s_memory_data_enable	=	by_index_data_enable;
		end
		else begin
			s_memory_address_in	=	0;
			s_memory_data_in		=	0;
			s_memory_data_enable	=	0;
		end
	end

endmodule 