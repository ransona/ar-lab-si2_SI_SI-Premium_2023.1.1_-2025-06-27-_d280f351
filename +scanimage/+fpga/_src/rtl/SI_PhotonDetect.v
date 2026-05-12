//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_PhotonDetect (
	input  wire dataClk,
	
	input  wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] sampleData,

	input  wire signed [`HS_PHYS_CHANNEL_WIDTH-1:0] threshold,
	input  wire invert,
	input  wire differentiateMode,
	input  wire [1:0] differentiateOrder,
	input  wire differentiateDeadTime,
	
	output wire [`HS_SAMPS_PER_TICK-1:0] photonPeaks
);

	reg  [`HS_SAMPS_PER_TICK-1:0] photonPeaksTrsh;
	reg  [`HS_SAMPS_PER_TICK-1:0] photonPeaksDiff;
	assign photonPeaks = differentiateMode ? photonPeaksDiff : photonPeaksTrsh;
	


	// simple threshold technique
	reg  lastSampleHi = 0;
	wire [`HS_SAMPS_PER_TICK-1:0] sampleHi;

	always @(posedge dataClk)
		lastSampleHi <= sampleHi[`HS_SAMPS_PER_TICK-1];
	
	generate
		genvar sampIterTH;

		for (sampIterTH = 0; sampIterTH < `HS_SAMPS_PER_TICK; sampIterTH=sampIterTH+1) begin:gen_th_samp
			wire signed [`HS_PHYS_CHANNEL_WIDTH-1:0] raw_sample = sampleData[`HS_PHYS_CHANNEL_WIDTH*sampIterTH+:`HS_PHYS_CHANNEL_WIDTH];
			wire signed [`HS_PHYS_CHANNEL_WIDTH-1:0] sample_i = invert ? ~raw_sample : raw_sample;
			assign sampleHi[sampIterTH] = sample_i > threshold;

			assign pSampHi = sampIterTH ? sampleHi[sampIterTH-1] : lastSampleHi;

			always @(posedge dataClk)
				photonPeaksTrsh[sampIterTH] <= sampleHi[sampIterTH] && ~pSampHi;
		end
	endgenerate
	


	// diff technique
	reg signed [`HS_PHYS_CHANNEL_WIDTH-1:0] sample[(`HS_SAMPS_PER_TICK*2)-1:0]; //0-31 are samples 1/z
	reg [`HS_SAMPS_PER_TICK-1:0] sampleDiffZ_ot;   // differentiated sample is over thold
	reg [`HS_SAMPS_PER_TICK-1:0] sampleDiffZ_pos;  // differentiated sample is positive
	reg [`HS_SAMPS_PER_TICK-1:0] sching;
	reg schingZ = 0;
	reg photonZ = 0;

	generate
		genvar sampIterD;

		for (sampIterD = 0; sampIterD < `HS_SAMPS_PER_TICK; sampIterD=sampIterD+1) begin:gen_diff_pc
			wire signed [`HS_PHYS_CHANNEL_WIDTH-1:0] raw_sample = sampleData[`HS_PHYS_CHANNEL_WIDTH*sampIterD+:`HS_PHYS_CHANNEL_WIDTH];
			always @(*)
				sample[sampIterD+`HS_SAMPS_PER_TICK] = invert ? ~raw_sample : raw_sample;
			
			always @(posedge dataClk)
				sample[sampIterD] <= sample[sampIterD+`HS_SAMPS_PER_TICK];
			
			if (sampIterD < (`HS_SAMPS_PER_TICK-1)) begin
				wire signed [`HS_PHYS_CHANNEL_WIDTH-1:0] currSample = sample[sampIterD+`HS_SAMPS_PER_TICK];
				wire signed [`HS_PHYS_CHANNEL_WIDTH-1:0] nextSample = sample[sampIterD+`HS_SAMPS_PER_TICK+1];
				wire signed [`HS_PHYS_CHANNEL_WIDTH-1:0] diffSample = sample[sampIterD+`HS_SAMPS_PER_TICK-1-differentiateOrder];
				always @(posedge dataClk) begin
					sampleDiffZ_ot[sampIterD] <= (sub_s(nextSample, diffSample) > threshold) && (nextSample > currSample);
					sampleDiffZ_pos[sampIterD] <= nextSample > currSample;
				end
			end else begin
				wire signed [`HS_PHYS_CHANNEL_WIDTH-1:0] currSample = sample[sampIterD];
				wire signed [`HS_PHYS_CHANNEL_WIDTH-1:0] nextSample = sample[sampIterD+1];
				wire signed [`HS_PHYS_CHANNEL_WIDTH-1:0] diffSample = sample[sampIterD-1-differentiateOrder];
				always @(*) begin
					sampleDiffZ_ot[sampIterD] = (sub_s(nextSample, diffSample) > threshold) && (nextSample > currSample);
					sampleDiffZ_pos[sampIterD] = nextSample > currSample;
				end
			end
			

			reg wasSching;
			reg inhibit;

			always @(*) begin
				wasSching = (sampIterD == 0) ? schingZ : sching[sampIterD-1];
				inhibit = differentiateDeadTime && ((sampIterD == 0) ? photonZ : photonPeaksDiff[sampIterD-1]);

				if (wasSching) begin
					photonPeaksDiff[sampIterD] = ~sampleDiffZ_pos[sampIterD];
					sching[sampIterD] = sampleDiffZ_pos[sampIterD];
				end else begin
					photonPeaksDiff[sampIterD] = 0;
					sching[sampIterD] = sampleDiffZ_ot[sampIterD] && ~inhibit;
				end
			end

			if (sampIterD == (`HS_SAMPS_PER_TICK-1))
				always @(posedge dataClk) begin
					schingZ <= sching[sampIterD];
					photonZ <= photonPeaksDiff[sampIterD];
				end
		end
	endgenerate


	
	// saturating subtract
	localparam signed [`HS_PHYS_CHANNEL_LSZ+2:0] SAMPLE_MIN = {3'b111, {`HS_PHYS_CHANNEL_LSZ{1'b0}}};
	localparam signed [`HS_PHYS_CHANNEL_LSZ+2:0] SAMPLE_MAX = {3'b000, {`HS_PHYS_CHANNEL_LSZ{1'b1}}};

	function signed [`HS_PHYS_CHANNEL_LSZ:0] sub_s;
		input signed [`HS_PHYS_CHANNEL_LSZ:0] a;
		input signed [`HS_PHYS_CHANNEL_LSZ:0] b;
		reg signed [`HS_PHYS_CHANNEL_LSZ+2:0] a_ext;
		reg signed [`HS_PHYS_CHANNEL_LSZ+2:0] diff_ext;
	begin
		a_ext = {a[`HS_PHYS_CHANNEL_LSZ], a[`HS_PHYS_CHANNEL_LSZ], a};
		diff_ext = a_ext - b;
		sub_s = (diff_ext < SAMPLE_MIN) ? SAMPLE_MIN : ((diff_ext > SAMPLE_MAX) ? SAMPLE_MAX : diff_ext);
	end
	endfunction

endmodule


