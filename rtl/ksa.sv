`default_nettype none
/*
	KSA
*/

module ksa
(
	input logic CLOCK_50,
	input  logic[9:0] SW,
	
	output logic[9:0] LEDR
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
		TASK 1 
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
		.assign_by_index_done(assign_by_index_done),
		.reset					(key_from_switches_changed)
		
	);
	
	/*
		TASK 2
	*/
	
	/*
		Switch controls
	*/
	logic [23:0] secret_key;
	logic key_from_switches_available;
	logic key_from_switches_changed;
	
	switches_fsm key_switches_control(
		.CLOCK_50		(CLOCK_50),
		.reset			(1'b0),
		.SW				(SW),
		.LEDR				(LEDR),
		.secret_key		(secret_key[9:0]),
		.key_available (key_from_switches_available),
		.key_changed	(key_from_switches_changed)	
	);
	
	/*
		Shuffle memory control
	*/
	logic [8:0] shuffle_mem_index;
	logic	[7:0]	shuffle_mem_data_out;
	logic [7:0]	shuffle_mem_address_out;
	logic 		shuffle_mem_s_i_j_avail;
	logic			shuffle_mem_finished;
	logic			shuffle_mem_write_enable;
	
	/*shuffle_fsm shuffle_control # (.KEY_LENGTH(3))
	(    
		 .CLOCK_50				(CLOCK_50),
		 .reset					(key_from_switches_changed),
		 .secret_key			(secret_key),
		 .s						(s_memory_q_data_out),
		 .index					(shuffle_mem_index),
		 .write_enble			(shuffle_mem_write_enable)
		 .data					(shuffle_mem_data_out),
		 .address				(shuffle_mem_address_out),
		 .sij_ready				(shuffle_mem_s_i_j_avail),
		 .shuffle_finished	(shuffle_mem_finished)
	); */
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
		else if (!shuffle_mem_finished) begin
			s_memory_data_enable = 	shuffle_mem_write_enable;
			s_memory_data_in		=	shuffle_mem_data_out;
			s_memory_address_in	= 	shuffle_mem_address_out;
		end
		else begin
			s_memory_address_in	=	0;
			s_memory_data_in		=	0;
			s_memory_data_enable	=	0;
		end
	end

endmodule 