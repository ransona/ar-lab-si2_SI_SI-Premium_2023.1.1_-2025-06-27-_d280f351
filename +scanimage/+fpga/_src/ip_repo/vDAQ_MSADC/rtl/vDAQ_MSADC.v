//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

/********************************************************************************\
Configuration AXI Bus Specification

 - Read at address 0 will return 0xADC1_ADC4
 
 - Read at unsupported location will return 0x1331_1331
 
 - 0x04 [W]: initiate an SPI configuration
	-write 0xFFFF_FFFF to configure all devices
	 VGA's will be programmed with buffered settings
	 ADC will be programmed with default settings
	-write 0xFFFF_FF12 to configure VGA12
	-write 0xFFFF_FE12 to read back settings of VGA12
	-write 0xFFFF_FF34 to configure VGA34
	-write 0xFFFF_FE34 to read back settings of VGA34
	-write 0xFFFF_FADC to configure ADC with default settings
	-for a targeted configuration of a certain ADC register:
	  wdata[31:22] = 0
	  wdata[21] = 0 for write, 1 for read
	  wdata[20:8] = address
	  wdata[7:0] = data
	 
 - 0x08 [R/W]: VGA setting buffer data[14:0]
	 
 - 0x0C [R]: VGA setting readback. vga12settings = data[14:0], vga34settings = data[30:16]

\********************************************************************************/

module vDAQ_MSADC #(
	// ADC settings

	
	// VGA default settings
	parameter [5:0] FILTER_FREQ = 40,
	parameter [0:0] POWER_MODE = 1,
	parameter [1:0] VGA1_GAIN = 3,
	parameter [1:0] VGA2_GAIN = 3,
	parameter [1:0] VGA3_GAIN = 3,
	parameter [0:0] POST_AMP_GAIN = 0,
	parameter [0:0] DC_OFFSET_DISABLE = 0,

	// do not change
	parameter SAXIL_CFG_DATA_WIDTH = 32,
	parameter SAXIL_CFG_ADDR_WIDTH = 8
) (
	input wire clk40,
	input wire axiResetN,
	input wire reset,
	
	// configuration
	output wire cfgInProgress,
	input wire applyCfgReq,
	
	// high speed data from device
	input wire DCLK_P,
	input wire DCLK_N,
	input wire FRCLK_P,
	input wire FRCLK_N,
	
	input wire CHA_D0_P,
	input wire CHA_D0_N,
	input wire CHA_D1_P,
	input wire CHA_D1_N,
	
	input wire CHB_D0_P,
	input wire CHB_D0_N,
	input wire CHB_D1_P,
	input wire CHB_D1_N,
	
	input wire CHC_D0_P,
	input wire CHC_D0_N,
	input wire CHC_D1_P,
	input wire CHC_D1_N,
	
	input wire CHD_D0_P,
	input wire CHD_D0_N,
	input wire CHD_D1_P,
	input wire CHD_D1_N,
	
	// device control
	input  wire board_rev,
	output wire adc_sync,
	output wire adc_pwrdwn,
	
	// SPI bus to devices
	output wire spi_adc_clk,
	output wire spi_adc_cs,
	inout  wire spi_adc_sdio,
	output wire spi_vga_clk,
	output wire spi_vga_cs12,
	output wire spi_vga_cs34,
	output wire spi_vga_mosi,
	input  wire spi_vga_miso,
	
	// data out to RTL
	output wire [13:0] ch1Data,
	output wire [13:0] ch2Data,
	output wire [13:0] ch3Data,
	output wire [13:0] ch4Data,
	output wire sampleClk,
	
	
	// SAXIL control/config bus
	input wire [SAXIL_CFG_ADDR_WIDTH-1 : 0] SAXIL_CFG_AWADDR,
	input wire [2 : 0] SAXIL_CFG_AWPROT,
	input wire  SAXIL_CFG_AWVALID,
	output wire  SAXIL_CFG_AWREADY,
	input wire [SAXIL_CFG_DATA_WIDTH-1 : 0] SAXIL_CFG_WDATA,
	input wire [(SAXIL_CFG_DATA_WIDTH/8)-1 : 0] SAXIL_CFG_WSTRB,
	input wire  SAXIL_CFG_WVALID,
	output wire  SAXIL_CFG_WREADY,
	output wire [1 : 0] SAXIL_CFG_BRESP,
	output wire  SAXIL_CFG_BVALID,
	input wire  SAXIL_CFG_BREADY,
	input wire [SAXIL_CFG_ADDR_WIDTH-1 : 0] SAXIL_CFG_ARADDR,
	input wire [2 : 0] SAXIL_CFG_ARPROT,
	input wire  SAXIL_CFG_ARVALID,
	output wire  SAXIL_CFG_ARREADY,
	output wire [SAXIL_CFG_DATA_WIDTH-1 : 0] SAXIL_CFG_RDATA,
	output wire [1 : 0] SAXIL_CFG_RRESP,
	output wire  SAXIL_CFG_RVALID,
	input wire  SAXIL_CFG_RREADY
);
	// low speed signal buffers
	wire board_rev_b;
	wire spi_adc_clk_b;
	wire spi_vga_clk_b;
	(* IOB = "TRUE" *) reg  sync_b = 0;
	(* IOB = "TRUE" *) reg  pwrdwn_b = 0;
	reg  pwrdwn_b_cpy = 0;
	(* IOB = "TRUE" *) reg spi_adc_cs_b = 1;
	(* IOB = "TRUE" *) reg spi_vga_cs12_b = 1;
	(* IOB = "TRUE" *) reg spi_vga_cs34_b = 1;
	wire spi_vga_miso_b;
	wire spi_adc_di;
	reg adc_spi_we = 0;
	(* IOB = "TRUE" *) reg spi_adc_do = 0;
	(* IOB = "TRUE" *) reg spi_vga_do = 0;
	
	
	OBUF spi_adc_clk_buf(.I(spi_adc_clk_b), .O(spi_adc_clk));
	OBUF spi_vga_clk_buf(.I(spi_vga_clk_b), .O(spi_vga_clk));
	
	IBUF board_rev_buf(.I(board_rev), .O(board_rev_b));
	OBUF sync_buf(.I(sync_b), .O(adc_sync));
	OBUF pwrdwn_buf(.I(pwrdwn_b), .O(adc_pwrdwn));
	OBUF spi_adc_cs_buf(.I(spi_adc_cs_b), .O(spi_adc_cs));
	OBUF spi_vga_cs12_buf(.I(spi_vga_cs12_b), .O(spi_vga_cs12));
	OBUF spi_vga_cs34_buf(.I(spi_vga_cs34_b), .O(spi_vga_cs34));
	IBUF spi_vga_miso_buf(.I(spi_vga_miso), .O(spi_vga_miso_b));
	OBUF spi_vga_mosi_obuf(.I(spi_vga_do), .O(spi_vga_mosi));
	IOBUF spi_adc_sdio_iobuf(.I(spi_adc_do), .O(spi_adc_di), .IO(spi_adc_sdio), .T(~adc_spi_we));
	
	
	// clocking
	wire frclk;
	wire dataClk;

	wire pllFbClk;
	wire pllLocked;

	reg  sampleClkResetReq = 0;
	reg  sampleClkResetReq_p = 1;
	wire sampleClkResetReq_RE = sampleClkResetReq && ~sampleClkResetReq_p;
	reg  [5:0] sampleClkResetCtr = 63;
	reg  sampleClkResetActive = 1;

	wire [15:0] sampleClkPllDrpDo;
	wire sampleClkPllDrpRdy;
	reg  [6:0] sampleClkPllDrpAddr = 0;
	wire sampleClkPllDrpClk;
	reg  [15:0] sampleClkPllDrpDi = 0;
	wire sampleClkPllDrpWe;

	always @(posedge frclk) begin
		sampleClkResetReq_p <= sampleClkResetReq;

		if (sampleClkResetReq_RE)
			sampleClkResetCtr <= 63;
		else if (sampleClkResetCtr)
			sampleClkResetCtr <= sampleClkResetCtr - 1;

		sampleClkResetActive <= sampleClkResetCtr > 0;
	end

	wire frclk_b;
	IBUFDS FRCLK_ibuf (.I(FRCLK_P), .IB(FRCLK_N), .O(frclk_b));
	BUFGCE frClkBuf (.I(frclk_b), .O(frclk));

	PLLE3_ADV #(
		.CLKFBOUT_MULT(8), // Multiply value for all CLKOUT, (1-19)
		.CLKFBOUT_PHASE(0.0), // Phase offset in degrees of CLKFB, (-360.000-360.000)
		.CLKIN_PERIOD(8.0), // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
		// CLKOUT0 Attributes: Divide, Phase and Duty Cycle for the CLKOUT0 output
		.CLKOUT0_DIVIDE(2), // Divide amount for CLKOUT0 (1-128)
		.CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999)
		.CLKOUT0_PHASE(0.0), // Phase offset for CLKOUT0 (-360.000-360.000)
		// CLKOUT1 Attributes: Divide, Phase and Duty Cycle for the CLKOUT1 output
		.CLKOUT1_DIVIDE(8), // Divide amount for CLKOUT1 (1-128)
		.CLKOUT1_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT1 (0.001-0.999)
		.CLKOUT1_PHASE(0), // Phase offset for CLKOUT1 (-360.000-360.000)
		.DIVCLK_DIVIDE(1) // Master division value, (1-15)
	) msadcClkPll (
		// Clock Outputs outputs: User configurable clock outputs
		.CLKOUT0(dataClk), // 1-bit output: General Clock output
		.CLKOUT1(sampleClk), // 1-bit output: General Clock output
		// DRP Ports outputs: Dynamic reconfiguration ports
		.DO(sampleClkPllDrpDo), // 16-bit output: DRP data
		.DRDY(sampleClkPllDrpRdy), // 1-bit output: DRP ready
		// Feedback Clocks outputs: Clock feedback ports
		.CLKFBOUT(pllFbClk), // 1-bit output: Feedback clock
		.LOCKED(pllLocked), // 1-bit output: LOCK
		.CLKIN(frclk), // 1-bit input: Input clock
		// Control Ports inputs: PLL control ports
		.CLKOUTPHYEN(0), // 1-bit input: CLKOUTPHY enable
		.PWRDWN(0), // 1-bit input: Power-down
		.RST(sampleClkResetActive), // 1-bit input: Reset
		// DRP Ports inputs: Dynamic reconfiguration ports
		.DADDR(sampleClkPllDrpAddr), // 7-bit input: DRP address
		.DCLK(sampleClkPllDrpClk), // 1-bit input: DRP clock
		.DEN(1), // 1-bit input: DRP enable
		.DI(sampleClkPllDrpDi), // 16-bit input: DRP data
		.DWE(sampleClkPllDrpWe), // 1-bit input: DRP write enable
		// Feedback Clocks inputs: Clock feedback ports
		.CLKFBIN(pllFbClk) // 1-bit input: Feedback clock
	);

	
	wire [19:0] fclkRate;
	CLK_RATE_MEASi #(.MEAS_COUNTER_WIDTH(20), .RESULT_COUNTER_WIDTH(20)) meas_fclk (.measClk(sampleClk), .resultClk(clk40), .measClkPeriod(fclkRate));
	
	
	// idelay control ref clk
	reg idelayRefClkRst = 0;
	wire idelayRefClkLocked;
	wire clkfb;
	wire refClk40;
	wire idelayRefClk;
	BUFGCE refClk40_bufg(.I(clk40), .O(refClk40));
	
	MMCME3_BASE #(
        .BANDWIDTH("OPTIMIZED"), // Jitter programming (HIGH, LOW, OPTIMIZED)
        .CLKFBOUT_MULT_F(20.000), // Multiply value for all CLKOUT (2.000-64.000)
        .CLKFBOUT_PHASE(0.000), // Phase offset in degrees of CLKFB (-360.000-360.000)
        .CLKIN1_PERIOD(25.000), // Input clock period in ns units, ps resolution (i.e. 33.333 is 30 MHz).
        .CLKOUT0_DIVIDE_F(2.000), // Divide amount for CLKOUT0 (1.000-128.000)
        // CLKOUT1_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
        .CLKOUT1_DIVIDE(1),
        .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
        .DIVCLK_DIVIDE(1), // Master division value (1-106)
        // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
        .IS_CLKFBIN_INVERTED(1'b0), // Optional inversion for CLKFBIN
        .IS_CLKIN1_INVERTED(1'b1), // Optional inversion for CLKIN1
        .IS_PWRDWN_INVERTED(1'b0), // Optional inversion for PWRDWN
        .IS_RST_INVERTED(1'b0), // Optional inversion for RST
        .REF_JITTER1(0.0), // Reference input jitter in UI (0.000-0.999)
        .STARTUP_WAIT("FALSE") // Delays DONE until MMCM is locked (FALSE, TRUE)
    ) MMCME3_BASE_inst (
        // Clock Outputs outputs: User configurable clock outputs
        .CLKOUT0(idelayRefClk), // 1-bit output: CLKOUT0
        // Feedback outputs: Clock feedback ports
        .CLKFBOUT(clkfb), // 1-bit output: Feedback clock
        .CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
        // Status Ports outputs: MMCM status ports
        .LOCKED(idelayRefClkLocked), // 1-bit output: LOCK
        // Clock Inputs inputs: Clock input
        .CLKIN1(refClk40), // 1-bit input: Clock
        // Control Ports inputs: MMCM control ports
        .PWRDWN(1'b0), // 1-bit input: Power-down
        .RST(idelayRefClkRst), // 1-bit input: Reset
        // Feedback inputs: Clock feedback ports
        .CLKFBIN(clkfb) // 1-bit input: Feedback clock
    );
	
	
	// idelay control
	reg idelayCtrlRst = 0;
	wire [4:0] idelayCtrlRdyi;
	wire idelayCtrlRdy = &idelayCtrlRdyi;
	
	genvar idci;
	generate
		for (idci=0; idci<5; idci=idci+1) begin : gen_idc
			IDELAYCTRL #(.SIM_DEVICE("ULTRASCALE")) IDELAYCTRL_inst (
				.RDY(idelayCtrlRdyi[idci]), // 1-bit output: Ready output
				.REFCLK(idelayRefClk), // 1-bit input: Reference clock input
				.RST(idelayCtrlRst) // 1-bit input: Active high reset input
			);
		end
	endgenerate
	
	
	
	// inputs
	wire [7:0] Din_P = {CHD_D1_P, CHD_D0_P, CHC_D1_P, CHC_D0_P, CHB_D1_P, CHB_D0_P, CHA_D1_P, CHA_D0_P};
	wire [7:0] Din_N = {CHD_D1_N, CHD_D0_N, CHC_D1_N, CHC_D0_N, CHB_D1_N, CHB_D0_N, CHA_D1_N, CHA_D0_N};
	// deserialized inputs
	wire [7:0] Din_parR[7:0];
	wire [7:0] Din_par[7:0];
	
	// idelay control signals
	reg [8:0] delayValN;
	reg [7:0] ce = 8'h00;
	reg [7:0] inc = 8'h00;
	reg [7:0] load = 8'h00;
	reg [7:0] en_vtc = 8'hFF;
	reg idelayRst = 0;
	reg iserdeseRst = 0;
	
	localparam [7:0] INVERT_PIN = 8'b11001111;
	
	genvar i,k;
	generate
		for (i=0; i<8; i=i+1) begin : gen_data_pin_process
			wire din;
			wire dinb;
			wire din_del;
			IBUFDS_DIFF_OUT data_ibuf_inst (.I(Din_P[i]),.IB(Din_N[i]),.O(din),.OB(dinb));
			
			IDELAYE3 #(
				.CASCADE("NONE"), // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
				.DELAY_FORMAT("TIME"), // Units of the DELAY_VALUE (COUNT, TIME)
				.DELAY_SRC("IDATAIN"), // Delay input (DATAIN, IDATAIN)
				.DELAY_TYPE("VAR_LOAD"), // Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
				.DELAY_VALUE(0), // Input delay value setting
				.IS_CLK_INVERTED(1'b0), // Optional inversion for CLK
				.IS_RST_INVERTED(1'b0), // Optional inversion for RST
				.REFCLK_FREQUENCY(400.0), // IDELAYCTRL clock input frequency in MHz (200.0-2400.0)
				.UPDATE_MODE("ASYNC") // Determines when updates to the delay will take effect (ASYNC, MANUAL, SYNC)
			) idelay (
				.CASC_OUT(), // 1-bit output: Cascade delay output to ODELAY input cascade
				.CNTVALUEOUT(), // 9-bit output: Counter value output
				.DATAOUT(din_del), // 1-bit output: Delayed data output
				.CASC_IN(), // 1-bit input: Cascade delay input from slave ODELAY CASCADE_OUT
				.CASC_RETURN(), // 1-bit input: Cascade delay returning from slave ODELAY DATAOUT
				.CE(ce[i]), // 1-bit input: Active high enable increment/decrement input
				.CLK(sampleClk), // 1-bit input: Clock input
				.CNTVALUEIN(delayValN), // 9-bit input: Counter value input
				.DATAIN(), // 1-bit input: Data input from the logic
				.EN_VTC(en_vtc[i]), // 1-bit input: Keep delay constant over VT
				.IDATAIN(INVERT_PIN[i] ? dinb : din), // 1-bit input: Data input from the IOBUF
				.INC(inc[i]), // 1-bit input: Increment / Decrement tap delay input
				.LOAD(load[i]), // 1-bit input: Load DELAY_VALUE input
				.RST(idelayRst) // 1-bit input: Asynchronous Reset to the DELAY_VALUE
			);
			
			ISERDESE3 #(.IS_CLK_INVERTED(1'b1)) iserdes (
				.CLK(dataClk),
				.CLK_B(dataClk),
				.CLKDIV(sampleClk),
				.D(din_del),
				.Q(Din_parR[i]),
				.RST(iserdeseRst),
				.FIFO_RD_CLK(1'b0),
				.FIFO_RD_EN(1'b0)
			);
			
			//reverse the bits
			for (k=0; k<8; k=k+1) begin : gen_bit_swap
				assign Din_par[i][k] = Din_parR[i][7-k];
			end
		end
	endgenerate
	

	reg boardRev = 0;
	reg testPatternOn = 0;

	wire [13:0] ch1DataP = {Din_par[1][7:0], Din_par[0][7:2]};
	wire [13:0] ch2DataP = {Din_par[3][7:0], Din_par[2][7:2]};
	wire [13:0] ch3DataP = {Din_par[5][7:0], Din_par[4][7:2]};
	wire [13:0] ch4DataP = {Din_par[7][7:0], Din_par[6][7:2]};
	wire invertSecondChan = ~boardRev || testPatternOn;
	
	assign ch1Data = ~ch1DataP;
	assign ch2Data = invertSecondChan ? ~ch2DataP : ch2DataP;
	assign ch3Data = ~ch3DataP;
	assign ch4Data = invertSecondChan ? ~ch4DataP : ch4DataP;
	
	
	// dynamic calibration gearbox
	reg calInProgress = 1;
	reg reqCal = 0;
	reg usrReqCal = 0;
	wire usrReqCal_sc;
	
	SBCCi usrReqCal_crss(.srcV(usrReqCal), .srcClk(clk40), .dstV(usrReqCal_sc), .dstClk(sampleClk));
	
	reg reqTestPattern = 0;
	wire calRqTestPattern;
	wire testPatternOn_sc;
	
	reg usrReqReset = 0;
	wire usrReqReset_sc;
	wire resetReq = reset || usrReqReset_sc;
	
	SBCCi reqTestPattern_crss(.srcV(reqTestPattern), .srcClk(sampleClk), .dstV(calRqTestPattern), .dstClk(clk40));
	SBCCi testPatternOn_crss(.srcV(testPatternOn), .srcClk(clk40), .dstV(testPatternOn_sc), .dstClk(sampleClk));
	SBCCi usrReqReset_crss(.srcV(usrReqReset), .srcClk(clk40), .dstV(usrReqReset_sc), .dstClk(sampleClk));
	
	
	reg [9:0] calRunsCompleted = 0;
	reg [2:0] calBitNum = 7;
	reg [1:0] calBitStep;
	reg [5:0] calDelayCtr;
	reg pReset = 0;
	reg resetExt = 0;
	reg resetFE = 0;
	
	// metastability flops
	(* ASYNC_REG = "TRUE" *)
	reg [2:0] delIsGoodFF;
	wire delIsGood = delIsGoodFF[0];
	
	reg delWasGood = 0;
	reg [8:0] firstGoodDelValN = 0;
	reg [8:0] lastGoodDelValN = 0;
	reg [8:0] delayVal[7:0] = {9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0};
	reg [8:0] firstGoodDelVal[7:0] = {509, 509, 509, 509, 509, 509, 509, 509};
	reg [8:0] lastGoodDelVal[7:0] = {509, 509, 509, 509, 509, 509, 509, 509};
	reg finalDelLoaded = 0;
	reg [4:0] consecGoodCtr = 0;
	wire inGoodZone = &consecGoodCtr;
	
	// expected bit pattern is 1010 0001 1001 1100
	localparam [7:0] EVEN_BIT_EXPECTED_PATTERN = 8'b1001_1100;
	localparam [7:0] ODD_BIT_EXPECTED_PATTERN = 8'b1010_0001;
	wire [7:0] epectedPattern = calBitNum[0] ? ODD_BIT_EXPECTED_PATTERN : EVEN_BIT_EXPECTED_PATTERN;

	always @(posedge sampleClk) begin
		// make reset a minimum of two clock pulses
		pReset <= resetReq;
		resetExt <= resetReq && ~pReset;
		
		// for detection of first clock after reset
		resetFE <= resetReq || resetExt;
		
		// kill metastability problems when checking data
		delIsGoodFF <= {Din_par[calBitNum] == epectedPattern, delIsGoodFF[2:1]};
		
		if (resetReq || resetExt) begin
			// revisit reset sequence
			sampleClkResetReq <= 0;
			idelayRefClkRst <= 1;
			idelayCtrlRst <= 1;
			idelayRst <= 1;
			iserdeseRst <= 1;
			reqCal <= 1;
			calInProgress <= 0;
			reqTestPattern <= 0;
			en_vtc <= 8'hFF;
			boardRev <= board_rev_b;
		end else if (resetFE)
			// reset divClk on the FE of reset
			sampleClkResetReq <= 1;
		else if (sampleClkResetReq || ~pllLocked)
			sampleClkResetReq <= 0;
		else if (idelayRefClkRst) begin
			idelayRefClkRst <= 0;
		end else if (idelayCtrlRst) begin
			idelayCtrlRst <= ~idelayRefClkLocked;
			idelayRst <= ~idelayRefClkLocked;
			iserdeseRst <= ~idelayRefClkLocked;
			calDelayCtr <= 60;
		end else if(~idelayCtrlRdy)
			calDelayCtr <= 60;
		else if (calDelayCtr && ~calInProgress)
			calDelayCtr <= calDelayCtr - 1;
		else if (calInProgress) begin
		
			if (~testPatternOn_sc)
				// waiting for test pattern to be enabled
				reqTestPattern <= 1;
			else if (calDelayCtr) begin
				calDelayCtr <= calDelayCtr - 1;
				load <= 0;
			end else if (!calBitStep) begin
				// start process for this bit.
				// set the delay value to zero
				calBitStep <= calBitStep + 1;
				delayValN <= 0;
				delWasGood <= 0;
				firstGoodDelValN <= 511;
				lastGoodDelValN <= 511;
				finalDelLoaded <= 0;
				consecGoodCtr <= 0;
			end else if(calBitStep == 1) begin
				// one clock after setting delay to zero, pulse load bit for one clock
				// set the delay
				calBitStep <= calBitStep + 1;
				calDelayCtr <= 20;
				load[calBitNum] <= 1;
			end else if(calBitStep == 2) begin
				// new delay is loaded. check if it is a good delay
				delWasGood <= delIsGood;
				
				if (~inGoodZone)
					consecGoodCtr <= delIsGood ? consecGoodCtr + 1 : 0;
				
				if (delIsGood) begin
					lastGoodDelValN <= delayValN;
					if(~delWasGood) begin
						firstGoodDelValN <= delayValN;
					end
				end
				
				if (finalDelLoaded) begin
					// we have set the solution delay. assert en_vtc for
					// this bit and move on to the next
					en_vtc[calBitNum] <= 1;
					
					if (calBitNum < 7) begin
						calBitNum <= calBitNum + 1;
						calBitStep <= 0;
					end else begin
						// all done
						calBitStep <= 3;
					end
				end else if ((inGoodZone && ~delIsGood) || (delayValN == 511)) begin
					// we were in good zone then left OR we have tested all possible delay vals.
					// pick a value between the first and last good readings
					delayValN <= firstGoodDelValN + ((lastGoodDelValN - firstGoodDelValN) >> 1);
					delayVal[calBitNum] <= firstGoodDelValN + ((lastGoodDelValN - firstGoodDelValN) >> 1);
					firstGoodDelVal[calBitNum] <= firstGoodDelValN;
					lastGoodDelVal[calBitNum] <= lastGoodDelValN;
					finalDelLoaded <= 1;
					calBitStep <= 1;
				end else begin
					// try the next delay
					delayValN <= delayValN + 1;
					calBitStep <= 1;
				end
				
			end else begin
				// all done!
				calRunsCompleted <= calRunsCompleted + 1;
				en_vtc <= 8'hFF;
				calInProgress <= 0;
				reqTestPattern <= 0;
			end
		
		end else if (reqCal || usrReqCal_sc) begin
			reqCal <= 0;
			reqTestPattern <= 1;
			calInProgress <= 1;
			calBitNum <= 0;
			calBitStep <= 0;
			en_vtc <= 8'h00;
			calDelayCtr <= 12;
		end
	end
	

	// spi configuration interface
	reg [7:0] adcReadbackBuf = 0;
	reg [7:0] adcOutputBuffer = 0;
	
	localparam [14:0] VGA_DEFAULT_SETTINGS = {FILTER_FREQ, POWER_MODE, VGA1_GAIN, VGA2_GAIN, VGA3_GAIN, POST_AMP_GAIN, DC_OFFSET_DISABLE};
	// vga settings output buffer
	reg [14:0] vgaSettingsOutput = VGA_DEFAULT_SETTINGS;
	// vga settings read back buffer
	reg [14:0] vga12SettingsReadback = 0;
	reg [14:0] vga34SettingsReadback = 0;
	
	// generate spi clocks
	(* IOB = "TRUE" *) reg adcSpiClkG = 0;
	(* IOB = "TRUE" *) reg vgaSpiClkG = 0;
	assign spi_adc_clk_b = adcSpiClkG;
	assign spi_vga_clk_b = vgaSpiClkG;
	reg spiClkLvl = 0;
	
	// spi logic
	reg [4:0] instrCtr = 0;
	reg addrDone = 0;
	reg [7:0] bitCtr = 0;
	reg cfgActive = 0;
	
	reg [9:0] spiCmdsCompleted = 0;
	reg cfgReq = 0;
	reg [2:0] cfgReqDev = 0; // 6=adc, 5=vga12, 3=vga34, 1=both vga's
	reg cfgReqRd = 0;
	reg [12:0] cfgAddrReq;
	reg [1:0] cfgNumBytes = 0;
	reg [7:0] cfgSzReqBits;
	reg [2:0] waitCnt = 6;
	
	wire [15:0] cfgInstr = {cfgReqRd, cfgNumBytes, cfgAddrReq};
	
	always @(posedge clk40) begin
		spiClkLvl <= ~spiClkLvl;
		adcSpiClkG <= ~spiClkLvl && cfgActive && (~cfgReqDev & 3'b001);
		vgaSpiClkG <= ~spiClkLvl && cfgActive && (~cfgReqDev & 3'b110);

		if (~axiResetN) begin
			{spi_vga_cs34_b, spi_vga_cs12_b, spi_adc_cs_b} <= 3'b111;
			cfgActive <= 0;
			adc_spi_we <= 0;
		end else if (spiClkLvl) begin
			if (waitCnt)
				waitCnt <= waitCnt - 1;
			else if (~cfgActive) begin
				{spi_vga_cs34_b, spi_vga_cs12_b, spi_adc_cs_b} <= 3'b111;
				adc_spi_we <= 0;
				if (cfgReq) begin
					instrCtr <= 0;
					bitCtr <= 0;
					addrDone <= 0;
					cfgActive <= 1;
					waitCnt <= 1;
				end
			end else if (instrCtr < 16) begin
				// drop cs and output address
				{spi_vga_cs34_b, spi_vga_cs12_b, spi_adc_cs_b} <= cfgReqDev;
				adc_spi_we <= cfgReqDev == 6;
				
				if (cfgReqDev == 6) begin
					// we are talking to the adc. need a full 16 bit instruction phase
					spi_adc_do <= cfgInstr[15-instrCtr];
					instrCtr <= instrCtr + 1;
				end else begin
					// we are talking to a vga. only one instruction bit (r/w)
					spi_vga_do <= ~cfgInstr[15-instrCtr]; // rw bit is inverted w.r.t. adc
					instrCtr <= 16; // move on to data phase
				end
			end else if (bitCtr < cfgSzReqBits) begin
				// if this is a write, write data
				{spi_vga_cs34_b, spi_vga_cs12_b, spi_adc_cs_b} <= cfgReqDev;
				addrDone <= 1;
				
				adc_spi_we <= ~cfgReqRd && (cfgReqDev == 6);
				if (~cfgReqRd) begin
					spi_adc_do <= (cfgReqDev == 6) ? adcOutputBuffer[7-bitCtr] : 0;
					spi_vga_do <= (cfgReqDev == 6) ? 0 : vgaSettingsOutput[bitCtr];
				end
					
				bitCtr <= bitCtr + 1;
			end else if (bitCtr == cfgSzReqBits) begin
				// raise cs
				addrDone <= 0;
				{spi_vga_cs34_b, spi_vga_cs12_b, spi_adc_cs_b} <= 3'b111;
				adc_spi_we <= 0;
				spi_adc_do <= 0;
				spi_vga_do <= 0;
				spiCmdsCompleted <= spiCmdsCompleted + 1;
				
				bitCtr <= bitCtr + 1;
			end else begin
				{spi_vga_cs34_b, spi_vga_cs12_b, spi_adc_cs_b} <= 3'b111;
				adc_spi_we <= 0;
				cfgActive <= 0;
			end
		end
	end
	
	always @(posedge clk40) begin
		// read spi
		if (cfgActive && cfgReqRd && addrDone && ~spiClkLvl) begin
			if (cfgReqDev == 6) begin
				// we are reading from the adc
				if (bitCtr < 9)
					adcReadbackBuf[8-bitCtr] <= spi_adc_di;
			end else if (bitCtr < 16) begin
				if (cfgReqDev == 5)
					// we are reading from vga12
					vga12SettingsReadback[bitCtr-1] <= spi_vga_miso_b;
				else
					// we are reading from vga34
					vga34SettingsReadback[bitCtr-1] <= spi_vga_miso_b;
			end
		end
	end
	
	
	// axi config slave
	// receives configuration data and commands from host
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0ReadAddress;
	reg [SAXIL_CFG_DATA_WIDTH-1:0] s0ReadData = 0;
	wire s0WriteActive;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0WriteAddress;
	wire [SAXIL_CFG_DATA_WIDTH-1:0] s0WriteData;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0WActiveWriteAddress = (axiResetN && s0WriteActive) ? s0WriteAddress : 0;
	
	reg [7:0] cfgStep = 0;
	reg usrTestPatternReq = 0;
	
	wire calInProgress_c40;
	SBCCi calInProgress_crss(.srcV(calInProgress), .srcClk(sampleClk), .dstV(calInProgress_c40), .dstClk(clk40));
	
	assign cfgInProgress = cfgActive || cfgStep || cfgReq;
	
	assign sampleClkPllDrpClk = clk40;
	assign sampleClkPllDrpWe = (s0WActiveWriteAddress == 84) && (s0WriteData == 45873);
	
	always @(posedge clk40) begin
		if (~axiResetN) begin
			cfgReq <= 0;
			cfgStep <= 1;
			vgaSettingsOutput = VGA_DEFAULT_SETTINGS;
			usrReqReset <= 0;
			usrTestPatternReq <= 0;
			testPatternOn <= 0;
		end else begin
			
			if ((s0ReadAddress >= 20) && (s0ReadAddress <= 48))
				s0ReadData <= {5'd0, lastGoodDelVal[(s0ReadAddress-20)>>2], firstGoodDelVal[(s0ReadAddress-20)>>2], delayVal[(s0ReadAddress-20)>>2]};
			else case (s0ReadAddress)
				0: s0ReadData <= 32'hADC1_ADC4;
				//4: spi cmd
				8: s0ReadData <= vgaSettingsOutput;
				12: s0ReadData <= {1'b0,vga34SettingsReadback,1'b0,vga12SettingsReadback};
				16: s0ReadData <= {24'd0,adcReadbackBuf};
				//20 - 48 delay cal info
				52: s0ReadData <= {31'd0,usrReqCal};
				56: s0ReadData <= {31'd0,usrTestPatternReq};
				60: s0ReadData <= {7'd0, calBitNum, testPatternOn, calInProgress_c40, spiCmdsCompleted, calRunsCompleted};
				64: s0ReadData <= {31'd0,usrReqReset};
				68: s0ReadData <= fclkRate;
				76: s0ReadData <= {31'd0,pwrdwn_b_cpy};
				80: s0ReadData <= {sampleClkPllDrpDi, 9'd0, sampleClkPllDrpAddr};
				84: s0ReadData <= {pllLocked, sampleClkPllDrpRdy, sampleClkPllDrpDo};
				88: s0ReadData <= boardRev;
				default: s0ReadData <= 32'h1331_1331;
			endcase
			
				
			if (s0WriteActive && (s0WriteAddress == 8) && (s0WriteData == 32'hFFFF_FFFF))
				vgaSettingsOutput = VGA_DEFAULT_SETTINGS;
			else if (s0WriteActive && (s0WriteAddress == 8))
				vgaSettingsOutput <= s0WriteData[14:0];
			
			if (s0WriteActive && (s0WriteAddress == 52))
				usrReqCal <= s0WriteData[0];
			else if (calInProgress_c40)
				usrReqCal <= 0;
			
			case (s0WActiveWriteAddress)
				56: usrTestPatternReq <= s0WriteData[0];
				64: usrReqReset <= s0WriteData[0];
				76: {pwrdwn_b,pwrdwn_b_cpy} <= {2{s0WriteData[0]}};
				80: begin
					sampleClkPllDrpAddr <= s0WriteData[6:0];
					sampleClkPllDrpDi <= s0WriteData[31:16];
				end
			//	84: PLL DRP OutputsS
			endcase
			
			// configuration state machine
			if (cfgActive)
				// configuration in progress. deassert start request
				cfgReq <= 0;
			else if (cfgReq)
				// waiting for request to be ackd
				cfgReq <= 1;
			else if (cfgStep == 1) begin
				// program both vgas
				cfgReqDev <= 1; // vga12 and vga34
				cfgReqRd <= 0;
				cfgSzReqBits <= 15;
				
				// increment the state ctr and start the cfg step
				cfgStep <= cfgStep + 1;
				cfgReq <= 1;
			end else if (cfgStep == 2) begin
				// turn on adc reset
				cfgReqDev <= 6; // adc
				cfgReqRd <= 0;
				cfgSzReqBits <= 8;
				cfgAddrReq <= 13'h0008;
				cfgNumBytes  <= 0;
				adcOutputBuffer <= 8'h03;
				
				// increment the state ctr and start the cfg step
				cfgStep <= cfgStep + 1;
				cfgReq <= 1;
			end else if (cfgStep == 3) begin
				// turn off adc reset
				cfgReqDev <= 6; // adc
				cfgReqRd <= 0;
				cfgSzReqBits <= 8;
				cfgAddrReq <= 13'h0008;
				cfgNumBytes  <= 0;
				adcOutputBuffer <= 8'h00;
				
				// increment the state ctr and start the cfg step
				cfgStep <= cfgStep + 1;
				cfgReq <= 1;
			end else if (cfgStep == 4) begin
				// program adc data output mode
				cfgReqDev <= 6; // adc
				cfgReqRd <= 0;
				cfgSzReqBits <= 8;
				cfgAddrReq <= 13'h0021;
				cfgNumBytes  <= 0;
				adcOutputBuffer <= 8'h30; // LVDS output LSB first = 0, DDR two-lane bytewise, Select 2xframe = 0, 16 bits
				
				// increment the state ctr and start the cfg step
				cfgStep <= cfgStep + 1;
				cfgReq <= 1;
			end else if (cfgStep == 5) begin
				// read back vga 12
				cfgReqDev <= 5; // vga12
				cfgReqRd <= 1;
				cfgSzReqBits <= 15;
				
				// increment the state ctr and start the cfg step
				cfgStep <= cfgStep + 1;
				cfgReq <= 1;
			end else if (cfgStep == 6) begin
				// read back vga 34
				cfgReqDev <= 3; // vga34
				cfgReqRd <= 1;
				cfgSzReqBits <= 15;
				
				// increment the state ctr and start the cfg step
				cfgStep <= cfgStep + 1;
				cfgReq <= 1;
			end else if (cfgStep == 7) begin
				// read back adc data output mode
				cfgReqDev <= 6; // adc
				cfgReqRd <= 1;
				cfgSzReqBits <= 8;
				cfgAddrReq <= 13'h0021;
				cfgNumBytes  <= 0;
				
				// increment the state ctr and start the cfg step
				cfgStep <= cfgStep + 1;
				cfgReq <= 1;
			end else if (cfgStep == 98) begin
				cfgStep <= 0;
				testPatternOn <= 1;
			end else if ((calRqTestPattern || usrTestPatternReq) && ~testPatternOn) begin
				cfgReqDev <= 6; // adc
				cfgReqRd <= 0;
				cfgSzReqBits <= 8;
				cfgAddrReq <= 13'h000D;
				cfgNumBytes  <= 0;
				adcOutputBuffer <= 8'b00_00_1100;
				
				cfgStep <= 98;
				cfgReq <= 1;
			end else if (cfgStep == 99) begin
				cfgStep <= 0;
				testPatternOn <= 0;
			end else if (testPatternOn && ~(calRqTestPattern || usrTestPatternReq)) begin
				cfgReqDev <= 6; // adc
				cfgReqRd <= 0;
				cfgSzReqBits <= 8;
				cfgAddrReq <= 13'h000D;
				cfgNumBytes  <= 0;
				adcOutputBuffer <= 8'd0;
				
				cfgStep <= 99;
				cfgReq <= 1;
			end else if (cfgStep)
				// no more steps
				cfgStep <= 0;
			else if (cfgStep == 3) begin
				// program adc termination?
				// 0x15
				
				// increment the state ctr and start the cfg step
				cfgStep <= 0;
				//cfgStep <= cfgStep + 1;
				cfgReq <= 1;
			end else if (cfgStep == 4) begin
				// program adc Vref?
				// 0x18
				
				// increment the state ctr and start the cfg step
				cfgStep <= 0;
				//cfgStep <= cfgStep + 1;
				cfgReq <= 1;
			end else begin
				// configuration is done
				if (applyCfgReq || (s0WriteActive && (s0WriteAddress == 4) && (s0WriteData == 32'hFFFF_FFFF)))
					// full all device config request start the state machine
					cfgStep <= 1;
				else if (s0WriteActive && (s0WriteAddress == 4) && (s0WriteData == 32'hFFFF_FF12)) begin
					// program vga12
					cfgReqDev <= 5; // vga12
					cfgReqRd <= 0;
					cfgSzReqBits <= 15;
					cfgReq <= 1;
				end else if (s0WriteActive && (s0WriteAddress == 4) && (s0WriteData == 32'hFFFF_FE12)) begin
					// read back vga12
					cfgReqDev <= 5; // vga12
					cfgReqRd <= 1;
					cfgSzReqBits <= 15;
					cfgReq <= 1;
				end else if (s0WriteActive && (s0WriteAddress == 4) && (s0WriteData == 32'hFFFF_FF34)) begin
					// program vga34
					cfgReqDev <= 3; // vga34
					cfgReqRd <= 0;
					cfgSzReqBits <= 15;
					cfgReq <= 1;
				end else if (s0WriteActive && (s0WriteAddress == 4) && (s0WriteData == 32'hFFFF_FE34)) begin
					// read back vga34
					cfgReqDev <= 3; // vga34
					cfgReqRd <= 1;
					cfgSzReqBits <= 15;
					cfgReq <= 1;
				end else if (s0WriteActive && (s0WriteAddress == 4) && (s0WriteData == 32'hFFFF_FADC)) begin
					// program all settings to adc. use the state machine
					cfgStep <= 2;
				end else if (s0WriteActive && (s0WriteAddress == 4)) begin
					// single cfg request
					cfgReqDev <= 6; // adc
					cfgReqRd <= s0WriteData[21];
					cfgSzReqBits <= 8;
					cfgAddrReq <= s0WriteData[20:8];
					cfgNumBytes <= 0;
					adcOutputBuffer <= s0WriteData[7:0];
					cfgReq <= 1;
				end
			end
		end
	end
	
	
	// Inst SAXIL_CFG
	SAXIL #(.DATA_WIDTH(SAXIL_CFG_DATA_WIDTH), .ADDR_WIDTH(SAXIL_CFG_ADDR_WIDTH)) SAXIL_CFG_Inst (
		.ACLK(clk40),
		.ARESETN(axiResetN),
		
		.writeAddress(s0WriteAddress),
		.writeData(s0WriteData),
		.writeStrobe(),
		.writeActive(s0WriteActive),
		.readAddress(s0ReadAddress),
		.readData(s0ReadData),
		
		// SAXIL_CFG
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
		.SAXIL_RREADY(SAXIL_CFG_RREADY)
	);
	
	
endmodule
