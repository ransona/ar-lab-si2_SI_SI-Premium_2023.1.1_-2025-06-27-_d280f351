//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 100 ps

module vDAQ_HSADC_fullsim();

    parameter CH_WIDTH = 12;

    function [63:0] min;
		input [63:0] a,b;
		min = (a<b)?a:b;
	endfunction
	               
	function integer clogb2 (input integer bit_depth); begin
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			bit_depth = bit_depth >> 1;
		end
	endfunction

    reg coreClk = 1; // in fs x 4 = Fs/10, otherwise = Fs / 8
    reg gthRefClk = 1; // = Fs / 8
    wire dataClk;

	reg [15:0] samps[1:0][7:0];

	reg [15:0] sampctr = 0;
	initial begin
		for (sampctr = 0; sampctr < 8; sampctr = sampctr + 1) begin
			samps[0][sampctr] = sampctr*16;
			samps[1][sampctr] = 5*sampctr*16;
		end
	end


    reg [255:0] serialData = 0;
    reg serialDataResetN = 0;
    reg serialDataValid = 0;
    wire resetSm = 0;

	// test case 1
	// Fsx4 mode
	// Fs = 2 GHz
	// Core clk = Fs / 10 = 200 MHz (5ns)
	// GTH ref clk = Fs / 8 = 250 MHz (4ns)
	// data clk = Fs / 32 = 62.5 MHz (16ns)

    // state machine operation mode
	reg fsx4_mode = 1;
	reg singleChannel_mode = 0;

    always begin
		if (fsx4_mode)
			#2.5;
		else if (singleChannel_mode)
			#4;
		else
			#2;
		
        coreClk <= ~coreClk;
    end

    always begin
        #2
        gthRefClk <= ~gthRefClk;
    end

    always @(posedge coreClk) begin
		for (sampctr = 0; sampctr < 8; sampctr = sampctr + 1) begin
			samps[0][sampctr] = samps[0][sampctr]+8*16;
			samps[1][sampctr] = samps[1][sampctr]+24*16;

		end
		serialData <= {samps[1][7][ 7:0], samps[1][5][ 7:0], samps[1][3][ 7:0], samps[1][1][ 7:0],
						samps[1][7][15:8], samps[1][5][15:8], samps[1][3][15:8], samps[1][1][15:8],
						samps[1][6][ 7:0], samps[1][4][ 7:0], samps[1][2][ 7:0], samps[1][0][ 7:0],
						samps[1][6][15:8], samps[1][4][15:8], samps[1][2][15:8], samps[1][0][15:8],
						samps[0][7][ 7:0], samps[0][5][ 7:0], samps[0][3][ 7:0], samps[0][1][ 7:0],
						samps[0][7][15:8], samps[0][5][15:8], samps[0][3][15:8], samps[0][1][15:8],
						samps[0][6][ 7:0], samps[0][4][ 7:0], samps[0][2][ 7:0], samps[0][0][ 7:0],
						samps[0][6][15:8], samps[0][4][15:8], samps[0][2][15:8], samps[0][0][15:8]};
    end

    initial begin
        #40
        serialDataResetN <= 1;
        serialDataValid <= 1;
    end


    // outputs
    wire [CH_WIDTH*32-1:0] dataA;
	wire [CH_WIDTH*32-1:0] dataB;
	wire dataValid;

	
    wire [CH_WIDTH-1:0] dataA_parsed [31:0];
	wire [CH_WIDTH-1:0] dataB_parsed [31:0];
	generate
		genvar octr;

		for (octr = 0; octr < 32; octr = octr + 1) begin:gen_parse
			assign dataA_parsed[octr] = dataA[octr*CH_WIDTH+:CH_WIDTH];
			assign dataB_parsed[octr] = dataB[octr*CH_WIDTH+:CH_WIDTH];
		end
	endgenerate

    
    



		
	
	// PLL to generate sample clock and phase reference
	wire [15:0] sampleClkPllDrpDo;
	wire sampleClkPllDrpRdy;
	reg  [6:0] sampleClkPllDrpAddr = 0;
	reg  [15:0] sampleClkPllDrpDi = 0;
	wire sampleClkPllDrpWe;
	reg  sampleClkRst = 0;
	wire sampleClkPhaseRef;
	wire sampleClkPllFbClk;
	wire sampleClkPllLocked;

	PLLE3_ADV #(
		.CLKFBOUT_MULT(5), // Multiply value for all CLKOUT, (1-19)
		.CLKFBOUT_PHASE(0.0), // Phase offset in degrees of CLKFB, (-360.000-360.000)
		.CLKIN_PERIOD(3.703), // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
		// CLKOUT0 Attributes: Divide, Phase and Duty Cycle for the CLKOUT0 output
		.CLKOUT0_DIVIDE(8), // Divide amount for CLKOUT0 (1-128)
		.CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999)
		.CLKOUT0_PHASE(0), // Phase offset for CLKOUT0 (-360.000-360.000)
		// CLKOUT1 Attributes: Divide, Phase and Duty Cycle for the CLKOUT1 output
		.CLKOUT1_DIVIDE(80), // Divide amount for CLKOUT1 (1-128)
		.CLKOUT1_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT1 (0.001-0.999)
		.CLKOUT1_PHASE(22.5), // Phase offset for CLKOUT1 (-360.000-360.000)
		.DIVCLK_DIVIDE(2) // Master division value, (1-15)
	) sampleClkPll (
		// Clock Outputs outputs: User configurable clock outputs
		.CLKOUT0(dataClk), // 1-bit output: General Clock output
		.CLKOUT1(sampleClkPhaseRef), // 1-bit output: General Clock output
		// DRP Ports outputs: Dynamic reconfiguration ports
		.DO(sampleClkPllDrpDo), // 16-bit output: DRP data
		.DRDY(sampleClkPllDrpRdy), // 1-bit output: DRP ready
		// Feedback Clocks outputs: Clock feedback ports
		.CLKFBOUT(sampleClkPllFbClk), // 1-bit output: Feedback clock
		.LOCKED(sampleClkPllLocked), // 1-bit output: LOCK
		.CLKIN(coreClk), // 1-bit input: Input clock
		// Control Ports inputs: PLL control ports
		.CLKOUTPHYEN(0), // 1-bit input: CLKOUTPHY enable
		.PWRDWN(0), // 1-bit input: Power-down
		.RST(sampleClkRst), // 1-bit input: Reset
		// DRP Ports inputs: Dynamic reconfiguration ports
		.DADDR(sampleClkPllDrpAddr), // 7-bit input: DRP address
		.DCLK(axiClk), // 1-bit input: DRP clock
		.DEN(1), // 1-bit input: DRP enable
		.DI(sampleClkPllDrpDi), // 16-bit input: DRP data
		.DWE(sampleClkPllDrpWe), // 1-bit input: DRP write enable
		// Feedback Clocks inputs: Clock feedback ports
		.CLKFBIN(sampleClkPllFbClk) // 1-bit input: Feedback clock
	);

	

	// Local sample buffer
	localparam OUT_SAMPS_PER_CLK = 32;
	localparam LCL_BUF_SAMP_WIDTH_BITS = min(14,CH_WIDTH);
	localparam LCL_BUF_LENGTH_READS = 5;
	localparam LCL_BUF_LENGTH_SAMPS = OUT_SAMPS_PER_CLK * LCL_BUF_LENGTH_READS;
	// this creates a local buffer 160 samples long; evenly divisible by 32 (read qty),
	// 16 (single channel write qty), 8 (dual channel write qty), and 10 (Fs x 4 write qty)

	reg  [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelA_lclBuf [LCL_BUF_LENGTH_SAMPS-1:0];
	reg  [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelB_lclBuf [LCL_BUF_LENGTH_SAMPS-1:0];

	// Local sample buffer read logic
	reg lclBufValid = 0;
	(* ASYNC_REG = "TRUE" *) reg [1:0] lclBufValidCC = 0;
	(* ASYNC_REG = "TRUE" *) reg [1:0] lockedCC = 0;
	reg [1:0] dataOutValidD = 0;
	assign dataValid = dataOutValidD[1];
	
    reg [CH_WIDTH*32-1:0] dataA_Out = 0;
	reg [CH_WIDTH*32-1:0] dataB_Out = 0;
	assign dataA = dataA_Out;
	assign dataB = dataB_Out;

	reg  [clogb2(LCL_BUF_LENGTH_READS)-1:0] lclBufReadPhase = 0;
	wire [clogb2(LCL_BUF_LENGTH_SAMPS)-1:0] lclBufReadPtr = lclBufReadPhase * OUT_SAMPS_PER_CLK;
	wire rdOvrRg = lclBufReadPhase >= LCL_BUF_LENGTH_READS;

	reg  sampleClkPhaseRef_rc = 0;
	reg  sampleClkPhaseRefRdP = 0;
	wire sampleClkPhaseRdRE = sampleClkPhaseRef_rc && ~sampleClkPhaseRefRdP;

	always @(posedge dataClk) begin
		lclBufValidCC <= {lclBufValidCC[0], lclBufValid};
		lockedCC <= {lockedCC[0], sampleClkPllLocked};

		sampleClkPhaseRef_rc <= sampleClkPhaseRef;
		sampleClkPhaseRefRdP <= sampleClkPhaseRef_rc;

		if (sampleClkPhaseRdRE)
			lclBufReadPhase <= 0;
		else if (lclBufReadPhase == (LCL_BUF_LENGTH_READS - 1))
			lclBufReadPhase <= 0;
		else
			lclBufReadPhase <= lclBufReadPhase + 1;

		if (sampleClkPhaseRdRE)
			dataOutValidD <= {dataOutValidD[0], lclBufValidCC[1] && lockedCC[1]};
	end

	localparam BUFFER_OUT_EXTEND = CH_WIDTH-LCL_BUF_SAMP_WIDTH_BITS;
	reg [clogb2(LCL_BUF_LENGTH_SAMPS):0] rctr = 0;
	always @(*)
		for (rctr = 0; rctr < OUT_SAMPS_PER_CLK; rctr = rctr + 1) begin:gen_read
			dataA_Out[rctr*CH_WIDTH+:CH_WIDTH] = rdOvrRg ? {CH_WIDTH{1'b0}} : (channelA_lclBuf[lclBufReadPtr+rctr] << BUFFER_OUT_EXTEND);
			dataB_Out[rctr*CH_WIDTH+:CH_WIDTH] = rdOvrRg ? {CH_WIDTH{1'b0}} : (channelB_lclBuf[lclBufReadPtr+rctr] << BUFFER_OUT_EXTEND);
		end


	// Local sample buffer write logic
	reg  sampleClkPhaseRef_wc = 0;
	reg  sampleClkPhaseRefWrP = 0;
	wire sampleClkPhaseWrRE = sampleClkPhaseRef_wc && ~sampleClkPhaseRefWrP;
	wire [clogb2(LCL_BUF_LENGTH_SAMPS/8)-1:0] lclBufWriteStartingPhase = fsx4_mode ? 3 : (singleChannel_mode ? 3 : 4);

	reg [3:0] resetCtr = 0;
	
	reg [255:0] serialDataR = 0;

	wire [clogb2(LCL_BUF_LENGTH_SAMPS/8):0]   lclBufLengthWrites = fsx4_mode ? 16 : (singleChannel_mode ? 10 : 20);
	reg  [clogb2(LCL_BUF_LENGTH_SAMPS/8)-1:0] lclBufWritePhase = 0;

	wire [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWe_fsx4 = {10{1'b1}} << (10 * lclBufWritePhase);
	wire [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWe_dc = {8{1'b1}} << (8 * lclBufWritePhase);
	wire [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWe_sc = {16{1'b1}} << (16 * lclBufWritePhase);
	reg  [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWe = 0;

	wire [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelDataInA [LCL_BUF_LENGTH_SAMPS-1:0];
	wire [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelDataInB [LCL_BUF_LENGTH_SAMPS-1:0];

	reg [clogb2(LCL_BUF_LENGTH_SAMPS)-1:0] wctr = 0;

	always @(posedge coreClk) begin
		for (wctr = 0; wctr < LCL_BUF_LENGTH_SAMPS; wctr = wctr + 1) begin
			if (lclBufWe[wctr]) begin
				channelA_lclBuf[wctr] <= channelDataInA[wctr];
				channelB_lclBuf[wctr] <= channelDataInB[wctr];
			end
		end

		sampleClkPhaseRef_wc <= sampleClkPhaseRef;
		sampleClkPhaseRefWrP <= sampleClkPhaseRef_wc;

		if (sampleClkPhaseWrRE)
			lclBufWritePhase <= lclBufWriteStartingPhase;
		else if (lclBufWritePhase == (lclBufLengthWrites - 1))
			lclBufWritePhase <= 0;
		else
			lclBufWritePhase <= lclBufWritePhase + 1;

		if (~serialDataResetN || ~serialDataValid || resetSm)
			resetCtr <= 15;
		else if (resetCtr)
			resetCtr <= resetCtr - 1;
		sampleClkRst <= resetCtr > 0;
		
		lclBufValid <= serialDataResetN && serialDataValid;
		
		lclBufWe <= fsx4_mode ? lclBufWe_fsx4 : (singleChannel_mode ? lclBufWe_sc : lclBufWe_dc);
		
		serialDataR <= serialData;
	end


	// Serial data decode logic
	wire [31:0]  laneData[7:0];
	wire [7:0]   octetData[7:0][1:0][1:0]; // octetData[lane][frame][octet][bit]
	wire [127:0] frameData[1:0];
	
	wire [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelDataInA_Fsx4 [9:0];
	wire [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelDataInB_Fsx4 [9:0];
	
	wire [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelDataInA_Fbw [7:0];
	wire [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelDataInB_Fbw [7:0];

	wire [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelDataIn_SC [15:0];

	localparam FSX4_BUFFER_IN_EXTEND = LCL_BUF_SAMP_WIDTH_BITS-12;

	generate
		genvar laneIter;
		genvar frameIter;
		genvar octetIter;
		genvar fullFrameIter;
		genvar sampleIter;
		genvar sampleIterE;

		for (laneIter = 0; laneIter < 8; laneIter = laneIter + 1) begin:gen_lanes
			assign laneData[laneIter] = serialDataR[laneIter*32+:32];

			for (frameIter = 0; frameIter < 2; frameIter = frameIter + 1) begin:gen_frames
				for (octetIter = 0; octetIter < 2; octetIter = octetIter + 1) begin:gen_octets
					assign octetData[laneIter][frameIter][octetIter] = laneData[laneIter][(frameIter*16 + octetIter*8)+:8];
				end
			end
		end

		for (fullFrameIter = 0; fullFrameIter < 2; fullFrameIter = fullFrameIter + 1) begin:gen_full_frames
			assign frameData[fullFrameIter] = {
				octetData[0][fullFrameIter][0], octetData[0][fullFrameIter][1],
				octetData[1][fullFrameIter][0], octetData[1][fullFrameIter][1],
				octetData[2][fullFrameIter][0], octetData[2][fullFrameIter][1],
				octetData[3][fullFrameIter][0], octetData[3][fullFrameIter][1],
				octetData[4][fullFrameIter][0], octetData[4][fullFrameIter][1],
				octetData[5][fullFrameIter][0], octetData[5][fullFrameIter][1],
				octetData[6][fullFrameIter][0], octetData[6][fullFrameIter][1],
				octetData[7][fullFrameIter][0], octetData[7][fullFrameIter][1]
			};
		end

		for (sampleIter = 0; sampleIter < 10; sampleIter = sampleIter + 1) begin:gen_samples

			wire [3:0] frmSamp = (sampleIter < 4) ? sampleIter : sampleIter - 4;
			wire [3:0] frmSamp4 = (sampleIter < 5) ? sampleIter : sampleIter - 5;

			// Fs x 4 mode
			assign channelDataInA_Fsx4[sampleIter] = frameData[sampleIter>4][(127-frmSamp4*12)-:12] << FSX4_BUFFER_IN_EXTEND;
			assign channelDataInB_Fsx4[sampleIter] = frameData[sampleIter>4][( 63-frmSamp4*12)-:12] << FSX4_BUFFER_IN_EXTEND;

			// FBW dual or single channel mode
			if (sampleIter < 8) begin
				assign channelDataInA_Fbw[sampleIter] = frameData[sampleIter>3][((8-frmSamp)*16-1)-:LCL_BUF_SAMP_WIDTH_BITS];
				assign channelDataInB_Fbw[sampleIter] = frameData[sampleIter>3][((4-frmSamp)*16-1)-:LCL_BUF_SAMP_WIDTH_BITS];
			end

			if (sampleIter < 4) begin
				assign channelDataIn_SC[sampleIter] = channelDataInA_Fbw[sampleIter];
				assign channelDataIn_SC[sampleIter+4] = channelDataInB_Fbw[sampleIter];
			end else if (sampleIter < 8) begin
				assign channelDataIn_SC[sampleIter+4] = channelDataInA_Fbw[sampleIter];
				assign channelDataIn_SC[sampleIter+8] = channelDataInB_Fbw[sampleIter];
			end
		end

		// Mux/extend
		for (sampleIterE = 0; sampleIterE < LCL_BUF_LENGTH_SAMPS; sampleIterE = sampleIterE + 1) begin:gen_mux
			assign channelDataInA[sampleIterE] = fsx4_mode ? channelDataInA_Fsx4[sampleIterE % 10] : (singleChannel_mode ? channelDataIn_SC[sampleIterE % 16] : channelDataInA_Fbw[sampleIterE % 8]);
			assign channelDataInB[sampleIterE] = fsx4_mode ? channelDataInB_Fsx4[sampleIterE % 10] : (singleChannel_mode ? channelDataIn_SC[sampleIterE % 16] : channelDataInB_Fbw[sampleIterE % 8]);
		end
		
	endgenerate


wire [clogb2(LCL_BUF_LENGTH_SAMPS):0] lclBufWritePtr = lclBufWritePhase * (fsx4_mode ? 10 : (singleChannel_mode ? 16 : 8));
wire [clogb2(LCL_BUF_LENGTH_SAMPS):0] unread = (lclBufWritePtr > lclBufReadPtr) ? lclBufWritePtr - lclBufReadPtr : LCL_BUF_LENGTH_SAMPS - lclBufReadPtr + lclBufWritePtr;
	


endmodule

