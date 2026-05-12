//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_DataScope #(
	parameter HSADC_SUPPORT = 0,
	parameter FIFO_WIDTH	= 80
)(
	input  wire dataClk,
	input  wire hsadcDataClk,
	
	input wire reset,
	input wire start,
	
	input wire [31:0] numberOfSamples,
	input wire [5:0]  sampleDecimationLB2,
	input wire [4:0]  triggerId,
	input wire [31:0] triggerHoldoff,
	input wire [15:0] triggerLineNumber,
	input wire customTrigger,
	
	input  wire afeSelect,
	input  wire [`MS_PHYS_CHANNEL_BUF_LSZ:0] msadcSampleData,
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataA,
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataB,
	input  wire [`HS_SAMPS_PER_TICK-1:0] hsPhotonPeaksA,
	input  wire [`HS_SAMPS_PER_TICK-1:0] hsPhotonPeaksB,
	input  wire hsChanSel,
	input  wire [1:0] hsScopeProbePhotons,
	input  wire [15:0] hsFirstSamplePhase,

	input  wire [`TRIGGER_PROCESS_OUT_LSZ:0] triggerProcessData,
	input  wire [`STATE_MACHINE_OUT_LSZ:0] stateMachineDataIn,
	input  wire [15:0] stateMachineCurrLine,
	input  wire dataValidIn,
	
	input  wire fifoFull,
	output wire fifoWriteEn,
	output wire [FIFO_WIDTH-1:0] fifoWriteData,
	output wire [31:0] fifoWriteCount,
	output wire [31:0] fifoOverflowCount
);
	wire [79:0] fifoWriteData_M;
	wire fifoWriteEn_M;
	wire trigger;

	wire [16:0] siTriggerArray;

	// insert pipeline stage
	reg [`MS_PHYS_CHANNEL_BUF_LSZ:0] msadcSampleData_R = 0;
	reg [15:0] siTriggerArrayM_R = 0;
	reg [15:0] stateMachineCurrLine_R = 0;
	reg dataValidIn_R = 0;

	always @(posedge dataClk) begin
		msadcSampleData_R <= msadcSampleData;
		siTriggerArrayM_R <= siTriggerArray[15:0];
		stateMachineCurrLine_R <= stateMachineCurrLine;
		dataValidIn_R <= dataValidIn;
	end

	SI_DataScope_M dataScopeM (
		.clk(dataClk),
		
		.reset(reset),
		.start(start),
		
		.numberOfSamples(numberOfSamples),
		.sampleDecimationLB2(sampleDecimationLB2),
		.trigger(trigger),
		
		.sampleData(msadcSampleData_R),
		.siTriggerArray(siTriggerArrayM_R),
		.dataValidIn(dataValidIn_R),
		
		.fifoWriteEn(fifoWriteEn_M),
		.fifoWriteData(fifoWriteData_M)
	);


	wire [FIFO_WIDTH-1:0] fifoWriteData_H;
	wire fifoWriteEn_H;

	generate
		if (HSADC_SUPPORT) begin
			// insert pipeline stage
			reg [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataA_R = 0;
			reg [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataB_R = 0;
			reg [16:0] siTriggerArrayH_R = 0;
			reg [15:0] hsFirstSamplePhase_R = 0;
			reg [`HS_SAMPS_PER_TICK-1:0] hsPhotonPeaksR = 0;

			always @(posedge hsadcDataClk) begin
				hsPhotonPeaksR <= (hsScopeProbePhotons == 1) ? hsPhotonPeaksA : hsPhotonPeaksB;
				hsadcSampleDataA_R <= hsadcSampleDataA;
				hsadcSampleDataB_R <= hsadcSampleDataB;
				siTriggerArrayH_R <= hsScopeProbePhotons ? {1'b0,hsPhotonPeaksR[15:0]} : siTriggerArray;
				hsFirstSamplePhase_R <= hsScopeProbePhotons ? hsPhotonPeaksR[31:16] : hsFirstSamplePhase;
			end

			SI_DataScope_H #(
				.FIFO_WIDTH(FIFO_WIDTH)
			) dataScopeH (
				.clk(hsadcDataClk),
				
				.reset(reset),
				.start(start),
				
				.numberOfSamples(numberOfSamples),
				.sampleDecimationLB2(sampleDecimationLB2),
				.trigger(trigger),
				.chanSel(hsChanSel),
				
				.sampleDataA(hsadcSampleDataA_R),
				.sampleDataB(hsadcSampleDataB_R),
				.firstSamplePhase(hsFirstSamplePhase_R),

				.siTriggerArray(siTriggerArrayH_R),
				.dataValidIn(dataValidIn_R),
				
				.fifoWriteEn(fifoWriteEn_H),
				.fifoWriteData(fifoWriteData_H)
			);
		end else begin
			assign fifoWriteData_H = 0;
			assign fifoWriteEn_H = 0;
		end
	endgenerate
	

	// Mux and stat track
	reg [FIFO_WIDTH-1:0] fifoWriteDataR = 0;
	reg fifoWriteEnR = 0;
	assign fifoWriteData = fifoWriteDataR;
	assign fifoWriteEn = fifoWriteEnR;
	
	reg [31:0] writeCount = 0;
	reg fifoOverflow = 0;
	reg [31:0] overflowCount = 0;

	always @(posedge dataClk) begin
		writeCount <= reset ? 0 : writeCount + fifoWriteEn;
		fifoOverflow <= fifoWriteEn && fifoFull;
		overflowCount <= reset ? 0 : overflowCount + fifoOverflow;

		fifoWriteDataR <= (afeSelect && HSADC_SUPPORT) ? fifoWriteData_H : fifoWriteData_M;
		fifoWriteEnR <= (afeSelect && HSADC_SUPPORT) ? fifoWriteEn_H : fifoWriteEn_M;
	end

	assign fifoWriteCount = writeCount;
	assign fifoOverflowCount = overflowCount;


	// trigger generation
	assign siTriggerArray = {
		triggerProcessData[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_SYNC_RAW_BIT],
		stateMachineDataIn[`STATE_MACHINE_OUT_CTL_SAMPLE_CLK_BIT],
		triggerProcessData[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_RAW_BIT],
		triggerProcessData[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_BIT],
		stateMachineDataIn[`STATE_MACHINE_OUT_VOLUME_CLK_BIT],
		stateMachineDataIn[`STATE_MACHINE_OUT_SLICE_CLK_BIT],
		stateMachineDataIn[`STATE_MACHINE_OUT_ROI_CLK_BIT],
		stateMachineDataIn[`STATE_MACHINE_OUT_BEAM_CLK_BIT],
		stateMachineDataIn[`STATE_MACHINE_OUT_LINE_CLK_BIT],
		stateMachineDataIn[`STATE_MACHINE_OUT_ACQ_CLK_BIT],
		triggerProcessData[`TRIGGER_PROCESS_OUT_STOP_TRIGGER_BIT],
		triggerProcessData[`TRIGGER_PROCESS_OUT_NEXT_TRIGGER_BIT],
		triggerProcessData[`TRIGGER_PROCESS_OUT_START_TRIGGER_BIT],
		triggerProcessData[`TRIGGER_PROCESS_OUT_DEL_MID_PERIOD_TRIGGER_BIT],
		triggerProcessData[`TRIGGER_PROCESS_OUT_DEL_PERIOD_TRIGGER_BIT],
		triggerProcessData[`TRIGGER_PROCESS_OUT_PERIOD_TRIGGER_BIT],
		triggerProcessData[`TRIGGER_PROCESS_OUT_PERIOD_TRIGGER_RAW_BIT]
	};
	wire [17:0] triggerArray = {customTrigger, siTriggerArray};

	reg pTrigger = 0;
	reg correctLine = 0;
	wire triggerPresent = triggerArray[triggerId - 1];
	wire triggerRE = ~pTrigger && triggerPresent && correctLine;
	reg sendTriggerNow = 0;
	reg [31:0] triggerHoldoffCtr = 0;
	reg triggerHoldoffCtrIs1 = 0;
	reg triggerHoldoffIsZero = 0;
	reg triggerHoldoffIs1 = 0;

	assign trigger = triggerId ? sendTriggerNow : 1'b1;

	always @(posedge dataClk) begin
		pTrigger <= triggerPresent;
		triggerHoldoffIsZero <= triggerHoldoff == 0;
		triggerHoldoffIs1 <= triggerHoldoff == 1;
		triggerHoldoffCtrIs1 <= (triggerHoldoffCtr == 2) || (triggerHoldoffIs1 && triggerRE);
		correctLine <= (triggerLineNumber == 0) || ((triggerLineNumber-1) == stateMachineCurrLine);

		sendTriggerNow <= ~reset && (triggerHoldoffCtrIs1 || (triggerHoldoffIsZero && triggerRE));
		
		if (reset)
			triggerHoldoffCtr <= 0;
		else if (triggerHoldoffCtr)
			triggerHoldoffCtr <= triggerHoldoffCtr - 1;
		else if (triggerRE)
			triggerHoldoffCtr <= triggerHoldoff;
	end
	
endmodule
