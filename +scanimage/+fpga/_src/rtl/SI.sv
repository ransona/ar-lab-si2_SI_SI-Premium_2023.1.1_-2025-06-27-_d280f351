//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI #(
	parameter NUM_DIO = 32,
	parameter NUM_RTSI	= 16,
	parameter NUM_ECLK	= 1,
	parameter CFG_BASE_ADDR = 0,
	parameter CFG_ADDR_WIDTH = 12,
	
	parameter MAX_NUM_PHY_CHANNELS = 4,
	parameter MASK_ADDR_BITS = 12,

	parameter HS_NUM_LOGICAL_CHANNELS = 8,
	parameter MS_NUM_LOGICAL_CHANNELS = 8,		// note, MS_NUM_LOGICAL_CHANNELS must be <= HS_NUM_LOGICAL_CHANNELS
	parameter NUM_DIVIDERS = 4,
	parameter HSADC_SUPPORT = 0,
	parameter DATA_FIFO_WIDTH = 64,
	parameter SAMPLE_PHASE_BITS = 12,
	parameter ACCUM_MULTIPLY_SUPPORT = 1,
	parameter HSADC_LRR_SUPPORT = 0,
	parameter NO_MSADC_SUPPORT = 0,

	parameter ACCUM_COEFFICIENT_FIXED_POINT_PRECISION = 16,
	
	localparam CFG_ADDR_SPACE = 1024,
	localparam SAMPLE_PHASE_BITS_DUMMY_SZ = 16 - SAMPLE_PHASE_BITS
)(
	input  wire dataClk,
	input  wire hsadcDataClk,
	input  wire cfgClk,
	input  wire resetn_dc,
	
	input  wire [63:0] systemClock,
	
	input  wire cfgWriteActive,
	input  wire [CFG_ADDR_WIDTH-1:0] cfgWriteAddr,
	input  wire [31:0] cfgWriteData,
	input  wire [CFG_ADDR_WIDTH-1:0] cfgReadAddr,
	output wire [31:0] cfgReadData,
	
	input  wire afeSelect,
	input  wire [`MS_PHYS_CHANNEL_BUF_LSZ:0] msadcSampleData,
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataA,
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataB,
	input  wire [15:0] hsSyncTrigger,  // sample clock half rate of ADC 16 bits
	input  wire [`HS_SAMPS_PER_TICK-1:0] hsPhotonPeaksA,
	input  wire [`HS_SAMPS_PER_TICK-1:0] hsPhotonPeaksB,
	
	input  wire [NUM_ECLK+NUM_RTSI+NUM_DIO-1:0] DIO_I,
	output wire [8:0] digitalTriggersOut,
	output wire [15:0] acqStatusLinesDone,
	
	input  wire dataFifoFull,
	output wire dataFifoWriteEn,
	output wire [5:0] dataFifoWriteWidth,
	output wire [DATA_FIFO_WIDTH-1:0] dataFifoData,
	
	input  wire triggerFifoFull,
	output wire triggerFifoWriteEn,
	output wire [79:0] triggerFifoData,
	
	output wire [`TRIGGER_PROCESS_OUT_LSZ:0] scopeTriggerProcessDataOut,
	output wire [`STATE_MACHINE_OUT_LSZ:0] scopeStateMachineDataOut,

	input  wire [(SAMPLE_PHASE_BITS*`HS_SAMPS_PER_TICK)-1:0] samplePhasePacked
);
	wire [CFG_ADDR_WIDTH-1:0] cfgOffsetWriteAddr = cfgWriteAddr - CFG_BASE_ADDR;
	wire [CFG_ADDR_WIDTH-1:0] cfgActiveWriteAddr = (cfgWriteActive && (cfgWriteAddr > CFG_BASE_ADDR) && ((cfgOffsetWriteAddr) < CFG_ADDR_SPACE)) ? cfgOffsetWriteAddr : 0;
	wire [CFG_ADDR_WIDTH-1:0] cfgOffsetReadAddr = cfgReadAddr - CFG_BASE_ADDR;
	reg  [31:0] cfgReadDataReg;
	assign cfgReadData = cfgReadDataReg;
	
	wire enableSm;
	wire resetSm_cc = (cfgActiveWriteAddr == 100) && (cfgWriteData == 38);
	wire resetSm_sc;
	wire resetSm = ~resetn_dc || resetSm_sc;
	wire softStartTrig;
	wire softNextTrig;
	wire softStopTrig;
	
	OSCC enableSm_crss(.srcV((cfgActiveWriteAddr == 100) && (cfgWriteData == 37)),.srcClk(cfgClk),.dstV(enableSm),.dstClk(dataClk));
	OSCC resetSm_crss(.srcV(resetSm_cc),.srcClk(cfgClk),.dstV(resetSm_sc),.dstClk(dataClk));
	OSCC softStart_crss(.srcV((cfgActiveWriteAddr == 100) && (cfgWriteData == 39)),.srcClk(cfgClk),.dstV(softStartTrig),.dstClk(dataClk));
	OSCC softNext_crss(.srcV((cfgActiveWriteAddr == 100) && (cfgWriteData == 40)),.srcClk(cfgClk),.dstV(softNextTrig),.dstClk(dataClk));
	OSCC softStop_crss(.srcV((cfgActiveWriteAddr == 100) && (cfgWriteData == 41)),.srcClk(cfgClk),.dstV(softStopTrig),.dstClk(dataClk));
	
	
	wire acqPlanWriteEnable = (cfgActiveWriteAddr == 104);
	wire [11:0] acqPlanWriteAddr = cfgWriteData[20:9];
	wire [8:0] acqPlanWriteData = cfgWriteData[8:0];
	reg [11:0] acqPlanNumSteps = 0;
	
	
	wire  maskTblWriteEnable = (cfgActiveWriteAddr == 112);
	wire [MASK_ADDR_BITS-1:0] maskTblWriteAddr = cfgWriteData;
	reg  [`ACCUM_BITS-1:0] maskTblWriteBin = 0;
	reg  [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] maskTblWriteDivisor = 0;
	wire [`ACCUM_MASK_TABLE_LSZ:0] maskTblWriteData = {maskTblWriteBin, maskTblWriteDivisor};
	reg  [MASK_ADDR_BITS-1:0] acqParamMaskSize = 0;
	
	reg [17:0] acqParamPeriodTriggerMaxPeriod = 16700;
	reg [17:0] acqParamPeriodTriggerMinPeriod = 0;
	reg [15:0] acqParamPeriodTriggerSettledThresh = 790;
	wire acqStatusPeriodClockSettled;
	reg acqParamPeriodTriggerSettledGate = 0;
	reg [17:0] acqParamSimulatedResonantPeriod = 0;
	reg acqParamEnableLineTag = 1;

	reg acqParamAnalogResonantPhaseDetection = 0;
	reg [`LOGICAL_CHANNEL_LSZ:0] acqParamAnalogResonantPhaseThreshold = 1000;
	
	reg [5:0] acqParamPeriodTriggerChIdx = 0;
	reg [5:0] acqParamStartTriggerChIdx = 63;
	reg [5:0] acqParamNextTriggerChIdx = 63;
	reg [5:0] acqParamStopTriggerChIdx = 63;
	reg acqParamStartTriggerInvert = 0;
	reg acqParamNextTriggerInvert = 0;
	reg acqParamStopTriggerInvert = 0;
	reg [4:0] acqParamPhotonChIdx = 4;
	reg [5:0] acqParamLaserClkChIdx = 63;
	reg [5:0] acqParamLaserClkSyncChIdx = 63;
	reg [9:0] acqParamPeriodTriggerDebounce = 0;  // note if changing debounce widths, also change widths in matlab when acq params are set
	reg [4:0] acqParamTriggerDebounce = 0;
	reg [4:0] acqParamPhotonPulseDebounce = 0;
	reg [4:0] acqParamLaserClkDebounce = 0;
	reg [15:0] acqParamTriggerHoldoff = 0;
	reg acqParamLiveHoldoffAdjustEnable = 0;
	reg [15:0] acqParamLiveHoldoffAdjustPeriod = 0;
	reg [5:0] acqParamAuxTrig1TriggerChIdx = 63;
	reg [5:0] acqParamAuxTrig2TriggerChIdx = 63;
	reg [5:0] acqParamAuxTrig3TriggerChIdx = 63;
	reg [5:0] acqParamAuxTrig4TriggerChIdx = 63;
	reg [4:0] acqParamAuxTriggerDebounce = 0;
	reg [3:0] acqParamAuxTriggerInvert = 0;
	reg acqParamAuxTriggerEnable = 0;
	reg [31:0] acqParamSampleClkPulsesPerPeriod = 100;
	reg [15:0] acqParamLinearSampleClkPulseDuration = 125;
	
	reg [MAX_NUM_PHY_CHANNELS-1:0] acqParamChannelsInvert = 0;
	reg [`PHYS_CHAN_BUF_LSZ:0] acqParamChannelOffsets = 0;
	
	reg acqParamEnableBidi;
	reg [15:0] acqParamSamplesPerLine = 0;
	reg [31:0] acqParamVolumesPerAcq = 0;
	reg [31:0] acqParamTotalAcqs = 0;
	reg [15:0] acqParamBeamClockAdvance = 0;
	reg [15:0] acqParamBeamClockDuration = 0;
	
	reg [16:0] acqParamDummyVal = 0;
	reg [2:0]  acqParamMaskBits = 0;
	
	reg [NUM_DIVIDERS-1:0] acqParamDisableDivide = 0;
	
	reg acqParamLinearMode = 0;
	reg [31:0] acqParamLinearFramesPerVolume = 0;
	reg [31:0] acqParamLinearFrameClkHighTime = 0;
	reg [31:0] acqParamLinearFrameClkLowTime = 0;
	
	reg [5:0] acqParamDataFifoWriteWidth1 = 7;
	reg [5:0] acqParamDataFifoWriteWidth2 = 0;
	
	reg acqParamUniformSampling = 0;
	reg [`ACCUM_BITS-1:0] acqParamUniformBinSize = 0;
	reg [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] acqParamUniformBinCoefficient = 0;

	reg i2cEnable = 0;
	reg [4:0] i2cParamDebounce = 0;
	reg [6:0] i2cParamAddress = 0;
	reg [5:0] i2cParamSdaChIdx = 0;
	reg [5:0] i2cParamSclChIdx = 0;

	reg acqParamEnableMixedLasergating = 0;
	
	
	wire [15:0] acqParamTriggerHoldoff_sc;
	SWCC #(.WW(16)) trigHoldoff_crss(.srcV(acqParamTriggerHoldoff), .srcClk(cfgClk), .dstV(acqParamTriggerHoldoff_sc), .dstClk(dataClk), .dstRst(0));
	
	wire [9:0]  acqParamPeriodTriggerDebounce_sc;
	SWCC #(.WW(10)) trigDebounce_crss(.srcV(acqParamPeriodTriggerDebounce), .srcClk(cfgClk), .dstV(acqParamPeriodTriggerDebounce_sc), .dstClk(dataClk), .dstRst(0));
	
	wire [17:0] acqStatusPeriodTriggerPeriod;
	wire [17:0] acqStatusPeriodTriggerPeriod_cc;
	SWCC #(.WW(18)) trigPeriod_crss(.srcV(acqStatusPeriodTriggerPeriod), .srcClk(dataClk), .dstV(acqStatusPeriodTriggerPeriod_cc), .dstClk(cfgClk), .dstRst(0));
	
	wire [3:0] acqStatusSmState;
	wire [3:0] acqStatusSmState_cc;
	SWCC #(.WW(4)) smState_crss(.srcV(acqStatusSmState), .srcClk(dataClk), .dstV(acqStatusSmState_cc), .dstClk(cfgClk), .dstRst(0));
	
	wire [31:0] acqStatusVolumesDone;
	wire [31:0] acqStatusVolumesDone_cc;
	SWCC #(.WW(32)) vd_crss(.srcV(acqStatusVolumesDone), .srcClk(dataClk), .dstV(acqStatusVolumesDone_cc), .dstClk(cfgClk), .dstRst(0));
	
	wire [`PHYS_CHAN_BUF_LSZ:0] logicalChannelsRaw;
	wire [`PHYS_CHAN_BUF_LSZ:0] logicalChannelsRaw_cc;
	SWCC #(.WW(`PHYS_CHAN_BUF_SIZE)) rawData_crss(.srcV(logicalChannelsRaw), .srcClk(dataClk), .dstV(logicalChannelsRaw_cc), .dstClk(cfgClk), .dstRst(0));


	// logical channel settings
	reg [5:0] logicalChannelAccessIdx = 0;
	wire [HS_NUM_LOGICAL_CHANNELS*32-1:0] acqParamLogicalChannelSettings_cc;
	wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] acqParamLaserTriggerFilterWindowStart_cc;
	wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] acqParamLaserTriggerFilterWindowN_cc;

	wire [HS_NUM_LOGICAL_CHANNELS*32-1:0] acqParamLogicalChannelSettings;
	wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] acqParamLaserTriggerFilterWindowStart;
	wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] acqParamLaserTriggerFilterWindowN;

	generate
		genvar lc_i;
		
		for (lc_i = 0; lc_i < HS_NUM_LOGICAL_CHANNELS; lc_i=lc_i+1) begin:gen_logical_channel_settings
			wire [5:0] signalSource = (lc_i > 3) ? 0 : lc_i;
			wire applyThreshold = 0;
			wire binarize = 0;
			wire edgeDetect = 0;
			wire laserGate = 0;
			wire downShift = 1;
			wire signed [15:0] thresh = 0;
			//											  {thresh, 5'd0, downShift, laserGate, edgeDetect, binarize, applyThreshold, signalSource};
			reg [31:0] acqParamLogicalChannelSettings_R;
			reg [SAMPLE_PHASE_BITS-1:0] acqParamLaserTriggerFilterWindowStart_R = 0;
			reg [SAMPLE_PHASE_BITS-1:0] acqParamLaserTriggerFilterWindowN_R = 1;

			initial begin
				acqParamLogicalChannelSettings_R[5:0] = (lc_i > 3) ? 0 : lc_i;	// signalSource
				acqParamLogicalChannelSettings_R[6] = 0;						// applyThreshold
				acqParamLogicalChannelSettings_R[7] = 0;						// binarize
				acqParamLogicalChannelSettings_R[8] = 0;						// edgeDetect
				acqParamLogicalChannelSettings_R[9] = 0;						// laserGate
				acqParamLogicalChannelSettings_R[10] = 1;						// downShift
				acqParamLogicalChannelSettings_R[31:16] = 0;					// threshold
			end
			
			assign acqParamLogicalChannelSettings_cc[lc_i*32+:32] = acqParamLogicalChannelSettings_R;
			assign acqParamLaserTriggerFilterWindowStart_cc[lc_i*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS] = acqParamLaserTriggerFilterWindowStart_R;
			assign acqParamLaserTriggerFilterWindowN_cc[lc_i*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS] = acqParamLaserTriggerFilterWindowN_R;

			always @(posedge cfgClk)
				if (logicalChannelAccessIdx == lc_i)
					case (cfgActiveWriteAddr)
						316:	acqParamLogicalChannelSettings_R <= cfgWriteData;
						
						320:	begin
									acqParamLaserTriggerFilterWindowStart_R <= cfgWriteData[SAMPLE_PHASE_BITS-1:0];
									acqParamLaserTriggerFilterWindowN_R <= cfgWriteData[31:16];
								end
					endcase

		//	SWCC #(.WW(32)) lcs_crss(.srcV(acqParamLogicalChannelSettings_R), .srcClk(cfgClk), .dstV(acqParamLogicalChannelSettings[lc_i*32+:32]), .dstClk(dataClk), .dstRst(0));
		//	SWCC #(.WW(12)) wndoS_crss(.srcV(acqParamLaserTriggerFilterWindowStart_R), .srcClk(cfgClk), .dstV(acqParamLaserTriggerFilterWindowStart[lc_i*12+:12]), .dstClk(dataClk), .dstRst(0));
		//	SWCC #(.WW(12)) wndN_crss(.srcV(acqParamLaserTriggerFilterWindowN_R), .srcClk(cfgClk), .dstV(acqParamLaserTriggerFilterWindowN[lc_i*12+:12]), .dstClk(dataClk), .dstRst(0));
			assign acqParamLogicalChannelSettings[lc_i*32+:32] = acqParamLogicalChannelSettings_R;
			assign acqParamLaserTriggerFilterWindowStart[lc_i*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS] = acqParamLaserTriggerFilterWindowStart_R;
			assign acqParamLaserTriggerFilterWindowN[lc_i*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS] = acqParamLaserTriggerFilterWindowN_R;
		end
	endgenerate


	// calc acq holdoff
	wire [15:0] periodClockDelay = (acqParamBeamClockAdvance > acqParamTriggerHoldoff_sc) ? 0 : acqParamTriggerHoldoff_sc - acqParamBeamClockAdvance;
	wire [15:0] acqParamAcqHoldoff = acqParamTriggerHoldoff_sc - periodClockDelay;
	
	wire pixelClock;
	wire aeSampleClk;
	
	wire [`TRIGGER_PROCESS_OUT_LSZ:0]		triggerProcessData;
	wire [`LOGICAL_CHANNEL_BUF_LSZ:0]		logicalChannels;
	wire 									logicalChannelDataValid;
	wire [`LOGICAL_CHANNEL_BUF_LSZ:0]		stateMachineLogicalChannels;
	wire [`STATE_MACHINE_OUT_LSZ:0]			stateMachineData;
	wire [`STATE_MACHINE_OUT_LSZ:0]			accumStateMachineData;
	wire [`LOGICAL_CHANNEL_BUF_LSZ:0]		pixelData;
	wire									pixelValid;
	wire									pixelEndOfLine;
	
	wire 		i2cDataValid;
	wire 		i2cPacketStart;
	wire 		i2cPacketEnd;
	wire [7:0]	i2cPacketData;
	wire		i2cAck;
	
	// Output signals
	assign digitalTriggersOut = {i2cAck, aeSampleClk, stateMachineData[7:2], pixelClock};
	assign scopeTriggerProcessDataOut = triggerProcessData;
	assign scopeStateMachineDataOut = stateMachineData;
	

	// Pipeline
	SI_TriggerProcess #(
		.NUM_DI(NUM_ECLK+NUM_RTSI+NUM_DIO)
	) triggerProcess (
		.clk(dataClk),
		.DI(DIO_I),
	
		.dataOut(triggerProcessData),
	
		.periodTriggerHoldoff(periodClockDelay),
		.periodTriggerChIdx(acqParamPeriodTriggerChIdx),
		.startTriggerChIdx(acqParamStartTriggerChIdx),
		.nextTriggerChIdx(acqParamNextTriggerChIdx),
		.stopTriggerChIdx(acqParamStopTriggerChIdx),
		.startTriggerInvert(acqParamStartTriggerInvert),
		.nextTriggerInvert(acqParamNextTriggerInvert),
		.stopTriggerInvert(acqParamStopTriggerInvert),
		.photonChIdx(acqParamPhotonChIdx),
		.laserClkChIdx(acqParamLaserClkChIdx),
		.laserClkSyncChIdx(acqParamLaserClkSyncChIdx),
		.periodTriggerDebounce(acqParamPeriodTriggerDebounce_sc),
		.triggerDebounce(acqParamTriggerDebounce),
		.photonPulseDebounce(acqParamPhotonPulseDebounce),
		.laserClkDebounce(acqParamLaserClkDebounce),
		.liveHoldoffAdjustEnable(acqParamLiveHoldoffAdjustEnable),
		.liveHoldoffAdjustPeriod(acqParamLiveHoldoffAdjustPeriod),
		.auxTrig1TriggerChIdx(acqParamAuxTrig1TriggerChIdx),
		.auxTrig2TriggerChIdx(acqParamAuxTrig2TriggerChIdx),
		.auxTrig3TriggerChIdx(acqParamAuxTrig3TriggerChIdx),
		.auxTrig4TriggerChIdx(acqParamAuxTrig4TriggerChIdx),
		.auxTriggerDebounce(acqParamAuxTriggerDebounce),
		.auxTriggerInvert(acqParamAuxTriggerInvert),
		.acqParamAuxTriggerEnable(acqParamAuxTriggerEnable),
		.acqParamPeriodTriggerMaxPeriod(acqParamPeriodTriggerMaxPeriod),
		.acqParamPeriodTriggerMinPeriod(acqParamPeriodTriggerMinPeriod),
		.acqParamPeriodTriggerSettledThresh(acqParamPeriodTriggerSettledThresh),
		.acqParamSimulatedResonantPeriod(acqParamSimulatedResonantPeriod),
		.periodTriggerSettledGate(acqParamPeriodTriggerSettledGate),
	
		.acqParamAnalogResonantPhaseDetection(acqParamAnalogResonantPhaseDetection),
		.acqParamAnalogResonantPhaseThreshold(acqParamAnalogResonantPhaseThreshold),
		.acqParamAnalogResonantPhaseValue(logicalChannelsRaw[`LOGICAL_CHANNEL_WIDTH*3+:`LOGICAL_CHANNEL_WIDTH]),
		
		.periodClockPeriod(acqStatusPeriodTriggerPeriod),
		.periodClockSettled(acqStatusPeriodClockSettled)
	);
	
	//(* KEEP_HIERARCHY = "YES" *)
	SI_SignalCondition #(
		.HSADC_SUPPORT(HSADC_SUPPORT),
		.HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
		.MS_NUM_LOGICAL_CHANNELS(MS_NUM_LOGICAL_CHANNELS),
		.SAMPLE_PHASE_BITS(SAMPLE_PHASE_BITS),
		.HSADC_LRR_SUPPORT(HSADC_LRR_SUPPORT),
		.NO_MSADC_SUPPORT(NO_MSADC_SUPPORT)
	) signalCondition (
		.clk(dataClk),
		.hsClk(hsadcDataClk),
		.afeSelect(afeSelect),
		
		.msadcSampleData(msadcSampleData),
		.hsadcSampleDataA(hsadcSampleDataA),
		.hsadcSampleDataB(hsadcSampleDataB),
		.hsSyncTrigger(hsSyncTrigger),
		.hsPhotonPeaksA(hsPhotonPeaksA),
		.hsPhotonPeaksB(hsPhotonPeaksB),

		.enableMixedLasergating(acqParamEnableMixedLasergating),
		.triggerProcessData(triggerProcessData),
		.dataOut(logicalChannels),
		.dataOutRaw(logicalChannelsRaw),
		.dataOutValid(logicalChannelDataValid),
		
		.channelsInvert(acqParamChannelsInvert),
		.channelOffsets(acqParamChannelOffsets),
		.acqParamMaskBits(acqParamMaskBits),
		.logicalChannelSettings(acqParamLogicalChannelSettings),
		.laserTriggerFilterWindowStart(acqParamLaserTriggerFilterWindowStart),
		.laserTriggerFilterWindowN(acqParamLaserTriggerFilterWindowN),

		.samplePhasePacked(samplePhasePacked)
	);
	
	SI_I2C i2c (
		// clk/reset
		.clk(dataClk),
		.resetSm(resetSm),
		.startSm(i2cEnable && enableSm),
		
		// params/settings
		.debounce(i2cParamDebounce),
		.myAddress(i2cParamAddress),
		.sdaChIdx(i2cParamSdaChIdx),
		.sclChIdx(i2cParamSclChIdx),
		
		// input signals
		.DIO_I(DIO_I),
		
		// output signals
		.ackAtv(i2cAck),
		
		// output data
		.dataValid(i2cDataValid),
		.packetStart(i2cPacketStart),
		.packetEnd(i2cPacketEnd),
		.packetData(i2cPacketData)
	);
	
	SI_StateMachine #(
		.HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS)
	) stateMchine (
		.dataClk(dataClk),
		.cfgClk(cfgClk),
		
		.systemClock(systemClock),
		
		.enableSm(enableSm),
		.resetSm(resetSm),
		.softStartTrig(softStartTrig),
		.softNextTrig(softNextTrig),
		.softStopTrig(softStopTrig),
		
		.triggerProcessData(triggerProcessData),
		.periodClockPeriod(acqStatusPeriodTriggerPeriod),

		.dataOut(stateMachineData),
		.aeSampleClkOut(aeSampleClk),

		.logicalChannelsIn(logicalChannels),
		.logicalChannelDataValid(logicalChannelDataValid),
		.logicalChannelsOut(stateMachineLogicalChannels),
		
		.i2cDataValid(i2cDataValid),
		.i2cPacketStart(i2cPacketStart),
		.i2cPacketEnd(i2cPacketEnd),
		.i2cPacketData(i2cPacketData),
		
		.writeTriggerEn(triggerFifoWriteEn),
		.writeTriggerData(triggerFifoData),
		
		.acqPlanWriteEnable(acqPlanWriteEnable),
		.acqPlanWriteAddr(acqPlanWriteAddr),
		.acqPlanWriteData(acqPlanWriteData),
		.acqPlanNumSteps(acqPlanNumSteps),
		
		.acqParamEnableBidi(acqParamEnableBidi),
		.acqParamSamplesPerLine(acqParamSamplesPerLine),
		.acqParamVolumesPerAcq(acqParamVolumesPerAcq),
		.acqParamTotalAcqs(acqParamTotalAcqs),
		.acqParamAcqHoldoff(acqParamAcqHoldoff),
		.acqParamBeamClockDuration(acqParamBeamClockDuration),
		
		.acqParamLinearMode(acqParamLinearMode),
		.acqParamLinearFramesPerVolume(acqParamLinearFramesPerVolume),
		.acqParamLinearFrameClkHighTime(acqParamLinearFrameClkHighTime),
		.acqParamLinearFrameClkLowTime(acqParamLinearFrameClkLowTime),
		.acqParamSampleClkPulsesPerPeriod(acqParamSampleClkPulsesPerPeriod),
		.acqParamLinearSampleClkPulseDuration(acqParamLinearSampleClkPulseDuration),
		
		.acqStatusSmState(acqStatusSmState),
		.acqStatusVolumesDone(acqStatusVolumesDone),
		.acqStatusLinesDone(acqStatusLinesDone)
	);
	
	generate
		if (ACCUM_MULTIPLY_SUPPORT) begin
			
			wire [`ACCUM_BUF_LSZ:0]						accumData;
			wire [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0]	accumCoefficient;
			wire 										accumDone;

			SI_SampleAccum #(
				.MASK_ADDR_BITS(MASK_ADDR_BITS),
				.HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
				.NUM_DIVIDERS(NUM_DIVIDERS)
			) sampleAccum (
				.dataClk(dataClk),
				.cfgClk(cfgClk),
				.resetSm(resetSm),
				
				.maskTblWriteEnable(maskTblWriteEnable),
				.maskTblWriteAddr(maskTblWriteAddr),
				.maskTblWriteData(maskTblWriteData),
				.maskSize(acqParamMaskSize),
				
				.acqParamUniformSampling(acqParamUniformSampling),
				.acqParamUniformBinSize(acqParamUniformBinSize),
				.acqParamUniformBinCoefficient(acqParamUniformBinCoefficient),
				
				.stateMachineDataIn(stateMachineData),
				.logicalChannelsIn(stateMachineLogicalChannels),
				
				.stateMachineDataOut(accumStateMachineData),
				.logicalChannelsAccumOut(accumData),
				.coefficient(accumCoefficient),
				.accumDone(accumDone),
				.pixelClock(pixelClock),
				
				.acqParamDummyVal(acqParamDummyVal)
			);
			
			SI_SampleMultiply #(
				.HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
				.NUM_DIVIDERS(NUM_DIVIDERS),
				.ACCUM_COEFFICIENT_FIXED_POINT_PRECISION(ACCUM_COEFFICIENT_FIXED_POINT_PRECISION)
			) sampleMultiply (
				.clk(dataClk),
				
				.accumStateMachineDataIn(accumStateMachineData),
				.logicalChannelsAccumIn(accumData),
				.coefficientIn(accumCoefficient),
				.accumDone(accumDone),
				
				.outputPixelData(pixelData),
				.pixelDataValid(pixelValid),
				.endOfLine(pixelEndOfLine),
				
				.disableDivide(acqParamDisableDivide)
			);

		end else begin
			
			assign pixelData = stateMachineLogicalChannels;
			assign pixelValid = stateMachineData[`STATE_MACHINE_OUT_ACQ_CLK_BIT];
			assign pixelEndOfLine = stateMachineData[`STATE_MACHINE_OUT_EOL_BIT];
			assign accumStateMachineData = stateMachineData;

		end
	endgenerate


	SI_LineTag #(
		.HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
		.FIFO_WIDTH(DATA_FIFO_WIDTH)
	) lineTag (
		.clk(dataClk),

		.acqParamEnableLineTag(acqParamEnableLineTag),

		// space optimization to make it so we don't need a 64 width fifo
		.dataWriteWidth1(acqParamDataFifoWriteWidth1),
		.dataWriteWidth2(acqParamDataFifoWriteWidth2),
		
		.accumStateMachineDataIn(accumStateMachineData),
		.pixelDataIn(pixelData),
		.pixelValid(pixelValid),
		.pixelEndOfLine(pixelEndOfLine),
		
		.fifoWriteEn(dataFifoWriteEn),
		.fifoData(dataFifoData),
		.fifoWriteWidth(dataFifoWriteWidth)
	);

	
	// logging of fifo full events
	reg [31:0] dataFifoOverflowCount = 0;
	reg [31:0] triggerFifoOverflowCount = 0;

	reg dataFifoOverflow = 0;
	reg triggerFifoOverflow = 0;
	
	always @(posedge dataClk) begin
		dataFifoOverflow <= dataFifoWriteEn && dataFifoFull;
		dataFifoOverflowCount <= resetSm ? 0 : dataFifoOverflowCount + dataFifoOverflow;

		triggerFifoOverflow <= triggerFifoWriteEn && triggerFifoFull;
		triggerFifoOverflowCount <= resetSm ? 0 : triggerFifoOverflowCount + triggerFifoOverflow;
	end

	
	// configuration logic
	always @(posedge cfgClk) begin
		case (cfgActiveWriteAddr)
			108:	acqPlanNumSteps <= cfgWriteData;
			
			116:	acqParamMaskSize <= cfgWriteData; // mask size should be set to actual mask size - 1
			
			120:	acqParamPeriodTriggerChIdx <= cfgWriteData;
			
			124:	acqParamStartTriggerChIdx <= cfgWriteData;
			
			128:	acqParamNextTriggerChIdx <= cfgWriteData;
			
			132:	acqParamStopTriggerChIdx <= cfgWriteData;
			
			136:	acqParamPhotonChIdx <= cfgWriteData;
			
			140:	acqParamPeriodTriggerDebounce <= cfgWriteData;
			
			144:	acqParamTriggerDebounce <= cfgWriteData;
			
			148:	acqParamLiveHoldoffAdjustEnable <= cfgWriteData;
			
			152:	acqParamLiveHoldoffAdjustPeriod <= cfgWriteData;
			
			156:	acqParamTriggerHoldoff <= cfgWriteData;
			
			160:	acqParamChannelsInvert <= cfgWriteData;
			
			164:	acqParamEnableLineTag <= cfgWriteData;
			
			168:	acqParamSamplesPerLine <= cfgWriteData;
			
			172:	acqParamVolumesPerAcq <= cfgWriteData;
			
			176:	acqParamTotalAcqs <= cfgWriteData;
			
			180:	acqParamBeamClockAdvance <= cfgWriteData;
			
			184:	acqParamBeamClockDuration <= cfgWriteData;
			
			188:	acqParamDummyVal <= cfgWriteData;
			
			192:	acqParamDisableDivide <= cfgWriteData;

			// 196: FREE
			
			200:	acqParamEnableBidi <= cfgWriteData;
			
			204:	acqParamPhotonPulseDebounce <= cfgWriteData;
			
			// TODO: acqParamMaskBits appears to be unused/deprecated
			208: 	acqParamMaskBits <= cfgWriteData;
			
			212: 	acqParamAuxTrig1TriggerChIdx <= cfgWriteData;
			
			216: 	acqParamAuxTrig2TriggerChIdx <= cfgWriteData;
			
			220: 	acqParamAuxTrig3TriggerChIdx <= cfgWriteData;
			
			224: 	acqParamAuxTrig4TriggerChIdx <= cfgWriteData;
			
			228: 	acqParamAuxTriggerDebounce <= cfgWriteData;
			
			232: 	acqParamAuxTriggerEnable <= cfgWriteData;
			
			236: 	acqParamPeriodTriggerMaxPeriod <= cfgWriteData;
			
			240: 	acqParamPeriodTriggerSettledThresh <= cfgWriteData;
			
			244:	acqParamDataFifoWriteWidth1 <= cfgWriteData;
			
			248:	acqParamDataFifoWriteWidth2 <= cfgWriteData;
			
			252:	acqParamEnableMixedLasergating <= cfgWriteData;
			
		//	256:	 <= cfgWriteData;
			
			260:	acqParamLinearMode <= cfgWriteData;
		
			264:	acqParamLinearFramesPerVolume <= cfgWriteData;
		
			268:	acqParamLinearFrameClkHighTime <= cfgWriteData;
		
			272:	acqParamLinearFrameClkLowTime <= cfgWriteData;
		
			276:	acqParamUniformSampling <= cfgWriteData;
		
			280:	acqParamUniformBinSize <= cfgWriteData;
		
			284:	acqParamSimulatedResonantPeriod <= cfgWriteData;
		
			288:	acqParamAuxTriggerInvert <= cfgWriteData;
			
			292:	acqParamStartTriggerInvert <= cfgWriteData;
			
			296:	acqParamNextTriggerInvert <= cfgWriteData;
			
			300:	acqParamStopTriggerInvert <= cfgWriteData;
			
			304:	acqParamLaserClkChIdx <= cfgWriteData;
			
			308:	acqParamLaserClkDebounce <= cfgWriteData;
			
			312:	logicalChannelAccessIdx <= cfgWriteData;
			
		//	316:	acqParamLogicalChannelSettings_cc[logicalChannelAccessIdx*32+:32] <= cfgWriteData;
			
		//	320:	begin
		//				acqParamLaserTriggerFilterWindowStart_cc[logicalChannelAccessIdx*12+:12] <= cfgWriteData[11:0];
		//				acqParamLaserTriggerFilterWindowN_cc[logicalChannelAccessIdx*12+:12] <= cfgWriteData[31:16];
		//			end
			
			324:	acqParamSampleClkPulsesPerPeriod <= cfgWriteData;
			
			328:	acqParamLinearSampleClkPulseDuration <= cfgWriteData;
			
			332:	acqParamAnalogResonantPhaseDetection <= cfgWriteData;
			
			336:	acqParamAnalogResonantPhaseThreshold <= cfgWriteData;
			
			340:	acqParamChannelOffsets[31:0] <= cfgWriteData;
			344:	acqParamChannelOffsets[63:32] <= cfgWriteData;

			348:	i2cEnable <= cfgWriteData;

			352:	i2cParamDebounce <= cfgWriteData;

			356:	i2cParamAddress <= cfgWriteData;

			360:	i2cParamSdaChIdx <= cfgWriteData;

			364:	i2cParamSclChIdx <= cfgWriteData;
			
			368:	acqParamPeriodTriggerMinPeriod <= cfgWriteData;
			
			372:	acqParamPeriodTriggerSettledGate <= cfgWriteData;

			376:	acqParamUniformBinCoefficient <= cfgWriteData;

			380:	maskTblWriteDivisor <= cfgWriteData;

			384:	maskTblWriteBin <= cfgWriteData;

			388:	acqParamLaserClkSyncChIdx <= cfgWriteData;
			
		endcase
	end
			
	always @* begin
		case (cfgOffsetReadAddr)
			4:   	cfgReadDataReg = 32'h2101_AECD;
			
			8:		cfgReadDataReg = {16'(HS_NUM_LOGICAL_CHANNELS),16'(MS_NUM_LOGICAL_CHANNELS)};
			
			12:		cfgReadDataReg = HSADC_SUPPORT;
			
			16:		cfgReadDataReg = DATA_FIFO_WIDTH/8;
			
		//	20:		cfgReadDataReg = 
			
			24:		cfgReadDataReg = NUM_DIVIDERS;

			28:		cfgReadDataReg = ACCUM_MULTIPLY_SUPPORT;

			32:		cfgReadDataReg = HSADC_LRR_SUPPORT;

			36:		cfgReadDataReg = ACCUM_COEFFICIENT_FIXED_POINT_PRECISION;
			
		//	100:	command reg
			
		//	104:	acq plan write
			
			108:	cfgReadDataReg = acqPlanNumSteps;
			
		//	112:	mask table write
			
			116:	cfgReadDataReg = acqParamMaskSize; // mask size should be set to actual mask size - 1
			
			120:	cfgReadDataReg = acqParamPeriodTriggerChIdx;
			
			124:	cfgReadDataReg = acqParamStartTriggerChIdx;
			
			128:	cfgReadDataReg = acqParamNextTriggerChIdx;
			
			132:	cfgReadDataReg = acqParamStopTriggerChIdx;
			
			136:	cfgReadDataReg = acqParamPhotonChIdx;
			
			140:	cfgReadDataReg = acqParamPeriodTriggerDebounce;
			
			144:	cfgReadDataReg = acqParamTriggerDebounce;
			
			148:	cfgReadDataReg = acqParamLiveHoldoffAdjustEnable;
			
			152:	cfgReadDataReg = acqParamLiveHoldoffAdjustPeriod;
			
			156:	cfgReadDataReg = acqParamTriggerHoldoff;
			
			160:	cfgReadDataReg = acqParamChannelsInvert;
			
			164:	cfgReadDataReg = acqParamEnableLineTag;
			
			168:	cfgReadDataReg = acqParamSamplesPerLine;
			
			172:	cfgReadDataReg = acqParamVolumesPerAcq;
			
			176:	cfgReadDataReg = acqParamTotalAcqs;
			
			180:	cfgReadDataReg = acqParamBeamClockAdvance;
			
			184:	cfgReadDataReg = acqParamBeamClockDuration;
			
			188:	cfgReadDataReg = acqParamDummyVal;
			
			192:	cfgReadDataReg = acqParamDisableDivide;

			// 196: FREE
			
			200:	cfgReadDataReg = acqParamEnableBidi;
			
			204:	cfgReadDataReg = acqParamPhotonPulseDebounce;
			
			// TODO: acqParamMaskBits appears to be unused/deprecated
			208:	cfgReadDataReg = acqParamMaskBits;
			
			212: 	cfgReadDataReg = acqParamAuxTrig1TriggerChIdx;
			
			216: 	cfgReadDataReg = acqParamAuxTrig2TriggerChIdx;
			
			220: 	cfgReadDataReg = acqParamAuxTrig3TriggerChIdx;
			
			224: 	cfgReadDataReg = acqParamAuxTrig4TriggerChIdx;
			
			228: 	cfgReadDataReg = acqParamAuxTriggerDebounce;
			
			232: 	cfgReadDataReg = acqParamAuxTriggerEnable;
			
			236: 	cfgReadDataReg = acqParamPeriodTriggerMaxPeriod;
			
			240: 	cfgReadDataReg = acqParamPeriodTriggerSettledThresh;
			
			244:	cfgReadDataReg = acqParamDataFifoWriteWidth1;
			
			248:	cfgReadDataReg = acqParamDataFifoWriteWidth2;
			
			252:	cfgReadDataReg = acqParamEnableMixedLasergating;
			
		//	256:	cfgReadDataReg = 
			
			260:	cfgReadDataReg = acqParamLinearMode;
		
			264:	cfgReadDataReg = acqParamLinearFramesPerVolume;
		
			268:	cfgReadDataReg = acqParamLinearFrameClkHighTime;
		
			272:	cfgReadDataReg = acqParamLinearFrameClkLowTime;
		
			276:	cfgReadDataReg = acqParamUniformSampling;
		
			280:	cfgReadDataReg = acqParamUniformBinSize;
		
			284:	cfgReadDataReg = acqParamSimulatedResonantPeriod;
		
			288:	cfgReadDataReg = acqParamAuxTriggerInvert;
			
			292:	cfgReadDataReg = acqParamStartTriggerInvert;
			
			296:	cfgReadDataReg = acqParamNextTriggerInvert;
			
			300:	cfgReadDataReg = acqParamStopTriggerInvert;
			
			304:	cfgReadDataReg = acqParamLaserClkChIdx;
			
			308:	cfgReadDataReg = acqParamLaserClkDebounce;
			
			312:	cfgReadDataReg = logicalChannelAccessIdx;
			
			316:	cfgReadDataReg = acqParamLogicalChannelSettings_cc[logicalChannelAccessIdx*32+:32];
			
			320:	cfgReadDataReg = {
						{SAMPLE_PHASE_BITS_DUMMY_SZ{1'b0}},
						acqParamLaserTriggerFilterWindowN_cc[logicalChannelAccessIdx*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS],
						{SAMPLE_PHASE_BITS_DUMMY_SZ{1'b0}},
						acqParamLaserTriggerFilterWindowStart_cc[logicalChannelAccessIdx*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS]
					};
			
			324:	cfgReadDataReg = acqParamSampleClkPulsesPerPeriod;
			
			328:	cfgReadDataReg = acqParamLinearSampleClkPulseDuration;

			332:	cfgReadDataReg = acqParamAnalogResonantPhaseDetection;
			
			336:	cfgReadDataReg = acqParamAnalogResonantPhaseThreshold;
			
			340:	cfgReadDataReg = acqParamChannelOffsets[31:0];
			344:	cfgReadDataReg = acqParamChannelOffsets[63:32];

			348:	cfgReadDataReg = i2cEnable;

			352:	cfgReadDataReg = i2cParamDebounce;

			356:	cfgReadDataReg = i2cParamAddress;

			360:	cfgReadDataReg = i2cParamSdaChIdx;

			364:	cfgReadDataReg = i2cParamSclChIdx;

			368:	cfgReadDataReg = acqParamPeriodTriggerMinPeriod;

			372:	cfgReadDataReg = acqParamPeriodTriggerSettledGate;
			
			376:	cfgReadDataReg = acqParamUniformBinCoefficient;

			380:	cfgReadDataReg = maskTblWriteDivisor;

			384:	cfgReadDataReg = maskTblWriteBin;

			388:	cfgReadDataReg = acqParamLaserClkSyncChIdx;
			
			400:	cfgReadDataReg = {acqStatusPeriodClockSettled, 13'h0, acqStatusPeriodTriggerPeriod_cc};
			
			404:	cfgReadDataReg = dataFifoOverflowCount;
			
			408:	cfgReadDataReg = triggerFifoOverflowCount;
			
			412:	cfgReadDataReg = acqStatusSmState_cc;
			
			416:	cfgReadDataReg = acqStatusVolumesDone_cc;
			
		//	420:	cfgReadDataReg =
			
		//	424:	cfgReadDataReg = 
			
			
			500:	cfgReadDataReg = logicalChannelsRaw_cc[31:0];
			
			504:	cfgReadDataReg = logicalChannelsRaw_cc[63:32];
			
			default:
				cfgReadDataReg = 32'h2101_A234;
		endcase
	end
	
endmodule
