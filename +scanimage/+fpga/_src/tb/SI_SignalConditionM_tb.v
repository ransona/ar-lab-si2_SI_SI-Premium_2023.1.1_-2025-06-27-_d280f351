//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Nelson Downs
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_SignalConditionM_tb();
	localparam HS_NUM_LOGICAL_CHANNELS = 2;
	localparam MS_NUM_LOGICAL_CHANNELS = 2;
	localparam SAMPLE_PHASE_BITS = 14;

	// clk
	reg clk = 1;
	always #5 clk <= ~clk;

	// inputs
	reg [`MS_PHYS_CHANNEL_BUF_LSZ:0] sampleData = 0;
	wire [`TRIGGER_PROCESS_OUT_LSZ:0] triggerProcessData;
	wire [`MS_NUM_PHYS_CHANNELS-1:0] channelsInvert = 0;
	wire [`PHYS_CHAN_BUF_LSZ:0] channelOffsets = 0;
	wire [2:0] acqParamMaskBits = 0;
	wire [HS_NUM_LOGICAL_CHANNELS*32-1:0] logicalChannelSettings;
	wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] laserTriggerFilterWindowStart;
	wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] laserTriggerFilterWindowN;

	// tb vars
	reg [5:0] ctr;
	reg [SAMPLE_PHASE_BITS-1:0] laserTrigPeriod = 200;
	reg [SAMPLE_PHASE_BITS-1:0] trigPhs = 0;
	reg lastTrig = 0;

	// outputs
	wire [`LOGICAL_CHANNEL_BUF_LSZ:0] dataOut;
	wire [`PHYS_CHAN_BUF_LSZ:0] dataOutRaw;
	wire dataOutValid;

	// watch vars
	wire signed [`MS_PHYS_CHANNEL_LSZ:0] ch0Samp = sampleData[0+:`MS_PHYS_CHANNEL_WIDTH];
	wire signed [`MS_PHYS_CHANNEL_LSZ:0] ch1Samp = sampleData[`MS_PHYS_CHANNEL_WIDTH+:`MS_PHYS_CHANNEL_WIDTH];
	wire signed [`MS_PHYS_CHANNEL_LSZ:0] ch2Samp = sampleData[(2*`MS_PHYS_CHANNEL_WIDTH)+:`MS_PHYS_CHANNEL_WIDTH];
	wire signed [`MS_PHYS_CHANNEL_LSZ:0] ch3Samp = sampleData[(3*`MS_PHYS_CHANNEL_WIDTH)+:`MS_PHYS_CHANNEL_WIDTH];
	// assign ch0Samp = sampleData[0+:`MS_PHYS_CHANNEL_WIDTH];
	// assign ch1Samp = sampleData[`MS_PHYS_CHANNEL_WIDTH+:`MS_PHYS_CHANNEL_WIDTH];
	// assign ch2Samp = sampleData[(2*`MS_PHYS_CHANNEL_WIDTH)+:`MS_PHYS_CHANNEL_WIDTH];
	// assign ch3Samp = sampleData[(3*`MS_PHYS_CHANNEL_WIDTH)+:`MS_PHYS_CHANNEL_WIDTH];

	// input setup
	always @(posedge clk) begin
		for (ctr = 0; ctr < `MS_NUM_PHYS_CHANNELS; ctr = ctr + 1) begin
			sampleData[ctr*`MS_PHYS_CHANNEL_WIDTH+:`MS_PHYS_CHANNEL_WIDTH] <= $urandom_range(1000,0);
		end

		trigPhs = (trigPhs >= laserTrigPeriod) ? 0 : trigPhs + 1;
		lastTrig <= triggerProcessData[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_RAW_BIT];
	end
	assign triggerProcessData[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_RAW_BIT] = trigPhs >= laserTrigPeriod/2;
	assign triggerProcessData[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_BIT] = triggerProcessData[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_RAW_BIT] && !lastTrig;
	assign triggerProcessData[15:0] = 0;

	generate
		genvar lc_i;
		for (lc_i = 0; lc_i < `MS_NUM_LOGICAL_CHANNELS; lc_i = lc_i + 1) begin
			reg [31:0] logicalChannelSettings_R = 0 | (1<<9); // laser gate on
			reg [SAMPLE_PHASE_BITS-1:0] laserTriggerFilterWindowStart_R = lc_i ? 56 : 0;
			reg [SAMPLE_PHASE_BITS-1:0] laserTriggerFilterWindowN_R = lc_i ? 16 : 16;

			assign logicalChannelSettings[lc_i*32+:32] = logicalChannelSettings_R;
			assign laserTriggerFilterWindowStart[lc_i*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS] = laserTriggerFilterWindowStart_R;
			assign laserTriggerFilterWindowN[lc_i*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS] = laserTriggerFilterWindowN_R;
		end
	endgenerate

	// instance
	SI_SignalConditionM #(
		.HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
		.MS_NUM_LOGICAL_CHANNELS(MS_NUM_LOGICAL_CHANNELS),
		.SAMPLE_PHASE_BITS(SAMPLE_PHASE_BITS)
	) signalCond (
		.clk(clk),
		
		.sampleData(sampleData),

		.triggerProcessData(triggerProcessData),
		.dataOut(dataOut),
		.dataOutRaw(dataOutRaw),
		.dataOutValid(dataOutValid),
		
		.channelsInvert(channelsInvert),
		.channelOffsets(channelOffsets),
		.acqParamMaskBits(acqParamMaskBits),
		
		.logicalChannelSettings(logicalChannelSettings),
		.laserTriggerFilterWindowStart(laserTriggerFilterWindowStart),
		.laserTriggerFilterWindowN(laserTriggerFilterWindowN)
	);

endmodule
