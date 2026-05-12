//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_SignalConditionH_LRR #(
	parameter HS_NUM_LOGICAL_CHANNELS = 4,
	parameter SAMPLE_PHASE_BITS = 6
)(
	input  wire clk,
	
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] sampleDataA,   // 32 samples for first physical channel
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] sampleDataB,   // 32 samples from 2nd physical channel
	input  wire [`HS_SAMPS_PER_TICK-1:0] photonPeaksA,
	input  wire [`HS_SAMPS_PER_TICK-1:0] photonPeaksB,

	output wire [`LOGICAL_CHANNEL_BUF_LSZ:0] dataOut,
	output wire [`PHYS_CHAN_BUF_LSZ:0] dataOutRaw,
	output wire dataOutValid,
	
	input  wire [`HS_NUM_PHYS_CHANNELS-1:0]  channelsInvert,
	input  wire [`PHYS_CHAN_BUF_LSZ:0] channelOffsets,

	input  wire [HS_NUM_LOGICAL_CHANNELS*32-1:0] logicalChannelSettings,
	input  wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] laserTriggerFilterWindowStart,
	input  wire [HS_NUM_LOGICAL_CHANNELS*SAMPLE_PHASE_BITS-1:0] laserTriggerFilterWindowN,

	input wire  [(SAMPLE_PHASE_BITS*`HS_SAMPS_PER_TICK)-1:0] samplePhasePacked
);
	localparam signed [`HS_PHYS_CHANNEL_LSZ+2:0] SAMPLE_MIN = {3'b111, {`HS_PHYS_CHANNEL_LSZ{1'b0}}};
	localparam signed [`HS_PHYS_CHANNEL_LSZ+2:0] SAMPLE_MAX = {3'b000, {`HS_PHYS_CHANNEL_LSZ{1'b1}}};

	localparam HS_PHYS_CHANNEL_LSZ_E = `HS_PHYS_CHANNEL_LSZ+1; //extend values by one bit after adding offset

	
	// sort samples, decimate channels for raw value reading
	wire signed [11:0] sample[`HS_NUM_PHYS_CHANNELS-1:0][31:0];               // sample: contains both physical channels samples
	reg  signed [15:0] decimatedPhyChannelSample[`HS_NUM_PHYS_CHANNELS-1:0];  // averaging the 32 samples together

	generate
		genvar sampIter;
		genvar phyCh;

		for (sampIter = 0; sampIter < `HS_SAMPS_PER_TICK; sampIter=sampIter+1) begin:gen_decim
			assign sample[0][sampIter] = sampleDataA[`HS_PHYS_CHANNEL_WIDTH*sampIter+:`HS_PHYS_CHANNEL_WIDTH];
			assign sample[1][sampIter] = sampleDataB[`HS_PHYS_CHANNEL_WIDTH*sampIter+:`HS_PHYS_CHANNEL_WIDTH];
		end

		for (phyCh = 0; phyCh < `HS_NUM_PHYS_CHANNELS; phyCh=phyCh+1) begin:gen_raw_phy_chans
			reg [5:0] i = 0;
			reg signed [16:0] decimSampleCalc;

			always @(posedge clk) begin
				decimSampleCalc = 0;
				for (i = 0; i < `HS_SAMPS_PER_TICK; i=i+1)
					decimSampleCalc = decimSampleCalc + sample[phyCh][i];
				
				decimatedPhyChannelSample[phyCh] <= decimSampleCalc[16:1];  
				// remove bit 0 which downshifts by one bit 32 samples -> 16 bit integer for reading of the offsets
				// samples that go downstream in imaging pipeline have another decimation
			end
		end
	endgenerate


	// physical channel intermediate conditioning
	// produces dataoutraw and physicalChanSamples
	// dataoutraw: signal used during measurement of offsets, liveRawChannels in MATLAB 32-samples averaged together with inversion applied
	// physicalChanSamples: used downstream for imaging pipeline, also stored in register to reduce time to pull value downstream
	wire signed [HS_PHYS_CHANNEL_LSZ_E:0] physicalChanSamples[`HS_NUM_PHYS_CHANNELS-1:0][`HS_SAMPS_PER_TICK-1:0];
	reg  signed [HS_PHYS_CHANNEL_LSZ_E:0] physicalChanSamplesR[`HS_NUM_PHYS_CHANNELS-1:0][`HS_SAMPS_PER_TICK-1:0];
	genvar pChCtr;
	genvar pSampCtr;
	generate
		for (pChCtr=0; pChCtr<`HS_NUM_PHYS_CHANNELS; pChCtr=pChCtr+1) begin : gen_phy_chans
			// per settings, we invert some of the channels
			wire signed [`LOGICAL_CHANNEL_LSZ:0] invChan = channelsInvert[pChCtr] ? ~decimatedPhyChannelSample[pChCtr] : decimatedPhyChannelSample[pChCtr];
			wire signed [`HS_PHYS_CHANNEL_LSZ:0] offset = channelOffsets[pChCtr*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH];
			
			assign dataOutRaw[pChCtr*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH] = invChan;

			for (pSampCtr=0; pSampCtr<`HS_SAMPS_PER_TICK; pSampCtr=pSampCtr+1) begin : generate_samps
				assign physicalChanSamples[pChCtr][pSampCtr] = (channelsInvert[pChCtr] ? ~sample[pChCtr][pSampCtr] : sample[pChCtr][pSampCtr]) + offset;

				always @(posedge clk)
					physicalChanSamplesR[pChCtr][pSampCtr] <= physicalChanSamples[pChCtr][pSampCtr];
			end
		end
	endgenerate

	// rest of the raw channel buffer
	assign dataOutRaw[`PHYS_CHAN_BUF_LSZ:`HS_NUM_PHYS_CHANNELS*`LOGICAL_CHANNEL_WIDTH] = 0;


	// array for photon counting signal
	wire [`HS_SAMPS_PER_TICK-1:0] photonPeaks[`HS_NUM_PHYS_CHANNELS-1:0];
	assign photonPeaks[0] = photonPeaksA;
	assign photonPeaks[1] = photonPeaksB;


	// keep track of sample phase w.r.t. laser clock
	wire [SAMPLE_PHASE_BITS-1:0] samplePhase[`HS_SAMPS_PER_TICK-1:0];

	generate
		genvar phsIter;
		for (phsIter = 0; phsIter < `HS_SAMPS_PER_TICK; phsIter = phsIter + 1) begin:gen_sync_trg_phs_unpack
			// unpack sample phase
			assign samplePhase[phsIter] = samplePhasePacked[phsIter*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS];
		end
	endgenerate

	wire laserGatingOn;

	reg dataPhsValidR = 0;
	always @(posedge clk) begin
		// if the last element of SamplePhase less than the first element of sample phase then a wrap around occurred
		// does ((samplePhase[0] == 0) || (samplePhase[0] > samplePhase[31]))
		// ^ this means a wrap around just occurred and a laser pulse has arrived

		// data valid is a signal to downstream pipeline that a laser pulse was detected and that the gated virtual channels were generated for that pulse
		// only applicable to SI_SignalConditionH_LRR; in the other Signal Conditioning modules, it's true every clock cycle
		dataPhsValidR <= ((samplePhase[0] == 0) || (samplePhase[0] > samplePhase[31]));
	end

	assign dataOutValid = dataPhsValidR || ~laserGatingOn;


	// logical channels
	generate
		genvar lc_i;
		genvar lcs_i;
		genvar lcPhase_i;
		genvar vcs_i;

		for (lc_i = 0; lc_i < HS_NUM_LOGICAL_CHANNELS; lc_i=lc_i+1) begin:gen_logical_chan
			wire [31:0] logicalChannelSettings_i = logicalChannelSettings[lc_i*32+:32];
		//	wire [5:0] signalSource = logicalChannelSettings_i[5:0];
		//	wire applyThreshold = logicalChannelSettings_i[6];
		//	wire binarize = logicalChannelSettings_i[7];
		//	wire edgeDetect = logicalChannelSettings_i[8];
			wire laserGate = logicalChannelSettings_i[9];
			wire downShift = logicalChannelSettings_i[10];
		//	wire signed [15:0] thresh = logicalChannelSettings_i[31:16];
			wire [SAMPLE_PHASE_BITS-1:0] wndoStart_i = laserTriggerFilterWindowStart[lc_i*SAMPLE_PHASE_BITS+:SAMPLE_PHASE_BITS];
			wire [4:0] wndoN_m1 = laserTriggerFilterWindowN[lc_i*SAMPLE_PHASE_BITS+:5]; // number of samples minus 1
			wire [SAMPLE_PHASE_BITS-1:0] wndoEnd_i = wndoStart_i + wndoN_m1;

			if (!lc_i)
				assign laserGatingOn = laserGate;
			
			// index out physical channel source
			// hardcoded to reduce logic utilization
			// logical channels 0-31 are AI0
			// logical channels 32-63 are AI1
			// this is for Alipasha's version, we won't need all 64 virtual channels and can set it up so we configure whether we are compiling with Alipasha's customization or with the lower virtual channel count which has more configurable logical channels
			wire signed [HS_PHYS_CHANNEL_LSZ_E:0] myPhysicalChanSamples[31:0];

			for (lcs_i = 0; lcs_i < `HS_SAMPS_PER_TICK; lcs_i=lcs_i+1) begin:gen_my_samps
				if (lc_i < (HS_NUM_LOGICAL_CHANNELS/2))
					assign myPhysicalChanSamples[lcs_i] = physicalChanSamplesR[0][lcs_i];
				else
					assign myPhysicalChanSamples[lcs_i] = physicalChanSamplesR[1][lcs_i];
			end


			// find start and end points of this channel's sample window
			reg [4:0] startSampleIdx = 0;
			reg [4:0] endSampleIdx = 0;
			reg foundStart = 0;
			reg foundEnd = 0;

			reg [5:0] schIter = 0;
			reg foundStartCalc = 0;
			reg foundEndCalc = 0;

			always @(posedge clk) begin
				foundStartCalc = 0;
				foundEndCalc = 0;

				for (schIter = 0; schIter < `HS_SAMPS_PER_TICK; schIter = schIter + 1) begin
					if (samplePhase[schIter] == wndoStart_i) begin
						startSampleIdx <= schIter;
						foundStartCalc = 1;
					end

					if (samplePhase[schIter] == wndoEnd_i) begin
						endSampleIdx <= schIter;
						foundEndCalc = 1;
					end
				end

				foundStart <= foundStartCalc;
				foundEnd <= foundEndCalc;
			end
			

			// calculate the channel sum
			reg signed [HS_PHYS_CHANNEL_LSZ_E:0] vChanSamples[`HS_SAMPS_PER_TICK-1:0];
			reg [5:0] vChanIter = 0;
			reg runCalc = 0;

			reg signed [`LOGICAL_CHANNEL_LSZ:0] channelCalc = 0;
			reg signed [`LOGICAL_CHANNEL_LSZ:0] channelCalc_p[1:0];
			reg signed [`LOGICAL_CHANNEL_LSZ:0] channelResult = 0;
			reg signed [`LOGICAL_CHANNEL_LSZ+1:0] channelResultPre = 0;

			wire [4:0] startSampleIdxSimp = 16 + startSampleIdx[3:0];

			always @(posedge clk) begin
				if (!laserGate || (foundStart && foundEnd)) begin
					for (vChanIter = 0; vChanIter < `HS_SAMPS_PER_TICK; vChanIter = vChanIter+1) begin
						if (((vChanIter >= startSampleIdx) && (vChanIter <= endSampleIdx)) || !laserGate)
							vChanSamples[vChanIter] <= myPhysicalChanSamples[vChanIter];
						else
							vChanSamples[vChanIter] <= 0;
					end
				end else if (foundStart) begin
					for (vChanIter = 0; vChanIter < `HS_SAMPS_PER_TICK; vChanIter = vChanIter+1) begin
						if (vChanIter >= startSampleIdx)
							vChanSamples[vChanIter] <= myPhysicalChanSamples[vChanIter];
						else
							vChanSamples[vChanIter] <= 0;
					end
				end else if (foundEnd) begin
					for (vChanIter = 0; vChanIter < `HS_SAMPS_PER_TICK; vChanIter = vChanIter+1) begin
						if (vChanIter <= endSampleIdx)
							vChanSamples[vChanIter] <= myPhysicalChanSamples[vChanIter];
					end
				end

				// vChanSamples now contains only the values for the logical channel and nothing else

				runCalc <= foundEnd || !laserGate;

				if (runCalc) begin
					channelCalc = vChanSamples[0];
					for (vChanIter = 1; vChanIter < (`HS_SAMPS_PER_TICK/2); vChanIter = vChanIter+1)
						channelCalc = channelCalc + vChanSamples[vChanIter];
					channelCalc_p[0] <= channelCalc;

					channelCalc = vChanSamples[`HS_SAMPS_PER_TICK/2];
					for (vChanIter = `HS_SAMPS_PER_TICK/2+1; vChanIter < `HS_SAMPS_PER_TICK; vChanIter = vChanIter+1)
						channelCalc = channelCalc + vChanSamples[vChanIter];
					channelCalc_p[1] <= channelCalc;
				end

				channelResultPre = channelCalc_p[0] + channelCalc_p[1];
				channelResult <= downShift ? channelResultPre >>> 1 : channelResultPre;
			end

			assign dataOut[lc_i*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH] = channelResult;
		end
	endgenerate
	
endmodule
