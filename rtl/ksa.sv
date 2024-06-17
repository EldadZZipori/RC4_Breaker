`default_nettype none
/*
	KSA
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
	
	assign reset = SW[0];
	
	localparam IDLE 				= 0;
	localparam READ_ROM 			= 1;
	localparam START_CORES 		= 2;
	localparam WAIT_FOR_FIND 	= 3;
	localparam FOUND				= 4;
	localparam NOT_FOUND			= 5;
	
	logic read_rom_start, read_rom_done, start_cores, stop_cores;
	logic [3:0] key_found;
	logic [3:0] core_done;
	
	logic[7:0] 	decrypted_data[3:0][31:0];
	logic[23:0] secret_key [3:0];
	logic[2:0] 	found_index;
	
	logic [4:0] current_state, next_state;
	
	always_ff @(posedge CLOCK_50) begin
		current_state <= next_state;
	end
	
	always_comb begin
		if(reset) next_state = IDLE;
		else begin
			case (current_state)
				IDLE: begin
					next_state = READ_ROM;
				end
				READ_ROM: begin
					if (read_rom_done)	next_state = START_CORES;
					else						next_state = READ_ROM;
				end
				START_CORES: begin
					next_state = WAIT_FOR_FIND;
				end
				WAIT_FOR_FIND: begin
					if (|key_found) 			next_state = FOUND;
					else if (&core_done)		next_state = NOT_FOUND;
					else							next_state = WAIT_FOR_FIND; 
				end
			endcase
		end
	end
	
	always_ff @(posedge CLOCK_50) begin
		if (reset) begin
			read_rom_start <= 1'b0;
			start_cores		<= 1'b0;
			LEDR 				<= 0;
			write_to_DE 	<= 1'b0;
			stop_cores		<= 1'b0;
		end
		else begin
			case (current_state) 
				IDLE: begin
					read_rom_start <= 1'b0;
					start_cores		<= 1'b0;
					stop_cores		<= 1'b0;
				end
				READ_ROM: begin
					read_rom_start <= 1'b1;
				end
				START_CORES: begin
					read_rom_start <= 1'b0;
					start_core		<= 1'b1;
				end
				WAIT_FOR_FIND: begin
					start_core 		<= 1'b0;
				end
				FOUND: begin
					LEDR[0] 			<= 1'b1;
					write_to_DE		<= 1'b1;
					stop_core		<= 1'b1;
					case (key_found)
						0:	found_index <= 0;
						1:	found_index <= 1;
						2: found_index <= 2;
						3: found_index <= 3;
					
					endcase
				end
				NOT_FOUND: begin
					LEDR[9] 			<= 1'b1;
				end
			endcase
		end
	end	
	
	genvar i;
	generate 
		for (i=0; i<4; i++) begin
			full_decryption_core
			# (.SEED((i == 0) ? 22'h3FFFFF :
						(i == 1) ? 22'h3FFFED :
						(i == 2) ? 22'h3FF8 :
						22'h30001))
			(
				.CLOCK_50			(CLOCK_50),
				.reset				(reset),
				.read_rom_done		(read_rome_done),
				.rom_data_d			(rom_data_d),
				.start_core			(start_core),
				.stop_core			(stop_core),
						
				.secret_key			(secret_key[i]),		
				.decrypted_data   (decrypted_data[i]),		
				.core_done			(core_done[i]),
				.found				(key_found[i])
				);
			end		
	endgenerate
	/*
		ROM memory (D) - Encrypted data (32 words x 8bits)
	*/
	
	logic[7:0] 	rom_data_d[31:0];								// Registers all the ROMS data so it can be taken for several parallel computation
	logic[7:0] 	rom_q_data_out;
	logic[5:0]	rom_reader_address_out;
	logic[7:0] 	rom_reader_data_out;
	logic 		rom_reader_enable;
	
	encrypted_data_memory rom_memory(
		.address	(rom_reader_address_out),
		.clock	(CLOCK_50 & (!read_rom_done)),			// When rom_read_done flag is up stop reading
		.q			(rom_q_data_out)
	);
	
	always_ff @(posedge CLOCK_50) begin
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
	
	/* Controls the HEX display with secret_key*/
	HEX_Control Hex_Control_inst
	(
		.orig_clk			(CLOCK_50),
		.secret_key 		(secret_key),
		.HEX0 				(HEX0),
		.HEX1 				(HEX1),
		.HEX2 				(HEX2),
		.HEX3 				(HEX3),
		.HEX4 				(HEX4),
		.HEX5 				(HEX5)
	);
	
	logic [23:0] activated_secret_key;
	always_ff @(posedge CLOCK_50) begin
		if (|key_found) 	activated_secret_key <= secret_key[found_index];
		else					activated_secret_key <= secret_key[0];
	end

	logic write_to_DE;
	logic done_writing_to_de;
	/*
		RAM Memory (DE) - Decrypted Data (32 words x 8bits)
	*/
	de_data_writer de_writer(
		.clk				(CLOCK_50),
		.reset			(1'b0),
		.start			(write_to_DE),
		.decrypted_data(decrypted_data[found_index]),
		.done				(done_writing_to_de)
	);
endmodule 
