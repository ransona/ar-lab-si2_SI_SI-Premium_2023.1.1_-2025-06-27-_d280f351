//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module CLK_RATE_MEASi #(
	parameter [7:0] MEAS_COUNTER_WIDTH = 20,
	parameter [7:0] RESULT_COUNTER_WIDTH = 32
)(
	input wire measClk,
	input wire resultClk,
	output reg [RESULT_COUNTER_WIDTH-1:0] measClkPeriod = 0
);
	// counts how many resultClk clock ticks elapse during 2^(MEAS_COUNTER_WIDTH-1) ticks of measClk
	
	reg [MEAS_COUNTER_WIDTH-1:0] mctr;
	wire mctrMsb = mctr[MEAS_COUNTER_WIDTH-1];
	
	always @(posedge measClk)
		mctr <= mctr + 1;
	
	reg phb;
	reg [RESULT_COUNTER_WIDTH-1:0] rctr = 0;
	
	// synchronizer
	(* ASYNC_REG = "TRUE" *) reg hb_b, hb;
	
	always @(posedge resultClk) begin
		hb_b <= mctrMsb;
		hb <= hb_b;
		phb <= hb;
		
		if ((hb != phb) || &rctr) begin
			measClkPeriod <= rctr;
			rctr <= 1;
		end else
			rctr <= rctr + 1;
	end
	
endmodule


