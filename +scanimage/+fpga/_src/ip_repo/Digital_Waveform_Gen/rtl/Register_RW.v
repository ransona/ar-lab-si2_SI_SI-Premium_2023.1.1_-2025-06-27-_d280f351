//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module Register_RW #(
	parameter ADDR = 0,
	parameter W = 32,
	parameter IV = 0,
	parameter MM_BYTES = 2048
)(
	input  wire aclk,
	input  wire reset,
	input  wire [ADDR+(W-1)/8:0] byteWriteEn,
	input  wire [ADDR*8+W-1:0]   bitWriteData,
	inout  wire [MM_BYTES*8-1:0] bitReadData,
	
	output wire [W-1:0] registerValue,
	
	output wire partialUpdate,
	output wire fullUpdate
	
//	input  wire clkb,
//	output wire [W-1:0] registerValue_b,
//	output wire partialUpdate_b,
//	output wire fullUpdate_b
);
	// Write logic
	reg [W-1:0] regVal = IV;
	assign registerValue = regVal;
	
	integer ctr;
	
	reg partialUpdateR;
	reg fullUpdateR;
	assign partialUpdate = partialUpdateR;
	assign fullUpdate = fullUpdateR;
	
	wire [(W-1)/8:0] myByteWriteEnables = byteWriteEn[ADDR+(W-1)/8:ADDR];
	
	always @(posedge aclk) begin
		if (reset)
			regVal <= IV;
		else for (ctr = 0; ctr < W; ctr = ctr + 1) begin
			regVal[ctr] <= myByteWriteEnables[ctr/8] ? bitWriteData[ADDR*8 + ctr] : regVal[ctr];
		end
		
		partialUpdateR <= |myByteWriteEnables;
		fullUpdateR <= &myByteWriteEnables;
	end
	
	
	// Read logic
	assign bitReadData[ADDR*8+:W] = regVal;
	
	// Clock crossing

endmodule
