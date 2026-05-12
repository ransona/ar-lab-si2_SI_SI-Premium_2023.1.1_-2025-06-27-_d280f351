//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module HSD_CLKCFG_IO #(
	parameter [0:0] AUTO_APPLY_CFG_ON_RESET = 1,
	parameter [0:0] USE_AXI_CFG_PORT = 1,

	// default clock settings
	parameter [0:0] INVSTAT = 0,
	parameter [0:0] PDALL = 0,
	parameter [0:0] SSYNC = 0,
	parameter [0:0] ALCEN = 0,
	parameter [0:0] ALCMON = 1,
	parameter [0:0] ALCCAL = 1,
	parameter [0:0] ALCULOK = 1,
	parameter [0:0] AUTOCAL = 1,
	parameter [0:0] BST = 1,
	parameter [0:0] FILT = 0,
	parameter [1:0] LKCT = 3,
	parameter [0:0] CPMID = 1,
	parameter [0:0] CPWIDE = 0,
	parameter [0:0] CPRST = 1,
	parameter [0:0] CPUP = 0,
	parameter [0:0] CPDN = 0,
	parameter [2:0] CP = 7,
	
	parameter [0:0] RAO = 0,
	parameter [3:0] BD = 10,
	parameter [0:0] LKWIN = 0,
	parameter [5:0] RD = 2,
	parameter [9:0] ND = 80,
	parameter [2:0] PD = 1,			// P = 2.5
	
	// aux clk to fmc
	parameter [0:0] MUTE0 = 1,		// only valid if RAO = 0
	parameter [0:0] SYNCEN0 = 0,	// only valid if RAO = 0
	parameter [0:0] OINV0 = 0,
	parameter [1:0] MC0 = 1,		// mute during vco cal
	parameter [3:0] MD0 = 5,		// 16x
	parameter [7:0] DLY0 = 0,		// only valid if RAO = 0. when RAO = 1, SN = DLY0[7], SR = DLY0[6]
	
	// ms adc clk
	parameter [0:0] MUTE1 = 0,
	parameter [0:0] SYNCEN1 = 0,
	parameter [0:0] OINV1 = 0,
	parameter [1:0] MC1 = 1,		// mute during vco cal
	parameter [3:0] MD1 = 5,		// 16x
	parameter [7:0] DLY1 = 0,
	
	// hs adc clk
	parameter [0:0] MUTE2 = 0,
	parameter [0:0] SYNCEN2 = 0,
	parameter [0:0] OINV2 = 0,
	parameter [1:0] MC2 = 1,		// mute during vco cal
	parameter [3:0] MD2 = 1,		// 2x
	parameter [7:0] DLY2 = 0,
	
	// aux to smb
	parameter [0:0] MUTE3 = 1,
	parameter [0:0] SYNCEN3 = 0,
	parameter [0:0] OINV3 = 0,
	parameter [1:0] MC3 = 1,		// mute during vco cal
	parameter [3:0] MD3 = 5,		// 16x
	parameter [7:0] DLY3 = 0,
	
	// aux clk to fpga
	parameter [0:0] MUTE4 = 1,
	parameter [0:0] SYNCEN4 = 0,
	parameter [0:0] OINV4 = 0,
	parameter [1:0] MC4 = 1,		// mute during vco cal
	parameter [3:0] MD4 = 5,		// 16x
	parameter [7:0] DLY4 = 0,
	
	// do not change
	parameter integer SAXIL_CFG_DATA_WIDTH = 32,
	parameter integer SAXIL_CFG_ADDR_WIDTH = 8
)(
	inout wire [5:0] BOARD_IO,
	
	input wire clk40,
	input wire axiResetN,
	
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
	HSD_CLKCFG #(
		.AUTO_APPLY_CFG_ON_RESET(AUTO_APPLY_CFG_ON_RESET),
		.USE_AXI_CFG_PORT(USE_AXI_CFG_PORT),
		.PDALL(PDALL),
		.INVSTAT(INVSTAT),
		.SSYNC(SSYNC),
		.ALCEN(ALCEN),
		.ALCMON(ALCMON),
		.ALCCAL(ALCCAL),
		.ALCULOK(ALCULOK),
		.AUTOCAL(AUTOCAL),
		.BST(BST),
		.FILT(FILT),
		.LKCT(LKCT),
		.CPMID(CPMID),
		.CPWIDE(CPWIDE),
		.CPRST(CPRST),
		.CPUP(CPUP),
		.CPDN(CPDN),
		.CP(CP),
		.RAO(RAO),
		.BD(BD),
		.LKWIN(LKWIN),
		.RD(RD),
		.ND(ND),
		.PD(PD),
		.MUTE0(MUTE0),
		.SYNCEN0(SYNCEN0),
		.OINV0(OINV0),
		.MC0(MC0),
		.MD0(MD0),
		.DLY0(DLY0),
		.MUTE1(MUTE1),
		.SYNCEN1(SYNCEN1),
		.OINV1(OINV1),
		.MC1(MC1),
		.MD1(MD1),
		.DLY1(DLY1),
		.MUTE2(MUTE2),
		.SYNCEN2(SYNCEN2),
		.OINV2(OINV2),
		.MC2(MC2),
		.MD2(MD2),
		.DLY2(DLY2),
		.MUTE3(MUTE3),
		.SYNCEN3(SYNCEN3),
		.OINV3(OINV3),
		.MC3(MC3),
		.MD3(MD3),
		.DLY3(DLY3),
		.MUTE4(MUTE4),
		.SYNCEN4(SYNCEN4),
		.OINV4(OINV4),
		.MC4(MC4),
		.MD4(MD4),
		.DLY4(DLY4),
		.SAXIL_CFG_DATA_WIDTH(SAXIL_CFG_DATA_WIDTH),
		.SAXIL_CFG_ADDR_WIDTH(SAXIL_CFG_ADDR_WIDTH)
	) HSD_CLKCFG_Inst (
		.clk40(clk40),
		.axiResetN(axiResetN),
		
		.applyCfgReq(0),
		.cfgInProgress(),
		
		// SAXIL control/config bus
		.SAXIL_CFG_AWADDR(SAXIL_CFG_AWADDR),
		.SAXIL_CFG_AWPROT(SAXIL_CFG_AWPROT),
		.SAXIL_CFG_AWVALID(SAXIL_CFG_AWVALID),
		.SAXIL_CFG_AWREADY(SAXIL_CFG_AWREADY),
		.SAXIL_CFG_WDATA(SAXIL_CFG_WDATA),
		.SAXIL_CFG_WSTRB(SAXIL_CFG_WSTRB),
		.SAXIL_CFG_WVALID(SAXIL_CFG_WVALID),
		.SAXIL_CFG_WREADY(SAXIL_CFG_WREADY),
		.SAXIL_CFG_BRESP(SAXIL_CFG_BRESP),
		.SAXIL_CFG_BVALID(SAXIL_CFG_BVALID),
		.SAXIL_CFG_BREADY(SAXIL_CFG_BREADY),
		.SAXIL_CFG_ARADDR(SAXIL_CFG_ARADDR),
		.SAXIL_CFG_ARPROT(SAXIL_CFG_ARPROT),
		.SAXIL_CFG_ARVALID(SAXIL_CFG_ARVALID),
		.SAXIL_CFG_ARREADY(SAXIL_CFG_ARREADY),
		.SAXIL_CFG_RDATA(SAXIL_CFG_RDATA),
		.SAXIL_CFG_RRESP(SAXIL_CFG_RRESP),
		.SAXIL_CFG_RVALID(SAXIL_CFG_RVALID),
		.SAXIL_CFG_RREADY(SAXIL_CFG_RREADY),
		
		// board io
		.extClockSelect(BOARD_IO[0]),
		.spiClk(BOARD_IO[1]),
		.cs(BOARD_IO[2]),
		.sdo(BOARD_IO[3]),
		.sdi(BOARD_IO[4]),
		.sync(BOARD_IO[5])
	);

endmodule