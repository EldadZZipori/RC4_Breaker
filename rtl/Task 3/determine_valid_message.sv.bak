/*
    DETERMINE VALID MESSAGE
    
    This module determines if the decrypted message obtained is valid with only lowercase letters and spaces.
     
    It checks each character in the message and outputs `finish` and `key_valid` signals for outside use.
*/

module determine_valid_message
# (
    parameter LOW_THRESHOLD = 97,    // ASCII value for 'a'
    parameter HIGH_THRESHOLD = 122,  // ASCII value for 'z'
    parameter SPECIAL = 32,          // ASCII value for space ' '
    parameter END_INDEX = 5        // Last index to check (the entire message is 32)
)
(
    input  logic        CLOCK_50,              // Clock signal                        
    input  logic        reset,                 // Reset signal
    input  logic [7:0]  decrypted_data[31:0],  // Input decrypted data array
    input  logic        decrypt_done,          // Signal indicating decryption is done                                                                    
    output logic        key_valid,             // Output signal indicating if the key is valid
    output logic        finish                 // Output signal indicating the checking process is finished
);

    // State machine states
    localparam IDLE      = 2'b00;  // Idle state
    localparam CHECKING  = 2'b01;  // Checking state
    localparam FINISH    = 2'b10;  // Finish state

    reg [1:0] state /*synthesis keep*/;             // Current state of the state machine
    reg [7:0] out_data /*synthesis keep*/;           // Specific character being determined if valid
    logic [4:0] index /*synthesis keep*/;           // Index to loop through the decrypted_data array


    // State machine sequential and combinational logic
    always_ff @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            state <= IDLE;  // Initialize state machine to IDLE on reset
            index         <= 0;     // Reset index to 0
            key_valid         <= 1;     // Assume valid initially
        end else begin
            case (state)
                IDLE: begin
                    if (decrypt_done) begin
                        state <= CHECKING;  // Move to CHECKING state if decrypt_done is high
                        key_valid <= 1;                 // Initialize valid to 1 at the beginning of checking
                    end
                end
                CHECKING: begin
                    if (index < END_INDEX) begin
                                out_data <= decrypted_data[index];
                        // Check if character is not a lowercase letter or space
                        if (!((decrypted_data[index] >= LOW_THRESHOLD && decrypted_data[index] <= HIGH_THRESHOLD) ||
                              (decrypted_data[index] == SPECIAL))) begin
                            key_valid <= 0;  // Set valid to 0 if an invalid character is found
									 state <= FINISH;
                        end
                        index <= index + 1;  // Increment index during CHECKING state
                    end else begin
                        state <= FINISH;  // Move to FINISH state after checking all characters
                    end
                end
                FINISH: begin
                    if (!decrypt_done) begin
                        state <= IDLE;  // Move to IDLE state if decrypt_done goes low
                    end
                end
            endcase
        end
    end

    // Output assignment
    always_comb begin
        finish = state[1];  // Set finish signal high in FINISH state
    end
endmodule