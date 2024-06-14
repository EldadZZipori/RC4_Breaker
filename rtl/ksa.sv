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

	localparam IDLE 					= 7'b0000_000;
	localparam RESET					= 7'b0001_001;
	localparam START_S_I_I 			= 7'b0100_010;
	localparam S_I_I					= 7'b0100_011;
	localparam START_SHUFFLE		= 7'b0010_100;
	localparam SHUFFLE				= 7'b0010_101;
	localparam STRAT_SEC_SHUFFLE	= 7'b1000_111;
	localparam SEC_SHUFFLE			= 7'b1000_000;
	localparam FINAL					= 7'b0000_110;
	localparam READ_S_DATA			= 7'b1111_000;
	localparam DECRYPT				= 7'b1111_111;


	
	
	logic [7:0] current_state;
	logic start_s_i_i,
			start_shuffle,
			start_sec_shuffle,
			start_read_s_data,
			decrypt_done,
			reset_all;
			
	time_machine time_controller(
		.CLOCK_50(CLOCK_50),
		.key_from_switches_changed		(key_from_switches_changed),
		.key_from_switches_available	(key_from_switches_available),
		.assign_by_index_done			(assign_by_index_done),
		.shuffle_mem_finished			(shuffle_mem_finished),
		.sec_shuffle_done					(sec_shuffle_mem_finished),
		.s_data_read_done					(s_data_read_done),
		.decrypt_done 						(decrypt_done),
		
		.reset_all							(reset_all),
		.start_shuffle						(start_shuffle),
		.start_s_i_i						(start_s_i_i),
		.start_sec_shuffle				(start_sec_shuffle),
		.s_data_read_start				(start_read_s_data),
		.start_decrypt						(start_decrypt),
		.current_state						(current_state)
	);
	/*
		MUX to control which signals conrtol the S memory
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
				S_I_I: begin									// indicates s[i] = i is done
					s_memory_address_in	=	by_index_address_out;
					s_memory_data_in		=	by_index_data_out;
					s_memory_data_enable	=	by_index_data_enable;
				end
				SHUFFLE: begin						// indicates j = (j + s[i] + secret_key[i mod keylength]) and swap s[i[ and s[j] done
					s_memory_data_enable = shuffle_mem_write_enable;
					s_memory_data_in		=	shuffle_mem_data_out;
					s_memory_address_in	= shuffle_mem_address_out;
				end
				SEC_SHUFFLE: begin						
					s_memory_data_enable = sec_shuffle_mem_write_enable;
					s_memory_data_in		= sec_shuffle_mem_data_out;
					s_memory_address_in	= sec_shuffle_mem_address_out;
				end
				READ_S_DATA: begin
					s_memory_data_enable = 1'b0;
					s_memory_data_in		= 1'b0;
					s_memory_address_in	= s_reader_address_out;
				end
				DECRYPT: begin
					s_memory_data_enable = 1'b0;
					s_memory_data_in		= 1'b0;
					s_memory_address_in	= 0;
				end
				default: begin
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
		.clock	(CLOCK_50),
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
		.clk						(CLOCK_50),
		.start					(start_s_i_i),
		.address_out			(by_index_address_out),
		.data_out				(by_index_data_out),
		.write_enable_out		(by_index_data_enable),
		.assign_by_index_done(assign_by_index_done),
		.reset					(reset_all)
		
	);
	
	
	/*
		TASK 2
	*/
	
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
		 .CLOCK_50				(CLOCK_50),
		 .reset					(reset_all),
		 .start					(start_shuffle),
		 .secret_key			(secret_key),
		 //.secret_key			(24'b00000000_00000010_01001001),
		 .s_data_in				(s_memory_q_data_out),
		 .write_enable_out	(shuffle_mem_write_enable),
		 .data_for_s_write	(shuffle_mem_data_out),
		 .address_out			(shuffle_mem_address_out),
		 .sij_ready				(shuffle_mem_s_i_j_avail),
		 .shuffle_finished	(shuffle_mem_finished)
	); 
	
	/*
		Reading from ROM memory
	*/
	
	logic[7:0] 	rom_data[31:0];								// Registers all the ROMS data so it can be taken for several parallel computation
	logic[7:0] 	rom_q_data_out;
	logic[5:0]	rom_reader_address_out;
	logic			rom_reader_done;
	
	encrypted_data_memory rom_memory(
		.address	(rom_reader_address_out),
		.clock	(CLOCK_50 & (!rom_reader_done)),			// When rom_read_done flag is up stop reading
		.q			(rom_q_data_out)
	);
	
	read_rom_mem rom_d(
		.clk				(CLOCK_50),
		.reset			(1'b0),
		.start			(1'b1),
		.rom_q_data_in	(rom_q_data_out),	
		.done				(rom_reader_done),				// TODO: add to time machine to check this is actually done before reading rom_data!!!
		.address			(rom_reader_address_out),
		.rom_data		(rom_data)
	);

	
	/*
		Second Shuffle for decryption
	*/
	// TODO - remove second shuffle and integrate with decryptor
	/*
		Shuffle memory control
	*/
	logic	[7:0]	sec_shuffle_mem_data_out;
	logic [7:0]	sec_shuffle_mem_address_out;
	logic 		sec_shuffle_mem_s_i_j_avail;
	logic			sec_shuffle_mem_finished;
	logic			sec_shuffle_mem_write_enable;
	
	shuffle_fsm 
	# (	.KEY_LENGTH	(3),
			.START_INDEX(1),
			.END_INDEX	(31)
	) 
	sec_shuffle_control
	(    
		 .CLOCK_50				(CLOCK_50),
		 .reset					(reset_all),
		 .start					(start_sec_shuffle),
		 .secret_key			(24'b0),
		 //.secret_key			(24'b00000000_00000010_01001001),
		 .s_data_in				(s_memory_q_data_out),
		 .write_enable_out	(sec_shuffle_mem_write_enable),
		 .data_for_s_write	(sec_shuffle_mem_data_out),
		 .address_out			(sec_shuffle_mem_address_out),
		 .sij_ready				(sec_shuffle_mem_s_i_j_avail),
		 .shuffle_finished	(sec_shuffle_mem_finished)
	); 
	
	/*
		read and register reshuffled memory
	*/
	
	
	logic[7:0] 	s_data[255:0];								// Registers all the ROMS data so it can be taken for several parallel computation
	logic[7:0]	s_reader_address_out;
	logic			s_data_read_done;
	
	
	read_rom_mem #(.DEP(256),.WID(8)) s_data_reader(
		.clk				(CLOCK_50),
		.reset			(reset_all),
		.start			(start_read_s_data),
		.rom_q_data_in	(s_memory_q_data_out),	
		.done				(s_data_read_done),
		.address			(s_reader_address_out),
		.rom_data		(s_data)
	);
	
	/*
		Decryptions
	*/
	
	logic[7:0] 	decrypted_data[31:0];	
	logic start_decrypt;
	
	decryptor_fsm
	# (.MSG_DEP(32), .S_DEP(256), .MSG_WIDTH (8))
	decryptor_1
	(
		.clk					(CLOCK_50),
		.reset				(reset_all),
		.encrypted_input	(rom_data),
		.s_data				(s_data),
		.start				(start_decrypt),
		.decrypted_output	(decrypted_data),
		.done					(decrypt_done)
	);
endmodule 