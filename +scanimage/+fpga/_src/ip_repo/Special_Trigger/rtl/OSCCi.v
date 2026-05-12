//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module OSCCi (
	input wire srcV,
	input wire srcClk,
	output wire dstV,
	input wire dstClk
);
	
	// synchronizer
	(* ASYNC_REG = "TRUE" *) reg [2:0] ssr = 0;
	
	reg srcFlag = 0;
	
	assign dstV = ssr[0] != ssr[1];
	
	always @(posedge dstClk) begin
		ssr <= {srcFlag, ssr[2:1]};
	end
	
	reg pSrcV = 1;
	always @(posedge srcClk) begin
		pSrcV <= srcV;
		if (~pSrcV && srcV)
			srcFlag <= ~srcFlag;
	end
	
endmodule


