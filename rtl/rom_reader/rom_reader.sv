/*
	ROM READER
*/

module rom_reader(
	input logic 		CLOCK_50
);
	
	logic[7:0] 	rom_data[31:0];								// Registers all the ROMS data so it can be taken for several parallel computation
	logic[7:0] 	reader_data_out;
	logic[7:0] 	rom_q_data_out;
	logic[7:0]	rom_reader_address_out;
	logic			rom_reader_done;
	logic    	reader_write_enable;
	
	always_ff @(posedge CLOCK_50) begin
		if (reader_write_enable) rom_data[rom_reader_address_out] <= reader_data_out;
	end
	
	encrypted_data_memory rom_memory(
		.address	(rom_reader_address_out),
		.clock	(CLOCK_50 & (!rom_reader_done)),			// When rom_read_done flag is up stop reading
		.q			(rom_q_data_out)
	);
	
	read_rom_mem reader(
		.clk				(CLOCK_50),
		.reset			(1'b0),
		.start			(1'b1),
		.rom_q_data_in	(rom_q_data_out),	
		.done				(rom_reader_done),
		.address			(rom_reader_address_out),
		.rom_data		(reader_data_out),
		.enable_output	(reader_write_enable)
	);
endmodule
