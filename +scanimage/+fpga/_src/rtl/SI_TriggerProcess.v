//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_TriggerProcess #(
	parameter NUM_DI = 32
)(
	input wire clk,
	
	input wire [NUM_DI-1:0] DI,
	
	output wire [`TRIGGER_PROCESS_OUT_LSZ:0] dataOut,
	
	input wire [15:0] periodTriggerHoldoff,
	input wire [5:0] periodTriggerChIdx,
	input wire [5:0] startTriggerChIdx,
	input wire [5:0] nextTriggerChIdx,
	input wire [5:0] stopTriggerChIdx,
	input wire [5:0] actualTriggerChIdx,
	input wire startTriggerInvert,
	input wire nextTriggerInvert,
	input wire stopTriggerInvert,
	input wire [4:0] photonChIdx,
	input wire [5:0] laserClkChIdx,
	input wire [5:0] laserClkSyncChIdx,
	input wire [9:0] periodTriggerDebounce,
	input wire [4:0] triggerDebounce,
	input wire [4:0] photonPulseDebounce,
	input wire [4:0] laserClkDebounce,
	input wire liveHoldoffAdjustEnable,
	input wire [15:0] liveHoldoffAdjustPeriod,
	input wire [5:0] auxTrig1TriggerChIdx,
	input wire [5:0] auxTrig2TriggerChIdx,
	input wire [5:0] auxTrig3TriggerChIdx,
	input wire [5:0] auxTrig4TriggerChIdx,
	input wire [4:0] auxTriggerDebounce,
	input wire [3:0] auxTriggerInvert,
	input wire acqParamAuxTriggerEnable,
	input wire [17:0] acqParamPeriodTriggerMaxPeriod,
	input wire [17:0] acqParamPeriodTriggerMinPeriod,
	input wire [15:0] acqParamPeriodTriggerSettledThresh,
	input wire [17:0] acqParamSimulatedResonantPeriod,
	input wire periodTriggerSettledGate,
	
	input wire acqParamAnalogResonantPhaseDetection,
	input wire signed [15:0] acqParamAnalogResonantPhaseThreshold,
	input wire signed [15:0] acqParamAnalogResonantPhaseValue,
	
	output wire [17:0] periodClockPeriod,
	output wire periodClockSettled
);
	wire periodTriggerIn;
	wire periodTrigger;
	wire midPeriodTrigger;
	wire delayedPeriodTrigger;
	wire delayedMidPeriodTrigger;
	wire startTrigger;
	wire nextTrigger;
	wire stopTrigger;
	wire [3:0] auxTrigger;
	wire laserClk;
	wire rawLaserClk;
	wire rawLaserClkSync;
	wire laserClkSync;
	
	wire [3:0] photonPulseP;
	reg  [3:0] photonPulse = 0;

	assign dataOut[`TRIGGER_PROCESS_OUT_PERIOD_TRIGGER_RAW_BIT] = periodTriggerIn;
	assign dataOut[`TRIGGER_PROCESS_OUT_PERIOD_TRIGGER_BIT] = periodTrigger;
	assign dataOut[`TRIGGER_PROCESS_OUT_MID_PERIOD_TRIGGER_BIT] = midPeriodTrigger;
	assign dataOut[`TRIGGER_PROCESS_OUT_DEL_PERIOD_TRIGGER_BIT] = delayedPeriodTrigger;
	assign dataOut[`TRIGGER_PROCESS_OUT_DEL_MID_PERIOD_TRIGGER_BIT] = delayedMidPeriodTrigger;
	assign dataOut[`TRIGGER_PROCESS_OUT_START_TRIGGER_BIT] = startTrigger;
	assign dataOut[`TRIGGER_PROCESS_OUT_NEXT_TRIGGER_BIT] = nextTrigger;
	assign dataOut[`TRIGGER_PROCESS_OUT_STOP_TRIGGER_BIT] = stopTrigger;
	assign dataOut[`TRIGGER_PROCESS_OUT_PHOTON_PULSE_START_BIT+:4] = photonPulse;
	assign dataOut[`TRIGGER_PROCESS_OUT_AUX_TRIGGER_START_BIT+:4] = auxTrigger;
	assign dataOut[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_BIT] = laserClk;
	assign dataOut[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_RAW_BIT] = rawLaserClk;
	assign dataOut[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_SYNC_BIT] = laserClkSync;
	assign dataOut[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_SYNC_RAW_BIT] = rawLaserClkSync;
	
	
	// signal input and debounce
	inputDebounce #(.CTR_WIDTH(10)) periodTrigDebInst(.clk(clk), .sigIn(periodTriggerIn), .sigOut(), .sigOutRE(periodTrigger), .debounceTime(periodTriggerDebounce));
	inputDebounce startTrigDebInst(.clk(clk), .sigIn((startTriggerChIdx < 63) && (DI[startTriggerChIdx]^startTriggerInvert)), .sigOutRE(startTrigger), .debounceTime(triggerDebounce));
	inputDebounce nextTrigDebInst(.clk(clk), .sigIn((nextTriggerChIdx < 63) && (DI[nextTriggerChIdx]^nextTriggerInvert)), .sigOutRE(nextTrigger), .debounceTime(triggerDebounce));
	inputDebounce stopTrigDebInst(.clk(clk), .sigIn((stopTriggerChIdx < 63) && (DI[stopTriggerChIdx]^stopTriggerInvert)), .sigOutRE(stopTrigger), .debounceTime(triggerDebounce));
	
	inputDebounce ph1DebInst(.clk(clk), .sigIn(DI[photonChIdx]), .sigOutRE(photonPulseP[0]), .debounceTime(photonPulseDebounce));
	inputDebounce ph2DebInst(.clk(clk), .sigIn(DI[photonChIdx+1]), .sigOutRE(photonPulseP[1]), .debounceTime(photonPulseDebounce));
	inputDebounce ph3DebInst(.clk(clk), .sigIn(DI[photonChIdx+2]), .sigOutRE(photonPulseP[2]), .debounceTime(photonPulseDebounce));
	inputDebounce ph4DebInst(.clk(clk), .sigIn(DI[photonChIdx+3]), .sigOutRE(photonPulseP[3]), .debounceTime(photonPulseDebounce));
	
	assign rawLaserClk = (laserClkChIdx < 63) && DI[laserClkChIdx];
	inputDebounce laserClkDeb(.clk(clk), .sigIn(rawLaserClk), .sigOutRE(laserClk), .debounceTime(laserClkDebounce));

	assign rawLaserClkSync = (laserClkSyncChIdx < 63) && DI[laserClkSyncChIdx];
	inputDebounce laserClkSyncDeb(.clk(clk), .sigIn(rawLaserClkSync), .sigOutRE(laserClkSync), .debounceTime(laserClkDebounce));
	
	wire [23:0] auxTriggerChIdx = {auxTrig4TriggerChIdx, auxTrig3TriggerChIdx, auxTrig2TriggerChIdx, auxTrig1TriggerChIdx};
	
	genvar ig;
	generate
		for (ig = 0; ig < 4; ig = ig+1) begin : gen_aux_trig
			wire [5:0] idx = auxTriggerChIdx[ig*6+:6];
			wire sigin = (idx < 63) && DI[idx];
			wire re;
			wire fe;
			
			inputDebounce auxTrigDebInst(.clk(clk), .sigIn(sigin), .sigOutRE(re), .sigOutFE(fe), .debounceTime(auxTriggerDebounce));
			
			assign auxTrigger[ig] = acqParamAuxTriggerEnable && (auxTriggerInvert[ig] ? fe : re);
		end
	endgenerate
	
	// simulated period trigger
	reg [17:0] simulatedPeriodTriggerCtr = 0;
	wire simulatedPeriodTrigger = simulatedPeriodTriggerCtr > (acqParamSimulatedResonantPeriod >> 1);
	wire analogPeriodTrigger = acqParamAnalogResonantPhaseValue >= acqParamAnalogResonantPhaseThreshold;
	assign periodTriggerIn = acqParamSimulatedResonantPeriod ? simulatedPeriodTrigger : (acqParamAnalogResonantPhaseDetection ? analogPeriodTrigger : DI[periodTriggerChIdx]);
	
	always @(posedge clk)
		if (simulatedPeriodTriggerCtr)
			simulatedPeriodTriggerCtr <= simulatedPeriodTriggerCtr - 1;
		else
			simulatedPeriodTriggerCtr <= acqParamSimulatedResonantPeriod;
	
	
	reg [17:0] periodClkSettledReg = 0;
	assign periodClockSettled = periodClkSettledReg > acqParamPeriodTriggerSettledThresh;
	
	reg [17:0] periodMeasCtr = 0;
	reg [17:0] periodClockPeriodReg = 0;
	assign periodClockPeriod = periodClockPeriodReg;
	
	reg [17:0] periodTriggerHoldoffCtr = 0;
	reg [17:0] midPeriodTriggerHoldoffCtr = 0;
	reg [17:0] delayedMidPeriodTriggerHoldoffCtr = 0;
	

	wire periodTriggerInhibit = periodMeasCtr < acqParamPeriodTriggerMinPeriod;
	wire periodTriggerAllow = !periodTriggerSettledGate || periodClockSettled;
	
	
	// live holdoff adjust
	wire [17:0] actualPeriodTriggerHoldoff = liveHoldoffAdjustEnable ? periodTriggerHoldoff + ((periodClockPeriodReg - liveHoldoffAdjustPeriod) >> 1) : periodTriggerHoldoff;
	
	
	always @(posedge clk) begin
		// period measurement
		if (periodTrigger && ~periodTriggerInhibit) begin
			periodClockPeriodReg <= periodMeasCtr + 1;
			periodMeasCtr <= 0;
			
			if (!(&periodClkSettledReg))
				periodClkSettledReg <= periodClkSettledReg + 1;
		end else begin
			periodMeasCtr = periodMeasCtr + (!(&periodMeasCtr)); // saturating add
			
			if (periodMeasCtr >= acqParamPeriodTriggerMaxPeriod)
				periodClkSettledReg <= 0;
		end
		
		// delayed period clk generation
		if (periodTrigger && ~periodTriggerInhibit && periodTriggerAllow) begin
			periodTriggerHoldoffCtr <= actualPeriodTriggerHoldoff + 1;
			midPeriodTriggerHoldoffCtr <= ((periodMeasCtr+1)>>1) + 1;
			delayedMidPeriodTriggerHoldoffCtr <= actualPeriodTriggerHoldoff + ((periodMeasCtr+1)>>1) + 1;
		end else begin
			if (periodTriggerHoldoffCtr)
				periodTriggerHoldoffCtr <= periodTriggerHoldoffCtr - 1;
			if (midPeriodTriggerHoldoffCtr)
				midPeriodTriggerHoldoffCtr <= midPeriodTriggerHoldoffCtr - 1;
			if (delayedMidPeriodTriggerHoldoffCtr)
				delayedMidPeriodTriggerHoldoffCtr <= delayedMidPeriodTriggerHoldoffCtr - 1;
		end

		photonPulse <= photonPulseP;
	end
	
	assign delayedPeriodTrigger = periodTriggerHoldoffCtr == 1;
	assign midPeriodTrigger = midPeriodTriggerHoldoffCtr == 1;
	assign delayedMidPeriodTrigger = delayedMidPeriodTriggerHoldoffCtr == 1;
	
endmodule
