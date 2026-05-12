//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_SignalConditionM #(
	parameter HS_NUM_LOGICAL_CHANNELS = 8,
	parameter MS_NUM_LOGICAL_CHANNELS = 8,
	parameter SAMPLE_PHASE_BITS = 12
)(
	input  wire clk,
	
	input  wire [`MS_PHYS_CHANNEL_BUF_LSZ:0] sampleData,

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
	input  wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] laserTriggerFilterWindowN
);
	localparam signed [`LOGICAL_CHANNEL_LSZ+2:0] LOGICAL_CHANNEL_MIN = {3'b111, {`LOGICAL_CHANNEL_LSZ{1'b0}}};
	localparam signed [`LOGICAL_CHANNEL_LSZ+2:0] LOGICAL_CHANNEL_MAX = {3'b000, {`LOGICAL_CHANNEL_LSZ{1'b1}}};

	// saturating adder
	function signed [`LOGICAL_CHANNEL_LSZ:0] add_s;
		input signed [`LOGICAL_CHANNEL_LSZ:0] a;
		input signed [`LOGICAL_CHANNEL_LSZ:0] b;
		reg signed [`LOGICAL_CHANNEL_LSZ+2:0] a_ext;
		reg signed [`LOGICAL_CHANNEL_LSZ+2:0] sum_ext;
	begin
		a_ext = {a[`LOGICAL_CHANNEL_LSZ], a[`LOGICAL_CHANNEL_LSZ], a};
		sum_ext = a_ext + b;
		add_s = (sum_ext < LOGICAL_CHANNEL_MIN) ? LOGICAL_CHANNEL_MIN : ((sum_ext > LOGICAL_CHANNEL_MAX) ? LOGICAL_CHANNEL_MAX : sum_ext);
	end
	endfunction

	wire [3:0] photonPulse = triggerProcessData[`TRIGGER_PROCESS_OUT_PHOTON_PULSE_START_BIT+:4];
	wire laserTrigger = triggerProcessData[`TRIGGER_PROCESS_OUT_LASER_TRIGGER_BIT];


	// physical channel intermediate conditioning
	reg [`LOGICAL_CHANNEL_BUF_LSZ:0] doutPhys = 0;
	
	genvar chIdx;
	generate
		for (chIdx=0; chIdx<`MS_NUM_PHYS_CHANNELS; chIdx=chIdx+1) begin : generate_chans
			// TODO: possibly might want to figure out when to do left justify, it should be unshifted here and then in the logical channel processing each one would have the option to left justify
			//  reasoning is that we want the precision for the accumulator step, but left justify is still useful for sinusoidal binning
			wire signed [`LOGICAL_CHANNEL_LSZ:0] rjChan = {sampleData[chIdx*`MS_PHYS_CHANNEL_WIDTH+:`MS_PHYS_CHANNEL_WIDTH], {`LOGICAL_CHANNEL_WIDTH-`MS_PHYS_CHANNEL_WIDTH{1'b0}}};
			wire signed [`LOGICAL_CHANNEL_LSZ:0] invChan = channelsInvert[chIdx] ? ~rjChan : rjChan;
			wire signed [`LOGICAL_CHANNEL_LSZ:0] offset = channelOffsets[chIdx*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH];
			wire signed [`LOGICAL_CHANNEL_LSZ:0] offsetChan = add_s(invChan, offset);
			
			wire [`LOGICAL_CHANNEL_LSZ:0] dout = (offsetChan >>> acqParamMaskBits) << acqParamMaskBits;
			
			assign dataOutRaw[chIdx*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH] = invChan;

			// register/pipeline here
			always @(posedge clk)
				doutPhys[chIdx*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH] <= dout;
		end
	endgenerate
	

	// laser clock phase tracking
	reg  [SAMPLE_PHASE_BITS-1:0] nextLaserTriggerFilterCtr = 0;
	wire [SAMPLE_PHASE_BITS-1:0] laserTriggerFilterCtr = laserTrigger ? 0 : nextLaserTriggerFilterCtr;

	always @(posedge clk) begin
		if (laserTrigger)
			nextLaserTriggerFilterCtr <= 1;
		else if (!(&nextLaserTriggerFilterCtr))
			nextLaserTriggerFilterCtr <= nextLaserTriggerFilterCtr + 1;
	end

	// wire from the generate block for dataOutValid
	wire laserGatingEnabled;

	// logical channel conditioning
	generate
		genvar lc_i;
		genvar lc_i_e;
		
		for (lc_i = 0; lc_i < MS_NUM_LOGICAL_CHANNELS; lc_i=lc_i+1) begin:gen_logical_chans
			wire [31:0] logicalChannelSettings_i = logicalChannelSettings[lc_i*32+:32];
			wire [5:0] signalSource = logicalChannelSettings_i[5:0];
			wire applyThreshold = logicalChannelSettings_i[6];
			wire binarize = logicalChannelSettings_i[7];
			wire edgeDetect = logicalChannelSettings_i[8];
			wire laserGate = logicalChannelSettings_i[9];
			wire signed [15:0] thresh = logicalChannelSettings_i[31:16];
			wire [SAMPLE_PHASE_BITS-1:0] wndoStart_i = laserTriggerFilterWindowStart[lc_i*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS];
			wire [SAMPLE_PHASE_BITS-1:0] wndoEnd_i = wndoStart_i + laserTriggerFilterWindowN[lc_i*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS];

			// if one is lasergated, all of them are - data is always valid when laser gating is off
			if (lc_i == 0)
				assign laserGatingEnabled = laserGate;

			// condition the raw signals: apply threshold and binarization
			wire signed [`LOGICAL_CHANNEL_LSZ:0] signal = (signalSource < `MS_NUM_PHYS_CHANNELS) ? doutPhys[`LOGICAL_CHANNEL_WIDTH*signalSource+:`LOGICAL_CHANNEL_WIDTH] : photonPulse[signalSource-`MS_NUM_PHYS_CHANNELS];
			wire signed [`LOGICAL_CHANNEL_LSZ:0] signalThreshd = (applyThreshold && (signal < thresh)) ? 0 : signal;
			wire signed [`LOGICAL_CHANNEL_LSZ:0] signalBd = (applyThreshold && binarize && (signalThreshd > 0)) ? 1 : signalThreshd;

			// apply edge detection
			reg signalEdP = 0;
			wire signed [`LOGICAL_CHANNEL_LSZ:0] signalEd = (applyThreshold && binarize && edgeDetect && signalEdP) ? 0 : signalBd;
			always @(posedge clk)
				signalEdP <= |signalBd;
			
			reg signed [`LOGICAL_CHANNEL_LSZ:0] signalAccumCalc = 0;
			reg signed [`LOGICAL_CHANNEL_LSZ:0] signalAccum = 0;
			reg signed [`LOGICAL_CHANNEL_LSZ:0] signalSnapshot = 0;
			always @(posedge clk) begin
				// combinational logic; doesn't need to be in the IF block, that would use more LUTs
				signalAccumCalc = add_s(signalAccum, signalEd);
				
				// accumulate signals based on current phase:
				// - restart the accumulator at the start of the lasergate window
				// - save a snapshot of the accumulator at the end of the lasergate window
				if (laserGate) begin
					if (laserTriggerFilterCtr == wndoStart_i)
						signalAccum <= signalEd;
					else
						signalAccum <= signalAccumCalc;

					if (laserTriggerFilterCtr == wndoStart_i && laserTriggerFilterCtr == wndoEnd_i)
						signalSnapshot <= signalEd;
					else if (laserTriggerFilterCtr == wndoEnd_i)
						signalSnapshot <= signalAccumCalc;
				end

				// otherwise the output is just going to be the conditioned signal
				else
					signalSnapshot <= signalEd;
			end
			
			assign dataOut[lc_i*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH] = signalSnapshot;
		end
		
		for (lc_i_e = MS_NUM_LOGICAL_CHANNELS; lc_i_e < HS_NUM_LOGICAL_CHANNELS; lc_i_e=lc_i_e+1) begin:gen_extra_logical_chans
			assign dataOut[lc_i_e*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH] = 0;
		end
	endgenerate

	// data is valid on trigger, or always valid if not laser gating
	assign dataOutValid = laserTrigger || !laserGatingEnabled || enableMixedLasergating;
	
endmodule
