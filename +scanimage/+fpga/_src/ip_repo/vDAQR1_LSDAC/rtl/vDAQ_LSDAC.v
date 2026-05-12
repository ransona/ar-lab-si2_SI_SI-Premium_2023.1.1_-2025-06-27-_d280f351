//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQ_LSDAC (
	input wire spiClkEn,
	
	input wire loadSample_0,
	input wire [15:0] data_0,
	input wire triggerImmediately_0,
	input wire asyncTrigger_0,
	input wire reset_0,
	
	input wire loadSample_1,
	input wire [15:0] data_1,
	input wire triggerImmediately_1,
	input wire asyncTrigger_1,
	input wire reset_1,
	
	input wire loadSample_2,
	input wire [15:0] data_2,
	input wire triggerImmediately_2,
	input wire asyncTrigger_2,
	input wire reset_2,
	
	input wire loadSample_3,
	input wire [15:0] data_3,
	input wire triggerImmediately_3,
	input wire asyncTrigger_3,
	input wire reset_3,
	
	input wire loadSample_4,
	input wire [15:0] data_4,
	input wire triggerImmediately_4,
	input wire asyncTrigger_4,
	input wire reset_4,
	
	input wire loadSample_5,
	input wire [15:0] data_5,
	input wire triggerImmediately_5,
	input wire asyncTrigger_5,
	input wire reset_5,
	
	input wire loadSample_6,
	input wire [15:0] data_6,
	input wire triggerImmediately_6,
	input wire asyncTrigger_6,
	input wire reset_6,
	
	input wire loadSample_7,
	input wire [15:0] data_7,
	input wire triggerImmediately_7,
	input wire asyncTrigger_7,
	input wire reset_7,
	
	input wire loadSample_8,
	input wire [15:0] data_8,
	input wire triggerImmediately_8,
	input wire asyncTrigger_8,
	input wire reset_8,
	
	input wire loadSample_9,
	input wire [15:0] data_9,
	input wire triggerImmediately_9,
	input wire asyncTrigger_9,
	input wire reset_9,
	
	input wire loadSample_10,
	input wire [15:0] data_10,
	input wire triggerImmediately_10,
	input wire asyncTrigger_10,
	input wire reset_10,
	
	input wire loadSample_11,
	input wire [15:0] data_11,
	input wire triggerImmediately_11,
	input wire asyncTrigger_11,
	input wire reset_11,
	
	// SPI bus to devices
	output wire [240:0] FW_IO
);
	wire [11:0]  loadSample = {loadSample_11, loadSample_10, loadSample_9, loadSample_8, loadSample_7, loadSample_6, loadSample_5, loadSample_4, loadSample_3, loadSample_2, loadSample_1, loadSample_0};
	wire [11:0]  triggerImmediately = {triggerImmediately_11, triggerImmediately_10, triggerImmediately_9, triggerImmediately_8, triggerImmediately_7, triggerImmediately_6, triggerImmediately_5, triggerImmediately_4, triggerImmediately_3, triggerImmediately_2, triggerImmediately_1, triggerImmediately_0};
	wire [11:0]  asyncTrigger = {asyncTrigger_11, asyncTrigger_10, asyncTrigger_9, asyncTrigger_8, asyncTrigger_7, asyncTrigger_6, asyncTrigger_5, asyncTrigger_4, asyncTrigger_3, asyncTrigger_2, asyncTrigger_1, asyncTrigger_0};
	wire [11:0]  reset_i = {reset_11, reset_10, reset_9, reset_8, reset_7, reset_6, reset_5, reset_4, reset_3, reset_2, reset_1, reset_0};
	wire [191:0] data = {data_11, data_10, data_9, data_8, data_7, data_6, data_5, data_4, data_3, data_2, data_1, data_0};

	genvar i_dac;
	generate
		for (i_dac = 0; i_dac < 12; i_dac = i_dac+1) begin : gen_dac_sigs
			assign FW_IO[i_dac*20] = loadSample[i_dac];
			assign FW_IO[i_dac*20+1] = triggerImmediately[i_dac];
			assign FW_IO[i_dac*20+2] = asyncTrigger[i_dac];
			assign FW_IO[i_dac*20+3] = reset_i[i_dac];
			assign FW_IO[(i_dac*20+4)+:16] = data[i_dac*16+:16];
		end
	endgenerate

	assign FW_IO[240] = spiClkEn;

endmodule

