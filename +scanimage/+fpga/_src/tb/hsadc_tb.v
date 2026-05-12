//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQ_HSADC ();
	localparam CH_WIDTH = 12;
	
	// function that returns the minimum of two numbers
	function [63:0] min;
		input [63:0] a,b;
		min = (a<b)?a:b;
	endfunction

	// function that returns the ceiling of the log base 2.                      
	function integer clogb2 (input integer bit_depth); begin
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			bit_depth = bit_depth >> 1;
		end
	endfunction

	reg serialDataResetN = 0;
	reg [255:0] serialData = 0;
	reg serialDataValid = 0;
	
	reg  sampleClkRst = 1;
	
	reg coreClk = 1;
	always #2 coreClk = ~coreClk;
	
	reg [31:0] TTT = 0;
	always #4 TTT = TTT + 1;
	
	always @(posedge coreClk) begin
		if (TTT == 100) begin
			sampleClkRst = 0;
		end
		if (TTT == 200) begin
			serialDataResetN = 1;
			serialDataValid = 1;
		end
	end
	// sample data out
	wire dataClk;
	wire dataValid;
	wire [CH_WIDTH*32-1:0] dataA;
	wire [CH_WIDTH*32-1:0] dataB;
	wire [15:0] syncTrigger;
	

	// state machine operation mode
	//reg fsx4_mode = 1;
	//reg singleChannel_mode = 0;
	// This implementation will only allow fsx4 mode to reduce resource utilization and aid timing cloture
	localparam fsx4_mode = 1;
	localparam singleChannel_mode = 0;


	// PLL to generate sample clock and phase reference
	wire [15:0] sampleClkPllDrpDo;
	wire sampleClkPllDrpRdy;
	reg  [6:0] sampleClkPllDrpAddr = 0;
	reg  [15:0] sampleClkPllDrpDi = 0;
	wire sampleClkPllDrpWe;
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
		.DCLK(), // 1-bit input: DRP clock
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

	reg [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelA_lclBuf [LCL_BUF_LENGTH_SAMPS-1:0];
	reg [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelB_lclBuf [LCL_BUF_LENGTH_SAMPS-1:0];
	reg [LCL_BUF_LENGTH_SAMPS-1:0]    syncTrigReset_lclBuf = 0;

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
	
	// generation of sync trigger
	localparam PHASE_BITS = 6;
	localparam PHASE_LSZ = PHASE_BITS-1;
	reg  [PHASE_LSZ:0] syncTriggerPeriod = 20; // period/2
	reg  [PHASE_LSZ:0] syncTriggerLastPhs = 0;

	generate
		genvar phsIter;
		for (phsIter = 0; phsIter < 16; phsIter = phsIter + 1) begin:gen_sync_trg_phs
			assign syncTrigger[phsIter] = (syncTriggerLastPhs+1+phsIter) == syncTriggerPeriod;
		end
	endgenerate

	reg [5:0] ppi = 0;
	reg [PHASE_LSZ+1:0] phsCalc;
	always @(posedge dataClk) begin
		phsCalc = syncTriggerLastPhs;
		for (ppi = 0; ppi < 16; ppi = ppi + 1)
			phsCalc = syncTrigReset_lclBuf[lclBufReadPtr+2*ppi] ? 0 : phsCalc + 1;
		syncTriggerLastPhs <= phsCalc >= syncTriggerPeriod ? phsCalc-syncTriggerPeriod : phsCalc;
	end


	// Local sample buffer write logic
	reg  sampleClkPhaseRef_wc = 0;
	reg  sampleClkPhaseRefWrP = 0;
	wire sampleClkPhaseWrRE = sampleClkPhaseRef_wc && ~sampleClkPhaseRefWrP;
	wire [clogb2(LCL_BUF_LENGTH_SAMPS/8)-1:0] lclBufWriteStartingPhase = fsx4_mode ? 3 : (singleChannel_mode ? 3 : 4);
	
	reg [255:0] serialDataR = 0;

	wire [clogb2(LCL_BUF_LENGTH_SAMPS/8):0]   lclBufLengthWrites = fsx4_mode ? 16 : (singleChannel_mode ? 10 : 20);
	reg  [clogb2(LCL_BUF_LENGTH_SAMPS/8)-1:0] lclBufWritePhase = 0;

	wire [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWe_fsx4 = {10{1'b1}} << (10 * lclBufWritePhase);
	wire [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWe_dc = {8{1'b1}} << (8 * lclBufWritePhase);
	wire [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWe_sc = {16{1'b1}} << (16 * lclBufWritePhase);
	reg  [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWe = 0;

	wire [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWeF_fsx4 = 2'b11 << (10 * lclBufWritePhase);
	wire [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWeF_dc = 2'b11 << (8 * lclBufWritePhase);
	wire [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWeF_sc = 2'b11 << (16 * lclBufWritePhase);
	reg  [LCL_BUF_LENGTH_SAMPS-1:0] lclBufWeF = 0;

	wire [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelDataInA [LCL_BUF_LENGTH_SAMPS-1:0];
	wire [LCL_BUF_SAMP_WIDTH_BITS-1:0] channelDataInB [LCL_BUF_LENGTH_SAMPS-1:0];

	reg [clogb2(LCL_BUF_LENGTH_SAMPS)-1:0] wctr = 0;

	always @(posedge coreClk) begin
		for (wctr = 0; wctr < LCL_BUF_LENGTH_SAMPS; wctr = wctr + 1) begin
			if (lclBufWe[wctr]) begin
				channelA_lclBuf[wctr] <= channelDataInA[wctr];
				channelB_lclBuf[wctr] <= channelDataInB[wctr];
			end

			if (lclBufWeF[wctr])
				syncTrigReset_lclBuf[wctr] <= serialDataResetN && serialDataValid && ~lclBufValid;
			else if (lclBufWe[wctr])
				syncTrigReset_lclBuf[wctr] <= 0;
		end

		sampleClkPhaseRef_wc <= sampleClkPhaseRef;
		sampleClkPhaseRefWrP <= sampleClkPhaseRef_wc;

		if (sampleClkPhaseWrRE)
			lclBufWritePhase <= lclBufWriteStartingPhase;
		else if (lclBufWritePhase == (lclBufLengthWrites - 1))
			lclBufWritePhase <= 0;
		else
			lclBufWritePhase <= lclBufWritePhase + 1;
		
		lclBufValid <= serialDataResetN && serialDataValid;
		
		lclBufWe <= fsx4_mode ? lclBufWe_fsx4 : (singleChannel_mode ? lclBufWe_sc : lclBufWe_dc);
		lclBufWeF <= fsx4_mode ? lclBufWeF_fsx4 : (singleChannel_mode ? lclBufWeF_sc : lclBufWeF_dc);
		
		serialDataR <= serialData;
	end


endmodule
