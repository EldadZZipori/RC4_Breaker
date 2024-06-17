/*
	PARALLEL CORES
	
	This is an FSM to instintiate multiple cores to decrypt a message
	
	It takes one paramer CORES that determine how many cores to create.
*/

module parallel_cores
# (parameter CORES = 4)
(
	input logic				reset,
	input logic 			CLOCK_50,
	
	input logic [7:0] 	rom_data_d[31:0],						// The data from the ROM memory
	input logic				read_rom_done,							// indication the ROM data is ready
	
	output logic[7:0] 	activated_decrypted_data[31:0],	// the decrypted data of a correct message
	output logic [23:0] 	secret_key_for_hex,					// a secret key that is currently beening processed to display on the HEX display
	output logic 			write_to_DE,							// Asserted when a valid key is found to write the decrypted message to the RAM (DE) memory
	output logic			LEDR_GOOD,
	output logic 			LEDR_BAD
);

	localparam IDLE 				= 0;
	localparam READ_ROM 			= 1;
	localparam START_CORES 		= 2;
	localparam WAIT_FOR_FIND 	= 3;
	localparam FOUND				= 4;
	localparam WRITE_DE			= 6;
	localparam NOT_FOUND			= 5;
	
	logic start_cores, stop_cores;
	logic [(CORES-1):0] key_found;
	logic [(CORES-1):0] core_done;
	
	logic[7:0] 	decrypted_data[3:0][31:0];
	logic[23:0] secret_key [3:0];
	
	logic [4:0] current_state, next_state;
	
	always_ff @(posedge CLOCK_50) begin
		current_state <= next_state;
	end
	
	always_comb begin
		if(reset) next_state = IDLE;
		else begin
			case (current_state)
				IDLE: begin
					if (read_rom_done)	next_state = START_CORES;
					else 						next_state = IDLE;
				end
				START_CORES: begin
					next_state = WAIT_FOR_FIND;
				end
				WAIT_FOR_FIND: begin
					if (|key_found) 			next_state = FOUND;							// If any core finds the key
					else if (&core_done)		next_state = NOT_FOUND;						// If all cores are done but no key was found
					else							next_state = WAIT_FOR_FIND; 
				end
				FOUND: next_state = WRITE_DE;
				NOT_FOUND: next_state = NOT_FOUND;
				WRITE_DE: next_state = WRITE_DE;
				default: next_state = IDLE;
			endcase
		end
	end
	
	always_ff @(posedge CLOCK_50) begin
		if (reset) begin
			start_cores		<= 1'b0;
			LEDR_GOOD		<= 1'b0;
			LEDR_BAD			<= 1'b0;
			write_to_DE 	<= 1'b0;
			stop_cores		<= 1'b0;
		end
		else begin
			case (current_state) 
				IDLE: begin
					start_cores		<= 1'b0;
					stop_cores		<= 1'b0;
				end
				START_CORES: begin
					start_cores		<= 1'b1;
				end
				WAIT_FOR_FIND: begin
					start_cores 	<= 1'b0;
				end
				FOUND: begin
					LEDR_GOOD		<= 1'b1;			// Indication that a valid key was found
					stop_cores		<= 1'b1;
				end
				WRITE_DE: begin
					write_to_DE		<= 1'b1;
				end
				NOT_FOUND: begin
					LEDR_BAD			<= 1'b1;			// Indication that no valid key was found in the search space.
				end
			endcase
		end
	end	
	
	genvar i;
	
	/*
		NOTE: to find the initial values for each LFSR inside the decryption core we used a python code to determine
				what bit values occures at 1/4, 2/4, and 3/4 of the sequance.
	*/
	generate 
		for (i=0; i<4; i++) begin				:GENERATE_CORES
			full_decryption_core										
			# (.SEED((i == 0) ? 22'h3FFFFF :
						(i == 1) ? 22'h3F07FF :
						(i == 2) ? 22'h3FF800 :
						22'h1F001F))
			(
				.CLOCK_50			(CLOCK_50),
				.reset				(reset),
				.read_rom_done		(read_rom_done),
				.rom_data_d			(rom_data_d),
				.start_core			(start_cores),
				.stop_core			(stop_cores),
						
				.secret_key			(secret_key[i]),		
				.decrypted_data   (decrypted_data[i]),		
				.core_done			(core_done[i]),
				.found				(key_found[i])
				);
				
			end		
	endgenerate
	
	
	int j;
	always_ff @(posedge CLOCK_50) begin												
		for (j=0; j<4; j++) begin : DETERMINE_DECRYPTED_DATA
			if (key_found[j] == 1'b1) begin
				activated_secret_key_found <= secret_key[j];
				activated_decrypted_data	<= decrypted_data[j];
			end
		end
	end
	
	assign activated_secret_key = secret_key[0];
	always_comb begin
		if (|key_found) secret_key_for_hex = activated_secret_key_found;
		else begin
			secret_key_for_hex = activated_secret_key;
		end
	end
	
	logic [23:0] activated_secret_key_found;
	logic [23:0] activated_secret_key;
	

endmodule
