//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module HSD_CLKCFG #(
	parameter [0:0] AUTO_APPLY_CFG_ON_RESET = 1,
	parameter [0:0] USE_AXI_CFG_PORT = 1,

	// default clock settings
	parameter [0:0] PDALL = 0,
	parameter [0:0] INVSTAT = 0,
	parameter [0:0] SSYNC = 0,
	parameter [0:0] ALCEN = 0,
	parameter [0:0] ALCMON = 1,
	parameter [0:0] ALCCAL = 1,
	parameter [0:0] ALCULOK = 1,
	parameter [0:0] AUTOCAL = 1,
	parameter [0:0] BST = 1,
	parameter [0:0] FILT = 0,
	parameter [1:0] LKCT = 3,
	parameter [0:0] CPMID = 1,
	parameter [0:0] CPWIDE = 0,
	parameter [0:0] CPRST = 1,
	parameter [0:0] CPUP = 0,
	parameter [0:0] CPDN = 0,
	parameter [2:0] CP = 7,
	
	parameter [0:0] RAO = 0,
	parameter [3:0] BD = 10,
	parameter [0:0] LKWIN = 0,
	parameter [5:0] RD = 2,
	parameter [9:0] ND = 80,
	parameter [2:0] PD = 1,			// P = 2.5
	
	// aux clk to fmc
	parameter [0:0] MUTE0 = 1,		// only valid if RAO = 0
	parameter [0:0] SYNCEN0 = 0,	// only valid if RAO = 0
	parameter [0:0] OINV0 = 0,
	parameter [1:0] MC0 = 1,		// mute during vco cal
	parameter [3:0] MD0 = 5,		// 16x
	parameter [7:0] DLY0 = 0,		// only valid if RAO = 0. when RAO = 1, SN = DLY0[7], SR = DLY0[6]
	
	// ms adc clk
	parameter [0:0] MUTE1 = 0,
	parameter [0:0] SYNCEN1 = 0,
	parameter [0:0] OINV1 = 0,
	parameter [1:0] MC1 = 1,		// mute during vco cal
	parameter [3:0] MD1 = 5,		// 16x
	parameter [7:0] DLY1 = 0,
	
	// hs adc clk
	parameter [0:0] MUTE2 = 0,
	parameter [0:0] SYNCEN2 = 0,
	parameter [0:0] OINV2 = 0,
	parameter [1:0] MC2 = 1,		// mute during vco cal
	parameter [3:0] MD2 = 1,		// 2x
	parameter [7:0] DLY2 = 0,
	
	// aux to smb
	parameter [0:0] MUTE3 = 1,
	parameter [0:0] SYNCEN3 = 0,
	parameter [0:0] OINV3 = 0,
	parameter [1:0] MC3 = 1,		// mute during vco cal
	parameter [3:0] MD3 = 5,		// 16x
	parameter [7:0] DLY3 = 0,
	
	// aux clk to fpga
	parameter [0:0] MUTE4 = 1,
	parameter [0:0] SYNCEN4 = 0,
	parameter [0:0] OINV4 = 0,
	parameter [1:0] MC4 = 1,		// mute during vco cal
	parameter [3:0] MD4 = 5,		// 16x
	parameter [7:0] DLY4 = 0,
	
	// do not change
	parameter integer SAXIL_CFG_DATA_WIDTH = 32,
	parameter integer SAXIL_CFG_ADDR_WIDTH = 8
)(
	input wire clk40,
	input wire axiResetN,
	
	input wire applyCfgReq,
	output reg cfgInProgress = 0,
	
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
	input wire  SAXIL_CFG_RREADY,
	
	// clock selector
	output wire extClockSelect,
	
	// SPI bus to device
	output wire spiClk,
	output wire cs,
	output wire sdo,
	input  wire sdi,
	output wire sync
);
	// function that returns the ceiling of the log base 2.                      
	function integer clogb2 (input integer bit_depth); begin
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			bit_depth = bit_depth >> 1;
		end
	endfunction
	
	
	
	// static default settings
	localparam [0:0] POR = 0;
	localparam [0:0] CAL = 0;
	localparam [0:0] PDPLL = 0;
	localparam [0:0] PDVCO = 0;
	localparam [0:0] PDOUT = 0;
	localparam [0:0] PDREFPK = 0;
	
	localparam [159:0] DEFAULT_SETTINGS = {
		8'h00,
		{INVSTAT,7'h00},
		{PDALL,PDPLL,PDVCO,PDOUT,PDREFPK,SSYNC,POR,CAL},
		{ALCEN,ALCMON,ALCCAL,ALCULOK,AUTOCAL,RAO,BST,FILT},
		{BD[3:0],1'b0,LKWIN,LKCT[1:0]},
		{RD[5:0],ND[9:8]},
		ND[7:0],
		{CPMID,CPWIDE,CPRST,CPUP,CPDN,CP[2:0]},
		{PD[2:0],MUTE4,MUTE3,MUTE2,MUTE1,MUTE0},
		{SYNCEN0,OINV0,MC0[1:0],MD0[3:0]},
		DLY0[7:0],
		{SYNCEN1,OINV1,MC1[1:0],MD1[3:0]},
		DLY1[7:0],
		{SYNCEN2,OINV2,MC2[1:0],MD2[3:0]},
		DLY2[7:0],
		{SYNCEN3,OINV3,MC3[1:0],MD3[3:0]},
		DLY3[7:0],
		{SYNCEN4,OINV4,MC4[1:0],MD4[3:0]},
		DLY4[7:0],
		8'h00
	};
	// buffers
	reg extClockSelect_b = 0;
	(* IOB = "TRUE" *) reg cs_b = 1;
	(* IOB = "TRUE" *) reg sdo_b = 0;
	wire sdi_b;
	wire sync_b;
	
	OBUF extClockSelect_buf(.I(extClockSelect_b), .O(extClockSelect));
	OBUF cs_buf(.I(cs_b), .O(cs));
	OBUF sdo_buf(.I(sdo_b), .O(sdo));
	IBUF sdi_buf(.I(sdi), .O(sdi_b));
	OBUF sync_buf(.I(sync_b), .O(sync));


	// register that stores read back of the current device settings
	reg [159:0] readbackBuf = 0;

	// register that store settings to be written
	reg [159:0] outputBuffer = DEFAULT_SETTINGS;
	
	
	// generate spi clock
	(* IOB = "TRUE" *) reg spiClkG = 0;
	reg [1:0] spiClkCtr = 0;

	OBUF spiClk_buf(.I(spiClkG), .O(spiClk));
	
	// spi logic
	reg [3:0] addrCtr = 0;
	reg addrDone = 0;
	reg [7:0] bitCtr = 0;
	
	reg cfgReq = 0;
	reg cfgReqRd = 0;
	reg [6:0] cfgAddrReq;
	reg [7:0] cfgSzReqBits;
	
	wire [7:0] addrByte = {cfgAddrReq, cfgReqRd};
	
	always @(posedge clk40) begin
		spiClkCtr <= spiClkCtr + 1;
		spiClkG <= (spiClkCtr < 2) && cfgInProgress;

		if (~axiResetN) begin
			cs_b <= 1;
			cfgInProgress <= 0;
		end else if (spiClkCtr == 2) begin
			if (~cfgInProgress) begin
				cs_b <= 1;
				if (cfgReq) begin
					addrCtr <= 0;
					bitCtr <= 0;
					addrDone <= 0;
					cfgInProgress <= 1;
				end
			end else if (addrCtr < 8) begin
				// drop cs and output address
				cs_b <= 0;
				sdo_b <= addrByte[7-addrCtr];
				addrCtr <= addrCtr + 1;
			end else if (bitCtr < cfgSzReqBits) begin
				// if this is a write, write data
				cs_b <= 0;
				addrDone <= 1;
				
				if (cfgReqRd)
					sdo_b <= 0;
				else
					sdo_b <= outputBuffer[159-(cfgAddrReq*8+bitCtr)];
					
				bitCtr <= bitCtr + 1;
			end else if (bitCtr == cfgSzReqBits) begin
				// keep cs low one more clock
				addrDone <= 0;
				cs_b <= 0;
				sdo_b <= 0;
				bitCtr <= bitCtr + 1;
			end else if (bitCtr == (cfgSzReqBits+1)) begin
				// raise cs
				cs_b <= 1;
				bitCtr <= bitCtr + 1;
			end else begin
				cs_b <= 1;
				cfgInProgress <= 0;
			end
		end
	end
	
	always @(posedge clk40) begin
		// read spi
		if (cfgInProgress && cfgReqRd && addrDone && (spiClkCtr == 1))
			readbackBuf[159-(cfgAddrReq*8+bitCtr-1)] <= sdi_b;
	end
	
	// sync generation
	reg [31:0] sync_ctr = 0;
	assign sync_b = |sync_ctr;
	
	// axi config slave
	// receives configuration data and commands from host
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0ReadAddress;
	reg [SAXIL_CFG_DATA_WIDTH-1:0] s0ReadData = 0;
	wire s0WriteActive;
	wire [(SAXIL_CFG_DATA_WIDTH/8)-1 : 0] s0WriteStrobe;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0WriteAddress;
	wire [SAXIL_CFG_DATA_WIDTH-1:0] s0WriteData;
	
	reg [clogb2(SAXIL_CFG_DATA_WIDTH)-1:0] byteIterR;
	reg [clogb2(SAXIL_CFG_DATA_WIDTH)-1:0] byteIterW;
	reg [4:0] rstCtr = 0;
	
	always @(posedge clk40) begin
		if (axiResetN && s0WriteActive && (s0WriteAddress == 64))
			sync_ctr <= s0WriteData;
		else if (sync_ctr)
			sync_ctr <= sync_ctr - 1;
	
		if (~axiResetN) begin
			cfgReq <= 0;
			rstCtr <= 28;
		end else if (rstCtr > 1)
			// hold reset to wait for all primitives to be ready
			rstCtr <= rstCtr - 1;
		else if (rstCtr) begin
			rstCtr <= rstCtr - 1;
			cfgReq <= AUTO_APPLY_CFG_ON_RESET;
			if (AUTO_APPLY_CFG_ON_RESET) begin
				cfgReqRd <= 0;
				cfgAddrReq <= 1;
				cfgSzReqBits <= 146;
			end
			outputBuffer <= DEFAULT_SETTINGS;
		end else begin
			if (s0ReadAddress < 20)
				// read current settings to be programmed
				for (byteIterR = 0; byteIterR < (SAXIL_CFG_DATA_WIDTH/8); byteIterR = byteIterR + 1)
					// swap bit order for more intuitive r/w from host and spi outpu
					s0ReadData[SAXIL_CFG_DATA_WIDTH - 1 - byteIterR*8-:8] <= outputBuffer[159-((byteIterR + s0ReadAddress)*8) -: 8];
			else if (s0ReadAddress < 40)
				// read device settings rdbk
				for (byteIterR = 0; byteIterR < (SAXIL_CFG_DATA_WIDTH/8); byteIterR = byteIterR + 1)
					// swap bit order for more intuitive r/w from host and spi outpu
					s0ReadData[SAXIL_CFG_DATA_WIDTH - 1 - byteIterR*8-:8] <= readbackBuf[159-((byteIterR + s0ReadAddress - 20)*8) -: 8];
			else case (s0ReadAddress)
				40: s0ReadData <= {31'd0, extClockSelect_b};
				44: s0ReadData <= 32'hBC1D_C10C;
				default: s0ReadData <= 32'h1331_1331;
			endcase
			
			if (s0WriteActive)
				case (s0WriteAddress)
					40: extClockSelect_b <= s0WriteData[0];
				endcase
		
			if (s0WriteActive && (s0WriteAddress < 20))
				for (byteIterW = 0; byteIterW < (SAXIL_CFG_DATA_WIDTH/8); byteIterW = byteIterW + 1)
					if (s0WriteStrobe[byteIterW])
						// swap byte order for more intuitive r/w from host
						outputBuffer[159-((byteIterW + s0WriteAddress)*8) -: 8] <= s0WriteData[SAXIL_CFG_DATA_WIDTH - 1 - byteIterW*8-:8];
			else if (s0WriteActive && (s0WriteAddress == 24))
				outputBuffer <= DEFAULT_SETTINGS;
			
			// latching of configuration request
			if (cfgInProgress)
				// configuration in progress. deassert start request
				cfgReq <= 0;
			else begin
				// configuration is done
				if (s0WriteActive && (s0WriteAddress == 20)) begin
					// axi cfg req
					cfgReqRd <= s0WriteData[16];
					cfgAddrReq <= s0WriteData[7:0];
					cfgSzReqBits <= s0WriteData[15:8];
					cfgReq <= 1;
				end if (applyCfgReq) begin
					// request of full write
					cfgReqRd <= 0;
					cfgAddrReq <= 2;
					cfgSzReqBits <= 136;
					cfgReq <= 1;
				end
			end
		end
	end
	
	
	
	// Inst SAXIL_CFG
	SAXIL #(.DATA_WIDTH(SAXIL_CFG_DATA_WIDTH), .ADDR_WIDTH(SAXIL_CFG_ADDR_WIDTH)) SAXIL_CFG_Inst (
		.ACLK(clk40),
		.ARESETN(axiResetN && USE_AXI_CFG_PORT),
		
		.writeAddress(s0WriteAddress),
		.writeData(s0WriteData),
		.writeStrobe(s0WriteStrobe),
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