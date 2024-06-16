`timescale 1ns / 1ps
module Generate_Arbitrary_Divided_Clk32(inclk,outclk,outclk_not,div_clk_count,Reset);
    input inclk/*synthesis keep*/;
	 input Reset/*synthesis keep*/;
    output outclk/*synthesis keep*/;
	 output outclk_not/*synthesis keep*/;
	 input[31:0] div_clk_count/*synthesis keep*/;
	 
	 logic[31:0] period_clk_count; 
	 assign period_clk_count = div_clk_count;
	 
	 logic [31:0] counter;
	 
	always_ff @(posedge inclk, negedge Reset) begin
		if (~Reset) begin // I"m assuming the reset is inverted as all the code in the lab passes HIGh for reset
			counter <= 32'b1;
			outclk <= 1'b0;
		end
		/*
			1. Divide by two as we need to switch from LOW/HIGH every half period.
			2. Advised by TA to do roll (>>1) to divide by 2 as using "/" will actually try
			to create a division functionality. 
			3. When new div_clk_count is lower then the previous one the counter can run into problem. hence the >=
		*/
		else if (counter >= period_clk_count) begin 
			counter <= 32'b1;
			outclk <= ~outclk;
			
		end
		else begin
			counter <= counter + 1;
		end
		
	end
	
	assign outclk_not = ~outclk;
endmodule

