//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQR0_AppWrapper
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
	inout wire [440:0]  USER_BOARD_IO,
	
	
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
	
	vDAQR0_SI vDAQ_SI_inst(
		.PCIE_AXI_I(PCIE_AXI_I),
		.PCIE_AXI_O(PCIE_AXI_O),
		.pcie_aclk(pcie_aclk),
		.pcie_aresetn(pcie_aresetn),
		
		.DIO_I(DIO_I),
		.DIO_O(DIO_O),
		.DIO_OE(DIO_OE),
		
		.RTSI_I(RTSI_I),
		.RTSI_O(RTSI_O),
		.RTSI_OE(RTSI_OE),
		
		.EFUSE_DATA(EFUSE_DATA),
		.DNA_DATA(DNA_DATA),
		
		.TEMPERATURE_ALARMS(TEMPERATURE_ALARMS),
		.TEMPERATURE_DATA(TEMPERATURE_DATA),
		.VOLTAGE_ALARMS(VOLTAGE_ALARMS),
		.THERMAL_PD(THERMAL_PD),
		
		
		.CLKCFG_BOARD_IO(USER_BOARD_IO[11:6]),
		.MSADC_BOARD_IO(USER_BOARD_IO[42:12]),
		.LSADC_BOARD_IO(USER_BOARD_IO[105:97]),
		.LSDAC_BOARD_IO(USER_BOARD_IO[126:106]),
	
		.IO_CLK_120_N(USER_BOARD_IO[247]),
		.IO_CLK_120_P(USER_BOARD_IO[248]),
	
		.SYS_CLK_200_N(USER_BOARD_IO[249]),
		.SYS_CLK_200_P(USER_BOARD_IO[250]),
	
		.EXT_CLK_REF_P(USER_BOARD_IO[287]),
		.EXT_CLK_REF_N(USER_BOARD_IO[288]),
	
		.LED(USER_BOARD_IO[252:251]),
		.MODULE_ID(USER_BOARD_IO[286:283])
	);
	
endmodule


