/*
	DECRYPTION CORE
	
	This module is a complete FSM of many other FSM's that preforme the decryption algorithem.
	
	NOTE: time machine is the FSM that controlles the transition of this FSM (timing) while the logic of this FSM
			(controls) are inside this module directly.
*/

module decryption_core(
	input logic 			clk,									
	input logic 			reset,								// reset must be given before new_key_available can be used again to check a new key
	
	input logic 			key_from_switches_changed,		// resets the state machine when switches have changed
	input logic 			key_from_switches_available,	// another start flag for this fsm only when the new switches position are available, for switches control
	input logic				new_key_available,				// start flag for this start machine, only when a new key is available, LFSR control
	
	input logic 			ROM_mem_read,						// Flag to ensure that the ROM data was actually registered already
	input logic[7:0] 		rom_data_d[31:0],					// Encrypted data to be decrpted by this FSM
	input logic [23:0] 	secret_key,							// Secret key provided by switches or LFSR
	
	output logic[7:0] 	decrypted_data[31:0],			// Result decrpted data to be determined if right by another FSM
	output logic 			done									// asserted when this core has finished processing a given key
	
 
);
	/*
		These states all come from time machine that manages the time of the decryption cores
	*/

	localparam IDLE 					= 7'b0000_000;
	localparam RESET					= 7'b0001_001;
	localparam START_S_I_I 			= 7'b0100_010;
	localparam S_I_I					= 7'b0100_011;
	localparam START_SHUFFLE		= 7'b0010_100;
	localparam SHUFFLE				= 7'b0010_101;
	localparam READ_S_DATA			= 7'b1111_000;
	localparam DECRYPT				= 7'b1111_111;
	localparam FINAL					= 7'b0000_110;
	
	logic [7:0] current_state;
	
	/*
		start flags for all internal FSMS
	*/
	logic start_s_i_i,											// populate_s_mem_by_index 	- s[i] = i
			start_shuffle,											// shuffle_fsm 					- second for loop
			start_read_s_data,									// read_rom_mem 					- s_data 
			start_decrypt,											// decryptor_fsm					- decryptor_fsm
			reset_all;												// reset all FSMs to initial state if switches have changed or a new key is going to be given
			
			
	time_machine time_controller(
		.CLOCK_50(clk),
		.reset(reset),
		
		.ROM_mem_read(ROM_mem_read),
		.key_from_switches_changed		(key_from_switches_changed),
		.key_from_switches_available	(key_from_switches_available),
		.new_key_available				(new_key_available),
		.reset_all							(reset_all),
		
		/*
			Done flags for all the internal state machines
			to move to next state in time machine
		*/
		.assign_by_index_done			(assign_by_index_done),				// populate_s_mem_by_index 	- s[i] = i
		.shuffle_mem_finished			(shuffle_mem_finished),				// shuffle_fsm 					- second for loop
		.s_data_read_done					(s_data_read_done),					// read_rom_mem 					- s_data 
		.decrypt_done 						(decrypt_done),						// decryptor_fsm					- decryptor_fsm
		
		/*
			Start flags to initiate all intermal state machine
			to begin operation
		*/
		.start_s_i_i						(start_s_i_i),							// populate_s_mem_by_index 	- s[i] = i
		.start_shuffle						(start_shuffle),						// shuffle_fsm 					- second for loop
		.s_data_read_start				(start_read_s_data),					// read_rom_mem 					- s_data 
		.start_decrypt						(start_decrypt),						// decryptor_fsm					- decryptor_fsm
		
		
		.current_state						(current_state),
		.done									(done)									// asserted when this core has finished processing a given key
	);
	
	
	/*
		MUX to control which FSM is in control of the S memory writer
		[*] Move to module at the end
	*/
	always_comb begin
		if(reset_all) begin
				s_memory_address_in	=	0;
				s_memory_data_in		=	0;
				s_memory_data_enable	=	0;
		end
		else begin
			case(current_state)
				S_I_I: begin															// Writing into S state						
					s_memory_address_in	=	by_index_address_out;
					s_memory_data_in		=	by_index_data_out;
					s_memory_data_enable	=	by_index_data_enable;
				end
				SHUFFLE: begin															// Writing into S state
					s_memory_data_enable = shuffle_mem_write_enable;
					s_memory_data_in		=	shuffle_mem_data_out;
					s_memory_address_in	= shuffle_mem_address_out;
				end
				READ_S_DATA: begin													// Reading into S state
					s_memory_data_enable = 1'b0;
					s_memory_data_in		= 1'b0;
					s_memory_address_in	= s_reader_address_out;
				end
				default: begin															// No change to S in any other case
					s_memory_address_in	=	0;
					s_memory_data_in		=	0;
					s_memory_data_enable	=	0;
				end
			endcase
		end
	end
	
	/*
		S Memory Instance Controls
	*/
	logic	[7:0]	s_memory_address_in;
	logic [7:0] s_memory_data_in;
	logic			s_memory_data_enable;
	logic	[7:0]	s_memory_q_data_out;
	
	s_memory s_memory_controller(
		.address	(s_memory_address_in),
		.clock	(clk),
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
		.clk						(clk),
		.start					(start_s_i_i),
		.address_out			(by_index_address_out),
		.data_out				(by_index_data_out),
		.write_enable_out		(by_index_data_enable),
		.assign_by_index_done(assign_by_index_done),
		.reset					(reset_all)
		
	);
	
	
	/*
		Shuffle memory control
	*/
	logic	[7:0]	shuffle_mem_data_out;
	logic [7:0]	shuffle_mem_address_out;
	logic 		shuffle_mem_s_i_j_avail;
	logic			shuffle_mem_finished;
	logic			shuffle_mem_write_enable;
	
	shuffle_fsm #(.KEY_LENGTH(3)) 
	shuffle_control
	(    
		 .CLOCK_50				(clk),
		 .reset					(reset_all),
		 .start					(start_shuffle),
		 .secret_key			(secret_key),
		 .s_data_in				(s_memory_q_data_out),
		 .write_enable_out	(shuffle_mem_write_enable),
		 .data_for_s_write	(shuffle_mem_data_out),
		 .address_out			(shuffle_mem_address_out),
		 .sij_ready				(shuffle_mem_s_i_j_avail),
		 .shuffle_finished	(shuffle_mem_finished)
	);
	
	
	/*
		read and register  memory
	*/
	logic[7:0] 	s_data[255:0];								// Registers all the ROMS data so it can be taken for several parallel computation
	logic[7:0]	s_reader_address_out;
	logic[7:0]	s_reader_data_out;
	logic			s_data_read_done;
	logic    	reader_write_enable;
	
	
	/*
		MUX + FF to allow writing into a local s_data register
		This will allow us to parallelize even more in the future so we 
		dont need to access S memory directly for decryption.
	*/
	always_ff @(posedge clk) begin
		if (current_state == READ_S_DATA) begin
			if (reader_write_enable) begin
					s_data[s_reader_address_out] <= s_reader_data_out;
			end
		end
		else if (current_state == DECRYPT) begin
			if(decrypt_enable) begin
				s_data[decryptor_address_out] <= decryptor_data_out;
			end
		end
	end
	
	read_rom_mem #(.DEP(256),.WID(8)) s_data_reader(
		.clk				(clk),
		.reset			(reset_all),
		.start			(start_read_s_data),
		.rom_q_data_in	(s_memory_q_data_out),	
		.done				(s_data_read_done),
		.address			(s_reader_address_out),
		.rom_data		(s_reader_data_out),
		.enable_output	(reader_write_enable)
	);
	
	/*
		Decryptions
	*/
	
	logic 			decrypt_enable;
	logic 			decrypt_done;
	logic[255:0] 	decryptor_address_out;
	logic[7:0] 		decryptor_data_out;
	
	decryptor_fsm
	# (.MSG_DEP(32), .S_DEP(256), .MSG_WIDTH (8))
	decryptor_1
	(
		.clk					(clk),
		.reset				(reset_all),
		.encrypted_input	(rom_data_d),
		.s_data				(s_data),
		.start				(start_decrypt),
		.decrypted_output	(decrypted_data),
		.done					(decrypt_done),
		.enable_write		(decrypt_enable),
		.address_out		(decryptor_address_out),
		.data_out			(decryptor_data_out)
	);

endmodule
