module full_decryption_core
# (parameter SEED = {24{1'b1}})
(
	input logic 		CLOCK_50,
	input logic 		reset,
	input logic 		read_rom_done,
	input logic[7:0] 	rom_data_d[31:0],
	input logic 		start_core,
	input logic			stop_core,
	
	output logic[7:0] decrypted_data[31:0],
	output logic[23:0] secret_key,
	output logic 		core_done,
	output logic		found
);

	localparam IDLE 					= 0;
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
	
	logic start_determine;
	
	always_comb begin
		if (reset) begin
			next_state = IDLE;
		end
		else begin
			if(!stop_core) begin
				case(current_state)
					IDLE: begin
						if (start_core) 	next_state = START_GEN_KEY;
						else					next_state = IDLE;
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
			else begin
				next_state = current_state;
			end
		end
	end
	
	
	logic reset_state;
	
	always_ff @(posedge CLOCK_50) begin
		if(reset) begin
			key_read 			<= 1'b0;
			core_done 			<= 1'b0;
			reset_state 		<= 1'b0;
			new_key_available <= 1'b0;
			start_determine 	<= 1'b0;
			found					<= 1'b0;
		end
		else begin
			case(current_state)
				START_GEN_KEY: begin
					if(key_available) begin
						secret_key <= {2'b00, key_counter};
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
					if (out_of_keys)			core_done <= 1'b1;							
				end
				FOUND: begin
					found <= 1'b1;
					core_done <= 1'b1;
				end
				RESET: reset_state <= 1'b1;
			endcase
		end
	end
	
	
	//logic [23:0] secret_key;
	logic [21:0] key_counter;
	logic key_available;
	logic out_of_keys;
	logic key_read;
	
	LFSR_Controller # (.OP_MODE(0),.SEED(SEED))
	key_generator
	(
		.clk					(CLOCK_50),
		.reset				(1'b0),
		.counter_read		(key_read),
		.counter				(key_counter),
		.available			(key_available),
		.counter_finished	(out_of_keys)
	);
	
	*/
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
	

	logic decryption_done;
	logic new_key_available;
	
	decryption_core decryption_core1(
	  .clk								(CLOCK_50),
	  .reset								(reset_state | reset),
	  .stop								(1'b0),
	  .s_memory_address_in			(s_memory_address_in),
	  .s_memory_data_in				(s_memory_data_in),
	  .s_memory_data_enable			(s_memory_data_enable),
	  .s_memory_q_data_out			(s_memory_q_data_out),
	  .key_from_switches_changed	(1'b0),
	  .key_from_switches_available(1'b0),
	  .new_key_available				(new_key_available),
	  .ROM_mem_read					(read_rom_done),
	  .rom_data_d						(rom_data_d),
	  .secret_key						(secret_key),
	  .decrypted_data					(decrypted_data),
	  .done								(decryption_done)
	);
	
	logic determine_valid_finised;
	logic msg_valid;
	determine_valid_message
		# (
		.LOW_THRESHOLD			(97),    						// ASCII value for 'a'
		.HIGH_THRESHOLD		(122),  							// ASCII value for 'z'
		.SPECIAL					(32),          				// ASCII value for space ' '
		.END_INDEX				(31)        					// Last index to check (the entire message is 32)
	)
	validator
	(
		.CLOCK_50				(CLOCK_50),          		// Clock signal                        
		.reset					(reset_state | reset),     // Reset signal
		.decrypted_data		(decrypted_data),  			// Input decrypted data array
		.decrypt_done			(start_determine), 		 	// Signal indicating decryption is done                                                                    
		.key_valid				(msg_valid),      			// Output signal indicating if the key is valid
		.finish					(determine_valid_finised), // Output signal indicating the checking process is finished
	);

endmodule