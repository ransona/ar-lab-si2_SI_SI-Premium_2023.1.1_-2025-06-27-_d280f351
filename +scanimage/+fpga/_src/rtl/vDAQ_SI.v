//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQ_SI #(
	parameter NUM_DIO	= 32,
	parameter NUM_RTSI	= 16,
	parameter NUM_ECLK	= 1,
	parameter HSADC_SUPPORT = 0,
	parameter PHOTON_COUNTING_SUPPORT = 1,
	parameter ACCUM_MULTIPLY_SUPPORT = 1,
	parameter HSADC_LRR_SUPPORT = 0,
	parameter NO_MSADC_SUPPORT = 0,

	parameter NUM_AE	= 1,
	parameter DATA_FIFO_1_WIDTH	= 64,
	parameter DATA_FIFO_2_WIDTH	= 64,
	parameter AE_1_HS_NUM_LOGICAL_CHANNELS	= 32,
	parameter AE_2_HS_NUM_LOGICAL_CHANNELS	= 4,
	parameter AE_1_MS_NUM_LOGICAL_CHANNELS	= 8,
	parameter AE_2_MS_NUM_LOGICAL_CHANNELS	= 4,
	parameter AE_1_NUM_DIVIDERS	= 32,
	parameter AE_2_NUM_DIVIDERS	= 4,

	parameter SCOPE_FIFO_WIDTH	= 80,

	// don't make SAMPLE_PHASE_BITS higher than 16 without changing logic for configuration
	parameter SAMPLE_PHASE_BITS	= 14,

	parameter [16*8-1:0] GIT_HASH = ""
)(
	input  wire dataClk,
	input  wire hsadcDataClk,
	input  wire cfgClk,
	input  wire sysClk200,
	input  wire resetn_cc,
	output wire syncTrigReset,
	
	output wire afeClkSel,
	output wire sysClk200_en,
	output wire sysClk100_en,
	output wire ioClkH_oxen,
	output wire ioClkH_en,
	output wire ioClk40_en,
	output wire lsadcSpiClkEn,
	output wire lsdacSpiClkEn,
	
	input  wire [55:0] msadcSampleData,
	input  wire [383:0] hsadcSampleDataA,
	input  wire [383:0] hsadcSampleDataB,
	input  wire [(`HS_SAMPS_PER_TICK/2)-1:0] hsSyncTrigger,

	input  wire [NUM_ECLK+NUM_RTSI+NUM_DIO-1:0] DI,
	output wire [NUM_AE*9-1:0] DO,
	output wire [1:0]  LED,
	output wire [6*(16+NUM_DIO)-1:0] dioOuputMode,
	
	input  wire [11:0] PCIE_SAXIL_readAddress,
	output wire [31:0] PCIE_SAXIL_readData,
	input  wire [11:0] PCIE_SAXIL_writeAddress,
	input  wire [31:0] PCIE_SAXIL_writeData,
	input  wire [3:0] PCIE_SAXIL_writeStrobe,
	
	input  wire [NUM_AE-1:0] dataFifoFull,
	output wire [NUM_AE-1:0] dataFifoWriteEn,
	output wire [NUM_AE*6-1:0] dataFifoWriteWidth,
	output wire [DATA_FIFO_1_WIDTH+DATA_FIFO_2_WIDTH-1:0] dataFifoData,
	
	input  wire [NUM_AE-1:0] triggerFifoFull,
	output wire [NUM_AE-1:0] triggerFifoWriteEn,
	output wire [NUM_AE*80-1:0] triggerFifoData,
	
	input  wire scopeFifoFull,
	output wire scopeFifoWriteEn,
	output wire [5:0] scopeFifoWriteWidth,
	output wire [SCOPE_FIFO_WIDTH-1:0] scopeFifoData,
	
	input wire [3:0]  module_id,
	input wire [1:0]  TEMPERATURE_ALARMS,
	input wire [6:0]  VOLTAGE_ALARMS
);
	localparam SI_CFG_BASE_ADDR = 1024;
	localparam SI_CFG_ADDR_WIDTH = 1024;
	localparam DIO_BASE_ADDRESS = 400;
	localparam GIT_HASH_ADDRESS = 300;
	
	reg sysClk200_enR = 1;
	reg sysClk100_enR = 1;
	reg ioClkH_oxenR = 1;
	reg ioClkH_enR = 1;
	reg ioClk40_enR = 1;
	reg lsadcSpiClkEnR = 1;
	reg lsdacSpiClkEnR = 1;
	
	assign sysClk200_en = sysClk200_enR;
	assign sysClk100_en = sysClk100_enR;
	assign ioClkH_oxen = ioClkH_oxenR;
	assign ioClkH_en = ioClkH_enR;
	assign ioClk40_en = ioClk40_enR;
	assign lsadcSpiClkEn = lsadcSpiClkEnR;
	assign lsdacSpiClkEn = lsdacSpiClkEnR;

	//clock rate measurement
	wire [22:0] dataClk_rate_200;
	wire [22:0] dataClk_period;
	CLK_RATE_MEAS #(.MEAS_COUNTER_WIDTH(20),.RESULT_COUNTER_WIDTH(23)) dataClk_meas (
		.measClk(dataClk), .resultClk(sysClk200), .measClkPeriod(dataClk_rate_200)
	);
	SWCC #(.WW(23)) dataClk_rate_crss(.srcV(dataClk_rate_200), .srcClk(sysClk200), .dstV(dataClk_period), .dstClk(cfgClk), .dstRst(0));
	
	
	reg  [63:0] systemClock = 0;
	wire [63:0] systemClock_sc;
	wire [63:0] systemClock_cc;
	reg  [63:0] systemClockReg = 0;
	
	always @(posedge sysClk200)
		systemClock <= systemClock + 1;
		
	SWCC #(.WW(64)) clk_sc_crss(.srcV(systemClock), .srcClk(sysClk200), .dstV(systemClock_sc), .dstClk(dataClk), .dstRst(0));
	SWCC #(.WW(64)) clk_cc_crss(.srcV(systemClock), .srcClk(sysClk200), .dstV(systemClock_cc), .dstClk(cfgClk), .dstRst(0));
	
	// DIO sync
	wire [NUM_DIO-1:0] DIO_I_s;
	wire [15:0] RTSI_I_s;
	
	generate
		genvar dio_s_iter;
		genvar rtsi_s_iter;
		
		for (dio_s_iter = 0; dio_s_iter < NUM_DIO; dio_s_iter=dio_s_iter+1) begin:gen_dio_sync
			(* ASYNC_REG = "TRUE" *)
			reg [1:0] cc;
			
			always @(posedge cfgClk)
				cc <= {DI[dio_s_iter], cc[1]};
			
			assign DIO_I_s[dio_s_iter] = cc[0];
		end
		for (rtsi_s_iter = 0; rtsi_s_iter < 16; rtsi_s_iter=rtsi_s_iter+1) begin:gen_rtsi_sync
			(* ASYNC_REG = "TRUE" *)
			reg [1:0] cc;
			
			always @(posedge cfgClk)
				cc <= {DI[NUM_DIO + rtsi_s_iter], cc[1]};
			
			assign RTSI_I_s[rtsi_s_iter] = cc[0];
		end
	endgenerate
	
	
	// DIO PWM measurement
	reg [6:0] pwmMeasChan = 63;
	wire dioMeasSig = DI[pwmMeasChan];
	
	reg [4:0] pwmMeasDebounce = 0;
	reg [11:0] pwmMeasDebounceCtr = 0;
	
	reg [31:0] pwmMeasPeriodMax = 60000000;
	reg [31:0] pwmMeasPeriodTmp = 0;
	
	reg [31:0] pwmMeasPeriod = 0;
	reg [31:0] pwmMeasHighTime = 0;
	
	wire pwmRisingEdge;
	wire pwmFallingEdge;
	
	inputDebounce pwmInputDeb(.clk(sysClk200), .sigIn(dioMeasSig), .sigOutRE(pwmRisingEdge), .sigOutFE(pwmFallingEdge), .debounceTime(pwmMeasDebounce));
	
	always @(posedge sysClk200) begin
		// measure 
		if (pwmRisingEdge)
			pwmMeasPeriodTmp <= 1;
		else if (~(&pwmMeasPeriodTmp))
			pwmMeasPeriodTmp <= pwmMeasPeriodTmp + 1;
		
		if (pwmRisingEdge || (pwmMeasPeriodTmp >= pwmMeasPeriodMax))
			// rising edge or timed out waiting for rising edge. latch result and reset counter
			pwmMeasPeriod <= pwmMeasPeriodTmp;
		
		// measure high time
		if (pwmFallingEdge)
			pwmMeasHighTime <= pwmMeasPeriodTmp;
	end
	
	wire [31:0] pwmMeasPeriod_ac;
	wire [31:0] pwmMeasHighTime_ac;
	SWCC #(.WW(32)) pwmMeasPeriod_crss(.srcV(pwmMeasPeriod), .srcClk(sysClk200), .dstV(pwmMeasPeriod_ac), .dstClk(cfgClk), .dstRst(0));
	SWCC #(.WW(32)) pwmMeasHighTime_crss(.srcV(pwmMeasHighTime), .srcClk(sysClk200), .dstV(pwmMeasHighTime_ac), .dstClk(cfgClk), .dstRst(0));
	
	
	// LED control
	wire anyVoltageAlarm = |VOLTAGE_ALARMS;
	reg [27:0] voltageAlmCtr = 0;
	wire voltageAlmCtrMax = &voltageAlmCtr;
	reg [1:0] LED_usr_force_on = 0;
	reg [1:0] LED_usr_force_off = 0;
	assign LED[0] = LED_usr_force_on[0] || ((|TEMPERATURE_ALARMS) && ~LED_usr_force_off[0]);
	assign LED[1] = LED_usr_force_on[1] || (voltageAlmCtrMax && ~LED_usr_force_off[1]);
	
	
	// PCIE AXI
	reg [39:0] SYS_T = 0;
	reg [31:0] PCIE_SAXIL_readDataR = 0;
	wire [11:0] PCIE_SAXIL_ActiveWriteAddress = (resetn_cc && PCIE_SAXIL_writeStrobe) ? PCIE_SAXIL_writeAddress : 0;
	assign PCIE_SAXIL_readData = PCIE_SAXIL_readDataR;
	
	wire [31:0] siCfgReadData;

	
	// 0-input, 1-outputL, 2-outputH,  3-digitalSignals[v-3]
	reg [6*(16+NUM_DIO)-1:0] dioOuputModeR = 0;
	assign dioOuputMode = dioOuputModeR;

	reg [5:0] scopeFifoWriteWidthR = 9;
	assign scopeFifoWriteWidth = scopeFifoWriteWidthR;
	wire [31:0] scopeFifoWriteCount;
	wire [31:0] scopeFifoOverflowCount;

	reg afeSelect = 0;
	assign afeClkSel = afeSelect;

	reg syncTrigResetR = 0;
	assign syncTrigReset = syncTrigResetR;


	// Data scope signals
	reg [31:0] scopeParamNumberOfSamples = 0;
	reg [5:0]  scopeParamDecimationLB2 = 0;
	reg [4:0]  scopeParamTriggerId = 0;
	reg [31:0] scopeParamTriggerHoldoff = 0;
	reg [15:0] scopeParamTriggerLineNumber = 0;
	reg scopeParamAeSel = 0;
	reg hsChanSel = 0;

	// photon detect params
	reg [`HS_PHYS_CHANNEL_WIDTH*`HS_NUM_PHYS_CHANNELS-1:0] photonDetectThresholds = 0;
	reg [`HS_NUM_PHYS_CHANNELS-1:0] photonDetectInverts = 0;
	reg [`HS_NUM_PHYS_CHANNELS-1:0] photonDetectDiffs = 0;
	reg [15:0] photonDifferentiateOrders = 0;
	reg [1:0] photonDifferentiateDeadTime = 2'b11;
	reg [1:0] hsScopeProbePhotons = 0;

	// hs data reg
	reg  [383:0] hsadcSampleDataA_R = 0;
	reg  [383:0] hsadcSampleDataB_R = 0;

	// assign sample data regs
	always @(posedge hsadcDataClk) begin
		hsadcSampleDataA_R <= hsadcSampleDataA;
		hsadcSampleDataB_R <= hsadcSampleDataB;
	end

	// sync trigger user parameters
	reg [SAMPLE_PHASE_BITS-1:0] hsSyncTrigPhaseShift = 0;  // the phase shift parameter for LRR phase correction
	reg hsSyncTrigIgnorePhysical = 0;                      // the switch for ignoring physical sync trigger and free running the pseudoclock instead
	reg [SAMPLE_PHASE_BITS-1:0] laserClkPeriodSamples = 32;  // the period of the laser (size samplephasebits)
	// note that hsSyncTrigPhaseShift is now used for sync trigger inversion as well (inversion is a 90 degree phase shift)

	// CfgClk (cc) clock transforms
	wire hsSyncTrigIgnorePhysical_cc;
	SBCC hsSyncTrigIgnorePhysical_crss(.srcV(hsSyncTrigIgnorePhysical), .srcClk(cfgClk), .dstV(hsSyncTrigIgnorePhysical_cc), .dstClk(hsadcDataClk));

	wire [SAMPLE_PHASE_BITS-1:0] hsSyncTrigPhaseShift_cc;
	SWCC #(.WW(SAMPLE_PHASE_BITS)) hsSyncTrigPhaseShift_crss(.srcV(hsSyncTrigPhaseShift), .srcClk(cfgClk), .dstV(hsSyncTrigPhaseShift_cc), .dstClk(hsadcDataClk), .dstRst(0));

	wire [SAMPLE_PHASE_BITS-1:0] laserClkPeriodSamples_cc;
	SWCC #(.WW(SAMPLE_PHASE_BITS)) laserClkPeriodSamples_crss(.srcV(laserClkPeriodSamples), .srcClk(cfgClk), .dstV(laserClkPeriodSamples_cc), .dstClk(hsadcDataClk), .dstRst(0));

	// packed version of samplePhase for downstream transfer
	wire [(SAMPLE_PHASE_BITS*`HS_SAMPS_PER_TICK)-1:0] samplePhasePacked;

	SI_SamplePhase #(.SAMPLE_PHASE_BITS(SAMPLE_PHASE_BITS)) samplePhase (
		.hsSyncTrigger(hsSyncTrigger),
		.hsadcDataClk(hsadcDataClk),
		.hsSyncTrigPhaseShift(hsSyncTrigPhaseShift_cc),
		.hsSyncTrigIgnorePhysical(hsSyncTrigIgnorePhysical_cc),
		.laserClkPeriodSamples(laserClkPeriodSamples_cc),
		.samplePhasePacked(samplePhasePacked)
	);


	// PCIE AXI
	always @(posedge cfgClk) begin
	
		if (anyVoltageAlarm && ~voltageAlmCtrMax)
			voltageAlmCtr <= voltageAlmCtr + 1;
		else if (~anyVoltageAlarm)
			voltageAlmCtr <= 0;
		
		// handle DIO requests
		if ((PCIE_SAXIL_ActiveWriteAddress >= DIO_BASE_ADDRESS) && (PCIE_SAXIL_ActiveWriteAddress < (DIO_BASE_ADDRESS + 4*(16+NUM_DIO))))
			dioOuputModeR[((PCIE_SAXIL_writeAddress-DIO_BASE_ADDRESS)/4)*6+:6] <= PCIE_SAXIL_writeData;
		if ((PCIE_SAXIL_readAddress >= DIO_BASE_ADDRESS) && (PCIE_SAXIL_readAddress < (DIO_BASE_ADDRESS + 4*(16+NUM_DIO))))
			PCIE_SAXIL_readDataR <= dioOuputModeR[((PCIE_SAXIL_readAddress-DIO_BASE_ADDRESS)/4)*6+:6];

		// handle SI AcquisitionEngine configuration requests
		else if ((PCIE_SAXIL_readAddress > SI_CFG_BASE_ADDR) && ((PCIE_SAXIL_readAddress-SI_CFG_BASE_ADDR) < (SI_CFG_ADDR_WIDTH * NUM_AE)))
			PCIE_SAXIL_readDataR <= siCfgReadData;

		// handle reading git hash
		else if ((PCIE_SAXIL_readAddress >= GIT_HASH_ADDRESS) && (PCIE_SAXIL_readAddress < (GIT_HASH_ADDRESS + 16)))
			PCIE_SAXIL_readDataR <= GIT_HASH[(PCIE_SAXIL_readAddress-GIT_HASH_ADDRESS)*8+:32];

		else case (PCIE_SAXIL_readAddress)
			0:  PCIE_SAXIL_readDataR <= SYS_T[39:8];
			
			4:	PCIE_SAXIL_readDataR <= dataClk_period;
			
			8:	PCIE_SAXIL_readDataR <= systemClockReg[31:0];
			
			12:	PCIE_SAXIL_readDataR <= systemClockReg[63:32];

			16: PCIE_SAXIL_readDataR <= NUM_AE;
			
			20: PCIE_SAXIL_readDataR <= {LED_usr_force_off, LED_usr_force_on};
			
			24: PCIE_SAXIL_readDataR <= DIO_I_s;
			
			28: PCIE_SAXIL_readDataR <= RTSI_I_s;
			
			32: PCIE_SAXIL_readDataR <= afeSelect;
			
			36: PCIE_SAXIL_readDataR <= sysClk200_enR;
			
			40: PCIE_SAXIL_readDataR <= sysClk100_enR;
			
			44: PCIE_SAXIL_readDataR <= ioClkH_oxenR;
			
			48: PCIE_SAXIL_readDataR <= ioClkH_enR;
			
			52: PCIE_SAXIL_readDataR <= ioClk40_enR;
			
			56: PCIE_SAXIL_readDataR <= lsadcSpiClkEnR;
			
			60: PCIE_SAXIL_readDataR <= lsdacSpiClkEnR;
			
			64: PCIE_SAXIL_readDataR <= module_id;
			
			68: PCIE_SAXIL_readDataR <= syncTrigResetR;
			
			72: PCIE_SAXIL_readDataR <= {{4{photonDetectThresholds[`HS_PHYS_CHANNEL_WIDTH*2-1]}}, photonDetectThresholds[`HS_PHYS_CHANNEL_WIDTH+:`HS_PHYS_CHANNEL_WIDTH], {4{photonDetectThresholds[`HS_PHYS_CHANNEL_WIDTH-1]}},photonDetectThresholds[0+:`HS_PHYS_CHANNEL_WIDTH]};
			
			76: PCIE_SAXIL_readDataR <= photonDetectInverts;
			
			80: PCIE_SAXIL_readDataR <= photonDetectDiffs;
			
			84: PCIE_SAXIL_readDataR <= hsScopeProbePhotons;
			
			92: PCIE_SAXIL_readDataR <= pwmMeasChan;
			
			96: PCIE_SAXIL_readDataR <= pwmMeasDebounce;
			
			100: PCIE_SAXIL_readDataR <= pwmMeasPeriodMax;
			
			104: PCIE_SAXIL_readDataR <= pwmMeasPeriod_ac;
			
			108: PCIE_SAXIL_readDataR <= pwmMeasHighTime_ac;
			
			112: PCIE_SAXIL_readDataR <= photonDifferentiateOrders;
			
			116: PCIE_SAXIL_readDataR <= photonDifferentiateDeadTime;

		//	140: data scope ctl
			
			144: PCIE_SAXIL_readDataR <= scopeFifoWriteWidthR;

			148: PCIE_SAXIL_readDataR <= scopeFifoWriteCount;

			152: PCIE_SAXIL_readDataR <= scopeFifoOverflowCount;
			
			156: PCIE_SAXIL_readDataR <= scopeParamNumberOfSamples;

			160: PCIE_SAXIL_readDataR <= scopeParamDecimationLB2;

			164: PCIE_SAXIL_readDataR <= scopeParamTriggerId;
			
			168: PCIE_SAXIL_readDataR <= scopeParamTriggerHoldoff;

			172: PCIE_SAXIL_readDataR <= scopeParamAeSel;

			176: PCIE_SAXIL_readDataR <= hsChanSel;

			180: PCIE_SAXIL_readDataR <= hsSyncTrigPhaseShift;

			184: PCIE_SAXIL_readDataR <= hsSyncTrigIgnorePhysical;

			188: PCIE_SAXIL_readDataR <= laserClkPeriodSamples;

			192: PCIE_SAXIL_readDataR <= scopeParamTriggerLineNumber;

			196: PCIE_SAXIL_readDataR <= SAMPLE_PHASE_BITS;

			200: PCIE_SAXIL_readDataR <= `ACCUM_COEFFICIENT_FIXED_POINT_WIDTH;

			204: PCIE_SAXIL_readDataR <= `ACCUM_BITS;
			
			default:
				PCIE_SAXIL_readDataR <= 1337;
		endcase
		
		// handle clock reset request
		if (PCIE_SAXIL_writeStrobe && !PCIE_SAXIL_writeAddress)
			SYS_T <= {8'd0, PCIE_SAXIL_writeData};
		else
			SYS_T <= SYS_T + 1;
		
		
		case (PCIE_SAXIL_ActiveWriteAddress)
			8:	systemClockReg <= systemClock_cc;
		
			20: {LED_usr_force_off, LED_usr_force_on} <= PCIE_SAXIL_writeData;
			
			32: afeSelect <= PCIE_SAXIL_writeData;
			
			36: sysClk200_enR <= PCIE_SAXIL_writeData;
			
			40: sysClk100_enR <= PCIE_SAXIL_writeData;
			
			44: ioClkH_oxenR <= PCIE_SAXIL_writeData;
			
			48: ioClkH_enR <= PCIE_SAXIL_writeData;
			
			52: ioClk40_enR <= PCIE_SAXIL_writeData;
			
			56: lsadcSpiClkEnR <= PCIE_SAXIL_writeData;
			
			60: lsdacSpiClkEnR <= PCIE_SAXIL_writeData;
			
		//	64: module_id
			
			68:	syncTrigResetR <= PCIE_SAXIL_writeData;
			
			72:	begin
				photonDetectThresholds[0+:`HS_PHYS_CHANNEL_WIDTH] <= PCIE_SAXIL_writeData[0+:`HS_PHYS_CHANNEL_WIDTH];
				photonDetectThresholds[`HS_PHYS_CHANNEL_WIDTH+:`HS_PHYS_CHANNEL_WIDTH] <= PCIE_SAXIL_writeData[16+:`HS_PHYS_CHANNEL_WIDTH];
			end
			
			76:	photonDetectInverts <= PCIE_SAXIL_writeData;
			
			80:	photonDetectDiffs <= PCIE_SAXIL_writeData;
			
			84:	hsScopeProbePhotons <= PCIE_SAXIL_writeData;
			
			92: pwmMeasChan <= PCIE_SAXIL_writeData;
			
			96: pwmMeasDebounce <= PCIE_SAXIL_writeData;
			
			100: pwmMeasPeriodMax <= PCIE_SAXIL_writeData;
			
			112: photonDifferentiateOrders <= PCIE_SAXIL_writeData;
			
			116: photonDifferentiateDeadTime <= PCIE_SAXIL_writeData;

		//	140: data scope ctl
			
			144: scopeFifoWriteWidthR <= PCIE_SAXIL_writeData;

		//	148: scopeFifoWriteCount

		//	152: scopeFifoOverflowCount
			
			156: scopeParamNumberOfSamples <= PCIE_SAXIL_writeData;

			160: scopeParamDecimationLB2 <= PCIE_SAXIL_writeData;

			164: scopeParamTriggerId <= PCIE_SAXIL_writeData;
			
			168: scopeParamTriggerHoldoff <= PCIE_SAXIL_writeData;

			172: scopeParamAeSel <= PCIE_SAXIL_writeData;

			176: hsChanSel <= PCIE_SAXIL_writeData;

			180: hsSyncTrigPhaseShift <= PCIE_SAXIL_writeData;

			184: hsSyncTrigIgnorePhysical <= PCIE_SAXIL_writeData;

			188: laserClkPeriodSamples <= PCIE_SAXIL_writeData;

			192: scopeParamTriggerLineNumber <= PCIE_SAXIL_writeData;

		//	196: SAMPLE_PHASE_BITS

		//	200: `ACCUM_COEFFICIENT_FIXED_POINT_WIDTH

		//	204: `ACCUM_BITS

		endcase
	end


	wire resetn_dc;
	SBCC reset_crss(.srcV(resetn_cc), .srcClk(cfgClk), .dstV(resetn_dc), .dstClk(dataClk));


	// photon detectors
	wire [`HS_SAMPS_PER_TICK-1:0] hsPhotonPeaksA;
	wire [`HS_SAMPS_PER_TICK-1:0] hsPhotonPeaksB;

	generate
		genvar ph_i;
		
		if (HSADC_SUPPORT && PHOTON_COUNTING_SUPPORT) begin
			for (ph_i = 0; ph_i < `HS_NUM_PHYS_CHANNELS; ph_i=ph_i+1) begin:gen_ph_detect
					
				wire [`HS_SAMPS_PER_TICK-1:0] photonPeaks;

				(* KEEP_HIERARCHY = "YES" *)
				SI_PhotonDetect photonDetect (
					.dataClk(hsadcDataClk),

					.sampleData(ph_i ? hsadcSampleDataB : hsadcSampleDataA),

					.threshold(photonDetectThresholds[ph_i*`HS_PHYS_CHANNEL_WIDTH+:`HS_PHYS_CHANNEL_WIDTH]),
					.invert(photonDetectInverts[ph_i]),
					.differentiateMode(photonDetectDiffs[ph_i]),
					.differentiateOrder(photonDifferentiateOrders[ph_i*8+:8]),
					.differentiateDeadTime(photonDifferentiateDeadTime[ph_i]),
					
					.photonPeaks(photonPeaks)
				);
				
				if (ph_i)
					assign hsPhotonPeaksB = photonPeaks;
				else
					assign hsPhotonPeaksA = photonPeaks;

			end
		end else begin
			assign hsPhotonPeaksA = 0;
			assign hsPhotonPeaksB = 0;
		end
	endgenerate

	
	// SI instances
	wire [31:0] siCfgReadData_i[NUM_AE-1:0];
	assign siCfgReadData = siCfgReadData_i[(PCIE_SAXIL_readAddress - SI_CFG_BASE_ADDR) / SI_CFG_ADDR_WIDTH];

	wire [`TRIGGER_PROCESS_OUT_LSZ:0] ae_triggerProcessData[NUM_AE-1:0];
	wire [`STATE_MACHINE_OUT_LSZ:0] ae_stateMachineData[NUM_AE-1:0];
	wire [15:0] ae_acqStatusLinesDone[NUM_AE-1:0];
	
	generate
		genvar si_i;
		
		for (si_i = 0; si_i < NUM_AE; si_i=si_i+1) begin:gen_si_inst

			wire [1023:0] fifoDat;

			if (si_i)
				assign dataFifoData[DATA_FIFO_1_WIDTH+:DATA_FIFO_2_WIDTH] = fifoDat;
			else
				assign dataFifoData[0+:DATA_FIFO_1_WIDTH] = fifoDat;
			
			//(* KEEP_HIERARCHY = "YES" *)
			SI #(
				.CFG_BASE_ADDR(SI_CFG_BASE_ADDR+SI_CFG_ADDR_WIDTH*si_i),
				.NUM_DIO(NUM_DIO),
				.HS_NUM_LOGICAL_CHANNELS(si_i ? AE_2_HS_NUM_LOGICAL_CHANNELS : AE_1_HS_NUM_LOGICAL_CHANNELS),
				.MS_NUM_LOGICAL_CHANNELS(si_i ? AE_2_MS_NUM_LOGICAL_CHANNELS : AE_1_MS_NUM_LOGICAL_CHANNELS),    // cannot be higher than HS_NUM_LOGICAL_CHANNELS
				.NUM_DIVIDERS(si_i ? AE_2_NUM_DIVIDERS : AE_1_NUM_DIVIDERS),
				.HSADC_SUPPORT(HSADC_SUPPORT),
				.DATA_FIFO_WIDTH(si_i ? DATA_FIFO_2_WIDTH : DATA_FIFO_1_WIDTH),
				.ACCUM_MULTIPLY_SUPPORT(ACCUM_MULTIPLY_SUPPORT),
				.HSADC_LRR_SUPPORT(HSADC_LRR_SUPPORT),
				.SAMPLE_PHASE_BITS(SAMPLE_PHASE_BITS),
				.NO_MSADC_SUPPORT(NO_MSADC_SUPPORT)
			) hSI (
				.dataClk(dataClk),
				.hsadcDataClk(hsadcDataClk),
				.cfgClk(cfgClk),
				.resetn_dc(resetn_dc),
				
				.systemClock(systemClock_sc),
			
				.cfgWriteActive(|PCIE_SAXIL_writeStrobe),
				.cfgWriteAddr(PCIE_SAXIL_writeAddress),
				.cfgWriteData(PCIE_SAXIL_writeData),
				.cfgReadAddr(PCIE_SAXIL_readAddress),
				.cfgReadData(siCfgReadData_i[si_i]),
			
				.afeSelect(afeSelect),
				.msadcSampleData(msadcSampleData),
				.hsadcSampleDataA(hsadcSampleDataA_R),
				.hsadcSampleDataB(hsadcSampleDataB_R),
				.hsSyncTrigger(samplePhasePacked[SAMPLE_PHASE_BITS-1:0]),
				.hsPhotonPeaksA(hsPhotonPeaksA),
				.hsPhotonPeaksB(hsPhotonPeaksB),
			
				.DIO_I(DI),
				.digitalTriggersOut(DO[9*si_i+:9]),
				.acqStatusLinesDone(ae_acqStatusLinesDone[si_i]),
			
				.dataFifoFull(dataFifoFull[si_i]),
				.dataFifoWriteEn(dataFifoWriteEn[si_i]),
				.dataFifoWriteWidth(dataFifoWriteWidth[si_i*6+:6]),
				.dataFifoData(fifoDat),
			
				.triggerFifoFull(triggerFifoFull[si_i]),
				.triggerFifoWriteEn(triggerFifoWriteEn[si_i]),
				.triggerFifoData(triggerFifoData[si_i*80+:80]),

				.scopeTriggerProcessDataOut(ae_triggerProcessData[si_i]),
				.scopeStateMachineDataOut(ae_stateMachineData[si_i]),

				.samplePhasePacked(samplePhasePacked)
			);

		end
	endgenerate
	
	
	// Data scope
	wire resetSampleScope_cc = (PCIE_SAXIL_ActiveWriteAddress == 140) && (PCIE_SAXIL_writeData == 51);
	wire resetSampleScope_sc;
	wire resetSampleScope = ~resetn_dc || resetSampleScope_sc;
	OSCC resetSS_crss(.srcV(resetSampleScope_cc),. srcClk(cfgClk), .dstV(resetSampleScope_sc), .dstClk(dataClk));

	wire startSampleScope;
	OSCC startSS_crss(.srcV((PCIE_SAXIL_ActiveWriteAddress == 140) && (PCIE_SAXIL_writeData == 52)), .srcClk(cfgClk), .dstV(startSampleScope), .dstClk(dataClk));
	
	//(* KEEP_HIERARCHY = "YES" *)
	SI_DataScope #(
		.HSADC_SUPPORT(HSADC_SUPPORT),
		.FIFO_WIDTH(SCOPE_FIFO_WIDTH)
	) dataScope (
		.dataClk(dataClk),
		.hsadcDataClk(hsadcDataClk),
		
		.reset(resetSampleScope),
		.start(startSampleScope),
		
		.numberOfSamples(scopeParamNumberOfSamples),
		.sampleDecimationLB2(scopeParamDecimationLB2),
		.triggerId(scopeParamTriggerId),
		.triggerHoldoff(scopeParamTriggerHoldoff),
		.triggerLineNumber(scopeParamTriggerLineNumber),
		.customTrigger(0),
		
		.afeSelect(afeSelect),
		.msadcSampleData(msadcSampleData),
		.hsadcSampleDataA(hsadcSampleDataA),
		.hsadcSampleDataB(hsadcSampleDataB),
		.hsScopeProbePhotons(hsScopeProbePhotons),
		.hsPhotonPeaksA(hsPhotonPeaksA),
		.hsPhotonPeaksB(hsPhotonPeaksB),
		.hsChanSel(hsChanSel),
		.hsFirstSamplePhase(samplePhasePacked[SAMPLE_PHASE_BITS-1:0]),

		.triggerProcessData(ae_triggerProcessData[scopeParamAeSel]),
		.stateMachineDataIn(ae_stateMachineData[scopeParamAeSel]),
		.stateMachineCurrLine(ae_acqStatusLinesDone[scopeParamAeSel]),
		.dataValidIn(1),
		
		.fifoFull(scopeFifoFull),
		.fifoWriteEn(scopeFifoWriteEn),
		.fifoWriteData(scopeFifoData),
		.fifoWriteCount(scopeFifoWriteCount),
		.fifoOverflowCount(scopeFifoOverflowCount)
	);

	
endmodule
