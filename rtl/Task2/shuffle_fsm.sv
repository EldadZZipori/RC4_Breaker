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
    input logic [23:0] secret_key,
    input logic [7:0] s,
	 input logic [7:0] index,
    
    // outputs
    output logic write_enable,
	 output logic sij_ready,
    output logic [7:0] data,
    output logic [7:0] address,
    output logic shuffle_finished
);
	
	logic 	  [7:0] a_i /*synthesis keep*/;
	logic 	  [7:0] a_j /*synthesis keep*/;
	logic 	  [7:0] k 			/*synthesis keep*/;
	logic 	  [7:0] s_i 		/*synthesis keep*/;
	logic 	  [7:0] temp		/*synthesis keep*/;
	
    
   // State register to hold the current state
   reg [6:0] state /*synthesis keep*/;      
    
     
   // State definitions using parameters
   localparam [6:0] IDLE            = 8'b0000_000;              // Check state
   localparam [6:0] MOD             = 8'b0001_000;              // Give state
   localparam [6:0] READ_SI         = 8'b0010_000;              // Waiting to finish
   localparam [6:0] ASSIGN_J        = 8'b0011_000;              // Registering data
   localparam [6:0] READ_SJ         = 8'b0100_000;              // Finishing
   localparam [6:0] SWAP        		= 8'b0101_000;              // Finishing
   localparam [6:0] WRITE_SJ        = 8'b0110_001;              // Finishing
   localparam [6:0] WRITE_SI        = 8'b0111_001;              // Finishing
   localparam [6:0] WAIT_FOR_I      = 8'b1000_010;              // Finishing
   localparam [6:0] FINISH          = 8'b1001_100;              // Finishing
    
   
	// assign outputs from state bit-wise
	assign write_enable = state[0];
	assign sij_ready = state[1];
   assign shuffle_finished = state[2];
	
     
    // State transition logic
    always_ff @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            a_j <= 0;
        end else begin
            case (state)
                IDLE: begin
                    state <= MOD;
                    a_i <= index;					// This starts at 0
                end

                MOD: begin
                    k <= a_i % KEY_LENGTH;
                    state <= READ_SI;
						  
                end

                READ_SI: begin
						  address <= a_i;
						  s_i <= s;
                    state <= ASSIGN_J;			// Wait one clock cycle to get s[i] from input s_i
                end

                ASSIGN_J: begin
						  a_j <= a_j + s_i + secret_key[k];
                    state <= READ_SJ;
                end

                READ_SJ: begin
						  address <= a_j;
                    state <= SWAP;
                end

                SWAP: begin
                    data <= s;
						  address <= a_i;
                    state <= WRITE_SJ;
                end

                WRITE_SJ: begin
                    data <= s_i;
						  address <= a_j;
                    state <= WRITE_SI;
                end

                WRITE_SI: begin
                    state <= WAIT_FOR_I;
                end

                WAIT_FOR_I: begin
                    if (a_i == 8'd255) begin
                        state <= FINISH;
                    end else if (a_i == index) begin
								state <= WAIT_FOR_I;
						  end	else if (secret_key == 23'd0) begin
								k <= a_i;
								state <= READ_SI;
						  end else begin
                        a_i <= index;
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