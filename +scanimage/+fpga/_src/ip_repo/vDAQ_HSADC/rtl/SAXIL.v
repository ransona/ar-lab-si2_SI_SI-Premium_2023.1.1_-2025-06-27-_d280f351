//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module SAXIL #(
	parameter DATA_WIDTH	= 32,
	parameter ADDR_WIDTH	= 12,

	parameter NUM_RTL_MASTERS = 1,
	parameter NUM_AXI_MASTERS = 0,

	parameter RTL_MASTER_1_BASE_ADDR = 0,
	parameter RTL_MASTER_1_SIZE = 0,

	parameter RTL_MASTER_2_BASE_ADDR = 0,
	parameter RTL_MASTER_2_SIZE = 0,

	parameter AXI_MASTER_1_BASE_ADDR = 0,
	parameter AXI_MASTER_1_SIZE = 0,

	parameter AXI_MASTER_2_BASE_ADDR = 0,
	parameter AXI_MASTER_2_SIZE = 0
)(
	input wire  ACLK,
	input wire  ARESETN,
	
	// SAXIL
	input wire [ADDR_WIDTH-1 : 0] SAXIL_AWADDR,
	input wire [2 : 0] SAXIL_AWPROT,
	input wire  SAXIL_AWVALID,
	output wire  SAXIL_AWREADY,
	input wire [DATA_WIDTH-1 : 0] SAXIL_WDATA, 
	input wire [(DATA_WIDTH/8)-1 : 0] SAXIL_WSTRB,
	input wire  SAXIL_WVALID,
	output wire  SAXIL_WREADY,
	output wire [1 : 0] SAXIL_BRESP,
	output wire  SAXIL_BVALID,
	input wire  SAXIL_BREADY,
	input wire [ADDR_WIDTH-1 : 0] SAXIL_ARADDR,
	input wire [2 : 0] SAXIL_ARPROT,
	input wire  SAXIL_ARVALID,
	output wire  SAXIL_ARREADY,
	output wire [DATA_WIDTH-1 : 0] SAXIL_RDATA,
	output wire [1 : 0] SAXIL_RRESP,
	output wire  SAXIL_RVALID,
	input wire  SAXIL_RREADY,
	

	// RTL M1
	output wire [ADDR_WIDTH-1 : 0] writeAddress,
	output wire [DATA_WIDTH-1 : 0] writeData,
	output wire [(DATA_WIDTH/8)-1 : 0] writeStrobe,
	output wire writeActive,
	output wire [ADDR_WIDTH-1 : 0] activeWriteAddress,
	output wire [ADDR_WIDTH-1 : 0] readAddress,
	input  wire [DATA_WIDTH-1 : 0] readData,
	
	
	// RTL M2
	output wire [ADDR_WIDTH-1 : 0] writeAddress2,
	output wire [DATA_WIDTH-1 : 0] writeData2,
	output wire [(DATA_WIDTH/8)-1 : 0] writeStrobe2,
	output wire writeActive2,
	output wire [ADDR_WIDTH-1 : 0] activeWriteAddress2,
	output wire [ADDR_WIDTH-1 : 0] readAddress2,
	input  wire [DATA_WIDTH-1 : 0] readData2,
	
	
	// MAXIL1
	output wire [ADDR_WIDTH-1 : 0] MAXIL1_AWADDR,
	output wire [2 : 0] MAXIL1_AWPROT,
	output wire  MAXIL1_AWVALID,
	input wire  MAXIL1_AWREADY,
	output wire [DATA_WIDTH-1 : 0] MAXIL1_WDATA, 
	output wire [(DATA_WIDTH/8)-1 : 0] MAXIL1_WSTRB,
	output wire  MAXIL1_WVALID,
	input wire  MAXIL1_WREADY,
	input wire [1 : 0] MAXIL1_BRESP,
	input wire  MAXIL1_BVALID,
	output wire  MAXIL1_BREADY,
	output wire [ADDR_WIDTH-1 : 0] MAXIL1_ARADDR,
	output wire [2 : 0] MAXIL1_ARPROT,
	output wire  MAXIL1_ARVALID,
	input wire  MAXIL1_ARREADY,
	input wire [DATA_WIDTH-1 : 0] MAXIL1_RDATA,
	input wire [1 : 0] MAXIL1_RRESP,
	input wire  MAXIL1_RVALID,
	output wire  MAXIL1_RREADY,
	
	
	// MAXIL2
	output wire [ADDR_WIDTH-1 : 0] MAXIL2_AWADDR,
	output wire [2 : 0] MAXIL2_AWPROT,
	output wire  MAXIL2_AWVALID,
	input wire  MAXIL2_AWREADY,
	output wire [DATA_WIDTH-1 : 0] MAXIL2_WDATA, 
	output wire [(DATA_WIDTH/8)-1 : 0] MAXIL2_WSTRB,
	output wire  MAXIL2_WVALID,
	input wire  MAXIL2_WREADY,
	input wire [1 : 0] MAXIL2_BRESP,
	input wire  MAXIL2_BVALID,
	output wire  MAXIL2_BREADY,
	output wire [ADDR_WIDTH-1 : 0] MAXIL2_ARADDR,
	output wire [2 : 0] MAXIL2_ARPROT,
	output wire  MAXIL2_ARVALID,
	input wire  MAXIL2_ARREADY,
	input wire [DATA_WIDTH-1 : 0] MAXIL2_RDATA,
	input wire [1 : 0] MAXIL2_RRESP,
	input wire  MAXIL2_RVALID,
	output wire  MAXIL2_RREADY
);
	// arbitrate between external axi masters
	wire [ADDR_WIDTH-1 : 0] SAXIL_INT_AWADDR;
	wire [2 : 0] SAXIL_INT_AWPROT;
	wire  SAXIL_INT_AWVALID;
	wire  SAXIL_INT_AWREADY;
	wire [DATA_WIDTH-1 : 0] SAXIL_INT_WDATA; 
	wire [(DATA_WIDTH/8)-1 : 0] SAXIL_INT_WSTRB;
	wire  SAXIL_INT_WVALID;
	wire  SAXIL_INT_WREADY;
	wire [1 : 0] SAXIL_INT_BRESP;
	wire  SAXIL_INT_BVALID;
	wire  SAXIL_INT_BREADY;
	wire [ADDR_WIDTH-1 : 0] SAXIL_INT_ARADDR;
	wire [2 : 0] SAXIL_INT_ARPROT;
	wire  SAXIL_INT_ARVALID;
	wire  SAXIL_INT_ARREADY;
	wire [DATA_WIDTH-1 : 0] SAXIL_INT_RDATA;
	wire [1 : 0] SAXIL_INT_RRESP;
	wire  SAXIL_INT_RVALID;
	wire  SAXIL_INT_RREADY;

	reg [ADDR_WIDTH-1:0] current_w_addr_R = 0;
	reg [ADDR_WIDTH-1:0] current_r_addr_R = 0;

	always @(posedge ACLK) begin
		if (SAXIL_AWVALID)
			current_w_addr_R <= SAXIL_AWADDR;
		if (SAXIL_ARVALID)
			current_r_addr_R <= SAXIL_ARADDR;
	end

	wire [ADDR_WIDTH-1:0] current_w_addr = SAXIL_AWVALID ? SAXIL_AWADDR : current_w_addr_R;
	wire [ADDR_WIDTH-1:0] current_r_addr = SAXIL_ARVALID ? SAXIL_ARADDR : current_r_addr_R;

	wire rtl1_w_active = (NUM_RTL_MASTERS > 0) && (((current_w_addr >= RTL_MASTER_1_BASE_ADDR) && (current_w_addr < (RTL_MASTER_1_BASE_ADDR + RTL_MASTER_1_SIZE))) || (RTL_MASTER_1_SIZE == 0));
	wire rtl2_w_active = (NUM_RTL_MASTERS > 1) && (current_w_addr >= RTL_MASTER_2_BASE_ADDR) && (current_w_addr < (RTL_MASTER_2_BASE_ADDR + RTL_MASTER_2_SIZE));
	wire axi1_w_active = (NUM_AXI_MASTERS > 0) && (current_w_addr >= AXI_MASTER_1_BASE_ADDR) && (current_w_addr < (AXI_MASTER_1_BASE_ADDR + AXI_MASTER_1_SIZE));
	wire axi2_w_active = (NUM_AXI_MASTERS > 1) && (current_w_addr >= AXI_MASTER_2_BASE_ADDR) && (current_w_addr < (AXI_MASTER_2_BASE_ADDR + AXI_MASTER_2_SIZE));
	wire rtl_w_active = rtl1_w_active || rtl2_w_active;

	wire rtl1_r_active = (NUM_RTL_MASTERS > 0) && (current_r_addr >= RTL_MASTER_1_BASE_ADDR) && (current_r_addr < (RTL_MASTER_1_BASE_ADDR + RTL_MASTER_1_SIZE));
	wire rtl2_r_active = (NUM_RTL_MASTERS > 1) && (current_r_addr >= RTL_MASTER_2_BASE_ADDR) && (current_r_addr < (RTL_MASTER_2_BASE_ADDR + RTL_MASTER_2_SIZE));
	wire axi1_r_active = (NUM_AXI_MASTERS > 0) && (current_r_addr >= AXI_MASTER_1_BASE_ADDR) && (current_r_addr < (AXI_MASTER_1_BASE_ADDR + AXI_MASTER_1_SIZE));
	wire axi2_r_active = (NUM_AXI_MASTERS > 1) && (current_r_addr >= AXI_MASTER_2_BASE_ADDR) && (current_r_addr < (AXI_MASTER_2_BASE_ADDR + AXI_MASTER_2_SIZE));
	wire rtl_r_active = rtl1_r_active || rtl2_r_active;

	assign SAXIL_INT_AWADDR = SAXIL_AWADDR;
	assign SAXIL_INT_AWPROT = SAXIL_AWPROT;
	assign SAXIL_INT_AWVALID = rtl_w_active && SAXIL_AWVALID;
	assign SAXIL_INT_WDATA = SAXIL_WDATA;
	assign SAXIL_INT_WSTRB = SAXIL_WSTRB;
	assign SAXIL_INT_WVALID = rtl_w_active && SAXIL_WVALID;
	assign SAXIL_INT_BREADY = rtl_w_active && SAXIL_BREADY;
	assign SAXIL_INT_ARADDR = SAXIL_ARADDR;
	assign SAXIL_INT_ARPROT = SAXIL_ARPROT;
	assign SAXIL_INT_ARVALID = rtl_r_active && SAXIL_ARVALID;
	assign SAXIL_INT_RREADY = rtl_r_active && SAXIL_RREADY;

	assign MAXIL1_AWADDR = SAXIL_AWADDR - AXI_MASTER_1_BASE_ADDR;
	assign MAXIL1_AWPROT = SAXIL_AWPROT;
	assign MAXIL1_AWVALID = axi1_w_active && SAXIL_AWVALID;
	assign MAXIL1_WDATA = SAXIL_WDATA;
	assign MAXIL1_WSTRB = SAXIL_WSTRB;
	assign MAXIL1_WVALID = axi1_w_active && SAXIL_WVALID;
	assign MAXIL1_BREADY = axi1_w_active && SAXIL_BREADY;
	assign MAXIL1_ARADDR = SAXIL_ARADDR - AXI_MASTER_1_BASE_ADDR;
	assign MAXIL1_ARPROT = SAXIL_ARPROT;
	assign MAXIL1_ARVALID = axi1_r_active && SAXIL_ARVALID;
	assign MAXIL1_RREADY = axi1_r_active && SAXIL_RREADY;

	assign MAXIL2_AWADDR = SAXIL_AWADDR - AXI_MASTER_2_BASE_ADDR;
	assign MAXIL2_AWPROT = SAXIL_AWPROT;
	assign MAXIL2_AWVALID = axi2_w_active && SAXIL_AWVALID;
	assign MAXIL2_WDATA = SAXIL_WDATA;
	assign MAXIL2_WSTRB = SAXIL_WSTRB;
	assign MAXIL2_WVALID = axi2_w_active && SAXIL_WVALID;
	assign MAXIL2_BREADY = axi2_w_active && SAXIL_BREADY;
	assign MAXIL2_ARADDR = SAXIL_ARADDR - AXI_MASTER_2_BASE_ADDR;
	assign MAXIL2_ARPROT = SAXIL_ARPROT;
	assign MAXIL2_ARVALID = axi2_r_active && SAXIL_ARVALID;
	assign MAXIL2_RREADY = axi2_r_active && SAXIL_RREADY;

	assign SAXIL_AWREADY = rtl_w_active ? SAXIL_INT_AWREADY : (axi1_w_active ? MAXIL1_AWREADY : MAXIL2_AWREADY);
	assign SAXIL_WREADY = rtl_w_active ? SAXIL_INT_WREADY : (axi1_w_active ? MAXIL1_WREADY : MAXIL2_WREADY);
	assign SAXIL_BRESP = rtl_w_active ? SAXIL_INT_BRESP : (axi1_w_active ? MAXIL1_BRESP : MAXIL2_BRESP);
	assign SAXIL_BVALID = rtl_w_active ? SAXIL_INT_BVALID : (axi1_w_active ? MAXIL1_BVALID : MAXIL2_BVALID);
	assign SAXIL_ARREADY = rtl_r_active ? SAXIL_INT_ARREADY : (axi1_r_active ? MAXIL1_ARREADY : MAXIL2_ARREADY);
	assign SAXIL_RDATA = rtl_r_active ? SAXIL_INT_RDATA : (axi1_r_active ? MAXIL1_RDATA : MAXIL2_RDATA);
	assign SAXIL_RRESP = rtl_r_active ? SAXIL_INT_RRESP : (axi1_r_active ? MAXIL1_RRESP : MAXIL2_RRESP);
	assign SAXIL_RVALID = rtl_r_active ? SAXIL_INT_RVALID : (axi1_r_active ? MAXIL1_RVALID : MAXIL2_RVALID);
	

	// AXI4LITE signals
	reg axi_bvalid = 0;
	reg axi_rvalid = 0;
	//reg axi_wready = 0;
	
	reg readPending = 0;
	reg readNow = 0;
	
	reg  [ADDR_WIDTH-1 : 0] writeAddressR = 0;
	reg  [DATA_WIDTH-1 : 0] writeDataR = 0;
	reg  [(DATA_WIDTH/8)-1 : 0] writeStrobeR = 0;
	reg  [ADDR_WIDTH-1 : 0] readAddressR = 0;
	
	assign writeAddress = writeAddressR - RTL_MASTER_1_BASE_ADDR;
	assign writeData = writeDataR;
	assign writeStrobe = writeStrobeR;
	assign readAddress = readAddressR - RTL_MASTER_1_BASE_ADDR;
	assign writeActive = (|writeStrobeR) && rtl1_w_active;
	assign activeWriteAddress = writeActive ? writeAddress : {ADDR_WIDTH{1'b1}};
	
	assign writeAddress2 = writeAddressR - RTL_MASTER_2_BASE_ADDR;
	assign writeData2 = writeDataR;
	assign writeStrobe2 = writeStrobeR;
	assign readAddress2 = readAddressR - RTL_MASTER_2_BASE_ADDR;
	assign writeActive2 = (|writeStrobeR) && rtl2_w_active;
	assign activeWriteAddress2 = writeActive2 ? writeAddress2 : {ADDR_WIDTH{1'b1}};
	

	// I/O Connections assignments
	assign SAXIL_INT_AWREADY = 1;
	assign SAXIL_INT_WREADY = 1;
	assign SAXIL_INT_BRESP = 0; // 'OKAY' response
	assign SAXIL_INT_BVALID = axi_bvalid;
	assign SAXIL_INT_ARREADY = ~readPending;
	assign SAXIL_INT_RRESP = 0; // 'OKAY' response
	assign SAXIL_INT_RVALID = axi_rvalid;
	assign SAXIL_INT_RDATA = rtl1_r_active ? readData : readData2;

	// Latch read and write addresses
	always @(posedge ACLK) begin
		// if master signals a valid address we immediately assert rvalid if the address has not changed
		// if the address changed, rvalid is asserted one clock later when the RTL has provided the new data
		// once the master stops signaling a valid read, we de-assert rvalid if master is signaling RREADY
		if (ARESETN == 0) begin
			axi_rvalid <= 0;
			readPending <= 0;
		end else begin
			if (SAXIL_INT_ARVALID && ~(axi_rvalid && ~SAXIL_INT_RREADY) && ~readPending) begin
				readAddressR <= SAXIL_INT_ARADDR;
				
				if (readAddressR == SAXIL_INT_ARADDR) begin
					readPending <= 0;
					readNow = 1;
				end else begin
					readPending <= 1;
					readNow = 0;
				end
			end else begin
				readPending <= 0;
				readNow = 0;
			end
			
			if (readPending || readNow)
				axi_rvalid <= 1;
			else
				axi_rvalid <= (axi_rvalid && ~SAXIL_INT_RREADY);
		end
	end

	// Latch write address, data, and send write response
	always @(posedge ACLK) begin
		
		if (ARESETN == 0) begin
			axi_bvalid  <= 0;
			writeStrobeR <= 0;
		end else begin
			if (SAXIL_INT_AWVALID)
				writeAddressR <= SAXIL_INT_AWADDR;
			
			if (SAXIL_INT_WVALID) begin
				writeDataR <= SAXIL_INT_WDATA;
				writeStrobeR <= SAXIL_INT_WSTRB;
				
				// indicates a valid write response is available
				axi_bvalid <= 1;
			end else begin
				writeStrobeR <= 0;
				
				// Master is no longer asserting write valid. de assert bvalid if it has been ack'd
				if (SAXIL_INT_BREADY)
					axi_bvalid <= 0;
			end
		end
	end

endmodule
