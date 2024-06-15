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
		.secret_key		(),
		.key_available (key_from_switches_available),
		.key_changed	(key_from_switches_changed)					// This sends a reset to the other state machines
	);
	
	assign secret_key = {{14{1'b0}},LEDR};
	
	/*
		RAM Memory (s) - Working Memory (256 words x 8 bit)
	*/
	
	logic	[7:0]		s_memory_q_data_out;
	
	logic [7:0]	s_memory_address_in;
	logic [7:0] 	s_memory_data_in;
	logic			s_memory_data_enable;
	s_memory s_memory_controller(
		.address	(s_memory_address_in),
		.clock	(CLOCK_50),
		.data		(s_memory_data_in),
		.wren		(s_memory_data_enable),				
		.q			(s_memory_q_data_out)									
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

	
	decryption_core decryption_core1(
	  .clk								(CLOCK_50),
	  .reset								(1'b0),
	  .stop								(1'b0),
	  .s_memory_address_in			(s_memory_address_in),
	  .s_memory_data_in				(s_memory_data_in),
	  .s_memory_data_enable			(s_memory_data_enable),
	  .s_memory_q_data_out			(s_memory_q_data_out),
	  .key_from_switches_changed	(key_from_switches_changed),
	  .key_from_switches_available(key_from_switches_available),
	  .ROM_mem_read					(rom_reader_done),
	  .rom_data_d						(rom_data_d),
	  .secret_key						(secret_key),
	  .decrypted_data					(decrypted_data),
	  .done								(decryption_done)
	);
	
	logic[7:0] 	decrypted_data[31:0];
	logic decryption_done;
	
	
	/*
		RAM Memory (DE) - Decrypted Data (32 words x 8bits)
	*/
	de_data_writer(
	.clk				(CLOCK_50),
	.reset			(1'b0),
	.start			(decryption_done),
	.decrypted_data(decrypted_data),
	.done				()
	);
endmodule 
