module HEX_Control(
	input 	logic orig_clk,
	input 	logic [23:0] secret_key,
   output 	logic[6:0] 	HEX0,	
   output 	logic[6:0] 	HEX1,
   output 	logic[6:0] 	HEX2,
   output 	logic[6:0] 	HEX3,
   output 	logic[6:0] 	HEX4,
   output 	logic[6:0] 	HEX5
);

	/*
		Switch controls
	*/
	logic [7:0] Seven_Seg_Val[5:0];
		 
	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst0(.ssOut(Seven_Seg_Val[0]), .nIn(secret_key[3:0]));
	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst1(.ssOut(Seven_Seg_Val[1]), .nIn(secret_key[7:4]));
	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst2(.ssOut(Seven_Seg_Val[2]), .nIn(secret_key[11:8]));
	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst3(.ssOut(Seven_Seg_Val[3]), .nIn(secret_key[15:12]));
	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst4(.ssOut(Seven_Seg_Val[4]), .nIn(secret_key[19:16]));
	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst5(.ssOut(Seven_Seg_Val[5]), .nIn(secret_key[23:20]));
	
	logic Clock_10Hz;
	Generate_Arbitrary_Divided_Clk32 
	Gen_100Hz_clk
	(.inclk(orig_clk),
	.outclk(Clock_10Hz),
	.outclk_Not(),
	.div_clk_count(5000000 >> 1),
	.Reset(1'h1)
); 
	
	always_ff @(posedge Clock_10Hz) begin
		
		
		HEX0 <= Seven_Seg_Val[0];
		HEX1 <= Seven_Seg_Val[1];
		HEX2 <= Seven_Seg_Val[2];
		HEX3 <= Seven_Seg_Val[3];
		HEX4 <= Seven_Seg_Val[4];
		HEX5 <= Seven_Seg_Val[5];
	end
	
endmodule
