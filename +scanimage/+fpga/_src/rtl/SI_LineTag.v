//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_LineTag #(
	parameter HS_NUM_LOGICAL_CHANNELS = 8,
	parameter FIFO_WIDTH = 64
)(
	input  wire clk,
	
	input wire acqParamEnableLineTag,
	input wire [5:0] dataWriteWidth1,
	input wire [5:0] dataWriteWidth2,

	input  wire [`STATE_MACHINE_OUT_LSZ:0] accumStateMachineDataIn,
	input  wire [`LOGICAL_CHANNEL_BUF_LSZ:0] pixelDataIn,
	input  wire pixelValid,
	input  wire pixelEndOfLine,
		
	output wire fifoWriteEn,
	output wire [FIFO_WIDTH-1:0] fifoData,
	output wire [5:0] fifoWriteWidth
);
	reg [1:0] lineTagState = 0;
	wire lineTagActive = ((lineTagState > 0) && (lineTagState < 3));
	wire [63:0] lineTagData = (lineTagState == 2) ? accumStateMachineDataIn[`STATE_MACHINE_OUT_LINE_TS_START_BIT+:64] : 64'hFFFF_0000_AAAA_CCCC;

	reg secondWritePending = 0;
	reg [FIFO_WIDTH-1:0] secondWriteData = 0;
	
	wire [FIFO_WIDTH-1:0] pixelDataOut = secondWritePending ? secondWriteData : pixelDataIn;
	wire [5:0] dataWriteWidth = secondWritePending ? dataWriteWidth2 : dataWriteWidth1;

	assign fifoData = lineTagActive ? lineTagData : pixelDataOut;
	assign fifoWriteEn = lineTagActive || (pixelValid && dataWriteWidth1) || secondWritePending;
	assign fifoWriteWidth = lineTagActive ? 7 : dataWriteWidth;
	
	always @(posedge clk) begin
		if (pixelEndOfLine && acqParamEnableLineTag)
			lineTagState <= 3;
		else if (lineTagState)
			lineTagState <= lineTagState - 1;

		secondWritePending <= pixelValid && (dataWriteWidth2 > 0);
		secondWriteData <= pixelDataIn[`LOGICAL_CHANNEL_BUF_LSZ:(`LOGICAL_CHANNEL_BUF_SIZE/2)];
	end
	
endmodule
