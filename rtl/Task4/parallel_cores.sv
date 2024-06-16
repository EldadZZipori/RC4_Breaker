module parallel_cores 
# (parameter CORES = 4)
(
	input logic 			CLOCK_50,
	
	input logic [7:0] 	rom_data[31:0],
	input logic				rom_data_read,
	
	output logic[7:0] 	decrypted_data[31:0],
	output logic 			correct_decryption,
	output logic[31:0]   secret_key,
	
	output logic 			LED_GOOD,
	output logic 			LED_BAD
);

	logic [(CORES-1):0] 	found_msg;
	logic [31:0]			corret_decrypted_data;
	
	//assign correct_decryption = |found_msg;
	
	genvar i;
	generate
	
		for (i=0; i < CORES; i++) begin				: GENERTATE_CORE
				/*
					RAM Memory (s) - Working Memory (256 words x 8 bit)
				*/
				/*
				logic	[7:0]	s_memory_q_data_out;
				
				logic [7:0]	s_memory_address_in;
				logic [7:0] s_memory_data_in;
				logic			s_memory_data_enable;
				s_memory s_memory_controller(
					.address	(s_memory_address_in),
					.clock	(CLOCK_50),
					.data		(s_memory_data_in),
					.wren		(s_memory_data_enable),				
					.q			(s_memory_q_data_out)									
				);

				logic 			new_key_available;
				logic [23:0] 	secret_key;
				
				decryption_core decryption_core1(
				  .clk								(CLOCK_50),
				  .reset								(reset_core),
				  .stop								(1'b0),
				  .s_memory_address_in			(s_memory_address_in),
				  .s_memory_data_in				(s_memory_data_in),
				  .s_memory_data_enable			(s_memory_data_enable),
				  .s_memory_q_data_out			(s_memory_q_data_out),
				  .key_from_switches_changed	(1'b0),
				  .key_from_switches_available(1'b0),
				  .new_key_available				(new_key_available),
				  .ROM_mem_read					(),
				  .rom_data_d						(rom_data),
				  .secret_key						(secret_key),
				  .decrypted_data					(decrypted_data),
				  .done								()
				);
				
				
				logic determine_valid_finised;
				determine_valid_message
				# (
					.LOW_THRESHOLD			(97),    						// ASCII value for 'a'
					.HIGH_THRESHOLD		(122),  							// ASCII value for 'z'
					.SPECIAL					(32),          				// ASCII value for space ' '
					.END_INDEX				(32)        					// Last index to check (the entire message is 32)
				)
				(
					.CLOCK_50				(CLOCK_50),          		// Clock signal                        
					.reset					(reset_core),              // Reset signal
					.decrypted_data		(decrypted_data),  			// Input decrypted data array
					.decrypt_done			(decryption_done), 		 	// Signal indicating decryption is done                                                                    
					.key_valid				(found_msg[i]),      		// Output signal indicating if the key is valid
					.finish					(determine_valid_finised), // Output signal indicating the checking process is finished
				);
		
				logic reset_core;
				always_ff @(posedge CLOCK_50) begin
					if(found_msg[i] & determine_valid_finised) 	reset_core <= 1'b0;
					else														reset_core <= 1'b1;
				end
				*/
		end
		
	endgenerate
	

endmodule
