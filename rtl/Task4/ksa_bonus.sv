`default_nettype none
/*
	KSA
*/

module ksa_bonus
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
	
	localparam IDLE 					= 0;
	localparam START_READ_ROM_D 	= 1;
	localparam READ_ROM_D			= 2;
	localparam START_GEN_KEY		= 3;
	localparam GEN_KEY				= 4;
	localparam DECRYPT				= 5;
	localparam DETERMINE				= 6;
	localparam FOUND					= 7;
	localparam NOT_FOUND				= 8;
	localparam RESET					= 9;
	
	logic [5:0] current_state, next_state;
	
	always_ff @(posedge CLOCK_50) begin
		current_state <= next_state;
	end
	
	logic read_rom_start, read_rom_done, start_determine;
	
	always_comb begin
		if (reset) begin
			next_state = IDLE;
		end
		else begin
			case(current_state)
				IDLE: next_state = START_READ_ROM_D;
				START_READ_ROM_D: begin
						next_state = READ_ROM_D;
				end
				READ_ROM_D: begin
					if(read_rom_done) 	next_state = START_GEN_KEY;
					else						next_state = READ_ROM_D;
				end
				START_GEN_KEY: begin
					if (key_available)	next_state = GEN_KEY;
					else						next_state = START_GEN_KEY;
				end
				GEN_KEY: 					next_state = DECRYPT;
				DECRYPT: begin
					if(decryption_done) 	next_state = DETERMINE;
					else						next_state = DECRYPT;
				end
				DETERMINE: begin
					if(determine_valid_finised) begin
						if(msg_valid)			next_state = FOUND;
						else if(out_of_keys) next_state = NOT_FOUND;
						else 						next_state = RESET;
					end
					else 							next_state = DETERMINE;
					
				end
				RESET: next_state = START_GEN_KEY;
				FOUND: next_state = FOUND;
				NOT_FOUND: begin
					next_state = NOT_FOUND;
				end
				default:	next_state = IDLE;
			endcase
		end
	end
	
	
	logic reset_state;
	
	always_ff @(posedge CLOCK_50) begin
		if(reset) begin
			key_read 			<= 1'b0;
			read_rom_start 	<= 1'b0;
			LEDR 					<= 0;
			reset_state 		<= 1'b0;
			new_key_available <= 1'b0;
			start_determine 	<= 1'b0;
			write_to_DE			<= 1'b0;
		end
		else begin
			case(current_state)
				START_READ_ROM_D: begin
											read_rom_start <= 1'b1;
				end
				READ_ROM_D:				read_rom_start <= 1'b0;
				START_GEN_KEY: begin
					if(key_available) begin
						key_read <= 1'b1;
						 start_determine <= 1'b0;
					end
					
					
					reset_state <= 1'b0;
				end
				GEN_KEY: key_read <= 1'b0;
				DETERMINE: start_determine <= 1'b1;
				DECRYPT: begin
					new_key_available <= 1'b1;
					
					//if(secret_key == 24'b1001001001) LEDR[5] <= 1'b1;
				end
				NOT_FOUND: begin
					if (out_of_keys)			LEDR[9] <= 1'b1;							
				end
				FOUND: begin
					LEDR[0] <= 1'b1;
					write_to_DE <= 1'b1;
				end
				RESET: reset_state <= 1'b1;
			endcase
		end
	end
	
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
	
	
	logic [23:0] secret_key;
	logic key_available;
	logic out_of_keys;
	logic key_read;
	
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

	logic[7:0] 	decrypted_data[31:0];
	logic decryption_done;
	logic new_key_available;
	
	logic determine_valid_finised;
	logic msg_valid;

	logic write_to_DE;
	logic done_writing_to_de;
	
	/*
		RAM Memory (DE) - Decrypted Data (32 words x 8bits)
	*/
	de_data_writer de_writer(
		.clk				(CLOCK_50),
		.reset			(1'b0),
		.start			(write_to_DE),
		.decrypted_data(decrypted_data),
		.done				(done_writing_to_de)
	);
	
	
	 /*
        BONUS: 4 PARALLEL CORES
    */
    logic correct_decryption;
    parallel_cores_beta # (.CORES(4)
    ) bonus_inst (
        .CLOCK_50              (CLOCK_50),
        .rom_data              (rom_data_d),
        .rom_data_read         (read_rom_done),
		  .key_read					 (key_read),
        .secret_key            (secret_key),
		  .start_determine		 (start_determine),
        .decrypted_data        (decrypted_data),
        .correct_decryption    (msg_valid),
        .LED_GOOD              (),
        .LED_BAD               ()    
    );
	 
endmodule 
