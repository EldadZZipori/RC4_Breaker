module parallel_cores 
# (parameter CORES = 4)
(
	input logic CLOCK_50,
	output logic LED_GOOD,
	output logic LED_BAD
);

	/*
		ROM memory (D) - Encrypted data (32 words x 8bits)
	*/
				
	logic[7:0] 	rom_data_d[31:0];								// Registers all the ROMS data so it can be taken for several parallel computation
	logic[7:0] 	rom_q_data_out;
	logic[5:0]	rom_reader_address_out;
	logic[7:0] 	rom_reader_data_out;
	logic			rom_reader_done;
	logic 		rom_reader_enable;
				
	encrypted_data_memory rom_memory(
		.address	(rom_reader_address_out),
		.clock	(CLOCK_50 & (!rom_reader_done)),			// When rom_read_done flag is up stop reading
		.q			(rom_q_data_out)
	);
				
	always_ff @(posedge CLOCK_50) begin
		if (rom_reader_enable) rom_data_d[rom_reader_address_out] <= rom_reader_data_out;
	end
				
	read_rom_mem rom_d(
		.clk				(CLOCK_50),
		.reset			(1'b0),
		.start			(1'b1),
		.rom_q_data_in	(rom_q_data_out),	
		.done				(rom_reader_done),				
		.address			(rom_reader_address_out),
		.rom_data		(rom_reader_data_out),
		.enable_output	(rom_reader_enable),
	);

	logic [(CORES-1):0] 	found_msg;
	logic [31:0]			corret_decrypted_data;
	
	
	genvar i;
	generate
	
		for (i=0; i < CORES; i++) begin				: GENERTATE_CORE
				/*
					RAM Memory (s) - Working Memory (256 words x 8 bit)
				*/
				
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
				  .ROM_mem_read					(rom_reader_done),
				  .rom_data_d						(rom_data_d),
				  .secret_key						(secret_key),
				  .decrypted_data					(decrypted_data),
				  .done								(decryption_done)
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
		end
		
	endgenerate
	
	logic[7:0] 	decrypted_data[31:0];
	logic decryption_done;
	
	/*
		RAM Memory (DE) - Decrypted Data (32 words x 8bits)
	*/
	de_data_writer(
	.clk				(CLOCK_50),
	.reset			(1'b0),
	.start			(|found_msg),
	.decrypted_data(decrypted_data),
	.done				()
	);

endmodule
