//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//   - 4/2023, Nelson Downs: Updated to enable custom clock LRR phase 
//     sync tracking
//   - 3/2022, Nelson Downs: Updated to reflect sync trigger signal is 
//     changed to phase of first sample
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_DataScope_H #(
	parameter FIFO_WIDTH   = 424,  // dependent on IP module configuration
	parameter NUM_TRIGGERS = 17
)(
	input  wire clk,
	
	input wire reset,
	input wire start,
	
	input wire [31:0] numberOfSamples,
	input wire [5:0]  sampleDecimationLB2,
	input wire [3:0]  trigger,
	
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] sampleDataA,
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] sampleDataB,
	input  wire chanSel,
	input  wire [15:0] firstSamplePhase,  // phase of the first sample, current max can be 16 bits big without changing logic here

	input  wire [NUM_TRIGGERS-1:0] siTriggerArray,
	input  wire dataValidIn,
	
	output wire fifoWriteEn,
	output wire [FIFO_WIDTH-1:0] fifoWriteData
);
	localparam NUM_TRIGGER_BYTES = $rtoi($ceil($itor(NUM_TRIGGERS) / 8.0));
	localparam NUM_TRIGGER_BITS  = NUM_TRIGGER_BYTES * 8;
	reg [NUM_TRIGGER_BITS-1:0] siTriggerAccumBuffer = 0;
	
	// Channel mux
	wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] dataIn = chanSel ? sampleDataB : sampleDataA;
	reg  [`HS_PHYS_CHANNEL_BUF_LSZ:0] dataInR = 0;  // width: 32*12=384
	reg  [15:0] firstSamplePhaseR = 0;
	
	always @(posedge clk) begin
		dataInR <= dataIn;
		firstSamplePhaseR <= firstSamplePhase;
	end

	// when using decimation, we switch to 16 bit samples
	localparam RAW_CH_WIDTH = 12;
	localparam DECIM_CH_WIDTH = 16;

	// Calc decimated data
	reg signed [DECIM_CH_WIDTH-1:0] rawSamplesExtended[31:0]; // extended samples for decimation purposes
	reg signed [DECIM_CH_WIDTH-1:0] decimatedData[4:0][15:0]; // decimatedData[decimlevel-1][sampleN]
	
	reg [5:0] rawSampIter;
	reg [2:0] decimLvlIter;
	reg [6:0] decimLvl;
	reg [4:0] sampleOutIter;
	reg [5:0] sampleInIter;
	reg [4:0] sampleOutIterM;
	reg signed [DECIM_CH_WIDTH-1:0] currSum;
	reg [DECIM_CH_WIDTH*16-1:0] decimationBuffer = 0;

	// extend samples for decimation
	always @(*)
		for (rawSampIter = 0; rawSampIter < 32; rawSampIter = rawSampIter + 1)
			rawSamplesExtended[rawSampIter] = dataInR[rawSampIter*RAW_CH_WIDTH+:RAW_CH_WIDTH] << (DECIM_CH_WIDTH - RAW_CH_WIDTH);

	// create decimation buffer
	always @(posedge clk) begin
		// 2D decimation data array, first dimension is decimation level, second dimension is data stored
		//  - at each decimation level we divide and bin the HS data frequency by a factor of 2
		//  - e.g., the first decimation level will decimate the 32 samples into 16 binned samples,
		//    the second decimation level will decimate the 32 samples into 8 binned samples,
		//    the third decimation level will decimate the 32 samples into 4 binned samples, etc
		for (decimLvlIter = 0; decimLvlIter < 5; decimLvlIter = decimLvlIter + 1) begin
			decimLvl = 1 << (decimLvlIter+1);
			for (sampleOutIter = 0; sampleOutIter < (16 >> decimLvlIter); sampleOutIter = sampleOutIter + 1) begin
				currSum = rawSamplesExtended[decimLvl*sampleOutIter] >>> (decimLvlIter+1);
				for (sampleInIter = 1; sampleInIter < decimLvl; sampleInIter = sampleInIter + 1)
					currSum = currSum + (rawSamplesExtended[decimLvl*sampleOutIter+sampleInIter] >>> (decimLvlIter+1));
				decimatedData[decimLvlIter][sampleOutIter] <= currSum;
			end
		end

		// based on the currently selected decimation level, pack the bits from the decimated data array into the
		// decimation buffer
		for (sampleOutIterM = 0; sampleOutIterM < 16; sampleOutIterM = sampleOutIterM + 1)
			if ((sampleDecimationLB2 > 1) && (sampleDecimationLB2 < 6))
				decimationBuffer[sampleOutIterM*DECIM_CH_WIDTH+:DECIM_CH_WIDTH] <= decimatedData[sampleDecimationLB2-1][sampleOutIterM];
			else
				decimationBuffer[sampleOutIterM*DECIM_CH_WIDTH+:DECIM_CH_WIDTH] <= decimatedData[0][sampleOutIterM];
	end


	// state machine
	reg acqRunning = 0;
	reg waitingForTrigger = 0;
	reg [7:0] numSamplesAccumed = 0;
	reg [31:0] numSamplesComplete = 0;
	
	wire inReset = reset || !acqRunning;
	wire triggered = ~waitingForTrigger || trigger;

	wire decimateAndAccum = sampleDecimationLB2 > 5;
	wire secondaryAccumLB2 = decimateAndAccum ? sampleDecimationLB2 - 5 : 0;
	wire [7:0] secondaryAccumN = 1 << secondaryAccumLB2;
	reg signed [19:0] secondaryAccumBuffer = 0;
	
	reg fifoWriteEnRegP = 0;
	reg [`HS_PHYS_CHANNEL_BUF_LSZ:0] fifoWriteDataRegP = 0;
	reg [15:0] firstSamplePhaseP = 0;
	reg [7:0] siTriggerDataP[3:0][NUM_TRIGGER_BYTES-1:0];  // trigger data delay array, stored in unpacked bytes

	reg fifoWriteEnReg = 0;
	reg [FIFO_WIDTH-1:0] fifoWriteDataReg = 0;
	
	assign fifoWriteEn = fifoWriteEnReg;
	assign fifoWriteData = fifoWriteDataReg;

	// Sample Data Width depends on the decimation level. For example:
	//  - Decimation level 0, 32 12-bit samples written each time, 48 bytes (384 bits) total
	//  - Decimation level 1, 16 16-bit samples written each time, 32 bytes (256 bits) total
	//  - Decimation level 2, 8  16-bit samples written each time, 16 bytes (128 bits) total
	localparam MAX_DATA_WIDTH_BYTES = `HS_PHYS_CHANNEL_BUF_SIZE / 8;
	wire [5:0] sampleDataWidthBytes = decimateAndAccum ? 2 : (sampleDecimationLB2 ? (64 >> sampleDecimationLB2) : MAX_DATA_WIDTH_BYTES);

	reg [5:0] dctr = 0;
	
	always @(posedge clk) begin
		if (inReset) begin
			numSamplesAccumed <= 0;
			numSamplesComplete <= 0;
			
			acqRunning <= start;
			waitingForTrigger <= 1;
		end else if (triggered) begin
			waitingForTrigger <= 0;

			if (numSamplesAccumed == secondaryAccumLB2) begin
				numSamplesAccumed <= 0;
				numSamplesComplete <= numSamplesComplete + 1;
				
				acqRunning <= (numSamplesComplete + 1) < numberOfSamples;
			end else
				numSamplesAccumed <= numSamplesAccumed + 1;
		end
		
		// accumulate samples for decimation levels greater than 6 (i.e. more than 32 samples decimated)
		if (inReset || waitingForTrigger || (numSamplesAccumed == secondaryAccumLB2)) begin
			secondaryAccumBuffer <= decimationBuffer[15:0];
			siTriggerAccumBuffer <= siTriggerArray;
		end else begin
			secondaryAccumBuffer <= secondaryAccumBuffer + decimationBuffer[15:0];
			siTriggerAccumBuffer <= siTriggerAccumBuffer | siTriggerArray;
		end
		
		fifoWriteEnRegP <= acqRunning && triggered && (numSamplesAccumed == secondaryAccumLB2);
		fifoWriteDataRegP <= sampleDecimationLB2 ? (decimateAndAccum ? secondaryAccumBuffer : decimationBuffer) : dataInR;
		firstSamplePhaseP <= firstSamplePhaseR;

		// when decimation is used, there are an additional 3 clock cycles of delay in the analog data pipeline. Add
		// appropriate delay to si triggers. syncTrigger is not supported with decimation on.
		for (dctr = 0; dctr < NUM_TRIGGER_BYTES; dctr = dctr + 1) begin
			siTriggerDataP[0][dctr] <= siTriggerAccumBuffer[dctr*8+:8];
			siTriggerDataP[1][dctr] <= siTriggerDataP[0][dctr];
			siTriggerDataP[2][dctr] <= siTriggerDataP[1][dctr];
			siTriggerDataP[3][dctr] <= sampleDecimationLB2 ? siTriggerDataP[2][dctr] : siTriggerAccumBuffer[dctr*8+:8];
		end

		// add fixed width sample data to fifo write row
		fifoWriteDataReg[15:0] <= fifoWriteDataRegP[15:0];

		// add variable width sample data for fifo row (one byte at a time)
		for (dctr = 2; dctr < MAX_DATA_WIDTH_BYTES; dctr = dctr + 1)  // dctr: sample byte index into fifoWriteDataReg
			if (dctr < sampleDataWidthBytes)
				fifoWriteDataReg[dctr*8+:8] <= fifoWriteDataRegP[dctr*8+:8];
			else // write trigger array early, since the fifo is variable width and changes based on decimation setting
				fifoWriteDataReg[dctr*8+:8] <= siTriggerDataP[3][dctr];

		// add trigger data after max sample data width (in case we have the whole row and do not decimate)
		for (dctr = 0; dctr < NUM_TRIGGER_BYTES; dctr = dctr + 1)
			fifoWriteDataReg[(MAX_DATA_WIDTH_BYTES+dctr)*8+:8] <= siTriggerDataP[3][dctr];

		// add sample phase afterwards (which is cut off if using decimation and less width)
		fifoWriteDataReg[(MAX_DATA_WIDTH_BYTES+NUM_TRIGGER_BYTES)*8+:16] <= firstSamplePhaseP;
		fifoWriteEnReg <= fifoWriteEnRegP;
	end
	
endmodule
