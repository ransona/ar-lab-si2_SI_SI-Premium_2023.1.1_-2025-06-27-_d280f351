//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQR1_64_AppWrapper #(
	parameter LRR_ENABLED = 0,
	parameter LRR_80kHz_SUPPORT = 0,
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
	output wire auxClkOut,
	
	input  wire [31:0] DIO_I,
	output wire [31:0] DIO_O,
	output wire [17:0] DIO_OE,
	input  wire [15:0] RTSI_I,
	output wire [15:0] RTSI_O,
	output wire [15:0] RTSI_OE,
	output wire [1:0]  LED_O,
	
	output wire SYNC_TRIGGER_clk,
	output wire SYNC_TRIGGER_reset,
	input  wire [15:0] SYNC_TRIGGER_i,
	
	output wire [240:0] LSDAC,
	output wire [12:0] LSADC_i,
	input  wire [204:0] LSADC_o,
	output wire [5:0] CLKCFG_i,
	input  wire CLKCFG_o,

	input  wire [31:0] EFUSE_DATA,
	input  wire [95:0] DNA_DATA,
	output wire [3:0]  MODULE_ID,
	
	input wire [1:0] TEMPERATURE_ALARMS,
	input wire [9:0] TEMPERATURE_DATA,
	input wire [6:0] VOLTAGE_ALARMS,
	input wire THERMAL_PD,
	
	
	// User App IO
	inout  wire [287:0] USER_GPIO,
	input  wire [15:0] USER_GTH_RX,
	output wire [15:0] USER_GTH_TX,
	
	
	// Debug Interface
	input  wire S_BSCAN_drck,
	input  wire S_BSCAN_shift,
	input  wire S_BSCAN_tdi,
	input  wire S_BSCAN_update,
	input  wire S_BSCAN_sel,
	output wire S_BSCAN_tdo,
	input  wire S_BSCAN_tms,
	input  wire S_BSCAN_tck,
	input  wire S_BSCAN_runtest,
	input  wire S_BSCAN_reset,
	input  wire S_BSCAN_capture,
	input  wire S_BSCAN_bscanid_en
);
	
	vDAQR1_64_SI #(
		.LRR_ENABLED(LRR_ENABLED),
		.LRR_80kHz_SUPPORT(LRR_80kHz_SUPPORT),
		.GIT_HASH(GIT_HASH)
	) vDAQ_SI_inst(
		.PCIE_AXI_I(PCIE_AXI_I),
		.PCIE_AXI_O(PCIE_AXI_O),
		.pcie_aclk(pcie_aclk),
		.pcie_aresetn(pcie_aresetn),
		
		.ioClk80OxEn(ioClk80OxEn),
		.ioClk80En(ioClk80En),
		.ioClk80(ioClk80),
		.auxClkIn(auxClkIn),
		
		.DIO_I(DIO_I),
		.DIO_O(DIO_O),
		.DIO_OE(DIO_OE),
		.RTSI_I(RTSI_I),
		.RTSI_O(RTSI_O),
		.RTSI_OE(RTSI_OE),
		.LED(LED_O),

		.SYNC_TRIGGER_clk(SYNC_TRIGGER_clk),
		.SYNC_TRIGGER_reset(SYNC_TRIGGER_reset),
		.SYNC_TRIGGER_i(SYNC_TRIGGER_i),

		.LSDAC_FW_IO(LSDAC),
		.LSADC_FW_I(LSADC_i),
		.LSADC_FW_O(LSADC_o),
		.CLKCFG_FW_I(CLKCFG_i),
		.CLKCFG_FW_O(CLKCFG_o),
		
		.MODULE_ID(MODULE_ID),
		
		.TEMPERATURE_ALARMS(TEMPERATURE_ALARMS),
		.TEMPERATURE_DATA(TEMPERATURE_DATA),
		.VOLTAGE_ALARMS(VOLTAGE_ALARMS),
		.THERMAL_PD(THERMAL_PD),
		
		
		// User App IO
		.MODULE_ID_IO(USER_GPIO[3:0]),
		
		.SYS_CLK_200_P(USER_GPIO[4]),
		.SYS_CLK_200_N(USER_GPIO[5]),

		.HSADC_BOARD_IO(USER_GPIO[55:37]),
		.HSADC_GTH_RX(USER_GTH_RX)
	);
	
endmodule


