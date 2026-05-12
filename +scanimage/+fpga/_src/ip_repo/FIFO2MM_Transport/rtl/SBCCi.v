//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module SBCCi (
	input wire srcV,
	input wire srcClk,
	output wire dstV,
	input wire dstClk
);
	
	// synchronizer
	(* ASYNC_REG = "TRUE" *) reg bufr1 = 0, bufr2 = 0;
	
	assign dstV = bufr2;
	
	always @(posedge dstClk) begin
		bufr1 <= srcV;
		bufr2 <= bufr1;
	end
	
	// dummy to keep the srcClk present for constraints
	(* DONT_TOUCH = "TRUE" *)
	reg dummyR;
	always @(posedge srcClk)
		dummyR <= srcV;
	
endmodule


