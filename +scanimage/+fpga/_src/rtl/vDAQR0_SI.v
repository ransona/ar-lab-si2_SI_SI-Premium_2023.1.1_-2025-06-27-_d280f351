//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQR0_SI
(
	// vDAQ_PCIE_AXI Interface
	output wire [749:0] PCIE_AXI_I,
	input  wire [699:0] PCIE_AXI_O,
	input  wire pcie_aclk,
	input  wire pcie_aresetn,
	
	input  wire [23:0] DIO_I,
	output wire [23:0] DIO_O,
	output wire [9:0]  DIO_OE,
	
	input  wire [15:0] RTSI_I,
	output wire [15:0] RTSI_O,
	output wire [15:0] RTSI_OE,
	
	input wire [31:0] EFUSE_DATA,
	input wire [95:0] DNA_DATA,
	
	input wire [1:0] TEMPERATURE_ALARMS,
	input wire [9:0] TEMPERATURE_DATA,
	input wire [6:0] VOLTAGE_ALARMS,
	input wire THERMAL_PD,
	
	
	// User App IO
	inout wire [5:0]   CLKCFG_BOARD_IO,
	inout wire [30:0]  MSADC_BOARD_IO,
	inout wire [8:0]   LSADC_BOARD_IO,
	inout wire [20:0]  LSDAC_BOARD_IO,
	
	input  wire IO_CLK_120_N,
	input  wire IO_CLK_120_P,
	
	input  wire SYS_CLK_200_N,
	input  wire SYS_CLK_200_P,
	
	input  wire EXT_CLK_REF_N,
	input  wire EXT_CLK_REF_P,
	
	output wire [1:0]  LED,
	input  wire [3:0]  MODULE_ID
);
	wire sysClk200in;
	wire sysClk200;

	wire sampleClk;

	wire ioClk120in;
	wire ioClk120;
	wire ioClk40;
	
	wire sysClk200_en;
	wire ioClk120_en;
	wire ioClk40_en;
	wire lsadcSpiClkEn;
	wire lsdacSpiClkEn;
	
	IBUFDS sysClk200iBuf(.I(SYS_CLK_200_P), .IB(SYS_CLK_200_N), .O(sysClk200in));
	BUFGCE sysClk200Buf(.I(sysClk200in), .O(sysClk200), .CE(sysClk200_en));
	IBUFDS ioClk120iBuf(.I(IO_CLK_120_P), .IB(IO_CLK_120_N), .O(ioClk120in));
	BUFGCE ioClk120Buf(.I(ioClk120in), .O(ioClk120), .CE(ioClk120_en));
	BUFGCE_DIV #(.BUFGCE_DIVIDE(3)) clk40bufg  (.I(ioClk120), .O(ioClk40), .CE(ioClk40_en));
	
	wire extClkIn;
	IBUFDS extClkRefiBuf(.I(EXT_CLK_REF_P), .IB(EXT_CLK_REF_N), .O(extClkIn));

	wire [1:0] LEDb;
	OBUF led0b(.I(~LEDb[0]), .O(LED[0]));
	OBUF led1b(.I(~LEDb[1]), .O(LED[1]));

	wire [3:0] module_id;
	IBUF module_id_buf_0(.I(MODULE_ID[0]), .O(module_id[0]));
	IBUF module_id_buf_1(.I(MODULE_ID[1]), .O(module_id[1]));
	IBUF module_id_buf_2(.I(MODULE_ID[2]), .O(module_id[2]));
	IBUF module_id_buf_3(.I(MODULE_ID[3]), .O(module_id[3]));
	
	
	// DIO arbitration and io
	wire [8:0] si_DO;
	wire [7:0] digitalTask0Lines;
	wire [7:0] digitalTask1Lines;
	wire [7:0] digitalTask2Lines;
	wire [7:0] digitalTask3Lines;
	wire [40:0] digitalSignals = {digitalTask3Lines, digitalTask2Lines, digitalTask1Lines, digitalTask0Lines, si_DO};
	
	// 0-input, 1-outputL, 2-outputH,  3-output spcl[v-3]
	wire [239:0] dioOuputMode;
	
    assign DIO_OE[9:8] = 2'b10;
    assign DIO_O[15:8] = 0;
	
	generate
		genvar dio0_iter;
		genvar dio2_iter;
		genvar rtsi_iter;
		
		for (dio0_iter = 0; dio0_iter < 8; dio0_iter=dio0_iter+1) begin:gen_dio0
			wire [5:0] myMode = dioOuputMode[dio0_iter*6+:6];
			wire myModeIsSpcl = myMode > 2;
			wire [5:0] spclAssignment = myMode-3;
			wire spclSig = digitalSignals[spclAssignment];
			wire myModeIsI2cAck = spclAssignment == 8;
			
			assign DIO_OE[dio0_iter] = myModeIsI2cAck ? spclSig : myMode > 0;
			assign DIO_O[dio0_iter] = myModeIsI2cAck ? 0 : ((myMode == 2) || (myModeIsSpcl && spclSig));
		end
		
		for (dio2_iter = 0; dio2_iter < 8; dio2_iter=dio2_iter+1) begin:gen_dio3
			wire [5:0] myMode = dioOuputMode[(dio2_iter+16)*6+:6];
			wire myModeIsSpcl = myMode > 2;
			wire [5:0] spclAssignment = myMode-3;
			
			assign DIO_O[dio2_iter+16] = (myMode == 2) || (myModeIsSpcl && digitalSignals[spclAssignment]);
		end
		
		for (rtsi_iter = 0; rtsi_iter < 16; rtsi_iter=rtsi_iter+1) begin:gen_rtsi
			wire [5:0] myMode = dioOuputMode[(rtsi_iter+24)*6+:6];
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

	
	// SI Inst
	wire [3:0] chFifoFull;
	
	wire dataFifoFull;
	wire dataFifoWriteEn;
	wire [2:0] dataFifoWriteWidth;
	wire [63:0] dataFifoData;
	
	wire triggerFifoFull;
	wire triggerFifoWriteEn;
	wire [79:0] triggerFifoData;
	
	wire scopeFifoFull;
	wire scopeFifoWriteEn;
	wire [3:0] scopeFifoWriteWidth;
	wire [79:0] scopeFifoData;
	
	wire [55:0] msadcSampleData;
	
	(* DONT_TOUCH = "true" *)
	vDAQ_SI #(
		.NUM_DIO(24),
		.NUM_AE(1),
		.AE_1_HS_NUM_LOGICAL_CHANNELS(8),  // must be >= MS channels
		.AE_1_MS_NUM_LOGICAL_CHANNELS(8),
		.AE_1_NUM_DIVIDERS(8),
		.HSADC_SUPPORT(0),
		.PHOTON_COUNTING_SUPPORT(1),
		.DATA_FIFO_1_WIDTH(64),
		.SCOPE_FIFO_WIDTH(80),
		.ACCUM_MULTIPLY_SUPPORT(1),
		.HSADC_LRR_SUPPORT(0),
		.SAMPLE_PHASE_BITS(12)
	) vDAQ_SI_Inst (
		.dataClk(sampleClk),
		.cfgClk(pcie_aclk),
		.sysClk200(sysClk200),
		.resetn_cc(aresetn),
		
		.sysClk200_en(sysClk200_en),
		.sysClk100_en(sysClk100_en),
		.ioClkH_en(ioClk120_en),
		.ioClk40_en(ioClk40_en),
		.lsadcSpiClkEn(lsadcSpiClkEn),
		.lsdacSpiClkEn(lsdacSpiClkEn),
	
		.msadcSampleData(msadcSampleData),

		.DI({extClkIn, RTSI_I, DIO_I}),
		.DO(si_DO),
		.LED(LEDb),
		.dioOuputMode(dioOuputMode),
		
		.PCIE_SAXIL_readAddress(PCIE_SAXIL_readAddress),
		.PCIE_SAXIL_readData(PCIE_SAXIL_readData),
		.PCIE_SAXIL_writeAddress(PCIE_SAXIL_writeAddress),
		.PCIE_SAXIL_writeData(PCIE_SAXIL_writeData),
		.PCIE_SAXIL_writeStrobe(PCIE_SAXIL_writeStrobe),
	
		.dataFifoFull(dataFifoFull || (|chFifoFull)),
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
		
		.module_id(module_id),
		.TEMPERATURE_ALARMS(TEMPERATURE_ALARMS),
		.VOLTAGE_ALARMS(VOLTAGE_ALARMS)
	);
	
	
	vDAQR0_BD vDAQ_BD_inst(
		.CLKCFG_BOARD_IO(CLKCFG_BOARD_IO),
		.MSADC_BOARD_IO(MSADC_BOARD_IO),
		.LSADC_BOARD_IO(LSADC_BOARD_IO),
		.LSDAC_BOARD_IO(LSDAC_BOARD_IO),
		
		.PCIE_AXI_i(PCIE_AXI_I),
		.PCIE_AXI_o(PCIE_AXI_O),
		.pcie_aclk(pcie_aclk),
		.pcie_aresetn(aresetn),
		
		.hsaeClk(sampleClk),
		.msadcSampleData(msadcSampleData),
		
		.PCIE_SAXIL_readAddress(PCIE_SAXIL_readAddress),
		.PCIE_SAXIL_readData(PCIE_SAXIL_readData),
		.PCIE_SAXIL_writeAddress(PCIE_SAXIL_writeAddress),
		.PCIE_SAXIL_writeData(PCIE_SAXIL_writeData),
		.PCIE_SAXIL_writeStrobe(PCIE_SAXIL_writeStrobe),
		
		.sysClk200(sysClk200),
		.ioClk120(ioClk120),
		.ioClk40(ioClk40),
		.lsdacSpiClkEn(lsdacSpiClkEn),
		.lsadcSpiClkEn(lsadcSpiClkEn),
		
		.ext_triggers({si_DO[7:3], RTSI_I, DIO_I}),
		.digitalTask0_o(digitalTask0Lines),
		.digitalTask1_o(digitalTask1Lines),
		.digitalTask2_o(digitalTask2Lines),
		.digitalTask3_o(digitalTask3Lines),
		
		.SI_DATA_FIFO_wr_data(dataFifoData),
		.SI_DATA_FIFO_wr_en(dataFifoWriteEn),
		.SI_DATA_FIFO_wr_width(dataFifoWriteWidth),
		.SI_DATA_FIFO_full(dataFifoFull),
		
		.SI_AUX_FIFO_wr_data(triggerFifoData),
		.SI_AUX_FIFO_wr_en(triggerFifoWriteEn),
		.SI_AUX_FIFO_full(triggerFifoFull),
		
		.SI_SCOPE_FIFO_wr_data(scopeFifoData),
		.SI_SCOPE_FIFO_wr_en(scopeFifoWriteEn),
		.SI_SCOPE_FIFO_wr_width(scopeFifoWriteWidth),
		.SI_SCOPE_FIFO_full(scopeFifoFull),
		

		// Individual channel fifos
		.CH0_FIFO_wr_data(dataFifoData[15:0] + 32768),
		.CH0_FIFO_wr_en(dataFifoWriteEn),
		.CH0_FIFO_full(chFifoFull[0]),
		
		.CH1_FIFO_wr_data(dataFifoData[31:16] + 32768),
		.CH1_FIFO_wr_en(dataFifoWriteEn),
		.CH1_FIFO_full(chFifoFull[1]),
		
		.CH2_FIFO_wr_data(dataFifoData[47:32] + 32768),
		.CH2_FIFO_wr_en(dataFifoWriteEn),
		.CH2_FIFO_full(chFifoFull[2]),
		
		.CH3_FIFO_wr_data(dataFifoData[63:48] + 32768),
		.CH3_FIFO_wr_en(dataFifoWriteEn),
		.CH3_FIFO_full(chFifoFull[3])
	);
	
endmodule
