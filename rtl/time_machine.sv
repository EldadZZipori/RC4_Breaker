/*
	TIME MACHINE
	
	This module manages the state of the three loops that create the decryption algorithem.
	
	It mostly takes in start and done flags from other FSM's and managed what should be the next state.
	
	outputs current_state for outside use.
	
*/


module time_machine(
	input logic CLOCK_50,						
	input logic reset,
	input logic key_from_switches_changed,					// Indicating that the position of the switches have been changes.
	input logic ROM_mem_read,
	input logic key_from_switches_available,				// Indicating the secret key have been synchronized
	input logic assign_by_index_done,						// Indicating s[i] = i is done
	input logic shuffle_mem_finished,						// Indicating the second loop that swaps s[i] and s[j] is done
	input logic	new_key_available,							// Allow state to move one from a reset

	input logic sec_shuffle_done,
	input logic s_data_read_done,								// Indicated that the s data has been read to a local register to be used in decryption
	input logic decrypt_done,									// Indicating decryption with some key is done
	
	output logic reset_all,										// Tells all FSM they need to reset as secret_key was changed
	
	output logic start_s_i_i,									// Initiates s[i] = i FSM (populate_s_mem_by_index)
	output logic start_shuffle,								// Initiates the second loop in the agorithem (shuffle_fsm)
	output logic start_sec_shuffle,
	output logic s_data_read_start,							//	Initiates the FSM that read the data in s into a local register (read_rom_mem)
	output logic start_decrypt,								// Tells last for loop to start (decryptor_fsm)
	output logic[7:0] current_state,							// For use outside this FSM to determine bus switching to read/write from memory locations
	
	output logic done
);

	localparam IDLE 					= 7'b0000_000;
	localparam RESET					= 7'b0001_001;
	localparam START_S_I_I 			= 7'b0100_010;
	localparam S_I_I					= 7'b0100_011;
	localparam START_SHUFFLE		= 7'b0010_100;
	localparam SHUFFLE				= 7'b0010_101;
	localparam FINAL					= 7'b0000_110;
	localparam READ_S_DATA			= 7'b1111_000;
	localparam DECRYPT				= 7'b1111_111;
	
	logic [7:0] next_state;
	
	
	/*
		all start flags are controlled internally by the relavent state
		NOTE done flags are controlled externally by each FSM
	*/
	assign reset_all 				= (current_state == RESET);
	assign start_shuffle 		= (current_state == START_SHUFFLE) | (current_state == SHUFFLE);
	assign start_s_i_i			= (current_state == START_S_I_I) | (current_state == S_I_I);
	assign s_data_read_start	= (current_state == READ_S_DATA);
	assign start_decrypt			= (current_state == DECRYPT);
	assign done						= (current_state == FINAL);
	
	
	// FF to register next_state
	always_ff @(posedge CLOCK_50) begin
		current_state <= next_state;
	end
	
	
	// Mux to determine an appropriate next state
	always_comb begin
		if (key_from_switches_changed | reset) begin											// When a switch key changed there is a new secret key. Trivially when reset is given reset all machines.
			next_state = RESET;
		end
		else begin
			case (current_state)
				IDLE: begin
					if(ROM_mem_read)						next_state = START_S_I_I;
					else										next_state = IDLE;
				end
				RESET: begin//TODO !!! add case for when new key is available
					if(key_from_switches_available | new_key_available) 	
																next_state = IDLE;					// Only move on from reset when a new key is actually available
					else										next_state = RESET;
				end
				START_S_I_I: begin
																next_state = S_I_I;
				end
				S_I_I: begin
					if (assign_by_index_done) 			next_state = START_SHUFFLE;		// Only move on to second for loop if first loop is done
					else 										next_state = S_I_I;
				end

				START_SHUFFLE: begin
																next_state = SHUFFLE;
				end
				SHUFFLE: begin																			// only read the data from s to local register when the second loop is done
					if (shuffle_mem_finished) 			next_state = READ_S_DATA;
					else										next_state = SHUFFLE;
				end
				READ_S_DATA: begin
					if(s_data_read_done)					next_state = DECRYPT;				// Start decryption only when when a local s register is available
					else										next_state = READ_S_DATA;
				end
				DECRYPT: begin
					if (decrypt_done)						next_state = FINAL;
					else										next_state = DECRYPT;
				end
				FINAL: begin
																next_state = FINAL;
				end
				default: next_state = FINAL;
			endcase
		end
	end


endmodule
