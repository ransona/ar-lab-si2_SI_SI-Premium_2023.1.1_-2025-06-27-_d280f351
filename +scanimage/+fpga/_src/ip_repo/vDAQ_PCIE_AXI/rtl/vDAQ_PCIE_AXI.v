//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQ_PCIE_AXI #(
	parameter USE_MASTER_BUS = 1,
	parameter USE_SLAVE_BUS = 0,
    parameter SHOW_FLASH_PORT = 0
) (
	// vDAQ BASE Intf
	output wire [749:0] PCIE_AXI_I,
	input wire [699:0] PCIE_AXI_O,
	
	(* KEEP = "TRUE" *) input  wire aclk,
	(* KEEP = "TRUE" *) input  wire aresetn,
	
	// PCIE MAXI
	(* KEEP = "TRUE" *) input  wire MAXI_AWREADY,
	(* KEEP = "TRUE" *) input  wire MAXI_WREADY,
	(* KEEP = "TRUE" *) input  wire [1:0] MAXI_BRESP,
	(* KEEP = "TRUE" *) input  wire MAXI_BVALID,
	(* KEEP = "TRUE" *) input  wire MAXI_ARREADY,
	(* KEEP = "TRUE" *) input  wire [255:0] MAXI_RDATA,
	(* KEEP = "TRUE" *) input  wire [1:0] MAXI_RRESP,
	(* KEEP = "TRUE" *) input  wire MAXI_RLAST,
	(* KEEP = "TRUE" *) input  wire MAXI_RVALID,
	(* KEEP = "TRUE" *) output wire [22:0] MAXI_AWADDR,
	(* KEEP = "TRUE" *) output wire [7:0] MAXI_AWLEN,
	(* KEEP = "TRUE" *) output wire [2:0] MAXI_AWSIZE,
	(* KEEP = "TRUE" *) output wire [1:0] MAXI_AWBURST,
	(* KEEP = "TRUE" *) output wire [2:0] MAXI_AWPROT,
	(* KEEP = "TRUE" *) output wire MAXI_AWVALID,
	(* KEEP = "TRUE" *) output wire MAXI_AWLOCK,
	(* KEEP = "TRUE" *) output wire [3:0] MAXI_AWCACHE,
	(* KEEP = "TRUE" *) output wire [255:0] MAXI_WDATA,
	(* KEEP = "TRUE" *) output wire [31:0] MAXI_WSTRB,
	(* KEEP = "TRUE" *) output wire MAXI_WLAST,
	(* KEEP = "TRUE" *) output wire MAXI_WVALID,
	(* KEEP = "TRUE" *) output wire MAXI_BREADY,
	(* KEEP = "TRUE" *) output wire [22:0] MAXI_ARADDR,
	(* KEEP = "TRUE" *) output wire [7:0] MAXI_ARLEN,
	(* KEEP = "TRUE" *) output wire [2:0] MAXI_ARSIZE,
	(* KEEP = "TRUE" *) output wire [1:0] MAXI_ARBURST,
	(* KEEP = "TRUE" *) output wire [2:0] MAXI_ARPROT,
	(* KEEP = "TRUE" *) output wire MAXI_ARVALID,
	(* KEEP = "TRUE" *) output wire MAXI_ARLOCK,
	(* KEEP = "TRUE" *) output wire [3:0] MAXI_ARCACHE,
	(* KEEP = "TRUE" *) output wire MAXI_RREADY,
	
	// PCIE MAXI
	(* KEEP = "TRUE" *) output wire SAXI_AWREADY,
	(* KEEP = "TRUE" *) output wire SAXI_WREADY,
	(* KEEP = "TRUE" *) output wire [7:0] SAXI_BID,
	(* KEEP = "TRUE" *) output wire [1:0] SAXI_BRESP,
	(* KEEP = "TRUE" *) output wire SAXI_BVALID,
	(* KEEP = "TRUE" *) output wire SAXI_ARREADY,
	(* KEEP = "TRUE" *) output wire [7:0] SAXI_RID,
	(* KEEP = "TRUE" *) output wire [255:0] SAXI_RDATA,
	(* KEEP = "TRUE" *) output wire [31:0] SAXI_RUSER,
	(* KEEP = "TRUE" *) output wire [1:0] SAXI_RRESP,
	(* KEEP = "TRUE" *) output wire SAXI_RLAST,
	(* KEEP = "TRUE" *) output wire SAXI_RVALID,
	(* KEEP = "TRUE" *) input  wire [7:0] SAXI_AWID,
	(* KEEP = "TRUE" *) input  wire [47:0] SAXI_AWADDR,
	(* KEEP = "TRUE" *) input  wire [3:0] SAXI_AWREGION,
	(* KEEP = "TRUE" *) input  wire [7:0] SAXI_AWLEN,
	(* KEEP = "TRUE" *) input  wire [2:0] SAXI_AWSIZE,
	(* KEEP = "TRUE" *) input  wire [1:0] SAXI_AWBURST,
	(* KEEP = "TRUE" *) input  wire SAXI_AWVALID,
	(* KEEP = "TRUE" *) input  wire [255:0] SAXI_WDATA,
	(* KEEP = "TRUE" *) input  wire [31:0] SAXI_WUSER,
	(* KEEP = "TRUE" *) input  wire [31:0] SAXI_WSTRB,
	(* KEEP = "TRUE" *) input  wire SAXI_WLAST,
	(* KEEP = "TRUE" *) input  wire SAXI_WVALID,
	(* KEEP = "TRUE" *) input  wire SAXI_BREADY,
	(* KEEP = "TRUE" *) input  wire [7:0] SAXI_ARID,
	(* KEEP = "TRUE" *) input  wire [47:0] SAXI_ARADDR,
	(* KEEP = "TRUE" *) input  wire [3:0] SAXI_ARREGION,
	(* KEEP = "TRUE" *) input  wire [7:0] SAXI_ARLEN,
	(* KEEP = "TRUE" *) input  wire [2:0] SAXI_ARSIZE,
	(* KEEP = "TRUE" *) input  wire [1:0] SAXI_ARBURST,
	(* KEEP = "TRUE" *) input  wire SAXI_ARVALID,
	(* KEEP = "TRUE" *) input  wire SAXI_RREADY,
	
	(* KEEP = "TRUE" *) output [3:0]FLASH_SD_I,
	(* KEEP = "TRUE" *) input  [3:0]FLASH_SD_O,
	(* KEEP = "TRUE" *) input  [3:0]FLASH_SD_T,
	(* KEEP = "TRUE" *) input  FLASH_CS_O,
	(* KEEP = "TRUE" *) input  FLASH_CS_T,
	(* KEEP = "TRUE" *) input  FLASH_CLK_O,
	(* KEEP = "TRUE" *) input  FLASH_CLK_T
);
	// MAXI
	assign PCIE_AXI_I[0] = USE_MASTER_BUS ? MAXI_AWREADY : 0;
	assign PCIE_AXI_I[1] = USE_MASTER_BUS ? MAXI_WREADY : 0;
	assign PCIE_AXI_I[3:2] = USE_MASTER_BUS ? MAXI_BRESP : 0;
	assign PCIE_AXI_I[4] = USE_MASTER_BUS ? MAXI_BVALID : 0;
	assign PCIE_AXI_I[5] = USE_MASTER_BUS ? MAXI_ARREADY : 0;
	assign PCIE_AXI_I[261:6] = USE_MASTER_BUS ? MAXI_RDATA : 0;
	assign PCIE_AXI_I[263:262] = USE_MASTER_BUS ? MAXI_RRESP : 0;
	assign PCIE_AXI_I[264] = USE_MASTER_BUS ? MAXI_RLAST : 0;
	assign PCIE_AXI_I[265] = USE_MASTER_BUS ? MAXI_RVALID : 0;
	assign MAXI_AWADDR = PCIE_AXI_O[22:0];
	assign MAXI_AWLEN = PCIE_AXI_O[30:23];
	assign MAXI_AWSIZE = PCIE_AXI_O[33:31];
	assign MAXI_AWBURST = PCIE_AXI_O[35:34];
	assign MAXI_AWPROT = PCIE_AXI_O[38:36];
	assign MAXI_AWVALID = PCIE_AXI_O[39];
	assign MAXI_AWLOCK = PCIE_AXI_O[40];
	assign MAXI_AWCACHE = PCIE_AXI_O[44:41];
	assign MAXI_WDATA = PCIE_AXI_O[300:45];
	assign MAXI_WSTRB = PCIE_AXI_O[332:301];
	assign MAXI_WLAST = PCIE_AXI_O[333];
	assign MAXI_WVALID = PCIE_AXI_O[334];
	assign MAXI_BREADY = PCIE_AXI_O[335];
	assign MAXI_ARADDR = PCIE_AXI_O[358:336];
	assign MAXI_ARLEN = PCIE_AXI_O[366:359];
	assign MAXI_ARSIZE = PCIE_AXI_O[369:367];
	assign MAXI_ARBURST = PCIE_AXI_O[371:370];
	assign MAXI_ARPROT = PCIE_AXI_O[374:372];
	assign MAXI_ARVALID = PCIE_AXI_O[375];
	assign MAXI_ARLOCK = PCIE_AXI_O[376];
	assign MAXI_ARCACHE = PCIE_AXI_O[380:377];
	assign MAXI_RREADY = PCIE_AXI_O[381];

	
	// SAXI
	assign SAXI_AWREADY = PCIE_AXI_O[382];
	assign SAXI_WREADY = PCIE_AXI_O[383];
	assign SAXI_BID = PCIE_AXI_O[391:384];
	assign SAXI_BRESP = PCIE_AXI_O[393:392];
	assign SAXI_BVALID = PCIE_AXI_O[394];
	assign SAXI_ARREADY = PCIE_AXI_O[395];
	assign SAXI_RID = PCIE_AXI_O[403:396];
	assign SAXI_RDATA = PCIE_AXI_O[659:404];
	assign SAXI_RUSER = PCIE_AXI_O[691:660];
	assign SAXI_RRESP = PCIE_AXI_O[693:692];
	assign SAXI_RLAST = PCIE_AXI_O[694];
	assign SAXI_RVALID = PCIE_AXI_O[695];
	assign PCIE_AXI_I[273:266] = USE_SLAVE_BUS ? SAXI_AWID : 0;
	assign PCIE_AXI_I[321:274] = USE_SLAVE_BUS ? SAXI_AWADDR : 0;
	assign PCIE_AXI_I[325:322] = USE_SLAVE_BUS ? SAXI_AWREGION : 0;
	assign PCIE_AXI_I[333:326] = USE_SLAVE_BUS ? SAXI_AWLEN : 0;
	assign PCIE_AXI_I[336:334] = USE_SLAVE_BUS ? SAXI_AWSIZE : 0;
	assign PCIE_AXI_I[338:337] = USE_SLAVE_BUS ? SAXI_AWBURST : 0;
	assign PCIE_AXI_I[339] = USE_SLAVE_BUS ? SAXI_AWVALID : 0;
	assign PCIE_AXI_I[595:340] = USE_SLAVE_BUS ? SAXI_WDATA : 0;
	assign PCIE_AXI_I[627:596] = USE_SLAVE_BUS ? SAXI_WUSER : 0;
	assign PCIE_AXI_I[659:628] = USE_SLAVE_BUS ? SAXI_WSTRB : 0;
	assign PCIE_AXI_I[660] = USE_SLAVE_BUS ? SAXI_WLAST : 0;
	assign PCIE_AXI_I[661] = USE_SLAVE_BUS ? SAXI_WVALID : 0;
	assign PCIE_AXI_I[662] = USE_SLAVE_BUS ? SAXI_BREADY : 0;
	assign PCIE_AXI_I[670:663] = USE_SLAVE_BUS ? SAXI_ARID : 0;
	assign PCIE_AXI_I[718:671] = USE_SLAVE_BUS ? SAXI_ARADDR : 0;
	assign PCIE_AXI_I[722:719] = USE_SLAVE_BUS ? SAXI_ARREGION : 0;
	assign PCIE_AXI_I[730:723] = USE_SLAVE_BUS ? SAXI_ARLEN : 0;
	assign PCIE_AXI_I[733:731] = USE_SLAVE_BUS ? SAXI_ARSIZE : 0;
	assign PCIE_AXI_I[735:734] = USE_SLAVE_BUS ? SAXI_ARBURST : 0;
	assign PCIE_AXI_I[736] = USE_SLAVE_BUS ? SAXI_ARVALID : 0;
	assign PCIE_AXI_I[737] = USE_SLAVE_BUS ? SAXI_RREADY : 0;

	// FIRMWARE
	assign FLASH_SD_I = PCIE_AXI_O[699:696];
	assign PCIE_AXI_I[741:738] = SHOW_FLASH_PORT ? FLASH_SD_O : 0;
	assign PCIE_AXI_I[745:742] = SHOW_FLASH_PORT ? FLASH_SD_T : 4'hF;
	assign PCIE_AXI_I[746] = SHOW_FLASH_PORT ? FLASH_CS_O : 1;
	assign PCIE_AXI_I[747] = SHOW_FLASH_PORT ? FLASH_CS_T : 0;
	assign PCIE_AXI_I[748] = SHOW_FLASH_PORT ? FLASH_CLK_O : 0;
	assign PCIE_AXI_I[749] = SHOW_FLASH_PORT ? FLASH_CLK_T : 1;
	
endmodule
