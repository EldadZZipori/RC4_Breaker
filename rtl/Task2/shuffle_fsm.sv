/*
    SHUFFLE S MEMORY (FINITE STATE MACHINE)
    
   This module implements the second loop in the decryption algorithe.
	
	j = 0
	for i = 1 to 255
		j = (j + s[i] + secret_key[i mode keylength])
		swap value of s[i] and s[j]
		
	NOTE: this fsm does not directly changes s. This must be done externally from the signals
			provided by this fsm.
    
   This module has three paramters -
	KEY_LENGTH				the amount of bytes to be used from secret key
	START_INDEX				allow to implement this loop with different bounds i from START_INDEX
	END_INDEX				i to END_INDEX
	 
*/
`default_nettype none

module shuffle_fsm
#( parameter KEY_LENGTH 	= 3,
	parameter START_INDEX 	= 0,
	parameter END_INDEX		= 255
)
     
(    // inputs
    input logic 			CLOCK_50,
    input logic 			reset,
    input logic [23:0] 	secret_key,
    input logic [7:0] 	s_data_in,
	 input logic			start,
    
    // outputs
    output logic 			write_enable_out,
	 output logic 			sij_ready,
    output logic [7:0] 	data_for_s_write,
    output logic [7:0] 	address_out,
    output logic 			shuffle_finished

);
	
	logic 	  [7:0] 		address_i 	/*synthesis keep*/;
	logic 	  [7:0] 		address_j 	/*synthesis keep*/;
	logic 	  [7:0] 		s_data_at_i 	/*synthesis keep*/;
	logic 	  [7:0] 		s_data_at_j 	/*synthesis keep*/;	
    
   // State register to hold the current state
   logic [3:0] state /*synthesis keep*/;     
    
     
   // State definitions using parameters
   localparam IDLE            = 4'b0000;              // Check state
   localparam SETUP_SI_J      = 4'b0001;              // Give state
   localparam READ_SI         = 4'b0010;              // Waiting to finish
   localparam ASSIGN_J        = 4'b0011;              // Registering data
	localparam SETUPT_SJ			= 4'b0100;
   localparam READ_SJ         = 4'b0101;              // Finishing
   localparam SETUP_WRTIE_SJ  = 4'b0110;              // Finishing
   localparam SETUP_WRITE_SI	= 4'b0111;              // Finishing
	localparam WRITE_SI			= 4'b1000;
	localparam WRITE_SJ			= 4'b1001;
   localparam WAIT_FOR_I      = 4'b1010;              // Finishing
   localparam FINISH          = 4'b1011;              // Finishing
	
	localparam WAIT_S_I			= 4'b1100;
	localparam WAIT_S_J			= 4'b1101;
    
   
	// assign outputs from state bit-wise
	assign write_enable_out = (state == WRITE_SI) || (state == WRITE_SJ);
   assign sij_ready = (state == IDLE);
   assign shuffle_finished = (state == FINISH);
	
     
    // State transition logic
    always_ff @(posedge CLOCK_50) begin
        if (reset) begin
            state 		<= IDLE;
            address_j 	<= START_INDEX;
				address_i	<=	0;
        end 
		  else begin
            case (state)
                IDLE: begin
						if(start) state <= SETUP_SI_J;
						else		 state <= IDLE;
                  address_i	<= INDEX;			
					   address_j	<= 0;				
	
                end
                SETUP_SI_J: begin	
						address_out 		<= address_i;													// Put the address for i in the address output for the s controller
                  state 				<= WAIT_S_I;
                end
					 WAIT_S_I: begin
						state 				<= READ_SI;
					end	
                READ_SI: begin
						s_data_at_i 		<= s_data_in;													// register data from s controller at address i
                  state 				<= ASSIGN_J;													// Wait one clock cycle to get s[i] from input s_i
                end

                ASSIGN_J: begin
						if (secret_key != 0)
							address_j <= (address_j + s_data_at_i + secret_key[5'd23 - (4'd8 * (address_i % 2'd3)) -: 8]);
						else 
							address_j <= (address_j + s_data_at_i );
														
						state 				<= SETUPT_SJ;
                end
					 SETUPT_SJ: begin
						address_out 		<= address_j;													// put address j into the output address for the s controller
						state 				<= WAIT_S_J;
					 end
					 WAIT_S_J: begin
						state 				<= READ_SJ;
					 end
                READ_SJ: begin
						s_data_at_j 		<= s_data_in;													// register data from s controller at address j
                  state 				<= SETUP_WRITE_SI;

                end

                SETUP_WRITE_SI: begin
                  data_for_s_write 	<= s_data_at_j;
						address_out 		<= address_i;
                  state					<= WRITE_SI;
                end
					 WRITE_SI: begin
						state					<= SETUP_WRTIE_SJ;
					 end
                SETUP_WRTIE_SJ: begin
                  data_for_s_write 	<= s_data_at_i;
						address_out 		<= address_j;
                  state					<= WRITE_SJ;
                end
					 WRITE_SJ: begin
						state					<= WAIT_FOR_I;
					 end
                WAIT_FOR_I: begin
                    if (address_i == END_INDEX) begin
                        state <= FINISH;
                    end 
						  else begin
                        address_i 	<= address_i + 1'b1;
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