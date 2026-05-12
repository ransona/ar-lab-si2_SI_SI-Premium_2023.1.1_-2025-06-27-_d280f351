//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module inputDebounce #(
	parameter integer CTR_WIDTH = 5
)(
	input  wire clk,
	input  wire sigIn,
	output wire sigOut,
	output wire sigOutRE,
	output wire sigOutFE,
	
	input  wire [CTR_WIDTH-1:0] debounceTime
);
	(* ASYNC_REG = "TRUE" *)
	reg [1:0] sigSync;
	
	wire syncedSig = sigSync[0];
	reg prevSig = 0;
	reg [CTR_WIDTH-1:0] debounceCtr = 0;
	
	
	assign sigOut = (debounceCtr > 0) ? prevSig : syncedSig;
	assign sigOutRE = sigOut && !prevSig;
	assign sigOutFE = !sigOut && prevSig;
	
	always @(posedge clk) begin
		// synchronizer
		sigSync <= {sigIn, sigSync[1]};
	
		// rising edge detection
		prevSig <= sigOut;
		
		// debounce
		if (sigOut != prevSig)
			debounceCtr <= debounceTime;
		else if (debounceCtr)
			debounceCtr <= debounceCtr - 1;
	end
	
endmodule


