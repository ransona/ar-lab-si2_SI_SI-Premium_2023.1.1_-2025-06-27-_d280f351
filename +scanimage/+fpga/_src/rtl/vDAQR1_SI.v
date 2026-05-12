//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQR1_SI #(
	parameter LRR_ENABLED = 0,
	parameter [16*8-1:0] GIT_HASH = ""
)(
	// vDAQ_PCIE_AXI Interface
	output wire [749:0] PCIE_AXI_I,
	input  wire [699:0] PCIE_AXI_O,
	input  wire pcie_aclk,
	input  wire pcie_aresetn,

	output wire ioClk80OxEn,
	output wire ioClk80En,
	input  wire ioClk80,
	input  wire auxClkIn,
	
	input  wire [31:0] DIO_I,
	output wire [31:0] DIO_O,
	output wire [17:0] DIO_OE,
	input  wire [15:0] RTSI_I,
	output wire [15:0] RTSI_O,
	output wire [15:0] RTSI_OE,
	output wire [1:0]  LED,
	
	output wire SYNC_TRIGGER_clk,
	output wire SYNC_TRIGGER_reset,
	input  wire [15:0] SYNC_TRIGGER_i,
	
	output wire [240:0] LSDAC_FW_IO,
	output wire [12:0] LSADC_FW_I,
	input  wire [204:0] LSADC_FW_O,
	output wire [5:0] CLKCFG_FW_I,
	input  wire CLKCFG_FW_O,
	
	output wire [3:0]  MODULE_ID,
	
	input wire [1:0] TEMPERATURE_ALARMS,
	input wire [9:0] TEMPERATURE_DATA,
	input wire [6:0] VOLTAGE_ALARMS,
	input wire THERMAL_PD,
	
	
	// User App IO
	input  wire [3:0]  MODULE_ID_IO,
	
	input  wire SYS_CLK_200_N,
	input  wire SYS_CLK_200_P,

	inout  wire [30:0] MSADC_BOARD_IO,
	inout  wire [18:0] HSADC_BOARD_IO,
	input  wire [15:0] HSADC_GTH_RX
);
	localparam NUM_AE = 2;
	localparam DATA_FIFO_1_WIDTH = 512;
	localparam DATA_FIFO_2_WIDTH = 64;
	localparam SCOPE_FIFO_WIDTH = 424;

	wire sysClk200_en;
	wire sysClk200in;
	wire sysClk200;
	
	wire ioClk40_en;
	wire ioClk40;

	wire afeClkSel;
	wire msadcSampleClk;
	wire hsadcDataClk;
	wire dataClk;
	
	wire lsadcSpiClkEn;
	wire lsdacSpiClkEn;
	
	IBUFDS sysClk200iBuf(.I(SYS_CLK_200_P), .IB(SYS_CLK_200_N), .O(sysClk200in));
	BUFGCE sysClk200Buf(.I(sysClk200in), .O(sysClk200), .CE(sysClk200_en && ~THERMAL_PD));
	BUFGCE_DIV #(.BUFGCE_DIVIDE(2)) clk40bufg (.I(ioClk80), .O(ioClk40), .CE(ioClk40_en && ~THERMAL_PD));
	

	IBUF module_id_buf_0(.I(MODULE_ID_IO[0]), .O(MODULE_ID[0]));
	IBUF module_id_buf_1(.I(MODULE_ID_IO[1]), .O(MODULE_ID[1]));
	IBUF module_id_buf_2(.I(MODULE_ID_IO[2]), .O(MODULE_ID[2]));
	IBUF module_id_buf_3(.I(MODULE_ID_IO[3]), .O(MODULE_ID[3]));
	
	
	// DIO arbitration and io
	wire [8:0] si_DO[NUM_AE-1:0];
	wire [7:0] digitalTask0Lines;
	wire [7:0] digitalTask1Lines;
	wire [7:0] digitalTask2Lines;
	wire [7:0] digitalTask3Lines;
	wire [49:0] digitalSignals = {digitalTask3Lines, digitalTask2Lines, digitalTask1Lines, digitalTask0Lines, si_DO[1], si_DO[0]};
	
	// 0-input, 1-outputL, 2-outputH,  3-digitalSignals[v-3]
	wire [287:0] dioOuputMode;
	
	assign DIO_OE[17:16] = 2'b10;
	
	generate
		genvar dio_iter;
		genvar rtsi_iter;
		
		for (dio_iter = 0; dio_iter < 32; dio_iter=dio_iter+1) begin:gen_dio
			wire [5:0] myMode = dioOuputMode[dio_iter*6+:6];
			wire myModeIsSpcl = myMode > 2;
			wire [5:0] spclAssignment = myMode-3;
			wire spclSig = digitalSignals[spclAssignment];
			wire myModeIsI2cAck = (spclAssignment == 8) || (spclAssignment == 17);
			
			if (dio_iter < 16)
				assign DIO_OE[dio_iter] = myModeIsI2cAck ? spclSig : myMode > 0;
			assign DIO_O[dio_iter] = myModeIsI2cAck ? 0 : ((myMode == 2) || (myModeIsSpcl && spclSig));
		end
		
		for (rtsi_iter = 0; rtsi_iter < 16; rtsi_iter=rtsi_iter+1) begin:gen_rtsi
			wire [5:0] myMode = dioOuputMode[(rtsi_iter+32)*6+:6];
			wire myModeIsSpcl = myMode > 2;
			wire [5:0] spclAssignment = myMode-3;
			
			assign RTSI_OE[rtsi_iter] = myMode > 0;
			assign RTSI_O[rtsi_iter] = (myMode == 2) || (myModeIsSpcl && digitalSignals[spclAssignment]);
		end
	endgenerate
	
	
	// PCIE AXI
	wire [11:0] PCIE_SAXIL_readAddress;
	wire [31:0] PCIE_SAXIL_readData;
	wire [11:0] PCIE_SAXIL_writeAddress;
	wire [31:0] PCIE_SAXIL_writeData;
	wire [3:0] PCIE_SAXIL_writeStrobe;

	reg aresetn = 0;
	always @(posedge pcie_aclk)
		aresetn <= pcie_aresetn;
	

	// AFE Clock mux
	BUFGMUX #(.CLK_SEL_TYPE("ASYNC")) afeClk_mux (
		.O(dataClk), // 1-bit output: Clock output
		.I0(msadcSampleClk), // 1-bit input: Clock input (S=0)
		.I1(hsadcDataClk), // 1-bit input: Clock input (S=1)
		.S(afeClkSel) // 1-bit input: Clock select
	);


	// Sync trigger
	assign SYNC_TRIGGER_clk = dataClk;
	wire extClkIn = |SYNC_TRIGGER_i[7:0];
	wire syncTrigReset;
	SBCC syncTrigRsetCrss(.srcV(syncTrigReset), .srcClk(pcie_aclk), .dstV(SYNC_TRIGGER_reset), .dstClk(dataClk));


	// SI Inst
	wire [NUM_AE-1:0] dataFifoFull;
	wire [NUM_AE-1:0] dataFifoWriteEn;
	wire [NUM_AE*6-1:0] dataFifoWriteWidth;
	wire [DATA_FIFO_1_WIDTH+DATA_FIFO_2_WIDTH-1:0] dataFifoData;
	
	wire [NUM_AE-1:0] triggerFifoFull;
	wire [NUM_AE-1:0] triggerFifoWriteEn;
	wire [NUM_AE*80-1:0] triggerFifoData;
	
	wire scopeFifoFull;
	wire scopeFifoWriteEn;
	wire [5:0] scopeFifoWriteWidth;
	wire [SCOPE_FIFO_WIDTH-1:0] scopeFifoData;
	
	wire [55:0] msadcSampleData;
	wire [383:0] hsadcSampleDataA;
	wire [383:0] hsadcSampleDataB;

	localparam AE_1_NUM_DIVIDERS       = (LRR_ENABLED) ? 16 : 24;
	localparam SAMPLE_PHASE_BITS       = (LRR_ENABLED) ? 14 : 12;
	localparam PHOTON_COUNTING_SUPPORT = !LRR_ENABLED;
	
	(* DONT_TOUCH = "true" *)
	vDAQ_SI #(
		.NUM_DIO(32),
		.NUM_AE(2),
		.AE_1_HS_NUM_LOGICAL_CHANNELS(32),
		.AE_1_MS_NUM_LOGICAL_CHANNELS(8),
		.AE_1_NUM_DIVIDERS(32),
		.AE_2_HS_NUM_LOGICAL_CHANNELS(8),
		.AE_2_MS_NUM_LOGICAL_CHANNELS(4),
		.AE_2_NUM_DIVIDERS(8),
		.HSADC_SUPPORT(1),
		.PHOTON_COUNTING_SUPPORT(PHOTON_COUNTING_SUPPORT),
		.DATA_FIFO_1_WIDTH(DATA_FIFO_1_WIDTH),
		.DATA_FIFO_2_WIDTH(DATA_FIFO_2_WIDTH),
		.SCOPE_FIFO_WIDTH(SCOPE_FIFO_WIDTH),
		.ACCUM_MULTIPLY_SUPPORT(1),
		.HSADC_LRR_SUPPORT(LRR_ENABLED),
		.SAMPLE_PHASE_BITS(SAMPLE_PHASE_BITS),
		.GIT_HASH(GIT_HASH)
	) vDAQ_SI_Inst (
		.dataClk(dataClk),
		.hsadcDataClk(hsadcDataClk),
		.cfgClk(pcie_aclk),
		.sysClk200(sysClk200),
		.resetn_cc(aresetn),
		.syncTrigReset(syncTrigReset),
		
		.afeClkSel(afeClkSel),
		.sysClk200_en(sysClk200_en),
		.ioClkH_oxen(ioClk80OxEn),
		.ioClkH_en(ioClk80En),
		.ioClk40_en(ioClk40_en),
		.lsadcSpiClkEn(lsadcSpiClkEn),
		.lsdacSpiClkEn(lsdacSpiClkEn),

		.msadcSampleData(msadcSampleData),
		.hsadcSampleDataA(hsadcSampleDataA),
		.hsadcSampleDataB(hsadcSampleDataB),
		.hsSyncTrigger(SYNC_TRIGGER_i),
	
		.DI({extClkIn, RTSI_I, DIO_I}),
		.DO({si_DO[1], si_DO[0]}),
		.LED(LED),
		.dioOuputMode(dioOuputMode),
		
		.PCIE_SAXIL_readAddress(PCIE_SAXIL_readAddress),
		.PCIE_SAXIL_readData(PCIE_SAXIL_readData),
		.PCIE_SAXIL_writeAddress(PCIE_SAXIL_writeAddress),
		.PCIE_SAXIL_writeData(PCIE_SAXIL_writeData),
		.PCIE_SAXIL_writeStrobe(PCIE_SAXIL_writeStrobe),
	
		.dataFifoFull(dataFifoFull),
		.dataFifoWriteEn(dataFifoWriteEn),
		.dataFifoWriteWidth(dataFifoWriteWidth),
		.dataFifoData(dataFifoData),
	
		.triggerFifoFull(triggerFifoFull),
		.triggerFifoWriteEn(triggerFifoWriteEn),
		.triggerFifoData(triggerFifoData),
		
		.scopeFifoFull(scopeFifoFull),
		.scopeFifoWriteEn(scopeFifoWriteEn),
		.scopeFifoWriteWidth(scopeFifoWriteWidth),
		.scopeFifoData(scopeFifoData),
		
		.module_id(MODULE_ID),
		.TEMPERATURE_ALARMS(TEMPERATURE_ALARMS),
		.VOLTAGE_ALARMS(VOLTAGE_ALARMS)
	);
	
	
	vDAQR1_BD vDAQ_BD_inst(
		.LSDAC_FW_IO(LSDAC_FW_IO),
		.LSADC_FW_i(LSADC_FW_I),
		.LSADC_FW_o(LSADC_FW_O),
		.CLKCFG_FW_i(CLKCFG_FW_I),
		.CLKCFG_FW_o(CLKCFG_FW_O),
		.MSADC_BOARD_IO(MSADC_BOARD_IO),
		.HSADC_BOARD_IO(HSADC_BOARD_IO),
		.HSADC_GTH_RX(HSADC_GTH_RX),
		
		.PCIE_AXI_i(PCIE_AXI_I),
		.PCIE_AXI_o(PCIE_AXI_O),
		.pcie_aclk(pcie_aclk),
		.pcie_aresetn(aresetn),
		.thermal_pd(THERMAL_PD),
		
		.msadcSampleClk(msadcSampleClk),
		.msadcSampleData(msadcSampleData),
		
		.hsadcDataClk(hsadcDataClk),
		.hsadcSampleDataA(hsadcSampleDataA),
		.hsadcSampleDataB(hsadcSampleDataB),
		
		.dataClk(dataClk),
		
		.PCIE_SAXIL_readAddress(PCIE_SAXIL_readAddress),
		.PCIE_SAXIL_readData(PCIE_SAXIL_readData),
		.PCIE_SAXIL_writeAddress(PCIE_SAXIL_writeAddress),
		.PCIE_SAXIL_writeData(PCIE_SAXIL_writeData),
		.PCIE_SAXIL_writeStrobe(PCIE_SAXIL_writeStrobe),
		
		.sysClk200(sysClk200),
		.ioClk80(ioClk80),
		.ioClk40(ioClk40),
		.auxClkIn(auxClkIn),
		.lsdacSpiClkEn(lsdacSpiClkEn),
		.lsadcSpiClkEn(lsadcSpiClkEn),
		
		.ext_triggers({si_DO[1][7:3], si_DO[0][7:3], RTSI_I, DIO_I}),
		.digitalTask0_o(digitalTask0Lines),
		.digitalTask1_o(digitalTask1Lines),
		.digitalTask2_o(digitalTask2Lines),
		.digitalTask3_o(digitalTask3Lines),

		
		// FIFOs for AE 1
		.SI_DATA_FIFO_0_wr_data(dataFifoData[0+:DATA_FIFO_1_WIDTH]),
		.SI_DATA_FIFO_0_wr_en(dataFifoWriteEn[0]),
		.SI_DATA_FIFO_0_wr_width(dataFifoWriteWidth[5:0]),
		.SI_DATA_FIFO_0_full(dataFifoFull[0]),
		
		.SI_AUX_FIFO_0_wr_data(triggerFifoData[0+:80]),
		.SI_AUX_FIFO_0_wr_en(triggerFifoWriteEn[0]),
		.SI_AUX_FIFO_0_full(triggerFifoFull[0]),


		// FIFOs for AE 2
		.SI_DATA_FIFO_1_wr_data(dataFifoData[DATA_FIFO_1_WIDTH+:DATA_FIFO_2_WIDTH]),
		.SI_DATA_FIFO_1_wr_en(dataFifoWriteEn[1]),
		.SI_DATA_FIFO_1_wr_width(dataFifoWriteWidth[11:6]),
		.SI_DATA_FIFO_1_full(dataFifoFull[1]),
		
		.SI_AUX_FIFO_1_wr_data(triggerFifoData[80+:80]),
		.SI_AUX_FIFO_1_wr_en(triggerFifoWriteEn[1]),
		.SI_AUX_FIFO_1_full(triggerFifoFull[1]),
		

		// Scope FIFO
		.SI_SCOPE_FIFO_wr_data(scopeFifoData),
		.SI_SCOPE_FIFO_wr_en(scopeFifoWriteEn),
		.SI_SCOPE_FIFO_wr_width(scopeFifoWriteWidth),
		.SI_SCOPE_FIFO_full(scopeFifoFull)
	);
	
endmodule
