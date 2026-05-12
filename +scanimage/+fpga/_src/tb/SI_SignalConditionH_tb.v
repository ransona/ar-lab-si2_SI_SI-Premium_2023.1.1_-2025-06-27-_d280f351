//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_SignalConditionH_tb();

    localparam HS_NUM_LOGICAL_CHANNELS = 2;

    reg hsClk = 1;

    always #5 hsClk <= ~hsClk;

    reg [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataA;
    reg [`HS_PHYS_CHANNEL_BUF_LSZ:0] hsadcSampleDataB;

	// sync trigger represents the laser clock, and rising edge means the laser pulsed
    reg [15:0] hsSyncTrigger = 16'b0000011111100000;
    reg [5:0] ctr;
	
	reg [12:0] laserTrigPeriod = 662;
	reg [12:0] lastTrigPhs = 2;
	reg [12:0] trigPhs;
	
	wire signed [11:0] chASamps[31:0];
	wire signed [11:0] chBSamps[31:0];

    always @(posedge hsClk) begin
        for (ctr = 0; ctr < 32; ctr = ctr + 1) begin
            hsadcSampleDataA[ctr*12+:12] <= $urandom_range(1000,0);
            hsadcSampleDataB[ctr*12+:12] <= $urandom_range(1000,0);
        end

		trigPhs = lastTrigPhs;
        for (ctr = 0; ctr < 16; ctr = ctr + 1) begin
			trigPhs = trigPhs + 2;
			trigPhs = (trigPhs >= laserTrigPeriod) ? 0 : trigPhs;
			hsSyncTrigger[ctr] <= trigPhs < (laserTrigPeriod/2);
		end
		lastTrigPhs <= trigPhs;
    end

    
    generate
        genvar ctri;
        for (ctri = 0; ctri < 32; ctri = ctri + 1) begin:chs
			assign chASamps[ctri] = hsadcSampleDataA[ctri*12+:12];
			assign chBSamps[ctri] = hsadcSampleDataB[ctri*12+:12];
		end
	endgenerate



	wire [HS_NUM_LOGICAL_CHANNELS*32-1:0] acqParamLogicalChannelSettings;
	wire [HS_NUM_LOGICAL_CHANNELS*12-1:0] acqParamLaserTriggerFilterWindowStart;
	wire [HS_NUM_LOGICAL_CHANNELS*12-1:0] acqParamLaserTriggerFilterWindowN;

	generate
		genvar lc_i;
		
		for (lc_i = 0; lc_i < HS_NUM_LOGICAL_CHANNELS; lc_i=lc_i+1) begin:gen_logical_channel_settings
			reg [31:0] acqParamLogicalChannelSettings_R = 0 | (1<<9); // laser gate on
			reg [11:0] acqParamLaserTriggerFilterWindowStart_R = lc_i ? 658 : 0;
			reg [11:0] acqParamLaserTriggerFilterWindowN_R = lc_i ? 3 : 3;
			
			assign acqParamLogicalChannelSettings[lc_i*32+:32] = acqParamLogicalChannelSettings_R;
			assign acqParamLaserTriggerFilterWindowStart[lc_i*12+:12] = acqParamLaserTriggerFilterWindowStart_R;
			assign acqParamLaserTriggerFilterWindowN[lc_i*12+:12] = acqParamLaserTriggerFilterWindowN_R;
		end
	endgenerate



    wire [`LOGICAL_CHANNEL_BUF_LSZ:0] logChans;
    wire signed [`LOGICAL_CHANNEL_LSZ:0] logicalChanDecode[HS_NUM_LOGICAL_CHANNELS-1:0];
    generate
		genvar lcd;
		
		for (lcd = 0; lcd < HS_NUM_LOGICAL_CHANNELS; lcd=lcd+1) begin:gen_logical_channel_unpack
			assign logicalChanDecode[lcd] = logChans[`LOGICAL_CHANNEL_WIDTH*lcd+:`LOGICAL_CHANNEL_WIDTH];
		end
	endgenerate

	wire dvo;

	reg [11:0] phaseShift = 0;
	reg ignorePhysical = 0;

	wire [(12*`HS_SAMPS_PER_TICK)-1:0] samplePhasePacked;

	SI_SamplePhase #(
		.SAMPLE_PHASE_BITS(12)
	) samplePhaseH (
		.hsadcDataClk(hsClk),
		.hsSyncTrigger(hsSyncTrigger),
		.hsSyncTrigPhaseShift(phaseShift),
		.hsSyncTrigIgnorePhysical(ignorePhysical),
		.laserClkPeriodSamples(laserTrigPeriod),
		.samplePhasePacked(samplePhasePacked)
	);

	SI_SignalConditionH #(
	   .HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
	   .SAMPLE_PHASE_BITS(12)
	) signalConditionH (
		.clk(hsClk),
		
		.sampleDataA(hsadcSampleDataA),
		.sampleDataB(hsadcSampleDataA),
		.syncTrigger(hsSyncTrigger),

		.dataOut(logChans),
		.dataOutRaw(),
		.dataOutValid(dvo),
		
		.channelsInvert(0),
		.channelOffsets(0),
		//.laserClkPeriodSamples(laserTrigPeriod),
		.logicalChannelSettings(acqParamLogicalChannelSettings),
		.laserTriggerFilterWindowStart(acqParamLaserTriggerFilterWindowStart),
		.laserTriggerFilterWindowN(acqParamLaserTriggerFilterWindowN),

		.samplePhasePacked(samplePhasePacked)
	);


	// output file with expected pixel values
	// generate phase lookup
	// SI_SignalConditionH applies one clock cycle of extra delay to the trigger. mimic this
	reg [11:0] prevp;
	reg [11:0] phsTest[31:0];
	reg [5:0] pt_iter;
	reg hsSyncTrigger_p;
	reg [15:0] hsSyncTriggerRE;
	always @(posedge hsClk) begin
		hsSyncTrigger_p <= hsSyncTrigger[15];

		hsSyncTriggerRE[0] = hsSyncTrigger[0] && ~hsSyncTrigger_p;
		for (pt_iter = 1; pt_iter < 16; pt_iter = pt_iter + 1)
			hsSyncTriggerRE[pt_iter] = hsSyncTrigger[pt_iter] && ~hsSyncTrigger[pt_iter-1];

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

		if (dvo) begin
			f = $fopen("actual_o.txt","a+");
			$fwrite(f,"%d\n",logicalChanDecode[0]);
			$fclose(f);
		end
	end
	
endmodule
