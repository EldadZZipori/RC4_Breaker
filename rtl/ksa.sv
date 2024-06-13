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

	localparam IDLE 				= 6'b000_000;
	localparam RESET				= 6'b001_001;
	localparam START_S_I_I 		= 6'b100_010;
	localparam S_I_I				= 6'b100_011;
	localparam START_SHUFFLE	= 6'b010_100;
	localparam SHUFFLE			= 6'b010_101;
	localparam FINAL				= 6'b000_110;
	
	logic [7:0] current_state;
	logic start_s_i_i, start_shuffle, reset_all;
	time_machine(
		.CLOCK_50(CLOCK_50),
		.key_from_switches_changed		(key_from_switches_changed),
		.key_from_switches_available	(key_from_switches_available),
		.assign_by_index_done			(assign_by_index_done),
		.shuffle_mem_finished			(shuffle_mem_finished),
		
		.reset_all							(reset_all),
		.start_shuffle						(start_shuffle),
		.start_s_i_i						(start_s_i_i),
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
		 //.secret_key			(secret_key),
		 .secret_key			(24'b00000000_00000010_01001001),
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
	
	read_rom_mem(
		.clk				(CLOCK_50),
		.reset			(1'b0),
		.rom_q_data_in	(rom_q_data_out),	
		.done				(rom_reader_done),
		.address			(rom_reader_address_out),
		.rom_data		(rom_data)
	);

	


endmodule 