//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module HSD_LSADC_IO #(
	parameter SHOW_SPI_ENABLE_PORT = 1,
	parameter SHOW_DBG_PORT = 0
)(
	input  wire clk120,
	input  wire spiClkEn,
	output wire dataClk,
	
	input wire startConv_0,
	output wire convDone_0,
	output wire [15:0] data_0,
	
	input wire startConv_1,
	output wire convDone_1,
	output wire [15:0] data_1,
	
	input wire startConv_2,
	output wire convDone_2,
	output wire [15:0] data_2,
	
	input wire startConv_3,
	output wire convDone_3,
	output wire [15:0] data_3,
	
	// SPI bus to device
	inout wire [8:0] BOARD_IO,
	
	output wire [127:0] dbg
);
	HSD_LSADC HSD_LSADC_Inst(
		.clk120(clk120),
		.spiClkEn(spiClkEn),
		.dataClk(dataClk),
		
		.startConv({startConv_3, startConv_2, startConv_1, startConv_0}),
		.convDone({convDone_3, convDone_2, convDone_1, convDone_0}),
		.data({data_3, data_2, data_1, data_0}),
		
		.spiClk(BOARD_IO[0]),
		.cnv(BOARD_IO[4:1]),
		.sdi(BOARD_IO[8:5])
	);
	
	assign dbg = 0;
	
endmodule

