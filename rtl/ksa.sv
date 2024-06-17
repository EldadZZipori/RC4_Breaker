`default_nettype none
/*
	KSA
	
	This operates as the top module of this project.
	
	It is not an FSM. Here we are instantiating all the modules for this project.
*/

module ksa
(
	output	logic		 	reset,
	input 	logic 		CLOCK_50,
	input  	logic[9:0] 	SW,
	
	output 	logic[6:0] 	HEX0,
   output 	logic[6:0] 	HEX1,
   output 	logic[6:0] 	HEX2,
   output 	logic[6:0] 	HEX3,
   output 	logic[6:0] 	HEX4,
   output 	logic[6:0] 	HEX5,
	
	output 	logic[9:0] 	LEDR
);
	
	assign reset = SW[0];														// Manual control to reset the operation of the decryption cores
	
	
	/*
		Decryption cores that will operate in 
		parallel to decrypted the message
	*/
	parallel_cores
	# (.CORES (4)) cores_4
	(	
		.reset							(reset),
		.CLOCK_50						(CLOCK_50),
		.rom_data_d						(rom_data_d),							// The ROM memory (D) containing the encrypted message
		.read_rom_done					(read_rom_done),						// Flag that indicates that thr ROM memory (D) was read and decryption can begin
		.write_to_DE					(write_to_DE),							// Indication that a valid key was found to write to RAM memory (DE)
		.activated_decrypted_data	(activated_decrypted_data),		// Decrypted data to be written to RAM memory (DE)
		.secret_key_for_hex			(secret_key_for_hex),
		
		.LEDR_GOOD						(LEDR[0]),								// Success/Failiure indication
		.LEDR_BAD						(LEDR[9])
	);
	/*
		ROM memory (D) - Encrypted data (32 words x 8bits)
	*/
	
	logic[7:0] 	rom_data_d[31:0];												// Registers all the ROMS data so it can be taken for several parallel computation
	logic[7:0] 	rom_q_data_out;
	logic[5:0]	rom_reader_address_out;
	logic[7:0] 	rom_reader_data_out;
	logic 		rom_reader_enable;
	logic 		read_rom_start, read_rom_done;
	
	
	/*
		ROM memory (DE)
	*/
	assign read_rom_start = 1'b1;
	
	encrypted_data_memory rom_memory(
		.address	(rom_reader_address_out),
		.clock	(CLOCK_50 & (!read_rom_done)),							// When rom_read_done flag is up stop reading
		.q			(rom_q_data_out)
	);
	
	always_ff @(posedge CLOCK_50) begin										// Registering the ROM (DE) data so all cores can use if at the same time
		if (rom_reader_enable) rom_data_d[rom_reader_address_out] <= rom_reader_data_out;
	end
	
	read_rom_mem rom_d(
		.clk				(CLOCK_50),
		.reset			(1'b0),
		.start			(read_rom_start),
		.rom_q_data_in	(rom_q_data_out),	
		.done				(read_rom_done),				
		.address			(rom_reader_address_out),
		.rom_data		(rom_reader_data_out),
		.enable_output	(rom_reader_enable),
	);
	
	logic [23:0] 	secret_key_for_hex;
	
	/* 
		HEX Display Control
	*/
	HEX_Control Hex_Control_inst
	(
		.orig_clk			(CLOCK_50),
		.secret_key 		(secret_key_for_hex),
		.HEX0 				(HEX0),
		.HEX1 				(HEX1),
		.HEX2 				(HEX2),
		.HEX3 				(HEX3),
		.HEX4 				(HEX4),
		.HEX5 				(HEX5)
	);
	
	/*
		RAM Memory (DE) - Decrypted Data (32 words x 8bits)
	*/

	logic[7:0] 	activated_decrypted_data[31:0];
	logic write_to_DE;
	logic done_writing_to_de;

	de_data_writer de_writer(
		.clk				(CLOCK_50),
		.reset			(1'b0),
		.start			(write_to_DE),
		.decrypted_data(activated_decrypted_data),
		.done				(done_writing_to_de)
	);
endmodule 
