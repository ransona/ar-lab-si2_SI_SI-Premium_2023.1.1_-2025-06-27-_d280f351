//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_DataScope_M (
	input  wire clk,
	
	input wire reset,
	input wire start,
	
	input wire [31:0] numberOfSamples,
	input wire [5:0]  sampleDecimationLB2,
	input wire [3:0]  trigger,
	
	input  wire [`MS_PHYS_CHANNEL_BUF_LSZ:0] sampleData,
	input  wire [15:0] siTriggerArray,
	input  wire dataValidIn,
	
	output wire fifoWriteEn,
	output wire [79:0] fifoWriteData
);
	localparam signed [13:0] LOGICAL_CHANNEL_MIN = 14'h2000;
	localparam signed [13:0] LOGICAL_CHANNEL_MAX = 14'h1FFF;
	localparam NUM_SEND_CHANS = 4;
	
	wire [NUM_SEND_CHANS-1:0] channelSaturateHigh;
	wire [NUM_SEND_CHANS-1:0] channelSaturateLow;
	
	
	reg signed [`LOGICAL_CHANNEL_LSZ+6:0] channelAccumBuffer [NUM_SEND_CHANS-1:0];
	reg [NUM_SEND_CHANS-1:0] channelSaturateHighLatch = 0;
	reg [NUM_SEND_CHANS-1:0] channelSaturateLowLatch = 0;
	reg [15:0] triggerAccumBuffer = 0;
	
	reg [7:0] loopIter;
	reg [7:0] numSamplesToAccum = 0;
	
	reg waitingForTrigger = 0;
	
	reg acqRunning = 0;
	reg [7:0] numSamplesAccumed = 0;
	reg [31:0] numSamplesComplete = 0;
	
	wire signed [`LOGICAL_CHANNEL_LSZ:0] logicalChannelsInArray [NUM_SEND_CHANS-1:0];
	wire [`LOGICAL_CHANNEL_LSZ:0] logicalChannelsOutArray [NUM_SEND_CHANS-1:0];
	
	
	reg fifoWriteEnReg = 0;
	reg [79:0] fifoWriteDataReg = 0;
	
	assign fifoWriteEn = fifoWriteEnReg;
	assign fifoWriteData = fifoWriteDataReg;
	
	genvar lci;
	generate
		for (lci=0; lci<NUM_SEND_CHANS; lci=lci+1) begin : generate_logical_channels
			assign logicalChannelsOutArray[lci] = channelSaturateHighLatch[lci] ? {LOGICAL_CHANNEL_MAX, 2'h0} : (channelSaturateLowLatch[lci] ? {LOGICAL_CHANNEL_MIN, 2'h0} : (channelAccumBuffer[lci] >>> sampleDecimationLB2));
			
			assign channelSaturateHigh[lci] = sampleData[lci*`MS_PHYS_CHANNEL_WIDTH+:`MS_PHYS_CHANNEL_WIDTH] == LOGICAL_CHANNEL_MAX;
			assign channelSaturateLow[lci] = sampleData[lci*`MS_PHYS_CHANNEL_WIDTH+:`MS_PHYS_CHANNEL_WIDTH] == LOGICAL_CHANNEL_MIN;
			
			assign logicalChannelsInArray[lci] = {sampleData[lci*`MS_PHYS_CHANNEL_WIDTH+:`MS_PHYS_CHANNEL_WIDTH], 2'h0};
		end
	endgenerate
	
	wire inReset = reset || !acqRunning;
	wire triggered = ~waitingForTrigger || trigger;
	
	always @(posedge clk) begin
		if (inReset) begin
			numSamplesAccumed <= 0;
			numSamplesComplete <= 0;
			
			acqRunning <= start;
			numSamplesToAccum <= 1 << sampleDecimationLB2 - 1;
			waitingForTrigger <= 1;
		end else if (triggered) begin 
			waitingForTrigger <= 0;
			
			if (numSamplesAccumed == numSamplesToAccum) begin
				numSamplesAccumed <= 0;
				numSamplesComplete <= numSamplesComplete + 1;
				
				acqRunning <= (numSamplesComplete + 1) < numberOfSamples;
			end else
				numSamplesAccumed <= numSamplesAccumed + 1;
		end
		
		for (loopIter = 0; loopIter < NUM_SEND_CHANS; loopIter = loopIter+1) begin
			if (inReset || waitingForTrigger || (numSamplesAccumed == numSamplesToAccum)) begin
				channelAccumBuffer[loopIter] <= logicalChannelsInArray[loopIter];
				channelSaturateHighLatch[loopIter] <= channelSaturateHigh[loopIter];
				channelSaturateLowLatch[loopIter] <= channelSaturateLow[loopIter];
				triggerAccumBuffer <= siTriggerArray;
			end else begin
				channelAccumBuffer[loopIter] <= channelAccumBuffer[loopIter] + logicalChannelsInArray[loopIter];
				channelSaturateHighLatch[loopIter] <= channelSaturateHighLatch[loopIter] || channelSaturateHigh[loopIter];
				channelSaturateLowLatch[loopIter] <= channelSaturateLowLatch[loopIter] || channelSaturateLow[loopIter];
				triggerAccumBuffer <= triggerAccumBuffer | siTriggerArray;
			end
		end
		
		fifoWriteEnReg <= acqRunning && triggered && (numSamplesAccumed == numSamplesToAccum);
		fifoWriteDataReg <= {triggerAccumBuffer, logicalChannelsOutArray[3], logicalChannelsOutArray[2], logicalChannelsOutArray[1], logicalChannelsOutArray[0]};
	end
	
endmodule
