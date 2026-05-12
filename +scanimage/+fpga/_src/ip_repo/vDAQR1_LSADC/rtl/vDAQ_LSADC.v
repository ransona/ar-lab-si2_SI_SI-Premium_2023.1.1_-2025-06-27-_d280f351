//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQ_LSADC (
	input  wire spiClkEn,
	output wire dataClk,
	
	input  wire startConv_0,
	output wire convDone_0,
	output wire [15:0] data_0,
	
	input  wire startConv_1,
	output wire convDone_1,
	output wire [15:0] data_1,
	
	input  wire startConv_2,
	output wire convDone_2,
	output wire [15:0] data_2,
	
	input  wire startConv_3,
	output wire convDone_3,
	output wire [15:0] data_3,
	
	input  wire startConv_4,
	output wire convDone_4,
	output wire [15:0] data_4,
	
	input  wire startConv_5,
	output wire convDone_5,
	output wire [15:0] data_5,
	
	input  wire startConv_6,
	output wire convDone_6,
	output wire [15:0] data_6,
	
	input  wire startConv_7,
	output wire convDone_7,
	output wire [15:0] data_7,
	
	input  wire startConv_8,
	output wire convDone_8,
	output wire [15:0] data_8,
	
	input  wire startConv_9,
	output wire convDone_9,
	output wire [15:0] data_9,
	
	input  wire startConv_10,
	output wire convDone_10,
	output wire [15:0] data_10,
	
	input  wire startConv_11,
	output wire convDone_11,
	output wire [15:0] data_11,
	
	// SPI bus to device
	output wire [12:0] FW_i,
	input  wire [204:0] FW_o
);
	assign dataClk = FW_o[204];
	assign {convDone_11, convDone_10, convDone_9, convDone_8, convDone_7, convDone_6, convDone_5, convDone_4, convDone_3, convDone_2, convDone_1, convDone_0} = FW_o[11:0];
	assign {data_11, data_10, data_9, data_8, data_7, data_6, data_5, data_4, data_3, data_2, data_1, data_0} = FW_o[203:12];
	assign FW_i[11:0] = {startConv_11, startConv_10, startConv_9, startConv_8, startConv_7, startConv_6, startConv_5, startConv_4, startConv_3, startConv_2, startConv_1, startConv_0};
	assign FW_i[12] = spiClkEn;
	
endmodule

