//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ns
`include "SI_Defines.v"

// TODO: refactor, clean up

module SI_SignalConditionH #(
	parameter HS_NUM_LOGICAL_CHANNELS = 8,
	parameter SAMPLE_PHASE_BITS = 12
)(
	input  wire clk,
	
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] sampleDataA,
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] sampleDataB,
	input  wire [15:0] syncTrigger,
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

	localparam signed [16:0] ACCUM_MIN = 17'b1_1000_0000_0000_0000;
	localparam signed [16:0] ACCUM_MAX = 17'b0_0111_1111_1111_1111;

	// saturating adder
	function signed [`HS_PHYS_CHANNEL_LSZ:0] add_s;
		input signed [`HS_PHYS_CHANNEL_LSZ:0] a;
		input signed [`HS_PHYS_CHANNEL_LSZ:0] b;
		reg signed [`HS_PHYS_CHANNEL_LSZ+2:0] a_ext;
		reg signed [`HS_PHYS_CHANNEL_LSZ+2:0] sum_ext;
	begin
		a_ext = {a[`HS_PHYS_CHANNEL_LSZ], a[`HS_PHYS_CHANNEL_LSZ], a};
		sum_ext = a_ext + b;
		add_s = (sum_ext < SAMPLE_MIN) ? SAMPLE_MIN : ((sum_ext > SAMPLE_MAX) ? SAMPLE_MAX : sum_ext);
	end
	endfunction

	
	// sort samples, decimate channels for raw value reading
	wire signed [11:0] sample[`HS_NUM_PHYS_CHANNELS-1:0][31:0];
	reg  signed [15:0] decimatedPhyChannelSample[`HS_NUM_PHYS_CHANNELS-1:0];

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
			end
		end
	endgenerate


	// physical channel intermediate conditioning
	wire [11:0] physicalChanSamples[`HS_NUM_PHYS_CHANNELS-1:0][31:0];
	genvar pChCtr;
	genvar pSampCtr;
	generate
		for (pChCtr=0; pChCtr<`HS_NUM_PHYS_CHANNELS; pChCtr=pChCtr+1) begin : gen_phy_chans
			wire signed [`LOGICAL_CHANNEL_LSZ:0] invChan = channelsInvert[pChCtr] ? ~decimatedPhyChannelSample[pChCtr] : decimatedPhyChannelSample[pChCtr];
			wire signed [`LOGICAL_CHANNEL_LSZ:0] offset = channelOffsets[pChCtr*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH];
			
			assign dataOutRaw[pChCtr*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH] = invChan;

			for (pSampCtr=0; pSampCtr<`HS_SAMPS_PER_TICK; pSampCtr=pSampCtr+1) begin : generate_samps
				assign physicalChanSamples[pChCtr][pSampCtr] = add_s(channelsInvert[pChCtr] ? ~sample[pChCtr][pSampCtr] : sample[pChCtr][pSampCtr], offset);
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
	localparam USED_SAMPLE_PHASE_BITS = 5;
	wire [USED_SAMPLE_PHASE_BITS-1:0] samplePhase[`HS_SAMPS_PER_TICK-1:0];
	generate
		genvar phsIter;
		for (phsIter = 0; phsIter < `HS_SAMPS_PER_TICK; phsIter = phsIter + 1) begin:gen_sync_trg_phs_unpack
			// unpack sample phase
			assign samplePhase[phsIter] = samplePhasePacked[phsIter*SAMPLE_PHASE_BITS+:USED_SAMPLE_PHASE_BITS];
		end
	endgenerate


	// logical channels
	reg [`LOGICAL_CHANNEL_BUF_LSZ:0] logicalChannelDataR = 0;
	//reg logicalChannelDivisorIncr = 0;
	assign dataOut = logicalChannelDataR;

	wire [11:0] physicalChanSamplesH[31:0];

	generate
		genvar lc_i;
		genvar lcs_i;

		for (lc_i = 0; lc_i < HS_NUM_LOGICAL_CHANNELS; lc_i=lc_i+1) begin:gen_logical_chan
			wire [31:0] logicalChannelSettings_i = logicalChannelSettings[lc_i*32+:32];
			wire [5:0] signalSource = logicalChannelSettings_i[5:0];
		//	wire applyThreshold = logicalChannelSettings_i[6];
		//	wire binarize = logicalChannelSettings_i[7];
		//	wire edgeDetect = logicalChannelSettings_i[8];
			wire laserGate = logicalChannelSettings_i[9];
			wire downShift = logicalChannelSettings_i[10];
		//	wire signed [15:0] thresh = logicalChannelSettings_i[31:16];
			wire [USED_SAMPLE_PHASE_BITS-1:0] wndoStart_i = laserTriggerFilterWindowStart[lc_i*SAMPLE_PHASE_BITS+:USED_SAMPLE_PHASE_BITS];
			wire [4:0] wndoN_m1 = laserTriggerFilterWindowN[lc_i*SAMPLE_PHASE_BITS+:5]; // number of samples minus 1
			wire [USED_SAMPLE_PHASE_BITS-1:0] wndoEnd_i = wndoStart_i + wndoN_m1;


			wire [`HS_SAMPS_PER_TICK-1:0] includeChSamp;
			wire signed [11:0] filteredSample[`HS_SAMPS_PER_TICK-1:0];

			// logical channels 16-31 must all have the same physical channel source
			// which is selected by the setting of channel 16
			wire [11:0] myPhysicalChanSamples[31:0];

			for (lcs_i = 0; lcs_i < `HS_SAMPS_PER_TICK; lcs_i=lcs_i+1) begin:gen_included_samps
				wire [11:0] selectedSample = (signalSource < `HS_NUM_PHYS_CHANNELS) ? physicalChanSamples[signalSource][lcs_i] : photonPeaks[signalSource-`HS_NUM_PHYS_CHANNELS][lcs_i];

				if (lc_i == 16)
					assign physicalChanSamplesH[lcs_i] = selectedSample;
				
				if (lc_i < 16)
					assign myPhysicalChanSamples[lcs_i] = selectedSample;
				else if (lc_i < 32)
					assign myPhysicalChanSamples[lcs_i] = physicalChanSamplesH[lcs_i];
				else
					assign myPhysicalChanSamples[lcs_i] = photonPeaks[1][lcs_i];
				
				assign includeChSamp[lcs_i] = !laserGate || ((samplePhase[lcs_i] >= wndoStart_i) && (samplePhase[lcs_i] <= wndoEnd_i));
				assign filteredSample[lcs_i] = includeChSamp[lcs_i] ? myPhysicalChanSamples[lcs_i] : 0;
			end


			reg [5:0] j = 0;
			reg signed [16:0] chanAccumCalc;
			reg signed [12:0] chanAccum_p[(`HS_SAMPS_PER_TICK/2 - 1):0];

			always @(posedge clk) begin
				for (j = 0; j < (`HS_SAMPS_PER_TICK/2); j=j+1)
					chanAccum_p[j] <= filteredSample[j*2] + filteredSample[j*2+1];

				chanAccumCalc = 0;
				for (j = 0; j < (`HS_SAMPS_PER_TICK/2); j=j+1)
					chanAccumCalc = chanAccumCalc + chanAccum_p[j];

				logicalChannelDataR[lc_i*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH] <= downShift ? chanAccumCalc[16:1] : ((chanAccumCalc > ACCUM_MAX) ? ACCUM_MAX[15:0] : ((chanAccumCalc < ACCUM_MIN) ? ACCUM_MIN[15:0] : chanAccumCalc[15:0]));
			end
		end
	endgenerate
	
	assign dataOutValid = 1;
	
endmodule
