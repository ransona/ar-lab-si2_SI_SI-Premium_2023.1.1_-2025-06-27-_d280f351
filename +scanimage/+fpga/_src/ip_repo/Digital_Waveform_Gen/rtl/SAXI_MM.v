//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module SAXI_MM #(
	parameter PROTOCOL			= "AXI4",
	parameter DATA_WIDTH		= 256,
	parameter ADDR_WIDTH		= 9,
	parameter MM_BYTES			= 512
)(
	// Clk/reset
	input wire aclk,
	input wire aresetn,
	
	// AXI Bus
	input  wire [ADDR_WIDTH-1:0] SAXI_araddr,
	input  wire [1:0] SAXI_arburst,
	input  wire [7:0] SAXI_arlen,
	input  wire [2:0] SAXI_arprot,
	output wire SAXI_arready,
	input  wire [2:0] SAXI_arsize,
	input  wire SAXI_arvalid,
	input  wire [ADDR_WIDTH-1:0] SAXI_awaddr,
	input  wire [1:0] SAXI_awburst,
	input  wire [7:0] SAXI_awlen,
	input  wire [2:0] SAXI_awprot,
	output wire SAXI_awready,
	input  wire [2:0] SAXI_awsize,
	input  wire SAXI_awvalid,
	input  wire SAXI_bready,
	output wire [1:0] SAXI_bresp,
	output wire SAXI_bvalid,
	output wire [DATA_WIDTH-1:0] SAXI_rdata,
	output wire SAXI_rlast,
	input  wire SAXI_rready,
	output wire [1:0] SAXI_rresp,
	output wire SAXI_rvalid,
	input  wire [DATA_WIDTH-1:0] SAXI_wdata,
	input  wire SAXI_wlast,
	output wire SAXI_wready,
	input  wire [DATA_WIDTH/8-1:0] SAXI_wstrb,
	input  wire SAXI_wvalid,
	
	output wire [MM_BYTES-1:0] byteWriteEn,
	output wire [MM_BYTES*8-1:0] bitWriteData,
	input  wire [MM_BYTES*8-1:0] bitReadData
);
	localparam DATA_WIDTH_BYTES	= DATA_WIDTH / 8;
	localparam LITE				= PROTOCOL == "AXI4LITE";
	
	// function that returns the ceiling of the log base 2
	function [63:0] clogb2;
		input [63:0] bit_depth;
	begin
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			bit_depth = bit_depth >> 1;
		end
	endfunction
	
	// function that computes an address aligned to DATA_WIDTH
	function [ADDR_WIDTH-1:0] alignedAddress;
		input [ADDR_WIDTH-1:0] addr;
		
		alignedAddress = {addr[ADDR_WIDTH-1:clogb2(DATA_WIDTH_BYTES-1)], {clogb2(DATA_WIDTH_BYTES-1){1'b0}}};
	endfunction
	
	wire awlen = LITE ? 0 : SAXI_awlen;
	wire arlen = LITE ? 0 : SAXI_arlen;
	wire wlast = LITE ? 1 : SAXI_wlast;
	
	reg  [11:0] alignedWriteAddrReg = 0;
	reg  [7:0]  writeBeatsRemaining = 0;
	wire [7:0]  writeBeatsRemainingPreup = (~aresetn && SAXI_awvalid) ? awlen : writeBeatsRemaining;
	wire        advanceWriteBurst = ~aresetn && SAXI_wvalid && writeBeatsRemainingPreup;
	wire [11:0] alignedWriteAddr = SAXI_awvalid ? alignedAddress(SAXI_awaddr) : alignedWriteAddrReg;
	
	reg  [11:0] alignedReadAddrReg = 0;
	reg  [7:0]  readBeatsRemaining = 0;
	wire [7:0]  readBeatsRemainingPreup = (~aresetn && SAXI_arvalid) ? arlen : readBeatsRemaining;
	wire        advanceReadBurst = ~aresetn && SAXI_rready && readBeatsRemainingPreup;
	wire [11:0] alignedReadAddr = SAXI_arvalid ? alignedAddress(SAXI_araddr) : alignedReadAddrReg;
	
	reg [MM_BYTES-1:0] byteWriteEnReg;
	assign byteWriteEn = byteWriteEnReg;
	
	reg  rvalid = 0;
	wire rlast = rvalid && (readBeatsRemaining == 0);
	reg  [4:0] bcnt = 0;
	reg  [DATA_WIDTH-1:0] rdata = 0;
	
	always @(posedge aclk) begin
		alignedWriteAddrReg <= alignedWriteAddr + (advanceWriteBurst ? DATA_WIDTH_BYTES : 0);
		alignedReadAddrReg <= alignedReadAddr + (advanceReadBurst ? DATA_WIDTH_BYTES : 0);
		
		writeBeatsRemaining <= writeBeatsRemainingPreup - advanceWriteBurst;
		readBeatsRemaining <= readBeatsRemainingPreup - advanceReadBurst;
		
		bcnt <= aresetn ? bcnt + (SAXI_wvalid && wlast) - (SAXI_bvalid && SAXI_bready) : 0;
		
		rvalid <= aresetn && (SAXI_arvalid || (rvalid && ~(rlast && SAXI_rready)));
			
		rdata <= bitReadData[alignedReadAddr*8+:DATA_WIDTH];
	end
	
    assign bitWriteData = {((MM_BYTES/DATA_WIDTH_BYTES)+1){SAXI_wdata}};
	
	integer ctr;
	always @(*)
		for (ctr = 0; ctr < MM_BYTES; ctr = ctr + 1)
			byteWriteEnReg[ctr] = aresetn && SAXI_wvalid && (ctr >= alignedWriteAddr) && (ctr < (alignedWriteAddr + DATA_WIDTH_BYTES)) && SAXI_wstrb[ctr % DATA_WIDTH_BYTES];
	
	assign SAXI_awready = 1;
	assign SAXI_wready = 1;
	assign SAXI_bresp = 0;
	assign SAXI_bvalid = bcnt > 0;
	assign SAXI_arready = 1;
	assign SAXI_rdata = rdata;
	assign SAXI_rvalid = rvalid;
	assign SAXI_rlast = rlast;
	assign SAXI_rresp = 0;
	
endmodule
