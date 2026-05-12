//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module HSD_LSADC_Chan (
	input wire dataClk,
	
	input wire startConv,
	output reg convDone = 0,
	output reg [15:0] data = 0,
	
	// SPI bus to device
	output wire cnv,
	input  wire sdi,
	output wire sdo
);
	reg [5:0] convCtr = 0;
	reg [4:0] readCtr = 0;
	reg cnvR = 0;
	
	(* ASYNC_REG = "TRUE" *)
	reg [1:0] startFF = 0;

	assign sdo = 0;
	assign cnv = cnvR || startFF || startConv;
	
	always @(posedge dataClk) begin
		startFF <= {startConv, startFF[1]};
		cnvR <= startFF[0] || (convCtr > 0);
		
		if (convCtr)
			convCtr <= convCtr - 1;
		else if (startFF[0])
			convCtr <= 37;
		
		convDone <= readCtr == 1;
		
		if (readCtr) begin
			readCtr <= readCtr - 1;

			if (readCtr < 17)
				data[readCtr-1] <= sdi;
		end else if (convCtr == 1)
			readCtr <= 18;
	end

endmodule

