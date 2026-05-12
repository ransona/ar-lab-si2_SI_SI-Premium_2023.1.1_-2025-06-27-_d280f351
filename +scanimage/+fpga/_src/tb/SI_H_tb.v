//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_H_tb();

    parameter NUM_DIO = 32;
	parameter NUM_RTSI	= 16;
	parameter NUM_ECLK	= 1;
	parameter CFG_BASE_ADDR = 0;
	parameter CFG_ADDR_WIDTH = 12;
	
	parameter MAX_NUM_PHY_CHANNELS = 4;
	parameter MASK_ADDR_BITS = 12;

	parameter NUM_LOGICAL_CHANNELS = 4;
	parameter NUM_DIVIDERS = 0;
	parameter HSADC_SUPPORT = 1;
	parameter DATA_FIFO_WIDTH = 64;
	parameter DATA_FIFO_VARIABLE_WIDTH = 1;
	parameter SAMPLE_PHASE_BITS = 12;
	parameter ACCUM_MULTIPLY_SUPPORT = 0;
	parameter HSADC_LRR_SUPPORT = 1;

    localparam CFG_ADDR_SPACE = 1024;


	wire dataClk;
	wire hsadcDataClk;
	wire cfgClk;
	wire resetn_dc;
	
	wire [63:0] systemClock;
	
	wire cfgWriteActive;
	wire [CFG_ADDR_WIDTH-1:0] cfgWriteAddr;
	wire [31:0] cfgWriteData;
	wire [CFG_ADDR_WIDTH-1:0] cfgReadAddr;
/*o*/wire [31:0] cfgReadData;
	
	wire afeSelect;
	wire [`MS_PHYS_CHANNEL_BUF_LSZ:0] msadcSampleData;
	wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataA;
	wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataB;
	wire [15:0] hsSyncTrigger;
	wire [`HS_SAMPS_PER_TICK-1:0] hsPhotonPeaksA;
	wire [`HS_SAMPS_PER_TICK-1:0] hsPhotonPeaksB;
	
	wire [NUM_ECLK+NUM_RTSI+NUM_DIO-1:0] DIO_I;
/*o*/wire [8:0] digitalTriggersOut;
/*o*/wire [15:0] acqStatusLinesDone;
	
	wire dataFifoFull;
/*o*/wire dataFifoWriteEn;
/*o*/wire [5:0] dataFifoWriteWidth;
/*o*/wire [DATA_FIFO_WIDTH-1:0] dataFifoData;
	
	wire triggerFifoFull;
/*o*/wire triggerFifoWriteEn;
/*o*/wire [79:0] triggerFifoData;
	
/*o*/wire [`TRIGGER_PROCESS_OUT_LSZ:0] scopeTriggerProcessDataOut;
/*o*/wire [`STATE_MACHINE_OUT_LSZ:0] scopeStateMachineDataOut;
    



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
	wire [MASK_ADDR_BITS-1:0] maskTblWriteAddr = cfgWriteData[MASK_ADDR_BITS+`ACCUM_BITS-1:`ACCUM_BITS];
	wire [`ACCUM_BITS-1:0] maskTblWriteData = cfgWriteData[`ACCUM_BITS-1:0];
	reg  [MASK_ADDR_BITS-1:0] acqParamMaskSize = 0;
	
	reg [17:0] acqParamPeriodTriggerMaxPeriod = 16700;
	reg [17:0] acqParamPeriodTriggerMinPeriod = 0;
	reg [15:0] acqParamPeriodTriggerSettledThresh = 2;
	wire acqStatusPeriodClockSettled;
	reg acqParamPeriodTriggerSettledGate = 0;
	reg [15:0] acqParamSimulatedResonantPeriod = 0;
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
	reg [9:0] acqParamPeriodTriggerDebounce = 0;
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
	reg [13:0] acqParamLinearSampleClkPulseDuration = 125;
	
	reg [MAX_NUM_PHY_CHANNELS-1:0] acqParamChannelsInvert = 0;
	reg [`PHYS_CHAN_BUF_LSZ:0] acqParamChannelOffsets = 0;
	
	reg acqParamEnableBidi;
	reg [15:0] acqParamSamplesPerLine = 45;
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
	
	reg acqParamUniformSampling = 1;
	reg [11:0] acqParamUniformBinSize = 1;
	reg [SAMPLE_PHASE_BITS:0] acqParamLaserClkPeriodSamples = 200;

	reg i2cEnable = 0;
	reg [4:0] i2cParamDebounce = 0;
	reg [6:0] i2cParamAddress = 0;
	reg [5:0] i2cParamSdaChIdx = 0;
	reg [5:0] i2cParamSclChIdx = 0;
	
	
	wire [15:0] acqParamTriggerHoldoff_sc;
	SWCC #(.WW(16)) trigHoldoff_crss(.srcV(acqParamTriggerHoldoff), .srcClk(cfgClk), .dstV(acqParamTriggerHoldoff_sc), .dstClk(dataClk), .dstRst(0));
	
	wire [9:0]  acqParamPeriodTriggerDebounce_sc;
	SWCC #(.WW(10)) trigDebounce_crss(.srcV(acqParamPeriodTriggerDebounce), .srcClk(cfgClk), .dstV(acqParamPeriodTriggerDebounce_sc), .dstClk(dataClk), .dstRst(0));
	
	wire [15:0] acqStatusPeriodTriggerPeriod;
	wire [15:0] acqStatusPeriodTriggerPeriod_cc;
	SWCC #(.WW(16)) trigPeriod_crss(.srcV(acqStatusPeriodTriggerPeriod), .srcClk(dataClk), .dstV(acqStatusPeriodTriggerPeriod_cc), .dstClk(cfgClk), .dstRst(0));
	
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
	wire [NUM_LOGICAL_CHANNELS*32-1:0] acqParamLogicalChannelSettings_cc;
	wire [NUM_LOGICAL_CHANNELS*12-1:0] acqParamLaserTriggerFilterWindowStart_cc;
	wire [NUM_LOGICAL_CHANNELS*12-1:0] acqParamLaserTriggerFilterWindowN_cc;

	wire [NUM_LOGICAL_CHANNELS*32-1:0] acqParamLogicalChannelSettings;
	wire [NUM_LOGICAL_CHANNELS*12-1:0] acqParamLaserTriggerFilterWindowStart;
	wire [NUM_LOGICAL_CHANNELS*12-1:0] acqParamLaserTriggerFilterWindowN;

	generate
		genvar lc_i;
		
		for (lc_i = 0; lc_i < NUM_LOGICAL_CHANNELS; lc_i=lc_i+1) begin:gen_logical_channel_settings
			wire [5:0] signalSource = (lc_i > 3) ? 0 : lc_i;
			wire applyThreshold = 0;
			wire binarize = 0;
			wire edgeDetect = 0;
			wire laserGate = 1;
			wire downShift = 1;
			wire signed [15:0] thresh = 0;
			//											  {thresh, 5'd0, downShift, laserGate, edgeDetect, binarize, applyThreshold, signalSource};
			reg [31:0] acqParamLogicalChannelSettings_R = 0 | (1<<9); // laser gate on
			reg [11:0] acqParamLaserTriggerFilterWindowStart_R = lc_i ? 658 : 0;
			reg [11:0] acqParamLaserTriggerFilterWindowN_R = lc_i ? 3 : 3;

			initial begin
			//	acqParamLogicalChannelSettings_R[5:0] = (lc_i > 3) ? 0 : lc_i;	// signalSource
				acqParamLogicalChannelSettings_R[6] = 0;						// applyThreshold
				acqParamLogicalChannelSettings_R[7] = 0;						// binarize
				acqParamLogicalChannelSettings_R[8] = 0;						// edgeDetect
				acqParamLogicalChannelSettings_R[9] = 1;						// laserGate
			//	acqParamLogicalChannelSettings_R[10] = 1;						// downShift
				acqParamLogicalChannelSettings_R[31:16] = 0;					// threshold
			end
			
			assign acqParamLogicalChannelSettings_cc[lc_i*32+:32] = acqParamLogicalChannelSettings_R;
			assign acqParamLaserTriggerFilterWindowStart_cc[lc_i*12+:12] = acqParamLaserTriggerFilterWindowStart_R;
			assign acqParamLaserTriggerFilterWindowN_cc[lc_i*12+:12] = acqParamLaserTriggerFilterWindowN_R;

			always @(posedge cfgClk)
				if (logicalChannelAccessIdx == lc_i)
					case (cfgActiveWriteAddr)
						316:	acqParamLogicalChannelSettings_R <= cfgWriteData;
						
						320:	begin
									acqParamLaserTriggerFilterWindowStart_R <= cfgWriteData[11:0];
									acqParamLaserTriggerFilterWindowN_R <= cfgWriteData[31:16];
								end
					endcase

		//	SWCC #(.WW(32)) lcs_crss(.srcV(acqParamLogicalChannelSettings_R), .srcClk(cfgClk), .dstV(acqParamLogicalChannelSettings[lc_i*32+:32]), .dstClk(dataClk), .dstRst(0));
		//	SWCC #(.WW(12)) wndoS_crss(.srcV(acqParamLaserTriggerFilterWindowStart_R), .srcClk(cfgClk), .dstV(acqParamLaserTriggerFilterWindowStart[lc_i*12+:12]), .dstClk(dataClk), .dstRst(0));
		//	SWCC #(.WW(12)) wndN_crss(.srcV(acqParamLaserTriggerFilterWindowN_R), .srcClk(cfgClk), .dstV(acqParamLaserTriggerFilterWindowN[lc_i*12+:12]), .dstClk(dataClk), .dstRst(0));
			assign acqParamLogicalChannelSettings[lc_i*32+:32] = acqParamLogicalChannelSettings_R;
			assign acqParamLaserTriggerFilterWindowStart[lc_i*12+:12] = acqParamLaserTriggerFilterWindowStart_R;
			assign acqParamLaserTriggerFilterWindowN[lc_i*12+:12] = acqParamLaserTriggerFilterWindowN_R;
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
		.NUM_LOGICAL_CHANNELS(NUM_LOGICAL_CHANNELS),
		.SAMPLE_PHASE_BITS(SAMPLE_PHASE_BITS)
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
		.laserClkPeriodSamples(acqParamLaserClkPeriodSamples)
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
		.NUM_LOGICAL_CHANNELS(NUM_LOGICAL_CHANNELS)
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
			
			wire [`ACCUM_BUF_LSZ:0]					accumData;
			wire [`ACCUM_BITS-1:0]					accumDivisor;
			wire 									accumDone;

			SI_SampleAccum #(
				.MASK_ADDR_BITS(MASK_ADDR_BITS),
				.NUM_LOGICAL_CHANNELS(NUM_LOGICAL_CHANNELS),
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
				
				.stateMachineDataIn(stateMachineData),
				.logicalChannelsIn(stateMachineLogicalChannels),
				
				.stateMachineDataOut(accumStateMachineData),
				.logicalChannelsAccumOut(accumData),
				.divisor(accumDivisor),
				.accumDone(accumDone),
				.pixelClock(pixelClock),
				
				.acqParamDummyVal(acqParamDummyVal)
			);
			
			SI_SampleDivide #(
				.NUM_LOGICAL_CHANNELS(NUM_LOGICAL_CHANNELS),
				.NUM_DIVIDERS(NUM_DIVIDERS)
			) sampleDivide (
				.clk(dataClk),
				
				.accumStateMachineDataIn(accumStateMachineData),
				.logicalChannelsAccumIn(accumData),
				.divisorIn(accumDivisor),
				.accumDone(accumDone),
				
				.outputPixelData(pixelData),
				.pixelDataValid(pixelValid),
				.endOfLine(pixelEndOfLine),
				
				.disableDivide(acqParamDisableDivide),
				.scalePower(acqParamScalePower)
			);

		end else begin
			
			assign pixelData = stateMachineLogicalChannels;
			assign pixelValid = stateMachineData[`STATE_MACHINE_OUT_ACQ_CLK_BIT];
			assign pixelEndOfLine = stateMachineData[`STATE_MACHINE_OUT_EOL_BIT];
			assign accumStateMachineData = stateMachineData;

		end
	endgenerate


	SI_LineTag #(
		.NUM_LOGICAL_CHANNELS(NUM_LOGICAL_CHANNELS),
		.FIFO_WIDTH(DATA_FIFO_WIDTH)
	) lineTag (
		.clk(dataClk),

		.acqParamEnableLineTag(acqParamEnableLineTag),
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
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





    reg resetnR = 0;
	assign resetn_dc = resetnR;
	
	assign systemClock = 0;
	
	assign afeSelect = 1;
	assign msadcSampleData = 0;
	assign hsPhotonPeaksA = 0;
	assign hsPhotonPeaksB = 0;
	
	assign dataFifoFull = 0;
	assign triggerFifoFull = 0;











    reg hsClk = 1;
    assign dataClk = hsClk;
	assign hsadcDataClk = hsClk;
	assign cfgClk = hsClk;

    always #6 hsClk <= ~hsClk;

    reg [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataA_R;
    reg [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataB_R;
	assign hsadcSampleDataA = hsadcSampleDataA_R;
	assign hsadcSampleDataB = hsadcSampleDataB_R;
    reg [15:0] hsSyncTrigger_R = 16'b0000011111100000;
	assign hsSyncTrigger = hsSyncTrigger_R;
    reg [5:0] ctr;
	
	reg [12:0] laserTrigPeriod = 2000;
	reg [12:0] lastTrigPhs = 2;
	reg [12:0] trigPhs;
	
	wire signed [11:0] chASamps[31:0];
	wire signed [11:0] chBSamps[31:0];

    always @(posedge hsClk) begin
        for (ctr = 0; ctr < 32; ctr = ctr + 1) begin
            hsadcSampleDataA_R[ctr*12+:12] <= $urandom_range(1000,0);
            hsadcSampleDataB_R[ctr*12+:12] <= $urandom_range(1000,0);
        end

		trigPhs = lastTrigPhs;
        for (ctr = 0; ctr < 16; ctr = ctr + 1) begin
			trigPhs = trigPhs + 2;
			trigPhs = (trigPhs >= laserTrigPeriod) ? 0 : trigPhs;
			hsSyncTrigger_R[ctr] <= trigPhs < (laserTrigPeriod/2);
		end
		lastTrigPhs <= trigPhs;
    end

    
    // decode input samps
    generate
        genvar ctri;
        for (ctri = 0; ctri < 32; ctri = ctri + 1) begin:chs
			assign chASamps[ctri] = hsadcSampleDataA_R[ctri*12+:12];
			assign chBSamps[ctri] = hsadcSampleDataB_R[ctri*12+:12];
		end
	endgenerate


    // sim res mirror
    reg resMirror = 0;
	assign DIO_I = resMirror;

    always #63000 resMirror = ~resMirror;


    wire signed [`LOGICAL_CHANNEL_LSZ:0] logicalChanDecode[NUM_LOGICAL_CHANNELS-1:0];
    generate
		genvar lcd;
		
		for (lcd = 0; lcd < NUM_LOGICAL_CHANNELS; lcd=lcd+1) begin:gen_logical_channel_unpack
			assign logicalChanDecode[lcd] = pixelData[`LOGICAL_CHANNEL_WIDTH*lcd+:`LOGICAL_CHANNEL_WIDTH];
		end
	endgenerate



	// output file with expected pixel values
	// generate phase lookup
	// SI_SignalConditionH applies one clock cycle of extra delay to the trigger. mimic this
	reg [11:0] prevp;
	reg [11:0] phsTest[31:0];
	reg [5:0] pt_iter;
	reg hsSyncTrigger_p;
	reg [15:0] hsSyncTriggerRE;
	always @(posedge hsClk) begin
		hsSyncTrigger_p <= hsSyncTrigger_R[15];

		hsSyncTriggerRE[0] = hsSyncTrigger_R[0] && ~hsSyncTrigger_p;
		for (pt_iter = 1; pt_iter < 16; pt_iter = pt_iter + 1)
			hsSyncTriggerRE[pt_iter] = hsSyncTrigger_R[pt_iter] && ~hsSyncTrigger_R[pt_iter-1];

		prevp = phsTest[31];
		for (pt_iter = 0; pt_iter < 16; pt_iter = pt_iter + 1) begin
			if (hsSyncTriggerRE[pt_iter]) begin
				phsTest[pt_iter*2] <= 0;
				phsTest[pt_iter*2+1] <= 1;
				prevp = 1;
			end else begin
				phsTest[pt_iter*2] <= prevp + 1;
				phsTest[pt_iter*2+1] <= prevp + 2;
				prevp = prevp + 2;
			end
		end
	end

	reg init = 1;

	reg signed [15:0] chResult;
	wire [11:0] wndo_st = acqParamLaserTriggerFilterWindowStart[11:0];
	wire [11:0] wndo_n = acqParamLaserTriggerFilterWindowN[11:0];
	wire [11:0] wndo_nd = wndo_st + wndo_n;

	reg [6:0] iter;
	integer f;

	always @(posedge hsClk) begin

		if (init) begin
			f = $fopen("epected_o.txt","w");
			$fclose(f);
			f = $fopen("actual_o.txt","w");
			$fclose(f);
			init = 0;
		end

		for (iter = 0; iter < 32; iter = iter + 1) begin
			if (phsTest[iter] == wndo_nd) begin
				if (phsTest[iter] == wndo_st)
					chResult = 0;
				
				chResult = chResult + chASamps[iter];

				f = $fopen("epected_o.txt","a+");
				$fwrite(f,"%d\n",chResult);
				$fclose(f);
			end else if (phsTest[iter] == wndo_st)
				chResult = chASamps[iter];
			else if ((phsTest[iter] > wndo_st) && (phsTest[iter] < wndo_nd))
				chResult = chResult + chASamps[iter];
		end

		if (pixelValid) begin
			f = $fopen("actual_o.txt","a+");
			$fwrite(f,"%d\n",logicalChanDecode[0]);
			$fclose(f);
		end
	end






	
	reg cfgWriteActiveR = 0;
	reg [CFG_ADDR_WIDTH-1:0] cfgWriteAddrR = 0;
	reg [31:0] cfgWriteDataR = 0;
	reg [CFG_ADDR_WIDTH-1:0] cfgReadAddrR = 0;

	assign cfgWriteActive = cfgWriteActiveR;
	assign cfgWriteAddr = cfgWriteAddrR;
	assign cfgWriteData = cfgWriteDataR;
	assign cfgReadAddr = cfgWriteAddrR;
    reg [31:0] simT = 0;
	
	always @(posedge hsClk) begin
        simT <= simT + 1;

        if (simT == 10)
            resetnR <= 1;


        if (simT == 12) begin
            cfgWriteActiveR <= 1;
            cfgWriteAddrR <= 168;
            cfgWriteDataR <= 1300;
        end
        if (simT == 13)
		    cfgWriteActiveR <= 0;
		
		
		
		////// acq plan. collect 12, flyback 4
		
		// num steps
        if (simT == 14) begin
            cfgWriteActiveR <= 1;
            cfgWriteAddrR <= 108;
            cfgWriteDataR <= 2;
        end
        if (simT == 15)
		    cfgWriteActiveR <= 0;
		
		// collect 12
        if (simT == 16) begin
            cfgWriteActiveR <= 1;
            cfgWriteAddrR <= 104;
            cfgWriteDataR <= {11'd0, 1'b1, 1'b1, 7'd6};
        end
        if (simT == 17)
		    cfgWriteActiveR <= 0;
		
		// flyback 4
        if (simT == 18) begin
            cfgWriteActiveR <= 1;
            cfgWriteAddrR <= 104;
            cfgWriteDataR <= {11'd1, 1'b1, 1'b0, 7'd2};
        end
        if (simT == 19)
		    cfgWriteActiveR <= 0;
		
		// dummy
        if (simT == 20) begin
            cfgWriteActiveR <= 1;
            cfgWriteAddrR <= 104;
            cfgWriteDataR <= {11'd2, 1'b1, 1'b0, 7'd0};
        end
        if (simT == 21)
		    cfgWriteActiveR <= 0;
		
		
		
        
		// reset sm
        if (simT == 22) begin
            cfgWriteActiveR <= 1;
            cfgWriteAddrR <= 100;
            cfgWriteDataR <= 38;
        end
        if (simT == 23)
		    cfgWriteActiveR <= 0;
		

        
		// start sm
        if (simT == 24) begin
            cfgWriteActiveR <= 1;
            cfgWriteAddrR <= 100;
            cfgWriteDataR <= 37;
        end
        if (simT == 25)
		    cfgWriteActiveR <= 0;
		
        
		// soft trig
        if (simT == 26) begin
            cfgWriteActiveR <= 1;
            cfgWriteAddrR <= 100;
            cfgWriteDataR <= 39;
        end
        if (simT == 27)
		    cfgWriteActiveR <= 0;
	end

	
endmodule
