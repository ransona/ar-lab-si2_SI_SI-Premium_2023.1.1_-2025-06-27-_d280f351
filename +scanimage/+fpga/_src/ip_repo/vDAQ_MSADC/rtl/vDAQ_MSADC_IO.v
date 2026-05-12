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

module vDAQ_MSADC_IO #(
	// ADC settings

	
	// VGA default settings
	parameter [5:0] FILTER_FREQ = 40,
	parameter [0:0] POWER_MODE = 1,
	parameter [1:0] VGA1_GAIN = 3,
	parameter [1:0] VGA2_GAIN = 3,
	parameter [1:0] VGA3_GAIN = 3,
	parameter [0:0] POST_AMP_GAIN = 0,
	parameter [0:0] DC_OFFSET_DISABLE = 0,
	
	parameter SHOW_CFG_PORTS = 0,

	// do not change
	localparam SAXIL_CFG_DATA_WIDTH = 32,
	localparam SAXIL_CFG_ADDR_WIDTH = 8
) (
	input wire clk40,
	input wire axiResetN,
	input wire reset,
	
	// configuration
	output wire cfgInProgress,
	input wire applyCfgReq,
	
	// high speed data from device
	inout wire [30:0] BOARD_IO,
	
	// data out to RTL
	output wire [55:0] sampleData,
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
	vDAQ_MSADC #(
		.FILTER_FREQ(FILTER_FREQ),
		.POWER_MODE(POWER_MODE),
		.VGA1_GAIN(VGA1_GAIN),
		.VGA2_GAIN(VGA2_GAIN),
		.VGA3_GAIN(VGA3_GAIN),
		.POST_AMP_GAIN(POST_AMP_GAIN),
		.DC_OFFSET_DISABLE(DC_OFFSET_DISABLE),
		.SAXIL_CFG_DATA_WIDTH(SAXIL_CFG_DATA_WIDTH),
		.SAXIL_CFG_ADDR_WIDTH(SAXIL_CFG_ADDR_WIDTH)
	) MSADC_Inst (
		.clk40(clk40),
		.axiResetN(axiResetN),
		.reset(SHOW_CFG_PORTS ? reset : 0),
		
		// configuration
		.cfgInProgress(cfgInProgress),
		.applyCfgReq(SHOW_CFG_PORTS ? applyCfgReq : 0),
		
		// high speed data from device
		.DCLK_P(BOARD_IO[0]),
		.DCLK_N(BOARD_IO[1]),
		.FRCLK_P(BOARD_IO[2]),
		.FRCLK_N(BOARD_IO[3]),
		
		.CHA_D0_P(BOARD_IO[4]),
		.CHA_D0_N(BOARD_IO[5]),
		.CHA_D1_P(BOARD_IO[6]),
		.CHA_D1_N(BOARD_IO[7]),
		
		.CHB_D0_P(BOARD_IO[8]),
		.CHB_D0_N(BOARD_IO[9]),
		.CHB_D1_P(BOARD_IO[10]),
		.CHB_D1_N(BOARD_IO[11]),
		
		.CHC_D0_P(BOARD_IO[12]),
		.CHC_D0_N(BOARD_IO[13]),
		.CHC_D1_P(BOARD_IO[14]),
		.CHC_D1_N(BOARD_IO[15]),
		
		.CHD_D0_P(BOARD_IO[16]),
		.CHD_D0_N(BOARD_IO[17]),
		.CHD_D1_P(BOARD_IO[18]),
		.CHD_D1_N(BOARD_IO[19]),
		
		// device control
		.board_rev(BOARD_IO[30]),
		.adc_sync(BOARD_IO[20]),
		.adc_pwrdwn(BOARD_IO[21]),
		
		// SPI bus to devices
		.spi_adc_clk(BOARD_IO[22]),
		.spi_adc_cs(BOARD_IO[23]),
		.spi_adc_sdio(BOARD_IO[24]),
		.spi_vga_clk(BOARD_IO[25]),
		.spi_vga_cs12(BOARD_IO[26]),
		.spi_vga_cs34(BOARD_IO[27]),
		.spi_vga_mosi(BOARD_IO[28]),
		.spi_vga_miso(BOARD_IO[29]),
		
		// data out to RTL
		.ch1Data(sampleData[13:0]),
		.ch2Data(sampleData[27:14]),
		.ch3Data(sampleData[41:28]),
		.ch4Data(sampleData[55:42]),
		.sampleClk(sampleClk),
		
		
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
		.SAXIL_CFG_RREADY(SAXIL_CFG_RREADY)
	);
	
endmodule
