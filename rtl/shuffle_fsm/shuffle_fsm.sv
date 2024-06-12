/*
    SHUFFLE S MEMORY (FINITE STATE MACHINE)
    
    Uses a state machine that shuffles the memory
    
    
*/
`default_nettype none

module shuffle_fsm
#( parameter KEY_LENGTH = 3)
     
(    // inputs
    input logic CLOCK_50,
    input logic reset,
    input logic assign_by_index_done,
    input logic [23:0] secret_key,
    input logic [7:0] s_i,
    input logic [7:0] s_j,
	 input logic [7:0] index,
    
    // outputs
    output logic write_en_i,
    output logic write_en_j,
	 output logic sij_ready,
    output logic [7:0] data_i,
    output logic [7:0] data_j,
    output logic [7:0] address_i,
    output logic [7:0] address_j,
    output logic shuffle_finished
);
	
	logic 	[7:0] i, j, k, temp;
   logic    [7:0] memory [255:0];                 // For storing the memory from s_memory
   logic    [7:0] current_q;
   logic    [8:0] address_in;                     // data_in and address_in is going to be exactly the same s[i] = i
   logic          write_enable;
    
    
   // State register to hold the current state
   reg [7:0] state;    
    
     
   // State definitions using parameters
   localparam [7:0] IDLE            = 8'b0000_0000;              // Check state
   localparam [7:0] MOD             = 8'b0001_0000;              // Give state
   localparam [7:0] READ_SI         = 8'b0010_0000;                // Waiting to finish
   localparam [7:0] ASSIGN_J        = 8'b0011_0000;              // Registering data
   localparam [7:0] READ_SJ         = 8'b0100_0000;              // Finishing
   localparam [7:0] WRITE_SI        = 8'b0101_0001;              // Finishing
   localparam [7:0] WRITE_SJ        = 8'b0110_0010;              // Finishing
   localparam [7:0] WAIT_FOR_I      = 8'b0111_0100;              // Finishing
   localparam [7:0] FINISH          = 8'b1000_1000;              // Finishing
    
   
	// assign outputs from state bit-wise
   assign write_en_j = state[0];
   assign write_en_i = state[1];
	assign sij_ready = state[2];
   assign shuffle_finished = state[3];
	
	// assign outputs from inputs
	assign address_i = i;
	assign address_j = j;
	
    
    // starting state
   initial begin
       state = IDLE;
		 i = index;
		 j = 0;
   end
     
     
    // State transition logic
    always_ff @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            j <= 0;
        end else begin
            case (state)
                IDLE: begin
                    state <= MOD;
                    i <= index;
                end

                MOD: begin
                    k <= i % KEY_LENGTH;
                    state <= READ_SI;
                end

                READ_SI: begin
                    state <= ASSIGN_J;
                end

                ASSIGN_J: begin
                    j <= j + s_i + secret_key[k];
                    state <= READ_SJ;
                end

                READ_SJ: begin
                    state <= WRITE_SI;
                end

                WRITE_SI: begin
						  temp <= data_i;
                    data_i <= data_j;
                    state <= WRITE_SJ;
                end

                WRITE_SJ: begin
                    data_j <= temp;
                    state <= WAIT_FOR_I;
                end

                WAIT_FOR_I: begin
                    if (i == 8'd255) begin
                        state <= FINISH;
                    end else if (i == index) begin
								state <= WAIT_FOR_I;
						  end	else if (secret_key == 23'd0) begin
								k <= i;
								state <= READ_SI;
						  end else begin
                        i <= index;
                        state <= MOD;
                    end
                end

                FINISH: begin
                    state <= FINISH;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
endmodule