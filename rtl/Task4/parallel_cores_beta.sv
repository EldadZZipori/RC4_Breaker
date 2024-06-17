`default_nettype none

module parallel_cores_beta
# (parameter CORES = 4)
(
	input logic 			CLOCK_50,
	input logic [7:0] 	rom_data[31:0],
	input logic			   rom_data_read,
	
	output logic [7:0] 	decrypted_data[31:0],
	output logic 		   correct_decryption,
	output logic [23:0]  secret_key,
	
	output logic 		   LED_GOOD,
	output logic 		   LED_BAD
);

	logic [CORES-1:0] 	found_msg;
	logic [23:0]			final_secret_key;
	logic [7:0]			   final_decrypted_data[31:0];
	logic [23:0]         core_secret_key[CORES];
	logic [21:0]			core_key_counter[CORES];
	logic [7:0]          core_decrypted_data[CORES][31:0];

	assign correct_decryption = |found_msg;

	always_ff @(posedge CLOCK_50) begin
		if (correct_decryption) begin
			LED_GOOD <= 1'b1;
			LED_BAD <= 1'b0;
		end else begin
			LED_GOOD <= 1'b0;
			LED_BAD <= 1'b1;
		end
	end

	always_ff @(posedge CLOCK_50) begin
		if (correct_decryption) begin
			for (int i = 0; i < CORES; i++) begin
				if (found_msg[i]) begin
					final_secret_key <= core_secret_key[i];
					for (int j = 0; j < 32; j++) begin
						final_decrypted_data[j] <= core_decrypted_data[i][j];
					end
				end
			end
		end
	end

	genvar i;
	generate
		for (i = 0; i < CORES; i++) begin: GENERATE_CORE
			logic reset_core;
			logic core_decryption_done;
			logic core_determine_valid_finished;
			logic key_available;
			logic out_of_keys;
			logic key_read;

			// LFSR for brute force key generation with specified initial values
			LFSR_Controller_Bonus #(
				.OP_MODE(0)
			) key_generator (
				.clk						(CLOCK_50),
				.reset					(reset_core),
				.counter_read			(key_read),
				.initial_value(
					(i == 0) ? 22'h3FFFFF :
					(i == 1) ? 22'h3FFFED :
					(i == 2) ? 22'h3FF8 :
					22'h30001
				),
				.counter					(core_secret_key[i][21:0]),
				.available				(key_available),
				.counter_finished		(out_of_keys)
			);

			// Memory for decryption core
			logic [7:0] s_memory_q_data_out;
			logic [7:0] s_memory_address_in;
			logic [7:0] s_memory_data_in;
			logic s_memory_data_enable;

			s_memory s_memory_controller (
				.address			(s_memory_address_in),
				.clock			(CLOCK_50),
				.data				(s_memory_data_in),
				.wren				(s_memory_data_enable),                
				.q					(s_memory_q_data_out)
			);

			// Decryption core
			decryption_core decryption_core_inst (
				.clk										(CLOCK_50),
				.reset									(reset_core),
				.stop										(1'b0),
				.s_memory_address_in					(s_memory_address_in),
				.s_memory_data_in						(s_memory_data_in),
				.s_memory_data_enable				(s_memory_data_enable),
				.s_memory_q_data_out					(s_memory_q_data_out),
				.key_from_switches_changed			(1'b0),
				.key_from_switches_available		(1'b0),
				.new_key_available					(key_available),
				.ROM_mem_read							(rom_data_read),
				.rom_data_d								(rom_data),
				.secret_key								({2'b00,core_secret_key[i]}),
				.decrypted_data						(core_decrypted_data[i]),
				.done										(core_decryption_done)
			);

			// Validator for decrypted message
			determine_valid_message # (
				.LOW_THRESHOLD		(97),     // ASCII value for 'a'
				.HIGH_THRESHOLD	(122),   // ASCII value for 'z'
				.SPECIAL				(32),           // ASCII value for space ' '
				.END_INDEX			(32)          // Last index to check (the entire message is 32)
			) validator (
				.CLOCK_50			(CLOCK_50),
				.reset				(reset_core),
				.decrypted_data	(core_decrypted_data[i]),
				.decrypt_done		(core_decryption_done),
				.key_valid			(found_msg[i]),
				.finish				(core_determine_valid_finished)
			);

			// Reset logic
			always_ff @(posedge CLOCK_50) begin
				if (found_msg[i] & core_determine_valid_finished) 	reset_core <= 1'b0;
				else													reset_core <= 1'b1;
			end

		end
	endgenerate
	
	assign secret_key = final_secret_key;
	assign decrypted_data = final_decrypted_data;

endmodule
