//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQ_LSDAC_IO #(
	parameter SHOW_RESET_PORT = 0
)(
	input wire sysClk120,
	input wire reset,
	input wire spiClkEn,
	
	input wire loadSample_0,
	input wire [15:0] data_0,
	output wire loadComplete_0,
	input wire triggerImmediately_0,
	input wire asyncTrigger_0,
	input wire reset_0,
	
	input wire loadSample_1,
	input wire [15:0] data_1,
	output wire loadComplete_1,
	input wire triggerImmediately_1,
	input wire asyncTrigger_1,
	input wire reset_1,
	
	input wire loadSample_2,
	input wire [15:0] data_2,
	output wire loadComplete_2,
	input wire triggerImmediately_2,
	input wire asyncTrigger_2,
	input wire reset_2,
	
	input wire loadSample_3,
	input wire [15:0] data_3,
	output wire loadComplete_3,
	input wire triggerImmediately_3,
	input wire asyncTrigger_3,
	input wire reset_3,
	
	input wire loadSample_4,
	input wire [15:0] data_4,
	output wire loadComplete_4,
	input wire triggerImmediately_4,
	input wire asyncTrigger_4,
	input wire reset_4,
	
	// SPI bus to devices
	inout wire [20:0] BOARD_IO
);
	vDAQ_LSDAC vDAQ_LSDAC_Inst(
		.sysClk120(sysClk120),
		.reset(SHOW_RESET_PORT ? reset : 0),
		.spiClkEn(spiClkEn),
		
		.loadSample({loadSample_4, loadSample_3, loadSample_2, loadSample_1, loadSample_0}),
		.data({data_4, data_3, data_2, data_1, data_0}),
		.loadComplete({loadComplete_4, loadComplete_3, loadComplete_2, loadComplete_1, loadComplete_0}),
		.triggerImmediately({triggerImmediately_4, triggerImmediately_3, triggerImmediately_2, triggerImmediately_1, triggerImmediately_0}),
		.asyncTrigger({asyncTrigger_4, asyncTrigger_3, asyncTrigger_2, asyncTrigger_1, asyncTrigger_0}),
		.reset_i({reset_4, reset_3, reset_2, reset_1, reset_0}),
		
		.CS(BOARD_IO[4:0]),
		.LDAC(BOARD_IO[9:5]),
		.RST(BOARD_IO[14:10]),
		.SDO(BOARD_IO[19:15]),
		.CLK(BOARD_IO[20])
	);

endmodule

