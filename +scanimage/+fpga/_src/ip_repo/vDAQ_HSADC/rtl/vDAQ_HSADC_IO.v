//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQ_HSADC_IO #(
	parameter CH_WIDTH = 12,
	// do not change
	localparam SAXIL_CFG_DATA_WIDTH = 32,
	localparam SAXIL_CFG_ADDR_WIDTH = 13
)(
	input wire [15:0] GTH_RX,
	inout wire [18:0] BOARD_IO,

	output wire dataClk,
	output wire dataValid,
	output wire [CH_WIDTH*32-1:0] dataA,
	output wire [CH_WIDTH*32-1:0] dataB,
	output wire [15:0] syncTrigger,
	
	input wire axiClk,
	input wire axiResetN,
	input wire auxClkIn,
	input wire thermal_pd,
	
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
	input  wire SAXIL_CFG_RREADY
);

	vDAQ_HSADC #(
		.CH_WIDTH(CH_WIDTH),
		.SAXIL_CFG_DATA_WIDTH(SAXIL_CFG_DATA_WIDTH),
		.SAXIL_CFG_ADDR_WIDTH(SAXIL_CFG_ADDR_WIDTH)
	) HSADC_inst (
		.adc_rx_p(GTH_RX[7:0]),
		.adc_rx_n(GTH_RX[15:8]),
		.clckg_sclk(BOARD_IO[0]),
		.clckg_csb(BOARD_IO[1]),
		.clckg_mosi(BOARD_IO[2]),
		.clckg_miso(BOARD_IO[3]),
		.clckg_sync(BOARD_IO[4]),
		.adc_sclk(BOARD_IO[5]),
		.adc_csb(BOARD_IO[6]),
		.adc_sdio(BOARD_IO[7]),
		.adc_pdwn(BOARD_IO[8]),
		.adc_gpio_a(BOARD_IO[10:9]),
		.adc_gpio_b(BOARD_IO[12:11]),
		.adc_refclk_p(BOARD_IO[13]),
		.adc_refclk_n(BOARD_IO[14]),
		.adc_syncb_p(BOARD_IO[15]),
		.adc_syncb_n(BOARD_IO[16]),
		.sysref_p(BOARD_IO[17]),
		.sysref_n(BOARD_IO[18]),
		
		.axiClk(axiClk),
		.axiResetN(axiResetN),
		.coreClk(auxClkIn),
		.thermal_pd(thermal_pd),

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

		.dataClk(dataClk),
		.dataValid(dataValid),
		.dataA(dataA),
		.dataB(dataB),
		.syncTrigger(syncTrigger)
	);

endmodule