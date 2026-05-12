//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQ_HSADC #(
	parameter CH_WIDTH = 12,
	// do not change
	parameter SAXIL_CFG_DATA_WIDTH = 32,
	parameter SAXIL_CFG_ADDR_WIDTH = 13
)(
	input wire axiClk,
	input wire axiResetN,
	input wire thermal_pd,
	input wire coreClk,
	
	// SAXIL control/config bus
	input  wire [SAXIL_CFG_ADDR_WIDTH-1:0] SAXIL_CFG_AWADDR,
	input  wire [2:0] SAXIL_CFG_AWPROT,
	input  wire SAXIL_CFG_AWVALID,
	output wire SAXIL_CFG_AWREADY,
	input  wire [SAXIL_CFG_DATA_WIDTH-1:0] SAXIL_CFG_WDATA,
	input  wire [(SAXIL_CFG_DATA_WIDTH/8)-1:0] SAXIL_CFG_WSTRB,
	input  wire SAXIL_CFG_WVALID,
	output wire SAXIL_CFG_WREADY,
	output wire [1:0] SAXIL_CFG_BRESP,
	output wire SAXIL_CFG_BVALID,
	input  wire SAXIL_CFG_BREADY,
	input  wire [SAXIL_CFG_ADDR_WIDTH-1:0] SAXIL_CFG_ARADDR,
	input  wire [2:0] SAXIL_CFG_ARPROT,
	input  wire SAXIL_CFG_ARVALID,
	output wire SAXIL_CFG_ARREADY,
	output wire [SAXIL_CFG_DATA_WIDTH-1:0] SAXIL_CFG_RDATA,
	output wire [1:0] SAXIL_CFG_RRESP,
	output wire SAXIL_CFG_RVALID,
	input  wire SAXIL_CFG_RREADY,
	
	// SPI bus to clock device
	output wire clckg_sclk,
	output wire clckg_csb,
	output wire clckg_mosi,
	input  wire clckg_miso,
	output wire clckg_sync,
	
	// SPI bus and gpio to ADC
	output wire adc_sclk,
	output wire adc_csb,
	inout  wire adc_sdio,
	output wire adc_pdwn,
	inout  wire [1:0] adc_gpio_a,
	inout  wire [1:0] adc_gpio_b,
	
	// JESD204B to ADC
	input  wire [7:0] adc_rx_p,
	input  wire [7:0] adc_rx_n,
	input  wire adc_refclk_p,
	input  wire adc_refclk_n,
	output wire adc_syncb_p,
	output wire adc_syncb_n,
	input  wire sysref_p,
	input  wire sysref_n,

	// sample data out
	output wire dataClk,
	output wire dataValid,
	output wire [CH_WIDTH*32-1:0] dataA,
	output wire [CH_WIDTH*32-1:0] dataB,
	output wire [15:0] syncTrigger
);
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



	// ADC JESD204B IO
	wire adc_syncb;
	IOBUFDS adc_sync_buf(.I(adc_syncb), .IO(adc_syncb_p), .IOB(adc_syncb_n), .O(), .T(0));

	wire sysref;
	IOBUFDS sysrefBuf(.IO(sysref_p), .IOB(sysref_n), .O(sysref), .I(0), .T(1));
	


	// JESD204 IP signals
	reg  jesd204_reset = 1;
	reg  jesd204phy_sys_reset = 1;
	wire jesd204_gt_powergood;
	wire jesd204_reset_done;

	wire serialDataResetN;
	wire [255:0] serialData;
	wire serialDataValid;
	wire [3:0] rx_start_of_frame;
	wire [3:0] rx_end_of_frame;
	wire [3:0] rx_start_of_multiframe;
	wire [3:0] rx_end_of_multiframe;
	wire [31:0] rx_frame_error;

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
	reg  sampleClkRst = 1;
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
	localparam PHASE_BITS = 11;
	localparam PHASE_LSZ = PHASE_BITS-1;
	reg  [PHASE_LSZ:0] syncTriggerPeriod = 16; // period/2
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
	


	// Signal caching for host debug
	wire latchStats;
//	reg  remap = 0;

	reg serialDataResetN_cc = 0;
//	reg [255:0] serialData_cc = 0;
	reg serialDataValid_cc = 0;
	reg [3:0] rx_start_of_frame_cc = 0;
	reg [3:0] rx_end_of_frame_cc = 0;
	reg [3:0] rx_start_of_multiframe_cc = 0;
	reg [3:0] rx_end_of_multiframe_cc = 0;
	reg [31:0] rx_frame_error_cc = 0;

	always @(posedge coreClk) begin
		if (latchStats) begin
			serialDataResetN_cc <= serialDataResetN;
//			serialData_cc <= remap ? {frameData[1], frameData[0]} : serialDataR;
			serialDataValid_cc <= serialDataValid;
			rx_start_of_frame_cc <= rx_start_of_frame;
			rx_end_of_frame_cc <= rx_end_of_frame;
			rx_start_of_multiframe_cc <= rx_start_of_multiframe;
			rx_end_of_multiframe_cc <= rx_end_of_multiframe;
			rx_frame_error_cc <= rx_frame_error;
		end
	end



	// ADC GPIO
	(* IOB = "TRUE" *) reg adc_pdwn_reg = 1;
	reg adc_pdwn_reg_cpy = 1;
	IOBUF pdn_buf(.I(adc_pdwn_reg), .IO(adc_pdwn), .O(), .T(0));

	wire [1:0] adc_gpio_a_i;
	wire [1:0] adc_gpio_b_i;
	reg [1:0] adc_gpio_a_t = 2'b11;
	reg [1:0] adc_gpio_b_t = 2'b11;
	reg [1:0] adc_gpio_a_o = 2'b00;
	reg [1:0] adc_gpio_b_o = 2'b00;
	IOBUF gpio_a_buf0(.I(adc_gpio_a_o[0]), .IO(adc_gpio_a[0]), .O(adc_gpio_a_i[0]), .T(adc_gpio_a_t[0]));
	IOBUF gpio_a_buf1(.I(adc_gpio_a_o[1]), .IO(adc_gpio_a[1]), .O(adc_gpio_a_i[1]), .T(adc_gpio_a_t[1]));
	IOBUF gpio_b_buf0(.I(adc_gpio_b_o[0]), .IO(adc_gpio_b[0]), .O(adc_gpio_b_i[0]), .T(adc_gpio_b_t[0]));
	IOBUF gpio_b_buf1(.I(adc_gpio_b_o[1]), .IO(adc_gpio_b[1]), .O(adc_gpio_b_i[1]), .T(adc_gpio_b_t[1]));


	// ADC SPI IO
	(* IOB = "TRUE" *) reg spiClkG = 0;
	reg [1:0] spiClkCtr = 0;
	wire spiClkRE = spiClkCtr == 1;
	wire spiClkFE = spiClkCtr == 2;
	IOBUF spiClk_buf(.I(spiClkG), .IO(adc_sclk), .O(), .T(0));

	(* IOB = "TRUE" *) reg adc_csb_reg = 1;
	IOBUF adc_csb_buf(.I(adc_csb_reg), .IO(adc_csb), .O(), .T(0));
	
	(* IOB = "TRUE" *) reg adc_sdo = 0;
	wire adc_sdi;
	reg  adc_sdio_t = 1;
	IOBUF adc_sdio_buf(.I(adc_sdo), .IO(adc_sdio), .O(adc_sdi), .T(adc_sdio_t));
	(* IOB = "TRUE" *) reg sdi_reg = 0;

	// ADC SPI state machine
	reg adcSpiStartReq = 0;
	reg adcSpiReqR = 0;
	reg [1:0]  adcSpiReqNumBytes = 0;
	reg [14:0] adcSpiReqAddr = 0;
	reg [31:0] adcSpiWriteData = 0;
	reg [31:0] adcSpiReadData = 0;

	reg [3:0] bitCtr = 0;
	reg addrMode = 0;
	reg [1:0] byteCtr = 0;
	reg adcSpiOpInProgress = 0;

	reg [3:0] readBitCtr = 0;
	reg [1:0] readByteCtr = 0;
	
	always @(posedge axiClk) begin
		spiClkCtr <= spiClkCtr + 1;
		spiClkG <= (spiClkCtr < 2) && adcSpiOpInProgress;

		// spi input sm
		if (~axiResetN)
			readBitCtr <= 0;
		else if (spiClkRE && ~addrMode && (bitCtr == 7) && adcSpiReqR) begin
			readBitCtr <= 8;
			readByteCtr <= byteCtr;
		end else if (spiClkRE && readBitCtr)
			readBitCtr <= readBitCtr - 1;
		
		if (spiClkRE)
			sdi_reg <= adc_sdi;

		if (spiClkRE && readBitCtr)
			adcSpiReadData[readByteCtr*8 + readBitCtr - 1] <= sdi_reg;

		
		// spi output sm
		if (~axiResetN) begin
			adc_csb_reg <= 1;
			adc_sdio_t <= 1;
			adc_sdo <= 0;
			bitCtr <= 0;
			adcSpiOpInProgress <= 0;
		end else if (spiClkFE) begin
			if (bitCtr) begin
				if (bitCtr == 1) begin
					if (addrMode) begin
						addrMode <= 0;
						bitCtr <= 8;
					end else if (byteCtr < adcSpiReqNumBytes) begin
						byteCtr <= byteCtr + 1;
						bitCtr <= 8;
					end else
						bitCtr <= 0;
				end else begin
					bitCtr <= bitCtr - 1;
				end

				adc_sdio_t <= ~addrMode && adcSpiReqR;

				if (addrMode)
					adc_sdo <= adcSpiReqAddr[bitCtr-1];
				else
					adc_sdo <= adcSpiWriteData[byteCtr*8 + bitCtr - 1];
			end else if (adcSpiStartReq) begin
				adc_csb_reg <= 0;
				adc_sdio_t <= 0;
				adc_sdo <= adcSpiReqR;
				addrMode <= 1;
				bitCtr <= 15;
				byteCtr <= 0;
				adcSpiOpInProgress <= 1;
			end else begin
				adc_csb_reg <= 1;
				adc_sdio_t <= 1;
				adcSpiOpInProgress <= 0;
			end
		end
	end


	// clock rate meas
	wire [19:0] dataClkPeriod;
	CLK_RATE_MEASi #(.MEAS_COUNTER_WIDTH(16),.RESULT_COUNTER_WIDTH(20)) dataClkRateMeas (
		.measClk(dataClk), .resultClk(axiClk), .measClkPeriod(dataClkPeriod)
	);

	
	// axi config interfaces
	wire [11:0] jesdcore_saxi_awaddr;
	wire jesdcore_saxi_awvalid;
	wire jesdcore_saxi_awready;
	wire [31:0] jesdcore_saxi_wdata;
	wire [3:0] jesdcore_saxi_wstrb;
	wire jesdcore_saxi_wvalid;
	wire jesdcore_saxi_wready;
	wire [1:0] jesdcore_saxi_bresp;
	wire jesdcore_saxi_bvalid;
	wire jesdcore_saxi_bready;
	wire [11:0] jesdcore_saxi_araddr;
	wire jesdcore_saxi_arvalid;
	wire jesdcore_saxi_arready;
	wire [31:0] jesdcore_saxi_rdata;
	wire [1:0] jesdcore_saxi_rresp;
	wire jesdcore_saxi_rvalid;
	wire jesdcore_saxi_rready;

	wire [11:0] jesdphy_saxi_awaddr;
	wire jesdphy_saxi_awvalid;
	wire jesdphy_saxi_awready;
	wire [31:0] jesdphy_saxi_wdata;
	wire jesdphy_saxi_wvalid;
	wire jesdphy_saxi_wready;
	wire [1:0] jesdphy_saxi_bresp;
	wire jesdphy_saxi_bvalid;
	wire jesdphy_saxi_bready;
	wire [11:0] jesdphy_saxi_araddr;
	wire jesdphy_saxi_arvalid;
	wire jesdphy_saxi_arready;
	wire [31:0] jesdphy_saxi_rdata;
	wire [1:0] jesdphy_saxi_rresp;
	wire jesdphy_saxi_rvalid;
	wire jesdphy_saxi_rready;

	wire [SAXIL_CFG_ADDR_WIDTH-1:0] cfgReadAddress;
	reg  [SAXIL_CFG_DATA_WIDTH-1:0] cfgReadData;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] cfgActiveWriteAddress;
	wire [SAXIL_CFG_DATA_WIDTH-1:0] cfgWriteData;

	wire [SAXIL_CFG_ADDR_WIDTH-1:0] cc_cfgReadAddress;
	wire [SAXIL_CFG_DATA_WIDTH-1:0] cc_cfgReadData;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] cc_cfgActiveWriteAddress;
	
	OSCCi latchStats_cc(.srcV(cfgActiveWriteAddress == 64), .srcClk(axiClk), .dstV(latchStats), .dstClk(coreClk));

	wire common0_qpll0_locked;
	wire common0_qpll1_locked;
	wire common1_qpll0_locked;
	wire common1_qpll1_locked;

	assign sampleClkPllDrpWe = cfgActiveWriteAddress == 60;

	always @(posedge axiClk) begin
		if (~axiResetN) begin
		end else begin
			case (cfgActiveWriteAddress)
				8: begin
					adcSpiReqAddr <= cfgWriteData;
					adcSpiReqR <= cfgWriteData[15];
					adcSpiReqNumBytes <= cfgWriteData[17:16];
				end

				12: adcSpiWriteData <= cfgWriteData;

			//	16: adcSpiReadData

				20: syncTriggerPeriod <= cfgWriteData;

			//	24:  <= cfgWriteData;

				28: {jesd204_reset, jesd204phy_sys_reset} <= cfgWriteData;

				32: sampleClkRst <= cfgWriteData;

			//  This implementation will only allow fsx4 mode to reduce resource utilization and aid timing cloture
			//	36: fsx4_mode <= cfgWriteData;
			//	40: singleChannel_mode <= cfgWriteData;

				44: {adc_pdwn_reg, adc_pdwn_reg_cpy} <= {2{cfgWriteData[0]}};

			//	48: {adc_gpio_b_i, adc_gpio_a_i}

				52: {adc_gpio_b_t, adc_gpio_a_t} <= cfgWriteData;

				56: {adc_gpio_b_o, adc_gpio_a_o} <= cfgWriteData;

			//	60: wr pll drp

				64: begin
					sampleClkPllDrpAddr <= cfgWriteData;
					sampleClkPllDrpDi <= cfgWriteData[31:16];
				end

			//	60: remap <= cfgWriteData;
			//	64: latchStats
			//  64-92: serial data
			//	96: frame info;
			//	100: frame error
			//	104: QPLL lock status

			endcase

			if (cfgActiveWriteAddress == 8)
				adcSpiStartReq <= 1;
			else if (adcSpiOpInProgress)
				adcSpiStartReq <= 0;
		end

		if ((cfgReadAddress >= 64) && (cfgReadAddress < 96))
			cfgReadData <= -3; //serialData_cc[(cfgReadAddress-64)*8+:32];
		else case (cfgReadAddress)
			0: cfgReadData <= 32'hADC2_ADCE;

			4: cfgReadData <= dataClkPeriod;
		
		//	8: axi cfg req

			12: cfgReadData <= adcSpiWriteData;

			16: cfgReadData <= adcSpiReadData;

			20: cfgReadData <= syncTriggerPeriod;

		//	24: cfgReadData <= ;

			28: cfgReadData <= {jesd204_reset, jesd204phy_sys_reset};

			32: cfgReadData <= sampleClkRst;

			36: cfgReadData <= fsx4_mode;

			40: cfgReadData <= singleChannel_mode;

			44: cfgReadData <= adc_pdwn_reg_cpy;

			48: cfgReadData <= {adc_gpio_b_i, adc_gpio_a_i};

			52: cfgReadData <= {adc_gpio_b_t, adc_gpio_a_t};

			56: cfgReadData <= {adc_gpio_b_o, adc_gpio_a_o};

			60: cfgReadData <= {sampleClkPllDrpDo, 14'h0000, sampleClkPllDrpRdy, sampleClkPllLocked};

			64: cfgReadData <= {sampleClkPllDrpDi, 9'h000, sampleClkPllDrpAddr};

		
		//	60: cfgReadData <= remap;
		//	64: latchStats
		//  64-92: serial data
			96: cfgReadData <= {serialDataValid_cc, serialDataResetN_cc, rx_end_of_multiframe_cc, rx_start_of_multiframe_cc, rx_end_of_frame_cc, rx_start_of_frame_cc};
			100: cfgReadData <= rx_frame_error_cc;
			104: cfgReadData <= {common1_qpll1_locked, common1_qpll0_locked, common0_qpll1_locked, common0_qpll0_locked};
			
			default: cfgReadData <= 32'h1331_1375;
		endcase
	end


	// HS clock cfg
	HSADC_CLK_CFG #(
		.RAO(1),		// Enable reference aligned output
		.BD(7),			// B divider = 96
		.RD(2),			// R divider = 2
		.ND(40),		// N divider = 40
		.PD(0),			// P  = 2
	
		// NC
		.MUTE0(1),
		.SYNCEN0(1),
		.MD0(0),		// 1x

		// default settings:
		// 125 MHz input
		// 2500 MHz sample rate
		// 12500 MHz lante rate
		// 312.5 MHz ref clk rate (sample rate / 8)
		// 156.25 MHz sysref
	
		// ADC sample clock (2500 MHz)
		.MUTE1(0),
		.SYNCEN1(1),
		.MD1(0),		// 1x
	
		// ADC SYSREF (156.25 MHz)
		.MUTE2(0),
		.SYNCEN2(1),
		.MD2(5),		// 16x
	
		// GTH refclk (312.5 MHz)
		.MUTE3(0),
		.SYNCEN3(1),
		.MD3(3),		// 8x
	
		// FPGA SYSREF (156.25 MHz)
		.MUTE4(0),
		.SYNCEN4(1),
		.MD4(5)			// 16x
	) CLK_CFG (
		.axiClk(axiClk),
		.axiResetN(axiResetN),

		// SAXIL control/config bus
		.cfgReadAddress(cc_cfgReadAddress),
		.cfgReadData(cc_cfgReadData),
		.cfgActiveWriteAddress(cc_cfgActiveWriteAddress),
		.cfgWriteData(cfgWriteData),

		// SPI bus to device
		.spiClk(clckg_sclk),
		.cs(clckg_csb),
		.sdo(clckg_mosi),
		.sdi(clckg_miso),
		.sync(clckg_sync)
	);


	// Inst SAXIL_CFG
	SAXIL #(
		.DATA_WIDTH(SAXIL_CFG_DATA_WIDTH),
		.ADDR_WIDTH(SAXIL_CFG_ADDR_WIDTH),

		.NUM_RTL_MASTERS(2),
		.NUM_AXI_MASTERS(2),

		.RTL_MASTER_1_BASE_ADDR(0),
		.RTL_MASTER_1_SIZE(1024),

		.RTL_MASTER_2_BASE_ADDR(1024),
		.RTL_MASTER_2_SIZE(1024),

		.AXI_MASTER_1_BASE_ADDR(2048),
		.AXI_MASTER_1_SIZE(2048),

		.AXI_MASTER_2_BASE_ADDR(4096),
		.AXI_MASTER_2_SIZE(4096)
	) SAXIL_CFG_Inst (
		.ACLK(axiClk),
		.ARESETN(axiResetN),

		.SAXIL_AWADDR(SAXIL_CFG_AWADDR),
		.SAXIL_AWPROT(SAXIL_CFG_AWPROT),
		.SAXIL_AWVALID(SAXIL_CFG_AWVALID),
		.SAXIL_AWREADY(SAXIL_CFG_AWREADY),
		.SAXIL_WDATA(SAXIL_CFG_WDATA),  
		.SAXIL_WSTRB(SAXIL_CFG_WSTRB),
		.SAXIL_WVALID(SAXIL_CFG_WVALID),
		.SAXIL_WREADY(SAXIL_CFG_WREADY),
		.SAXIL_BRESP(SAXIL_CFG_BRESP),
		.SAXIL_BVALID(SAXIL_CFG_BVALID),
		.SAXIL_BREADY(SAXIL_CFG_BREADY),
		.SAXIL_ARADDR(SAXIL_CFG_ARADDR),
		.SAXIL_ARPROT(SAXIL_CFG_ARPROT),
		.SAXIL_ARVALID(SAXIL_CFG_ARVALID),
		.SAXIL_ARREADY(SAXIL_CFG_ARREADY),
		.SAXIL_RDATA(SAXIL_CFG_RDATA),
		.SAXIL_RRESP(SAXIL_CFG_RRESP),
		.SAXIL_RVALID(SAXIL_CFG_RVALID),
		.SAXIL_RREADY(SAXIL_CFG_RREADY),
		
		.activeWriteAddress(cfgActiveWriteAddress),
		.writeData(cfgWriteData),
		.readAddress(cfgReadAddress),
		.readData(cfgReadData),

		.activeWriteAddress2(cc_cfgActiveWriteAddress),
		.readAddress2(cc_cfgReadAddress),
		.readData2(cc_cfgReadData),


		// MAXIL1
		.MAXIL1_AWADDR(jesdphy_saxi_awaddr),
		.MAXIL1_AWVALID(jesdphy_saxi_awvalid),
		.MAXIL1_AWREADY(jesdphy_saxi_awready),
		.MAXIL1_WDATA(jesdphy_saxi_wdata), 
		.MAXIL1_WVALID(jesdphy_saxi_wvalid),
		.MAXIL1_WREADY(jesdphy_saxi_wready),
		.MAXIL1_BRESP(jesdphy_saxi_bresp),
		.MAXIL1_BVALID(jesdphy_saxi_bvalid),
		.MAXIL1_BREADY(jesdphy_saxi_bready),
		.MAXIL1_ARADDR(jesdphy_saxi_araddr),
		.MAXIL1_ARVALID(jesdphy_saxi_arvalid),
		.MAXIL1_ARREADY(jesdphy_saxi_arready),
		.MAXIL1_RDATA(jesdphy_saxi_rdata),
		.MAXIL1_RRESP(jesdphy_saxi_rresp),
		.MAXIL1_RVALID(jesdphy_saxi_rvalid),
		.MAXIL1_RREADY(jesdphy_saxi_rready),


		// MAXIL2
		.MAXIL2_AWADDR(jesdcore_saxi_awaddr),
		.MAXIL2_AWVALID(jesdcore_saxi_awvalid),
		.MAXIL2_AWREADY(jesdcore_saxi_awready),
		.MAXIL2_WDATA(jesdcore_saxi_wdata), 
		.MAXIL2_WSTRB(jesdcore_saxi_wstrb),
		.MAXIL2_WVALID(jesdcore_saxi_wvalid),
		.MAXIL2_WREADY(jesdcore_saxi_wready),
		.MAXIL2_BRESP(jesdcore_saxi_bresp),
		.MAXIL2_BVALID(jesdcore_saxi_bvalid),
		.MAXIL2_BREADY(jesdcore_saxi_bready),
		.MAXIL2_ARADDR(jesdcore_saxi_araddr),
		.MAXIL2_ARVALID(jesdcore_saxi_arvalid),
		.MAXIL2_ARREADY(jesdcore_saxi_arready),
		.MAXIL2_RDATA(jesdcore_saxi_rdata),
		.MAXIL2_RRESP(jesdcore_saxi_rresp),
		.MAXIL2_RVALID(jesdcore_saxi_rvalid),
		.MAXIL2_RREADY(jesdcore_saxi_rready)
	);


	// JESD204 IP
	wire [31:0] gt_rxdata[7:0];
	wire [3:0] gt_rxcharisk[7:0];
	wire [3:0] gt_rxdisperr[7:0];
	wire [3:0] gt_rxnotintable[7:0];
	wire rxencommaalign;
	wire rx_reset_gt;
	wire gth_ref_clk;

	IBUFDS_GTE3 #(
		.REFCLK_EN_TX_PATH(1'b0), // Refer to Transceiver User Guide
		.REFCLK_HROW_CK_SEL(2'b00), // UG576: divide by 1
		.REFCLK_ICNTL_RX(2'b00) // Refer to Transceiver User Guide
	) gthRefClkBuf (
		.O(gth_ref_clk), // 1-bit output: Refer to Transceiver User Guide
		.ODIV2(), // 1-bit output: Refer to Transceiver User Guide
		.CEB(thermal_pd), // 1-bit input: Refer to Transceiver User Guide
		.I(adc_refclk_p), // 1-bit input: Refer to Transceiver User Guide
		.IB(adc_refclk_n) // 1-bit input: Refer to Transceiver User Guide
	);


	HSADC_JESD204 jesd204_inst (
		.gt0_rxdata(gt_rxdata[0]),                          // input wire [31 : 0] gt0_rxdata
		.gt0_rxcharisk(gt_rxcharisk[0]),                    // input wire [3 : 0] gt0_rxcharisk
		.gt0_rxdisperr(gt_rxdisperr[0]),                    // input wire [3 : 0] gt0_rxdisperr
		.gt0_rxnotintable(gt_rxnotintable[0]),              // input wire [3 : 0] gt0_rxnotintable
		.gt1_rxdata(gt_rxdata[1]),                          // input wire [31 : 0] gt1_rxdata
		.gt1_rxcharisk(gt_rxcharisk[1]),                    // input wire [3 : 0] gt1_rxcharisk
		.gt1_rxdisperr(gt_rxdisperr[1]),                    // input wire [3 : 0] gt1_rxdisperr
		.gt1_rxnotintable(gt_rxnotintable[1]),              // input wire [3 : 0] gt1_rxnotintable
		.gt2_rxdata(gt_rxdata[2]),                          // input wire [31 : 0] gt2_rxdata
		.gt2_rxcharisk(gt_rxcharisk[2]),                    // input wire [3 : 0] gt2_rxcharisk
		.gt2_rxdisperr(gt_rxdisperr[2]),                    // input wire [3 : 0] gt2_rxdisperr
		.gt2_rxnotintable(gt_rxnotintable[2]),              // input wire [3 : 0] gt2_rxnotintable
		.gt3_rxdata(gt_rxdata[3]),                          // input wire [31 : 0] gt3_rxdata
		.gt3_rxcharisk(gt_rxcharisk[3]),                    // input wire [3 : 0] gt3_rxcharisk
		.gt3_rxdisperr(gt_rxdisperr[3]),                    // input wire [3 : 0] gt3_rxdisperr
		.gt3_rxnotintable(gt_rxnotintable[3]),              // input wire [3 : 0] gt3_rxnotintable
		.gt4_rxdata(gt_rxdata[4]),                          // input wire [31 : 0] gt4_rxdata
		.gt4_rxcharisk(gt_rxcharisk[4]),                    // input wire [3 : 0] gt4_rxcharisk
		.gt4_rxdisperr(gt_rxdisperr[4]),                    // input wire [3 : 0] gt4_rxdisperr
		.gt4_rxnotintable(gt_rxnotintable[4]),              // input wire [3 : 0] gt4_rxnotintable
		.gt5_rxdata(gt_rxdata[5]),                          // input wire [31 : 0] gt5_rxdata
		.gt5_rxcharisk(gt_rxcharisk[5]),                    // input wire [3 : 0] gt5_rxcharisk
		.gt5_rxdisperr(gt_rxdisperr[5]),                    // input wire [3 : 0] gt5_rxdisperr
		.gt5_rxnotintable(gt_rxnotintable[5]),              // input wire [3 : 0] gt5_rxnotintable
		.gt6_rxdata(gt_rxdata[6]),                          // input wire [31 : 0] gt6_rxdata
		.gt6_rxcharisk(gt_rxcharisk[6]),                    // input wire [3 : 0] gt6_rxcharisk
		.gt6_rxdisperr(gt_rxdisperr[6]),                    // input wire [3 : 0] gt6_rxdisperr
		.gt6_rxnotintable(gt_rxnotintable[6]),              // input wire [3 : 0] gt6_rxnotintable
		.gt7_rxdata(gt_rxdata[7]),                          // input wire [31 : 0] gt7_rxdata
		.gt7_rxcharisk(gt_rxcharisk[7]),                    // input wire [3 : 0] gt7_rxcharisk
		.gt7_rxdisperr(gt_rxdisperr[7]),                    // input wire [3 : 0] gt7_rxdisperr
		.gt7_rxnotintable(gt_rxnotintable[7]),              // input wire [3 : 0] gt7_rxnotintable
		.rx_reset_done(jesd204_reset_done),                    // input wire rx_reset_done
		.rxencommaalign_out(rxencommaalign),          // output wire rxencommaalign_out
		.rx_reset_gt(rx_reset_gt),                        // output wire rx_reset_gt
		.rx_core_clk(coreClk),                        // input wire rx_core_clk
		.s_axi_aclk(axiClk),                          // input wire s_axi_aclk
		.s_axi_aresetn(axiResetN),                    // input wire s_axi_aresetn
		.s_axi_awaddr(jesdcore_saxi_awaddr),                      // input wire [11 : 0] s_axi_awaddr
		.s_axi_awvalid(jesdcore_saxi_awvalid),                    // input wire s_axi_awvalid
		.s_axi_awready(jesdcore_saxi_awready),                    // output wire s_axi_awready
		.s_axi_wdata(jesdcore_saxi_wdata),                        // input wire [31 : 0] s_axi_wdata
		.s_axi_wstrb(jesdcore_saxi_wstrb),                        // input wire [3 : 0] s_axi_wstrb
		.s_axi_wvalid(jesdcore_saxi_wvalid),                      // input wire s_axi_wvalid
		.s_axi_wready(jesdcore_saxi_wready),                      // output wire s_axi_wready
		.s_axi_bresp(jesdcore_saxi_bresp),                        // output wire [1 : 0] s_axi_bresp
		.s_axi_bvalid(jesdcore_saxi_bvalid),                      // output wire s_axi_bvalid
		.s_axi_bready(jesdcore_saxi_bready),                      // input wire s_axi_bready
		.s_axi_araddr(jesdcore_saxi_araddr),                      // input wire [11 : 0] s_axi_araddr
		.s_axi_arvalid(jesdcore_saxi_arvalid),                    // input wire s_axi_arvalid
		.s_axi_arready(jesdcore_saxi_arready),                    // output wire s_axi_arready
		.s_axi_rdata(jesdcore_saxi_rdata),                        // output wire [31 : 0] s_axi_rdata
		.s_axi_rresp(jesdcore_saxi_rresp),                        // output wire [1 : 0] s_axi_rresp
		.s_axi_rvalid(jesdcore_saxi_rvalid),                      // output wire s_axi_rvalid
		.s_axi_rready(jesdcore_saxi_rready),                      // input wire s_axi_rready
		.rx_reset(jesd204_reset || thermal_pd),                              // input wire rx_reset
		.rx_aresetn(serialDataResetN),                          // output wire rx_aresetn
		.rx_tdata(serialData),                              // output wire [255 : 0] rx_tdata
		.rx_tvalid(serialDataValid),                            // output wire rx_tvalid
		.rx_start_of_frame(rx_start_of_frame),            // output wire [3 : 0] rx_start_of_frame
		.rx_end_of_frame(rx_end_of_frame),                // output wire [3 : 0] rx_end_of_frame
		.rx_start_of_multiframe(rx_start_of_multiframe),  // output wire [3 : 0] rx_start_of_multiframe
		.rx_end_of_multiframe(rx_end_of_multiframe),      // output wire [3 : 0] rx_end_of_multiframe
		.rx_frame_error(rx_frame_error),                  // output wire [31 : 0] rx_frame_error
		.rx_sysref(sysref),                            // input wire rx_sysref
		.rx_sync(adc_syncb)                                // output wire rx_sync
	);

	HSADC_JESD204_PHY jesd204_phy_inst (
		.cpll_refclk(),                            // input wire cpll_refclk
		.qpll0_refclk(gth_ref_clk),                          // input wire qpll0_refclk
		.qpll1_refclk(gth_ref_clk),                          // input wire qpll1_refclk
		.drpclk(axiClk),                                      // input wire drpclk
		.tx_reset_gt(1),                            // input wire tx_reset_gt
		.rx_reset_gt(rx_reset_gt),                            // input wire rx_reset_gt
		.tx_sys_reset(1),                          // input wire tx_sys_reset
		.rx_sys_reset(jesd204phy_sys_reset || thermal_pd),                          // input wire rx_sys_reset
		.rxp_in(adc_rx_p),                                      // input wire [7 : 0] rxp_in
		.rxn_in(adc_rx_n),                                      // input wire [7 : 0] rxn_in
		.rx_core_clk(coreClk),                            // input wire rx_core_clk
		.rxoutclk(),                                  // output wire rxoutclk
		.gt_powergood(jesd204_gt_powergood),                          // output wire gt_powergood
		.gt0_rxdata(gt_rxdata[0]),                          // input wire [31 : 0] gt0_rxdata
		.gt0_rxcharisk(gt_rxcharisk[0]),                    // input wire [3 : 0] gt0_rxcharisk
		.gt0_rxdisperr(gt_rxdisperr[0]),                    // input wire [3 : 0] gt0_rxdisperr
		.gt0_rxnotintable(gt_rxnotintable[0]),              // input wire [3 : 0] gt0_rxnotintable
		.gt1_rxdata(gt_rxdata[1]),                          // input wire [31 : 0] gt1_rxdata
		.gt1_rxcharisk(gt_rxcharisk[1]),                    // input wire [3 : 0] gt1_rxcharisk
		.gt1_rxdisperr(gt_rxdisperr[1]),                    // input wire [3 : 0] gt1_rxdisperr
		.gt1_rxnotintable(gt_rxnotintable[1]),              // input wire [3 : 0] gt1_rxnotintable
		.gt2_rxdata(gt_rxdata[2]),                          // input wire [31 : 0] gt2_rxdata
		.gt2_rxcharisk(gt_rxcharisk[2]),                    // input wire [3 : 0] gt2_rxcharisk
		.gt2_rxdisperr(gt_rxdisperr[2]),                    // input wire [3 : 0] gt2_rxdisperr
		.gt2_rxnotintable(gt_rxnotintable[2]),              // input wire [3 : 0] gt2_rxnotintable
		.gt3_rxdata(gt_rxdata[3]),                          // input wire [31 : 0] gt3_rxdata
		.gt3_rxcharisk(gt_rxcharisk[3]),                    // input wire [3 : 0] gt3_rxcharisk
		.gt3_rxdisperr(gt_rxdisperr[3]),                    // input wire [3 : 0] gt3_rxdisperr
		.gt3_rxnotintable(gt_rxnotintable[3]),              // input wire [3 : 0] gt3_rxnotintable
		.gt4_rxdata(gt_rxdata[4]),                          // input wire [31 : 0] gt4_rxdata
		.gt4_rxcharisk(gt_rxcharisk[4]),                    // input wire [3 : 0] gt4_rxcharisk
		.gt4_rxdisperr(gt_rxdisperr[4]),                    // input wire [3 : 0] gt4_rxdisperr
		.gt4_rxnotintable(gt_rxnotintable[4]),              // input wire [3 : 0] gt4_rxnotintable
		.gt5_rxdata(gt_rxdata[5]),                          // input wire [31 : 0] gt5_rxdata
		.gt5_rxcharisk(gt_rxcharisk[5]),                    // input wire [3 : 0] gt5_rxcharisk
		.gt5_rxdisperr(gt_rxdisperr[5]),                    // input wire [3 : 0] gt5_rxdisperr
		.gt5_rxnotintable(gt_rxnotintable[5]),              // input wire [3 : 0] gt5_rxnotintable
		.gt6_rxdata(gt_rxdata[6]),                          // input wire [31 : 0] gt6_rxdata
		.gt6_rxcharisk(gt_rxcharisk[6]),                    // input wire [3 : 0] gt6_rxcharisk
		.gt6_rxdisperr(gt_rxdisperr[6]),                    // input wire [3 : 0] gt6_rxdisperr
		.gt6_rxnotintable(gt_rxnotintable[6]),              // input wire [3 : 0] gt6_rxnotintable
		.gt7_rxdata(gt_rxdata[7]),                          // input wire [31 : 0] gt7_rxdata
		.gt7_rxcharisk(gt_rxcharisk[7]),                    // input wire [3 : 0] gt7_rxcharisk
		.gt7_rxdisperr(gt_rxdisperr[7]),                    // input wire [3 : 0] gt7_rxdisperr
		.gt7_rxnotintable(gt_rxnotintable[7]),              // input wire [3 : 0] gt7_rxnotintable
		.rx_reset_done(jesd204_reset_done),                        // output wire rx_reset_done
		.rxencommaalign(rxencommaalign),                      // input wire rxencommaalign
		.common0_qpll0_clk_out(),        // output wire common0_qpll0_clk_out
		.common0_qpll0_refclk_out(),  // output wire common0_qpll0_refclk_out
		.common0_qpll0_lock_out(common0_qpll0_locked),      // output wire common0_qpll0_lock_out
		.common0_qpll1_clk_out(),        // output wire common0_qpll1_clk_out
		.common0_qpll1_refclk_out(),  // output wire common0_qpll1_refclk_out
		.common0_qpll1_lock_out(common0_qpll1_locked),      // output wire common0_qpll1_lock_out
		.common1_qpll0_clk_out(),        // output wire common1_qpll0_clk_out
		.common1_qpll0_refclk_out(),  // output wire common1_qpll0_refclk_out
		.common1_qpll0_lock_out(common1_qpll0_locked),      // output wire common1_qpll0_lock_out
		.common1_qpll1_clk_out(),        // output wire common1_qpll1_clk_out
		.common1_qpll1_refclk_out(),  // output wire common1_qpll1_refclk_out
		.common1_qpll1_lock_out(common1_qpll1_locked),      // output wire common1_qpll1_lock_out
		.s_axi_aclk(axiClk),                              // input wire s_axi_aclk
		.s_axi_aresetn(axiResetN),                        // input wire s_axi_aresetn
		.s_axi_awaddr(jesdphy_saxi_awaddr),                          // input wire [11 : 0] s_axi_awaddr
		.s_axi_awvalid(jesdphy_saxi_awvalid),                        // input wire s_axi_awvalid
		.s_axi_awready(jesdphy_saxi_awready),                        // output wire s_axi_awready
		.s_axi_wdata(jesdphy_saxi_wdata),                            // input wire [31 : 0] s_axi_wdata
		.s_axi_wvalid(jesdphy_saxi_wvalid),                          // input wire s_axi_wvalid
		.s_axi_wready(jesdphy_saxi_wready),                          // output wire s_axi_wready
		.s_axi_bresp(jesdphy_saxi_bresp),                            // output wire [1 : 0] s_axi_bresp
		.s_axi_bvalid(jesdphy_saxi_bvalid),                          // output wire s_axi_bvalid
		.s_axi_bready(jesdphy_saxi_bready),                          // input wire s_axi_bready
		.s_axi_araddr(jesdphy_saxi_araddr),                          // input wire [11 : 0] s_axi_araddr
		.s_axi_arvalid(jesdphy_saxi_arvalid),                        // input wire s_axi_arvalid
		.s_axi_arready(jesdphy_saxi_arready),                        // output wire s_axi_arready
		.s_axi_rdata(jesdphy_saxi_rdata),                            // output wire [31 : 0] s_axi_rdata
		.s_axi_rresp(jesdphy_saxi_rresp),                            // output wire [1 : 0] s_axi_rresp
		.s_axi_rvalid(jesdphy_saxi_rvalid),                          // output wire s_axi_rvalid
		.s_axi_rready(jesdphy_saxi_rready)                           // input wire s_axi_rready
	);

endmodule
