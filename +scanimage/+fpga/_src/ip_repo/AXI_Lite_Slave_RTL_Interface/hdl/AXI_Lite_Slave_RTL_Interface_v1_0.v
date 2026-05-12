//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module AXI_Lite_Slave_RTL_Interface_v1_0 #(
	parameter integer DATA_WIDTH	= 32,
	parameter integer ADDR_WIDTH	= 12
)(
	// RTL Ports
	
	input wire  ACLK,
	input wire  ARESETN,
	
	output reg [ADDR_WIDTH-1 : 0] writeAddress = 0,
	output reg [DATA_WIDTH-1 : 0] writeData = 0,
	output reg [(DATA_WIDTH/8)-1 : 0] writeStrobe = 0,
	output wire writeActive,
	output reg [ADDR_WIDTH-1 : 0] readAddress = 0,
	input wire [DATA_WIDTH-1 : 0] readData,
	
	
	// SAXIL

	// Write address (issued by master, acceped by Slave)
	input wire [ADDR_WIDTH-1 : 0] SAXIL_AWADDR,
	
	// Write channel Protection type. This signal indicates the
		// privilege and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
	input wire [2 : 0] SAXIL_AWPROT,
	
	// Write address valid. This signal indicates that the master signaling
		// valid write address and control information.
	input wire  SAXIL_AWVALID,
	
	// Write address ready. This signal indicates that the slave is ready
		// to accept an address and associated control signals.
	output wire  SAXIL_AWREADY,
	
	// Write data (issued by master, acceped by Slave) 
	input wire [DATA_WIDTH-1 : 0] SAXIL_WDATA,
	
	// Write strobes. This signal indicates which byte lanes hold
		// valid data. There is one write strobe bit for each eight
		// bits of the write data bus.    
	input wire [(DATA_WIDTH/8)-1 : 0] SAXIL_WSTRB,
	
	// Write valid. This signal indicates that valid write
		// data and strobes are available.
	input wire  SAXIL_WVALID,
	
	// Write ready. This signal indicates that the slave
		// can accept the write data.
	output wire  SAXIL_WREADY,
	
	// Write response. This signal indicates the status
		// of the write transaction.
	output wire [1 : 0] SAXIL_BRESP,
	
	// Write response valid. This signal indicates that the channel
		// is signaling a valid write response.
	output wire  SAXIL_BVALID,
	
	// Response ready. This signal indicates that the master
		// can accept a write response.
	input wire  SAXIL_BREADY,
	
	// Read address (issued by master, acceped by Slave)
	input wire [ADDR_WIDTH-1 : 0] SAXIL_ARADDR,
	
	// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether the
		// transaction is a data access or an instruction access.
	input wire [2 : 0] SAXIL_ARPROT,
	
	// Read address valid. This signal indicates that the channel
		// is signaling valid read address and control information.
	input wire  SAXIL_ARVALID,
	
	// Read address ready. This signal indicates that the slave is
		// ready to accept an address and associated control signals.
	output wire  SAXIL_ARREADY,
	
	// Read data (issued by slave)
	output wire [DATA_WIDTH-1 : 0] SAXIL_RDATA,
	
	// Read response. This signal indicates the status of the
		// read transfer.
	output wire [1 : 0] SAXIL_RRESP,
	
	// Read valid. This signal indicates that the channel is
		// signaling the required read data.
	output wire  SAXIL_RVALID,
	
	// Read ready. This signal indicates that the master can
		// accept the read data and response information.
	input wire  SAXIL_RREADY
);

	// AXI4LITE signals
	reg axi_bvalid = 0;
	reg axi_rvalid = 0;
	//reg axi_wready = 0;
	
	reg readPending = 0;
	reg readNow = 0;
	

	// I/O Connections assignments
	assign SAXIL_AWREADY = 1;
	assign SAXIL_WREADY = 1;
	assign SAXIL_BRESP = 0; // 'OKAY' response
	assign SAXIL_BVALID = axi_bvalid;
	assign SAXIL_ARREADY = ~readPending;
	assign SAXIL_RRESP = 0; // 'OKAY' response
	assign SAXIL_RVALID = axi_rvalid;
	assign SAXIL_RDATA = readData;
	

	// Latch read and write addresses
	always @(posedge ACLK) begin
		// if master signals a valid address we immediately assert rvalid if the address has not changed
		// if the address changed, rvalid is asserted one clock later when the RTL has provided the new data
		// once the master stops signaling a valid read, we de-assert rvalid if master is signaling RREADY
		if (ARESETN == 0) begin
			axi_rvalid <= 0;
			readPending <= 0;
		end else begin
			if (SAXIL_ARVALID && ~(axi_rvalid && ~SAXIL_RREADY) && ~readPending) begin
				readAddress <= SAXIL_ARADDR;
				
				if (readAddress == SAXIL_ARADDR) begin
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
				axi_rvalid <= (axi_rvalid && ~SAXIL_RREADY);
		end
	end
	
	assign writeActive = |writeStrobe;

	// Latch write address, data, and send write response
	always @(posedge ACLK) begin
		
		if (ARESETN == 0) begin
			axi_bvalid  <= 0;
			writeStrobe <= 0;
		end else begin
			if (SAXIL_AWVALID)
				writeAddress <= SAXIL_AWADDR;
			
			if (SAXIL_WVALID) begin
				writeData <= SAXIL_WDATA;
				writeStrobe <= SAXIL_WSTRB;
				
				// indicates a valid write response is available
				axi_bvalid <= 1;
			end else begin
				writeStrobe <= 0;
				
				// Master is no longer asserting write valid. de assert bvalid if it has been ack'd
				if (SAXIL_BREADY)
					axi_bvalid <= 0;
			end
		end
	end

endmodule
