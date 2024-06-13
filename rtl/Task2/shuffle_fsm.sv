/*
    SHUFFLE S MEMORY (FINITE STATE MACHINE)
    
    Uses a state machine that shuffles the memory
    
    
*/
`default_nettype none

module shuffle_fsm
#( parameter KEY_LENGTH = 3)
     
(    // inputs
    input logic 			CLOCK_50,
    input logic 			reset,
    input logic [23:0] 	secret_key,
    input logic [7:0] 	s_data_in,
    
    // outputs
    output logic 			write_enable_out,
	 output logic 			sij_ready,
    output logic [7:0] 	data_for_s_write,
    output logic [7:0] 	address_out,
    output logic 			shuffle_finished
);
	
	logic 	  [7:0] address_i 	/*synthesis keep*/;
	logic 	  [7:0] address_j 	/*synthesis keep*/;
	logic 	  [7:0] k		 		/*synthesis keep*/;
	logic 	  [7:0] s_data_at_i 	/*synthesis keep*/;
	logic 	  [7:0] s_data_at_j 	/*synthesis keep*/;
	logic 	  [7:0] temp			/*synthesis keep*/;
	
    
   // State register to hold the current state
   logic [6:0] state /*synthesis keep*/;     
    
     
   // State definitions using parameters
   localparam [6:0] IDLE            = 8'b0000_000;              // Check state
   localparam [6:0] SETUP_SI_J      = 8'b0001_000;              // Give state
   localparam [6:0] READ_SI         = 8'b0010_000;              // Waiting to finish
   localparam [6:0] ASSIGN_J        = 8'b0011_000;              // Registering data
	localparam [6:0] SETUPT_SJ			= 8'b1111_000;
   localparam [6:0] READ_SJ         = 8'b0100_000;              // Finishing
   localparam [6:0] SWAP        		= 8'b0101_000;              // Finishing
   localparam [6:0] SETUP_WRTIE_SJ  = 8'b0110_000;              // Finishing
   localparam [6:0] SETUP_WRITE_SI	= 8'b0111_000;              // Finishing
	localparam [6:0] WRITE_TO_S_I		= 8'b1100_001;
	localparam [6:0] WRITE_TO_S_J		= 8'b1110_001;
   localparam [6:0] WAIT_FOR_I      = 8'b1000_010;              // Finishing
   localparam [6:0] FINISH          = 8'b1001_100;              // Finishing
    
   
	// assign outputs from state bit-wise
	assign write_enable_out = state[0];
	assign sij_ready 			= state[1];
   assign shuffle_finished = state[2];
	
     
    // State transition logic
    always_ff @(posedge CLOCK_50) begin
        if (reset) begin
            state 		<= IDLE;
            address_j 	<= 0;
				address_i	<=	0;
        end 
		  else begin
            case (state)
                IDLE: begin
                  state 		<= SETUP_SI_J;
                  address_i	<= 0;			
					   address_j	<= 0;				
	
                end
                SETUP_SI_J: begin
                  k 						<= address_i % KEY_LENGTH;							// Setting up the modulo for j
						address_out 		<= address_i;											// Put the address for i in the address output for the s controller
                  state 				<= READ_SI;
                end

                READ_SI: begin
						s_data_at_i 		<= s_data_in;											// register data from s controller at address i
                  state 				<= ASSIGN_J;											// Wait one clock cycle to get s[i] from input s_i
                end

                ASSIGN_J: begin
						if (k == 0) begin																	// pick up the correct amount of BYTES!!!!
							address_j 		<= address_j + s_data_at_i + secret_key[23:16];	// calculating the nex address j
						end	
						else if (k == 1) begin
							address_j 		<= address_j + s_data_at_i + secret_key[15:8];
						end
						else begin
							address_j 		<= address_j + s_data_at_i + secret_key[7:0];
						end
																							
						state 				<= SETUPT_SJ;
                end
					 SETUPT_SJ: begin
						address_out 		<= address_j;											// put address j into the output address for the s controller
						state 				<= READ_SJ;
					 end
                READ_SJ: begin
						s_data_at_j 		<= s_data_in;											// register data from s controller at address j
                  state 				<= SWAP;

                end
                SWAP: begin
                  s_data_at_j 		<= s_data_at_i;
						s_data_at_i 		<= s_data_at_j;
                  state 				<= SETUP_WRITE_SI;
                end

                SETUP_WRITE_SI: begin
                  data_for_s_write 	<= s_data_at_i;
						address_out 		<= address_i;
                  state					<= WRITE_TO_S_I;
                end
					 WRITE_TO_S_I: begin
						state					<= SETUP_WRTIE_SJ;
					 end
                SETUP_WRTIE_SJ: begin
                  data_for_s_write 	<= s_data_at_j;
						address_out 		<= address_j;
                  state					<= WRITE_TO_S_J;
                end
					 WRITE_TO_S_J: begin
						state					<= WAIT_FOR_I;
					 end
                WAIT_FOR_I: begin
                    if (address_i == 8'd255) begin
                        state <= FINISH;
                    end 
						  else if (secret_key == 23'd0) begin 			// When there is no secret key skip the modulo operation
								k 				<= 0;				
								address_out <= address_i + 1;
								address_i 	<= address_i + 1;
								state 		<= READ_SI;
						  end 
						  else begin
                        address_i 	<= address_i + 1;
                        state 		<= SETUP_SI_J;
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