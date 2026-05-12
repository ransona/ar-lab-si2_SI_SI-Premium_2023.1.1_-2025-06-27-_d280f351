//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_SignalCondition #(
	parameter HS_NUM_LOGICAL_CHANNELS = 8,
	parameter MS_NUM_LOGICAL_CHANNELS = 8,
	parameter SAMPLE_PHASE_BITS = 12,
	parameter HSADC_LRR_SUPPORT = 0,
	parameter HSADC_SUPPORT = 0,
	parameter NO_MSADC_SUPPORT = 0
)(
	input  wire clk,
	input  wire hsClk,
	input  wire afeSelect,
	
	input  wire [`MS_PHYS_CHANNEL_BUF_LSZ:0] msadcSampleData,
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataA,
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataB,
	input  wire [15:0] hsSyncTrigger,
	input  wire [`HS_SAMPS_PER_TICK-1:0] hsPhotonPeaksA,
	input  wire [`HS_SAMPS_PER_TICK-1:0] hsPhotonPeaksB,

	input  wire enableMixedLasergating,
	input  wire [`TRIGGER_PROCESS_OUT_LSZ:0] triggerProcessData,
	output wire [`LOGICAL_CHANNEL_BUF_LSZ:0] dataOut,
	output wire [`PHYS_CHAN_BUF_LSZ:0] dataOutRaw,
	output wire dataOutValid,
	
	input  wire [`MS_NUM_PHYS_CHANNELS-1:0] channelsInvert,
	input  wire [`PHYS_CHAN_BUF_LSZ:0] channelOffsets,
	// TODO: acqParamMaskBits appears to be unused/deprecated
	input  wire [2:0] acqParamMaskBits,
	
	input  wire [HS_NUM_LOGICAL_CHANNELS*32-1:0] logicalChannelSettings,
	input  wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] laserTriggerFilterWindowStart,
	input  wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] laserTriggerFilterWindowN,

	input wire  [(SAMPLE_PHASE_BITS*`HS_SAMPS_PER_TICK)-1:0] samplePhasePacked
);
	wire [SAMPLE_PHASE_BITS-1:0] samplePhase[`HS_SAMPS_PER_TICK-1:0];

	wire [`LOGICAL_CHANNEL_BUF_LSZ:0] dataOutM;
	wire [`PHYS_CHAN_BUF_LSZ:0] dataOutRawM;
	wire dataOutValidM;

	wire [`LOGICAL_CHANNEL_BUF_LSZ:0] dataOutH;
	wire [`PHYS_CHAN_BUF_LSZ:0] dataOutRawH;
	wire dataOutValidH;

	assign dataOut = (HSADC_SUPPORT && afeSelect) ? dataOutH : dataOutM;
	assign dataOutRaw = (HSADC_SUPPORT && afeSelect) ? dataOutRawH : dataOutRawM;
	assign dataOutValid = (HSADC_SUPPORT && afeSelect) ? dataOutValidH : dataOutValidM;

	generate
		if (!NO_MSADC_SUPPORT) begin
			//(* KEEP_HIERARCHY = "YES" *)
			SI_SignalConditionM #(
				.HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
				.MS_NUM_LOGICAL_CHANNELS(MS_NUM_LOGICAL_CHANNELS),
				.SAMPLE_PHASE_BITS(SAMPLE_PHASE_BITS)
			) signalConditionM (
				.clk(clk),
				
				.sampleData(msadcSampleData),

				.enableMixedLasergating(enableMixedLasergating),
				.triggerProcessData(triggerProcessData),
				.dataOut(dataOutM),
				.dataOutRaw(dataOutRawM),
				.dataOutValid(dataOutValidM),
				
				.channelsInvert(channelsInvert),
				.channelOffsets(channelOffsets),
				.acqParamMaskBits(acqParamMaskBits),
				.logicalChannelSettings(logicalChannelSettings),
				.laserTriggerFilterWindowStart(laserTriggerFilterWindowStart),
				.laserTriggerFilterWindowN(laserTriggerFilterWindowN)
			);
		end else begin
			assign dataOutM = 0;
			assign dataOutRawM = 0;
			assign dataOutvalidM = 0;
		end

		if (HSADC_SUPPORT && HSADC_LRR_SUPPORT) begin
			//(* KEEP_HIERARCHY = "YES" *)
			SI_SignalConditionH_LRR #(
				.HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
				.SAMPLE_PHASE_BITS(SAMPLE_PHASE_BITS)
			) signalConditionH_LRR (
				.clk(hsClk),
				
				.sampleDataA(hsadcSampleDataA),
				.sampleDataB(hsadcSampleDataB),
				.photonPeaksA(hsPhotonPeaksA),
				.photonPeaksB(hsPhotonPeaksB),

				.dataOut(dataOutH),
				.dataOutRaw(dataOutRawH),
				.dataOutValid(dataOutValidH),
				
				.channelsInvert(channelsInvert),
				.channelOffsets(channelOffsets),
				.logicalChannelSettings(logicalChannelSettings),
				.laserTriggerFilterWindowStart(laserTriggerFilterWindowStart),
				.laserTriggerFilterWindowN(laserTriggerFilterWindowN),

				.samplePhasePacked(samplePhasePacked)
			);
		end else if (HSADC_SUPPORT) begin
			//(* KEEP_HIERARCHY = "YES" *)
			SI_SignalConditionH #(
				.HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
				.SAMPLE_PHASE_BITS(SAMPLE_PHASE_BITS)
			) signalConditionH (
				.clk(hsClk),
				
				.sampleDataA(hsadcSampleDataA),
				.sampleDataB(hsadcSampleDataB),
				.syncTrigger(hsSyncTrigger),
				.photonPeaksA(hsPhotonPeaksA),
				.photonPeaksB(hsPhotonPeaksB),

				.dataOut(dataOutH),
				.dataOutRaw(dataOutRawH),
				.dataOutValid(dataOutValidH),
				
				.channelsInvert(channelsInvert),
				.channelOffsets(channelOffsets),
				.logicalChannelSettings(logicalChannelSettings),
				.laserTriggerFilterWindowStart(laserTriggerFilterWindowStart),
				.laserTriggerFilterWindowN(laserTriggerFilterWindowN),

				.samplePhasePacked(samplePhasePacked)
			);
		end else begin
			assign dataOutH = 0;
			assign dataOutRawH = 0;
			assign dataOutValidH = 0;
		end
	endgenerate
	
endmodule
