//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module Special_Trigger #(
	parameter NUM_EXT_TRIGGERS    		= 48,
	parameter NUM_PEER_TRIGGERS    		= 26,
	parameter PEER_TRIGGER_IDX    		= 0,
	
	// these should not be changed
	localparam SAXIL_CFG_DATA_WIDTH		= 32,
	localparam SAXIL_CFG_ADDR_WIDTH		= 10
)(
	input  wire [NUM_EXT_TRIGGERS-1:0] ext_triggers,
	inout  wire [NUM_PEER_TRIGGERS-1:0] peer_triggers,
	
	input wire axiClk,
	input wire sampleClkTimebase,
	input wire axiResetN,
	
	
	// SAXIL control/config bus
	input wire [SAXIL_CFG_ADDR_WIDTH-1:0] SAXIL_CFG_AWADDR,
	input wire [2:0] SAXIL_CFG_AWPROT,
	input wire  SAXIL_CFG_AWVALID,
	output wire  SAXIL_CFG_AWREADY,
	input wire [SAXIL_CFG_DATA_WIDTH-1:0] SAXIL_CFG_WDATA,
	input wire [(SAXIL_CFG_DATA_WIDTH/8)-1:0] SAXIL_CFG_WSTRB,
	input wire  SAXIL_CFG_WVALID,
	output wire  SAXIL_CFG_WREADY,
	output wire [1:0] SAXIL_CFG_BRESP,
	output wire  SAXIL_CFG_BVALID,
	input wire  SAXIL_CFG_BREADY,
	input wire [SAXIL_CFG_ADDR_WIDTH-1:0] SAXIL_CFG_ARADDR,
	input wire [2:0] SAXIL_CFG_ARPROT,
	input wire  SAXIL_CFG_ARVALID,
	output wire  SAXIL_CFG_ARREADY,
	output wire [SAXIL_CFG_DATA_WIDTH-1:0] SAXIL_CFG_RDATA,
	output wire [1:0] SAXIL_CFG_RRESP,
	output wire  SAXIL_CFG_RVALID,
	input wire  SAXIL_CFG_RREADY
);
	wire resetSm;
	wire startSm;
	reg  triggerMode = 0; // 0-auto trigger, 1-armed trigger

	always @(posedge sampleClkTimebase) begin
	end
	
	
	/****************************************\
			SAXIL_CFG slave intf
	\****************************************/
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0ReadAddress;
	reg [SAXIL_CFG_DATA_WIDTH-1:0] s0ReadData = 0;
	wire s0WriteActive;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0WriteAddress;
	wire [SAXIL_CFG_DATA_WIDTH-1:0] s0WriteData;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0ActiveWriteAddress = (axiResetN && s0WriteAddress) ? s0WriteAddress : 0;
	
	reg [63:0] ownerUuid = 0;
	
	// trigger counters
	//reg [5:0]  ctrN_triggerId [15:0];
	//reg [15:0] ctrN_cnt [15:0];
	
	always @(posedge axiClk) begin
		if (~axiResetN) begin
			ownerUuid <= 0;
		end else begin
	
			case (s0ReadAddress)
				0: s0ReadData <= 32'h5545_C23A;
				
			//	4: cmd
			
				8: s0ReadData <= ownerUuid;
			
				12: s0ReadData <= ownerUuid;
				
				default: s0ReadData <= 32'hFAAF_FEFF;
			endcase
		
			case (s0ActiveWriteAddress)
			
				8: ownerUuid[31:0] <= s0WriteData;
				12: ownerUuid[63:32] <= s0WriteData;
			endcase
		end
	end
	
	OSCC resetReqCC(.srcV((s0ActiveWriteAddress == 4) && (s0WriteData == 0)), .srcClk(axiClk), .dstV(resetSm), .dstClk(sampleClkTimebase));
	OSCC startReqCC(.srcV((s0ActiveWriteAddress == 4) && (s0WriteData == 1)), .srcClk(axiClk), .dstV(startSm), .dstClk(sampleClkTimebase));

	// Inst SAXIL_CFG
	SAXIL #(.DATA_WIDTH(SAXIL_CFG_DATA_WIDTH), .ADDR_WIDTH(SAXIL_CFG_ADDR_WIDTH)) SAXIL_CFG (
		.ACLK(axiClk),
		.ARESETN(axiResetN),
		
		.writeAddress(s0WriteAddress),
		.writeData(s0WriteData),
		.writeStrobe(),
		.writeActive(s0WriteActive),
		.readAddress(s0ReadAddress),
		.readData(s0ReadData),
		
		// SAXIL_CFG
		.SAXIL_AWADDR(SAXIL_CFG_AWADDR),
		.SAXIL_AWPROT(SAXIL_CFG_AWPROT),
		.SAXIL_AWVALID(SAXIL_CFG_AWVALID),
		.SAXIL_AWREADY(SAXIL_CFG_AWREADY),
		.SAXIL_WDATA(SAXIL_CFG_WDATA),  
		.SAXIL_WSTRB(SAXIL_CFG_WSTRB),
		.SAXIL_WVALID(SAXIL_CFG_WVALID),
		.SAXIL_WREADY(SAXIL_CFG_WREADY),
		.SAXIL_BRESP(SAXIL_CFG_BRESP),
		.SAXIL_BVALID(SAXIL_CFG_BVALID),
		.SAXIL_BREADY(SAXIL_CFG_BREADY),
		.SAXIL_ARADDR(SAXIL_CFG_ARADDR),
		.SAXIL_ARPROT(SAXIL_CFG_ARPROT),
		.SAXIL_ARVALID(SAXIL_CFG_ARVALID),
		.SAXIL_ARREADY(SAXIL_CFG_ARREADY),
		.SAXIL_RDATA(SAXIL_CFG_RDATA),
		.SAXIL_RRESP(SAXIL_CFG_RRESP),
		.SAXIL_RVALID(SAXIL_CFG_RVALID),
		.SAXIL_RREADY(SAXIL_CFG_RREADY)
	);
	
endmodule
