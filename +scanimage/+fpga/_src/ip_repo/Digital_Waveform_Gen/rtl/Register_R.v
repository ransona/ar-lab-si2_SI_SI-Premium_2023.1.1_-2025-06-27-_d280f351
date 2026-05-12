//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module Register_R #(
	parameter ADDR = 0,
	parameter W = 32,
	parameter MM_BYTES = 2048
)(
	input  wire [ADDR+(W-1)/8:0] byteWriteEn,
	input  wire [ADDR*8+W-1:0]   bitWriteData,
	output wire [MM_BYTES*8-1:0] bitReadData,
	input  wire [W-1:0] registerValue,
	
	output wire cmdActive,
	output wire [W-1:0] cmdValue
	
//	input  wire clkb,
//	output wire cmdActive_b,
//	output wire [W-1:0] cmdValue_b
);

	assign bitReadData[ADDR*8+:W] = registerValue;
	
	assign cmdActive = |byteWriteEn[ADDR+(W-1)/8:ADDR];
	assign cmdValue = bitWriteData[ADDR*8+W-1:ADDR*8];
	
endmodule
