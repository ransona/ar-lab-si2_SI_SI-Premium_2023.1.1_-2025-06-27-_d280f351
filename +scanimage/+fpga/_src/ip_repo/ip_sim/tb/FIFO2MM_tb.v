//Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2016.4 (win64) Build 1733598 Wed Dec 14 22:35:39 MST 2016
//Date        : Wed Jan 18 16:10:24 2017
//Host        : xJ running 64-bit major release  (build 9200)
//Command     : generate_target tbbd_wrapper.bd
//Design      : tbbd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ns / 100 ps

module FIFO2MM_tb();

	reg [63:0] wr_data = {191'h123456789ABCDEF123456789};
	reg wr_en = 0;
	reg [2:0] write_size = 0;

	reg clk = 1;
	reg aresetn = 0;

	reg [7:0] cfgWriteAddress = 0;
	reg [31:0] cfgWriteData = 0;
	reg cfgWrActive = 0;

	always begin
		#5
		clk = ~clk;
	end
	
	// buffer starts at 4
	// read ptr is at d12
	// write ptr is at d16


	initial begin
		#40
		aresetn = 1;
		
		
		#20
		// write buffer address to configure FIFO
		cfgWriteAddress = 16;
		cfgWriteData = 256;
		cfgWrActive = 1;
		// wait for finish
		#10
		cfgWrActive = 0;
		
		#10
		// write buffer size to configure FIFO
		cfgWriteAddress = 20;
		cfgWriteData = 512;
		cfgWrActive = 1;
		// wait for finish
		#10
		cfgWrActive = 0;
		
		#10
		// write buffer size HI to configure FIFO
		cfgWriteAddress = 24;
		cfgWriteData = 0;
		cfgWrActive = 1;
		// wait for finish
		#10
		cfgWrActive = 0;
		
		
		#10
		// write num sg pages to configure FIFO
		cfgWriteAddress = 28;
		cfgWriteData = 1;
		cfgWrActive = 1;
		// wait for finish
		#10
		cfgWrActive = 0;
		
		
		#200
		wr_en <= 1;
		write_size <= 1;
		#10
		wr_en <= 0;
		
		#20
		wr_en <= 1;
		write_size <= 3;
		#10
		wr_en <= 0;
		
		#10
		wr_en <= 1;
		write_size <= 2;
		#10
		wr_en <= 1;
		write_size <= 4;
		#10
		wr_en <= 0;
	end





	wire [39:0] DATA_AWADDR;
	wire [7:0] DATA_AWLEN;
	wire [2:0] DATA_AWSIZE;
	wire [1:0] DATA_AWBURST;
	wire DATA_AWLOCK;
	wire [3:0] DATA_AWCACHE;
	wire [2:0] DATA_AWPROT;
	wire [3:0] DATA_AWQOS;
	wire DATA_AWVALID;
	wire DATA_AWREADY;
	wire [31:0] DATA_WDATA;
	wire [3:0] DATA_WSTRB;
	wire DATA_WLAST;
	wire DATA_WVALID;
	wire DATA_WREADY;
	wire [1:0] DATA_BRESP;
	wire DATA_BVALID;
	wire DATA_BREADY;
	wire [39:0] DATA_ARADDR;
	wire [7:0] DATA_ARLEN;
	wire [2:0] DATA_ARSIZE;
	wire [1:0] DATA_ARBURST;
	wire DATA_ARLOCK;
	wire [3:0] DATA_ARCACHE;
	wire [2:0] DATA_ARPROT;
	wire [3:0] DATA_ARQOS;
	wire DATA_ARVALID;
	wire DATA_ARREADY;
	wire [31:0] DATA_RDATA;
	wire [1:0] DATA_RRESP;
	wire DATA_RLAST;
	wire DATA_RVALID;
	wire DATA_RREADY;

	VFIFO fifo (
		.inputData(wr_data),                  // input wire [63 : 0] inputData
		.writeEnable(wr_en),              // input wire writeEnable
		.writeSizeBytes(write_size),        // input wire [2 : 0] writeSizeBytes
		.fifoFull(),                    // output wire fifoFull
		.inputClk(clk),                    // input wire inputClk
		.axiClk(clk),                        // input wire axiClk
		.axiResetN(aresetn),                  // input wire axiResetN

		.SAXIL_CFG_AWADDR(cfgWriteAddress),    // input wire [7 : 0] SAXIL_CFG_AWADDR
		.SAXIL_CFG_AWVALID(cfgWrActive),  // input wire SAXIL_CFG_AWVALID
		.SAXIL_CFG_WDATA(cfgWriteData),      // input wire [31 : 0] SAXIL_CFG_WDATA
		.SAXIL_CFG_WSTRB(4'hF),      // input wire [3 : 0] SAXIL_CFG_WSTRB
		.SAXIL_CFG_WVALID(cfgWrActive),    // input wire SAXIL_CFG_WVALID
		.SAXIL_CFG_BREADY(1),    // input wire SAXIL_CFG_BREADY

		.MAXI_DATA_AWADDR(DATA_AWADDR),    // output wire [39:0] MAXI_DATA_AWADDR
		.MAXI_DATA_AWLEN(DATA_AWLEN),      // output wire [7:0] MAXI_DATA_AWLEN
		.MAXI_DATA_AWSIZE(DATA_AWSIZE),    // output wire [2:0] MAXI_DATA_AWSIZE
		.MAXI_DATA_AWBURST(DATA_AWBURST),  // output wire [1:0] MAXI_DATA_AWBURST
		.MAXI_DATA_AWLOCK(DATA_AWLOCK),    // output wire MAXI_DATA_AWLOCK
		.MAXI_DATA_AWCACHE(DATA_AWCACHE),  // output wire [3:0] MAXI_DATA_AWCACHE
		.MAXI_DATA_AWPROT(DATA_AWPROT),    // output wire [2:0] MAXI_DATA_AWPROT
		.MAXI_DATA_AWQOS(DATA_AWQOS),      // output wire [3:0] MAXI_DATA_AWQOS
		.MAXI_DATA_AWVALID(DATA_AWVALID),  // output wire MAXI_DATA_AWVALID
		.MAXI_DATA_AWREADY(DATA_AWREADY),  // input wire MAXI_DATA_AWREADY
		.MAXI_DATA_WDATA(DATA_WDATA),      // output wire [31:0] MAXI_DATA_WDATA
		.MAXI_DATA_WSTRB(DATA_WSTRB),      // output wire [3:0] MAXI_DATA_WSTRB
		.MAXI_DATA_WLAST(DATA_WLAST),      // output wire MAXI_DATA_WLAST
		.MAXI_DATA_WVALID(DATA_WVALID),    // output wire MAXI_DATA_WVALID
		.MAXI_DATA_WREADY(DATA_WREADY),    // input wire MAXI_DATA_WREADY
		.MAXI_DATA_BRESP(DATA_BRESP),      // input wire [1:0] MAXI_DATA_BRESP
		.MAXI_DATA_BVALID(DATA_BVALID),    // input wire MAXI_DATA_BVALID
		.MAXI_DATA_BREADY(DATA_BREADY),    // output wire MAXI_DATA_BREADY
		.MAXI_DATA_ARADDR(DATA_ARADDR),    // output wire [39:0] MAXI_DATA_ARADDR
		.MAXI_DATA_ARLEN(DATA_ARLEN),      // output wire [7:0] MAXI_DATA_ARLEN
		.MAXI_DATA_ARSIZE(DATA_ARSIZE),    // output wire [2:0] MAXI_DATA_ARSIZE
		.MAXI_DATA_ARBURST(DATA_ARBURST),  // output wire [1:0] MAXI_DATA_ARBURST
		.MAXI_DATA_ARLOCK(DATA_ARLOCK),    // output wire MAXI_DATA_ARLOCK
		.MAXI_DATA_ARCACHE(DATA_ARCACHE),  // output wire [3:0] MAXI_DATA_ARCACHE
		.MAXI_DATA_ARPROT(DATA_ARPROT),    // output wire [2:0] MAXI_DATA_ARPROT
		.MAXI_DATA_ARQOS(DATA_ARQOS),      // output wire [3:0] MAXI_DATA_ARQOS
		.MAXI_DATA_ARVALID(DATA_ARVALID),  // output wire MAXI_DATA_ARVALID
		.MAXI_DATA_ARREADY(DATA_ARREADY),  // input wire MAXI_DATA_ARREADY
		.MAXI_DATA_RDATA(DATA_RDATA),      // input wire [31:0] MAXI_DATA_RDATA
		.MAXI_DATA_RRESP(DATA_RRESP),      // input wire [1:0] MAXI_DATA_RRESP
		.MAXI_DATA_RLAST(DATA_RLAST),      // input wire MAXI_DATA_RLAST
		.MAXI_DATA_RVALID(DATA_RVALID),    // input wire MAXI_DATA_RVALID
		.MAXI_DATA_RREADY(DATA_RREADY)     // output wire MAXI_DATA_RREADY
	);

	AXI_TG tg (
		.s_axi_aclk(clk),          // input wire s_axi_aclk
		.s_axi_aresetn(aresetn),    // input wire s_axi_aresetn
		
		.s_axi_awaddr(DATA_AWADDR),      // input wire [31:0] s_axi_awaddr
		.s_axi_awlen(DATA_AWLEN),        // input wire [7:0] s_axi_awlen
		.s_axi_awsize(DATA_AWSIZE),      // input wire [2:0] s_axi_awsize
		.s_axi_awburst(DATA_AWBURST),    // input wire [1:0] s_axi_awburst
		.s_axi_awlock(DATA_AWLOCK),      // input wire [0:0] s_axi_awlock
		.s_axi_awcache(DATA_AWCACHE),    // input wire [3:0] s_axi_awcache
		.s_axi_awprot(DATA_AWPROT),      // input wire [2:0] s_axi_awprot
		.s_axi_awqos(DATA_AWQOS),        // input wire [3:0] s_axi_awqos
		.s_axi_awvalid(DATA_AWVALID),    // input wire s_axi_awvalid
		.s_axi_awready(DATA_AWREADY),    // output wire s_axi_awready
		.s_axi_wlast(DATA_WLAST),        // input wire s_axi_wlast
		.s_axi_wdata(DATA_WDATA),        // input wire [31:0] s_axi_wdata
		.s_axi_wstrb(DATA_WSTRB),        // input wire [3:0] s_axi_wstrb
		.s_axi_wvalid(DATA_WVALID),      // input wire s_axi_wvalid
		.s_axi_wready(DATA_WREADY),      // output wire s_axi_wready
		.s_axi_bresp(DATA_BRESP),        // output wire [1:0] s_axi_bresp
		.s_axi_bvalid(DATA_BVALID),      // output wire s_axi_bvalid
		.s_axi_bready(DATA_BREADY),      // input wire s_axi_bready
		.s_axi_araddr(DATA_ARADDR),      // input wire [31:0] s_axi_araddr
		.s_axi_arlen(DATA_ARLEN),        // input wire [7:0] s_axi_arlen
		.s_axi_arsize(DATA_ARSIZE),      // input wire [2:0] s_axi_arsize
		.s_axi_arburst(DATA_ARBURST),    // input wire [1:0] s_axi_arburst
		.s_axi_arlock(DATA_ARLOCK),      // input wire [0:0] s_axi_arlock
		.s_axi_arcache(DATA_ARCACHE),    // input wire [3:0] s_axi_arcache
		.s_axi_arprot(DATA_ARPROT),      // input wire [2:0] s_axi_arprot
		.s_axi_arqos(DATA_ARQOS),        // input wire [3:0] s_axi_arqos
		.s_axi_arvalid(DATA_ARVALID),    // input wire s_axi_arvalid
		.s_axi_arready(DATA_ARREADY),    // output wire s_axi_arready
		.s_axi_rlast(DATA_RLAST),        // output wire s_axi_rlast
		.s_axi_rdata(DATA_RDATA),        // output wire [31:0] s_axi_rdata
		.s_axi_rresp(DATA_RRESP),        // output wire [1:0] s_axi_rresp
		.s_axi_rvalid(DATA_RVALID),      // output wire s_axi_rvalid
		.s_axi_rready(DATA_RREADY)       // input wire s_axi_rready
	);

endmodule
