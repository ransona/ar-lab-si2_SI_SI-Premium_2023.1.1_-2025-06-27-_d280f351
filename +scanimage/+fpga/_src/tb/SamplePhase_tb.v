//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies (now part of MBF)
// Engineer: Nelson Downs
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 10 ps
`include "SI_Defines.v"

// TODO: refactor, cleanup

module SamplePhase_tb();
	// clock
	reg hsClk = 1;
	always #5 hsClk <= ~hsClk;

	localparam SAMPLE_PHASE_BITS = 12;
	localparam HS_NUM_LOGICAL_CHANNELS = 2;

	// user params
	reg [SAMPLE_PHASE_BITS-1:0] hsSyncTrigPhaseShift = 0;
	reg [15:0]                  hsSyncTrigger = 16'b0000_0000_1111_1111;
	reg                         hsSyncTrigIgnorePhysical = 0;
	
	localparam [SAMPLE_PHASE_BITS-1:0] PERIOD = 32;

	// analog data
	reg [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataA;
	reg [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataB;
	wire signed [11:0] chASamps[31:0];
	wire signed [11:0] chBSamps[31:0];

	// sample phase nets (to be tested)
	wire [SAMPLE_PHASE_BITS-1:0] samplePhase[`HS_SAMPS_PER_TICK-1:0];
	wire [SAMPLE_PHASE_BITS-1:0] samplePhase32;
	reg  [SAMPLE_PHASE_BITS-1:0] lastSamplePhase32;
	wire [(SAMPLE_PHASE_BITS*`HS_SAMPS_PER_TICK)-1:0] samplePhasePacked;

	// validation nets
	reg  samplePhaseWithinBounds = 1;
	wire lastTickWas32Difference;

	// logical channel settings
	wire [HS_NUM_LOGICAL_CHANNELS*32-1:0] acqParamLogicalChannelSettings;
	wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] acqParamLaserTriggerFilterWindowStart;
	wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] acqParamLaserTriggerFilterWindowN;
	wire [`LOGICAL_CHANNEL_BUF_LSZ:0] logicalChannels;
	wire signed [`LOGICAL_CHANNEL_LSZ:0] logicalChanDecode[HS_NUM_LOGICAL_CHANNELS-1:0];

	// data out valid
	wire dataOutValid;

	// sync trigger & channel signal generation:
	reg [SAMPLE_PHASE_BITS:0] lastTrigPhs = 0;
	reg [SAMPLE_PHASE_BITS:0] trigPhs = 0;
	reg [5:0]  ctr;
	always @(posedge hsClk) begin
		for (ctr = 0; ctr < 32; ctr = ctr + 1) begin
			hsadcSampleDataA[ctr*12+:12] <= $urandom_range(1000,0);
			hsadcSampleDataB[ctr*12+:12] <= $urandom_range(1000,0);
		end

		trigPhs = lastTrigPhs;
		for (ctr = 0; ctr < 16; ctr = ctr + 1) begin
			trigPhs = trigPhs + 2;
			trigPhs = (trigPhs >= PERIOD) ? 0 : trigPhs;
			// hsSyncTrigger[ctr] <= trigPhs < (PERIOD >> 1);
		end
		lastTrigPhs <= trigPhs;
	end

	// channels & sample phase unpack
	generate
		genvar ctri;
		for (ctri = 0; ctri < 32; ctri = ctri + 1) begin:chs
			assign chASamps[ctri] = hsadcSampleDataA[ctri*12+:12];
			assign chBSamps[ctri] = hsadcSampleDataB[ctri*12+:12];
		end

		for (ctri = 0; ctri < `HS_SAMPS_PER_TICK; ctri = ctri + 1) begin:gen_sync_trg_phs_unpack
			assign samplePhase[ctri] = samplePhasePacked[ctri*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS];
		end
	endgenerate

	assign samplePhase32 = samplePhase[31];
	always @(posedge hsClk)
		lastSamplePhase32 <= samplePhase32;

	// logical channel settings
	localparam CHAN_WIDTH = 4;
	generate
		genvar lc_i;
		for (lc_i = 0; lc_i < HS_NUM_LOGICAL_CHANNELS; lc_i=lc_i+1) begin:gen_logical_channel_settings
			reg [31:0] acqParamLogicalChannelSettings_R = 1 << 9; // laser gate on
			reg [SAMPLE_PHASE_BITS-1:0] acqParamLaserTriggerFilterWindowStart_R = lc_i ? 16 : 0;
			reg [SAMPLE_PHASE_BITS-1:0] acqParamLaserTriggerFilterWindowN_R = lc_i ? CHAN_WIDTH : CHAN_WIDTH;
			
			assign acqParamLogicalChannelSettings[lc_i*32+:32] = acqParamLogicalChannelSettings_R;
			assign acqParamLaserTriggerFilterWindowStart[lc_i*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS] = acqParamLaserTriggerFilterWindowStart_R;
			assign acqParamLaserTriggerFilterWindowN[lc_i*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS] = acqParamLaserTriggerFilterWindowN_R;
		end

		for (lc_i = 0; lc_i < HS_NUM_LOGICAL_CHANNELS; lc_i=lc_i+1) begin:gen_logical_channel_unpack
			assign logicalChanDecode[lc_i] = logicalChannels[`LOGICAL_CHANNEL_WIDTH*lc_i+:`LOGICAL_CHANNEL_WIDTH];
		end
	endgenerate

	// sample phase module
	SI_SamplePhase #(.SAMPLE_PHASE_BITS(SAMPLE_PHASE_BITS)) samplePhaseMachine (
		.hsSyncTrigger(hsSyncTrigger),
		.hsadcDataClk(hsClk),
		.hsSyncTrigPhaseShift(hsSyncTrigPhaseShift),
		.hsSyncTrigIgnorePhysical(hsSyncTrigIgnorePhysical),
		.laserClkPeriodSamples(PERIOD),
		.samplePhasePacked(samplePhasePacked)
	);

	// signal conditioning LRR module
	SI_SignalConditionH #(
	   .HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
	   .SAMPLE_PHASE_BITS(SAMPLE_PHASE_BITS)
	) signalConditionH (
		.clk(hsClk),
		
		.sampleDataA(hsadcSampleDataA),
		.sampleDataB(hsadcSampleDataA),

		.dataOut(logicalChannels),
		.dataOutRaw(),
		.dataOutValid(dataOutValid),
		
		.channelsInvert(0),
		.channelOffsets(0),
		.logicalChannelSettings(acqParamLogicalChannelSettings),
		.laserTriggerFilterWindowStart(acqParamLaserTriggerFilterWindowStart),
		.laserTriggerFilterWindowN(acqParamLaserTriggerFilterWindowN),

		.samplePhasePacked(samplePhasePacked)
	);

	// test sequence logic
	reg [14:0] testCtr = 0;
	localparam ADD_PHASE = 512;
	always @(posedge hsClk) begin
		if (testCtr < ADD_PHASE)
			testCtr <= testCtr + 1;
		else begin
			hsSyncTrigPhaseShift <= (hsSyncTrigPhaseShift + 1) % PERIOD;
			hsSyncTrigger <= {hsSyncTrigger[14:0], hsSyncTrigger[15]};
			testCtr <= 0;
		end
	end

	// validation logic
	reg [5:0] val_i;
	always @(posedge hsClk) begin
		samplePhaseWithinBounds = samplePhase[0] < PERIOD;
		for (val_i = 1; val_i < `HS_SAMPS_PER_TICK; val_i = val_i+1) begin
			samplePhaseWithinBounds = samplePhaseWithinBounds && (samplePhase[val_i] < PERIOD);
		end
	end

	assign lastTickWas32Difference = (samplePhase32 - lastSamplePhase32) == 32;

	// initial begin
	// 	hsSyncTrigPhaseShift       = 0;
	// 	hsSyncTrigger              = 16'b0;
	// 	PERIOD      = 662;
	// 	hsSyncTrigIgnorePhysical   = 0;

	// 	#110 hsSyncTrigPhaseShift  = 331;
	// 	#110 hsSyncTrigPhaseShift  = 0;

	// 	#100  hsSyncTrigPhaseShift = 125;
	// 	#100  hsSyncTrigPhaseShift = 75;
	// 	#100  hsSyncTrigPhaseShift = 150;
	// 	#25   hsSyncTrigPhaseShift = 50;
	// 	#5    hsSyncTrigPhaseShift = 100;
	// 	#5    hsSyncTrigPhaseShift = 150;
	// 	#5    hsSyncTrigPhaseShift = 200;
	// 	#5    hsSyncTrigPhaseShift = 250;
	// 	#5    hsSyncTrigPhaseShift = 0;
	// end

endmodule
