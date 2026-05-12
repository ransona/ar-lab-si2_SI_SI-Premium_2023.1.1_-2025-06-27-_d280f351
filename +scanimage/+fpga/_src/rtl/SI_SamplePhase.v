//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Nelson Downs
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 10 ps
`include "SI_Defines.v"

// TODO: replace with new refactored version (issues #1178 and #1220)

module SI_SamplePhase #(
	parameter SAMPLE_PHASE_BITS	= 12
)(
	input  wire hsadcDataClk,
	input  wire [(`HS_SAMPS_PER_TICK/2)-1:0] hsSyncTrigger,
	input  wire [SAMPLE_PHASE_BITS-1:0] hsSyncTrigPhaseShift,
	input  wire hsSyncTrigIgnorePhysical,
	input  wire [SAMPLE_PHASE_BITS-1:0] laserClkPeriodSamples,

	output wire [(SAMPLE_PHASE_BITS*`HS_SAMPS_PER_TICK)-1:0] samplePhasePacked
);

	// keep track of sample phase w.r.t. laser clock
	wire [SAMPLE_PHASE_BITS-1:0] samplePhase[`HS_SAMPS_PER_TICK-1:0];
	reg  [SAMPLE_PHASE_BITS-1:0] samplePhaseR[`HS_SAMPS_PER_TICK-1:0];

	// used for rising edge detection
	reg lastClkLvl = 0;
	always @(posedge hsadcDataClk)
		lastClkLvl <= hsSyncTrigger[(`HS_SAMPS_PER_TICK/2)-1];
	wire [(`HS_SAMPS_PER_TICK/2)-1:0] syncTriggerRE; // sync trigger rising edge

	// sample phase calculation: bits 0 to 31
	generate
		genvar phaseIter;
		genvar phaseIterH;
		for (phaseIter = 0; phaseIter < `HS_SAMPS_PER_TICK; phaseIter = phaseIter + 1) begin:gen_sync_trg_phase
			// taking clock cycle, add 1 (cause next clock cycle) + phaseIter
			// 1 bit bigger because can go over max value
			wire [SAMPLE_PHASE_BITS:0] samplePhaseCalcPre = samplePhaseR[`HS_SAMPS_PER_TICK-1]+1+phaseIter; 

			// if its greater than the period, subtract to wrap around
			assign samplePhase[phaseIter] = (samplePhaseCalcPre >= laserClkPeriodSamples) ? samplePhaseCalcPre - laserClkPeriodSamples : samplePhaseCalcPre;

			if (phaseIter < (`HS_SAMPS_PER_TICK-1)) begin
				always @(posedge hsadcDataClk)
					samplePhaseR[phaseIter] <= samplePhase[phaseIter];
			end

			// create packed version for transfer
			assign samplePhasePacked[phaseIter*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS] = samplePhaseR[phaseIter];
		end

		// detect rising edge on Sync Trigger
		for (phaseIterH = 0; phaseIterH < (`HS_SAMPS_PER_TICK / 2); phaseIterH=phaseIterH+1) begin:gen_samp_phs
			assign syncTriggerRE[phaseIterH] = phaseIterH > 0 ? hsSyncTrigger[phaseIterH] && ~hsSyncTrigger[phaseIterH-1] : hsSyncTrigger[phaseIterH] && ~lastClkLvl;
		end
	endgenerate

	// TIMING IDEAS:
	// If there is no rising edge and hsSyncTrigIgnorePhysical is false, then we know it will just add +32. Can we detect that?
	// if we do detect that and there is a rising edge, how would we handle that such that its faster?
	// - If we know it would be +32 normally, it would be split such that X + Y = 32, X = samples before RE, Y = samples after RE
	//   We iterate X to find the rising edge and then just set samples to 32 - X?
	// - This should work for all cases - since the for loop never breaks, if there are more than one RE pulses in the
	//   syncTriggerRE, it will go through all of them and set phsCalc accordingly.
	
	reg [5:0] ppi = 0;                           // TODO: reduce this width? unless `HS_SAMPS_PER_TICK gets bigger
	reg [SAMPLE_PHASE_BITS:0] phsCalc;  // 1 bit bigger to handle overflow

	reg [SAMPLE_PHASE_BITS-1:0] samplePhase31Pre = 0;

	// sample phase calculation: bit 32
	always @(posedge hsadcDataClk) begin
		// start phase calculation at the phase of the last sample
		phsCalc = samplePhase31Pre;

		// if there is no rising edge, or ignoring physical trigger, increment phase by `HS_SAMPS_PER_TICK (32)
		if (hsSyncTrigIgnorePhysical || syncTriggerRE == 0)
			phsCalc = phsCalc + `HS_SAMPS_PER_TICK;
		else begin
			// otherwise, the last rising edge will reset the phase, so the phase at the end of the tick is 32-lastRisingEdgePos
			// since ppi is 0:15, shift left 1 (x2) to make it 0:31
			for (ppi = 0; ppi < `HS_SAMPS_PER_TICK/2; ppi = ppi + 1) begin
				if (syncTriggerRE[ppi])
					phsCalc = `HS_SAMPS_PER_TICK - (ppi << 1);
			end
		end

		samplePhase31Pre <= (phsCalc >= laserClkPeriodSamples) ? phsCalc-laserClkPeriodSamples : phsCalc;

		// in second step apply phase shift
		phsCalc = samplePhase31Pre + hsSyncTrigPhaseShift;
		samplePhaseR[`HS_SAMPS_PER_TICK-1] <= (phsCalc >= laserClkPeriodSamples) ? phsCalc-laserClkPeriodSamples : phsCalc;
	end

endmodule
