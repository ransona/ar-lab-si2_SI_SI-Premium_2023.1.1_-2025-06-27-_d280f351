//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
// Module Name: FIFO2MM_Transport
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 100 ps

module FIFO2MM_Transport #(
	parameter FIFO_INPUT_WIDTH_BYTES		= 4,
	parameter FIFO_VARIABLE_INPUT_WIDTH		= 0,
	parameter FIFO_SAFE_VARIABLE_INPUT		= 0,

	parameter AXI_DATA_WIDTH    			= 128,
	parameter MAXI_DATA_ADDR_WIDTH 			= 40,
		
	parameter FIFO_DEPTH        			= 512,
	
	parameter BLOCK_FOR_READ        		= 1,
	
	parameter SG_PAGE_LIST_LENGTH      		= 2048, // must be multiple of 512
	
	parameter SHOW_DBG_PORTS				= 0,
	
	// these should not be changed
	localparam SAXIL_CFG_DATA_WIDTH		= 32,
	localparam SAXIL_CFG_ADDR_WIDTH		= 8
)(
	input  wire [FIFO_INPUT_WIDTH_BYTES*8-1:0] inputData,
	input  wire writeEnable,
	input  wire [$clog2(FIFO_INPUT_WIDTH_BYTES)-1:0] writeSizeBytes,
	output wire fifoFull,

	input wire inputClk,
	input wire axiClk,
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
	input wire  SAXIL_CFG_RREADY,
	
	
	// MAXI data bus
	output wire [MAXI_DATA_ADDR_WIDTH-1:0] MAXI_DATA_AWADDR,
	output wire [7:0] MAXI_DATA_AWLEN,
	output wire [2:0] MAXI_DATA_AWSIZE,
	output wire [1:0] MAXI_DATA_AWBURST,
	output wire  MAXI_DATA_AWLOCK,
	output wire [3:0] MAXI_DATA_AWCACHE,
	output wire [2:0] MAXI_DATA_AWPROT,
	output wire [3:0] MAXI_DATA_AWQOS,
	output wire  MAXI_DATA_AWVALID,
	input wire  MAXI_DATA_AWREADY,
	output wire [AXI_DATA_WIDTH-1:0] MAXI_DATA_WDATA,
	output wire [AXI_DATA_WIDTH/8-1:0] MAXI_DATA_WSTRB,
	output wire  MAXI_DATA_WLAST,
	output wire  MAXI_DATA_WVALID,
	input wire  MAXI_DATA_WREADY,
	input wire [1:0] MAXI_DATA_BRESP,
	input wire  MAXI_DATA_BVALID,
	output wire  MAXI_DATA_BREADY,
	output wire [MAXI_DATA_ADDR_WIDTH-1:0] MAXI_DATA_ARADDR,
	output wire [7:0] MAXI_DATA_ARLEN,
	output wire [2:0] MAXI_DATA_ARSIZE,
	output wire [1:0] MAXI_DATA_ARBURST,
	output wire  MAXI_DATA_ARLOCK,
	output wire [3:0] MAXI_DATA_ARCACHE,
	output wire [2:0] MAXI_DATA_ARPROT,
	output wire [3:0] MAXI_DATA_ARQOS,
	output wire  MAXI_DATA_ARVALID,
	input wire  MAXI_DATA_ARREADY,
	input wire [AXI_DATA_WIDTH-1:0] MAXI_DATA_RDATA,
	input wire [1:0] MAXI_DATA_RRESP,
	input wire  MAXI_DATA_RLAST,
	input wire  MAXI_DATA_RVALID,
	output wire  MAXI_DATA_RREADY,

	// Debug ports
	output wire        dbg_oflowOccurredLatch,
	output wire [15:0] dbg_oflowCount,
	output wire [19:0] dbg_lclBufWritePointer,
	output wire [19:0] dbg_lclBufReadPointer,
	output wire [19:0] dbg_lclBufUnreadBytes,
	output wire  [2:0] dbg_state,
	output wire        dbg_axi_awvalid,
	output wire        dbg_axi_wvalid,
	output wire  [7:0] dbg_axi_wlen,
	output wire        dbg_axi_awready,
	output wire        dbg_axi_wready,
	output wire        dbg_axi_wlast,
	output wire [MAXI_DATA_ADDR_WIDTH-1:0] dbg_hb_writePtr,
	output wire [MAXI_DATA_ADDR_WIDTH-1:0] dbg_hb_hostReadPtr,
	output wire [13:0] dbg_hostBufferWriteableBytes
);
	// constants
	localparam AXI_DATA_BYTES = AXI_DATA_WIDTH / 8;
	localparam AXI_BRST_LIM = (AXI_DATA_BYTES) > 8 ? 256 : 255; // limit burst length to avoid issue with calculating max data transfer when there is an alignment offset
	localparam BRAM_BYTES_PER_COL_LB2 = 2;
	localparam BRAM_BYTES_PER_COL = 1 << BRAM_BYTES_PER_COL_LB2;
	localparam NUM_BR_ROWS_LB2 = 9;
	localparam NUM_BR_ROWS = 1 << NUM_BR_ROWS_LB2;

	// this DB buffer width would result in a wrapping write overlap
	localparam AVOID_DB_WIDTH = FIFO_INPUT_WIDTH_BYTES+1;

	// using variable input width introduces some potential errors. write wrap error can occur
	// under the following test cases (M = FIFO_INPUT_WIDTH_BYTES, N = actual write width):
	// 1: N = M-1
	// 2: N = 1,2,or3 followed by N = M
	// is user wants complete freedom for variable width writes, they can turn on FIFO_SAFE_VARIABLE_INPUT
	localparam MIN_DB_WIDTH = FIFO_INPUT_WIDTH_BYTES + ((FIFO_VARIABLE_INPUT_WIDTH && FIFO_SAFE_VARIABLE_INPUT) ? 3 : 0);

	// decide num BRAM columns
	localparam NUM_BR_COLS_LB2_PRE = max(clogb2((max(MIN_DB_WIDTH,AXI_DATA_BYTES)-1)/BRAM_BYTES_PER_COL),1); //min of 2 cols. 1 col produces a problem for addressing
	localparam NUM_BR_COLS_PRE = 1 << NUM_BR_COLS_LB2_PRE;
	localparam NUM_BR_COLS_LB2 = NUM_BR_COLS_LB2_PRE + ((NUM_BR_COLS_PRE*BRAM_BYTES_PER_COL) == AVOID_DB_WIDTH);
	localparam NUM_BR_COLS = 1 << NUM_BR_COLS_LB2;

	// decide num BRAM ranks
	localparam NUM_BR_RANKS = (FIFO_DEPTH * FIFO_INPUT_WIDTH_BYTES - 1)/(NUM_BR_ROWS * NUM_BR_COLS * 4) + 1;
	localparam NUM_BLOCK_RAMS = NUM_BR_COLS * NUM_BR_RANKS;
	localparam RAM_SIZE_BYTES = NUM_BLOCK_RAMS * BRAM_BYTES_PER_COL * NUM_BR_ROWS;
	localparam FIFO_ACTUAL_DEPTH = RAM_SIZE_BYTES / FIFO_INPUT_WIDTH_BYTES;
	localparam RANK_BITS = 32-BRAM_BYTES_PER_COL_LB2-NUM_BR_COLS_LB2-NUM_BR_ROWS_LB2;
	localparam BRNUM_BITS = clogb2(NUM_BLOCK_RAMS-1);
	localparam SG_LIST_NUM_BRAMS = SG_PAGE_LIST_LENGTH / 512;
	

	// function that returns the minimum of two numbers
	function [63:0] min;
		input [63:0] a,b;
		min = (a<b)?a:b;
	endfunction
	
	// function that returns the minimum of two numbers
	function [63:0] max;
		input [63:0] a,b;
		max = (a>b)?a:b;
	endfunction
	
	// function that returns the ceiling of the log base 2
	// note: not exactly. More accurate: returns the number of bits required to store the specified number
	// clogb2(x) = ceil(log_2(x+1))
	function [63:0] clogb2;
		input [63:0] bit_depth;
	begin
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			bit_depth = bit_depth >> 1;
		end
	endfunction
	
	// function that computes an address aligned to AXI_DATA_WIDTH
	function [MAXI_DATA_ADDR_WIDTH-1:0] alignedAddress;
		input [MAXI_DATA_ADDR_WIDTH-1:0] addr;
		
		alignedAddress = {addr[MAXI_DATA_ADDR_WIDTH-1:clogb2(AXI_DATA_BYTES-1)], {clogb2(AXI_DATA_BYTES-1){1'b0}}};
	endfunction
	
	// function to return the upper 32 bits of a 64 bit value
	function [31:0] HI;
		input [63:0] val;
		HI = val[63:32];
	endfunction
	
	
	
	// block ram interface
	reg [8:0] bramWrAddr[0:NUM_BLOCK_RAMS-1];
	reg [BRAM_BYTES_PER_COL*8-1:0] bramWrData[0:NUM_BLOCK_RAMS-1];
	reg [BRAM_BYTES_PER_COL-1:0] bramWE[0:NUM_BLOCK_RAMS-1];
	wire [BRAM_BYTES_PER_COL*8-1:0] bramRdData[0:NUM_BLOCK_RAMS-1];
	
	
	// block ram memory structure (each column is 4 bytes wide)
	// column:    0 1 2 3
	//           +-+-+-+-+
	//           |0|1|2|3|  row0
	//  rank 0   |4|5|6|7|  row1
	//           +-+-+-+-+
	//           |8|9|A|B|  row0
	//  rank 1   |C|D|E|F|  row1
	//           +-+-+-+-+	
	
	
	// FIFO INPUT ENGINE
	wire [clogb2(FIFO_INPUT_WIDTH_BYTES)-1:0] actualWriteWidthBytes = FIFO_VARIABLE_INPUT_WIDTH ? min(writeSizeBytes+1,FIFO_INPUT_WIDTH_BYTES) : FIFO_INPUT_WIDTH_BYTES;

	wire wc_resetFifo;
	reg [31:0] wc_lbWritePointer = 0;
	wire [31:0] wc_lbReadPointer;
	
	wire [31:0] freeSpace = (wc_lbWritePointer >= wc_lbReadPointer) ? RAM_SIZE_BYTES - wc_lbWritePointer + wc_lbReadPointer - 1: wc_lbReadPointer - wc_lbWritePointer - 1;
	assign fifoFull = freeSpace < (FIFO_INPUT_WIDTH_BYTES + AXI_DATA_BYTES); // always leave at least AXI_DATA_BYTES between read and write ptr so that we don't need to worry about strobing
	
	wire [31:0] writeEndBytePointer = wc_lbWritePointer + actualWriteWidthBytes - 1;
	
	reg [RANK_BITS-1:0] brStartRank = 0;
	reg [NUM_BR_ROWS_LB2-1:0] brStartSubRow = 0;
	reg [NUM_BR_COLS_LB2+BRAM_BYTES_PER_COL_LB2:0] brStartColByte = 0;
	reg [NUM_BR_COLS_LB2-1:0] brStartCol = 0;
	reg [BRAM_BYTES_PER_COL_LB2-1:0] brStartColSubByte = 0;
	reg [BRNUM_BITS:0] startBrNum = 0;
	
	reg [NUM_BR_ROWS_LB2-1:0] brEndRow = 0;
	reg [RANK_BITS-1:0] brEndRankPre = 0;
	reg [RANK_BITS-1:0] brEndRank = 0;
	reg [NUM_BR_COLS_LB2-1:0] brEndCol = 0;
	reg [BRAM_BYTES_PER_COL_LB2-1:0] brEndColSubByte = 0;
	reg [BRNUM_BITS:0] endBrNum = 0;
	reg [NUM_BR_COLS_LB2+BRAM_BYTES_PER_COL_LB2:0] wrapOffset = 0;
	reg isWrap = 0;
	
	wire [31:0] writePointerIncr = wc_lbWritePointer + actualWriteWidthBytes;
	
	reg [31:0] rank;
	reg [31:0] ctr;
	reg [31:0] bctr;
	reg [31:0] brctr;
	reg [31:0] currColByte;

	wire oflowOccurred = writeEnable && fifoFull;
	reg [31:0] oflowCount = 0;
	reg oflowOccurredLatch = 0;
	
	always @(posedge inputClk) begin
		if (wc_resetFifo) begin
			oflowCount <= 0;
			oflowOccurredLatch <= 0;
		end else begin
			oflowOccurredLatch <= oflowOccurredLatch || oflowOccurred;
			oflowCount <= oflowCount + ((!(&oflowCount)) && oflowOccurred); // saturating add
		end
		
		if (wc_resetFifo) begin
		
			wc_lbWritePointer <= 0;
			for (ctr = 0; ctr < NUM_BLOCK_RAMS; ctr=ctr+1)
                bramWE[ctr] <= 0;
				
		end else if (~fifoFull && writeEnable) begin
		
			{brStartRank, brStartSubRow, brStartCol, brStartColSubByte} = wc_lbWritePointer;
			startBrNum = (brStartRank << NUM_BR_COLS_LB2) + brStartCol;
			brStartColByte = {brStartCol, brStartColSubByte};
			
			{brEndRankPre, brEndRow, brEndCol, brEndColSubByte} = writeEndBytePointer;
			brEndRank = (brEndRankPre >= NUM_BR_RANKS) ? 0 : brEndRankPre;
			endBrNum = (brEndRank << NUM_BR_COLS_LB2) + brEndCol;
			
			isWrap = brEndCol < brStartCol;
			wrapOffset = (NUM_BR_COLS << BRAM_BYTES_PER_COL_LB2) - brStartColByte;
			
			for (rank = 0; rank < NUM_BR_RANKS; rank=rank+1)
				for (ctr = 0; ctr < NUM_BR_COLS; ctr=ctr+1) begin
					brctr = (rank << NUM_BR_COLS_LB2) + ctr;
					
					if ((rank == brStartRank) && (brctr >= startBrNum))
						bramWrAddr[brctr] <= brStartSubRow;
					else if (rank == brStartRank)
						bramWrAddr[brctr] <= brStartSubRow+1;
					else
						bramWrAddr[brctr] <= 0;
					
					for (bctr = 0; bctr < BRAM_BYTES_PER_COL; bctr=bctr+1) begin
						currColByte = (ctr << BRAM_BYTES_PER_COL_LB2) + bctr;
					
						if (isWrap && (rank == brEndRank) && ((brctr < endBrNum) || ((brctr == endBrNum) && (bctr <= brEndColSubByte)))) begin
							// this write wraps from last collumn to first collumn AND we are in the rank of the end of the write
							// AND {we have not reached the last BR OR {we are in the last BR AND have not passed the last byte}}
							bramWE[brctr][bctr] <= 1'b1;
							bramWrData[brctr][bctr*8+:8] <= inputData[(currColByte+wrapOffset)*8+:8];
						end else if ((rank == brStartRank) && ((brctr > startBrNum) || ((brctr == startBrNum) && (bctr >= brStartColSubByte))) && (isWrap || (brctr < endBrNum) || ((brctr == endBrNum) && (bctr <= brEndColSubByte)))) begin
							// we are in the rank of the start of the write AND {we are past the first BR OR {we are in the first
							// BR AND at or past the first byte}} AND {this is a wrap OR {we have not passed th last byte}}
							bramWE[brctr][bctr] <= 1'b1;
							bramWrData[brctr][bctr*8+:8] <= inputData[(currColByte-brStartColByte)*8+:8];
						end else begin
							bramWE[brctr][bctr] <= 1'b0;
							bramWrData[brctr][bctr*8+:8] <= 0;
						end
					end
				end
			
			wc_lbWritePointer <= ((writePointerIncr >= RAM_SIZE_BYTES) && (wc_lbReadPointer > 0)) ? writePointerIncr - RAM_SIZE_BYTES : writePointerIncr;
		end else begin
			for (ctr = 0; ctr < NUM_BLOCK_RAMS; ctr=ctr+1)
				bramWE[ctr] <= 0;
			wc_lbWritePointer <= ((wc_lbWritePointer >= RAM_SIZE_BYTES) && (wc_lbReadPointer > 0)) ? wc_lbWritePointer - RAM_SIZE_BYTES : wc_lbWritePointer;
		end
	end
	
	
	
	// SAXIL_CFG slave intf
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0ReadAddress;
	reg [SAXIL_CFG_DATA_WIDTH-1:0] s0ReadData = 0;
	wire s0WriteActive;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0WriteAddress;
	wire [SAXIL_CFG_DATA_WIDTH-1:0] s0WriteData;

	// MAXI_DATA bus internal temp signals
	reg [7:0] axi_burstLength = 0;
	reg axi_awvalid = 0;
	reg axi_wlast = 0;
	reg axi_wvalid = 0;
	reg [MAXI_DATA_ADDR_WIDTH-1 : 0] 	axi_awaddr = 0;
	reg [MAXI_DATA_ADDR_WIDTH-1 : 0] 	axi_araddr = 0;
	reg [AXI_DATA_WIDTH-1 : 0] 	axi_wdata = 0;
	reg [AXI_DATA_BYTES-1 : 0] 	axi_wstrb = {AXI_DATA_WIDTH{1'b1}};
	reg axi_arvalid = 0;
	reg axi_rready = 0;
	
	// MAXI_DATA bus I/O Connection assignments 
	assign MAXI_DATA_AWID	= 'b0;
	assign MAXI_DATA_AWADDR	= axi_awaddr;
	assign MAXI_DATA_AWLEN	= axi_burstLength;			// Burst LENgth is number of transaction beats, minus 1
	assign MAXI_DATA_AWSIZE	= clogb2(AXI_DATA_BYTES-1);		// Size should be DATA_WIDTH, in 2^SIZE bytes, otherwise narrow bursts are used
	assign MAXI_DATA_AWBURST	= 2'b01;				// INCR burst type
	assign MAXI_DATA_AWLOCK	= 1'b0;
	assign MAXI_DATA_AWCACHE	= 4'b0001; 				// Device Bufferable. The write response can be obtained from an intermediate point. Was 4'b0010 (Normal Non-cacheable Non-bufferable)
	assign MAXI_DATA_AWPROT	= 3'h0;
	assign MAXI_DATA_AWQOS	= 4'h0;
	assign MAXI_DATA_AWVALID	= axi_awvalid;
	assign MAXI_DATA_WDATA	= axi_wdata;
	assign MAXI_DATA_WSTRB	= axi_wstrb;
	assign MAXI_DATA_WLAST	= axi_wlast;
	assign MAXI_DATA_WVALID	= axi_wvalid;
	assign MAXI_DATA_BREADY	= 1;
	assign MAXI_DATA_ARID	= 'b0;
	assign MAXI_DATA_ARADDR	= axi_araddr;
	assign MAXI_DATA_ARLEN	= 0;						// Burst LENgth is number of transaction beats, minus 1
	assign MAXI_DATA_ARSIZE	= clogb2(AXI_DATA_BYTES-1);		// Size should be DATA_WIDTH, in 2^n bytes, otherwise narrow bursts are used
	assign MAXI_DATA_ARBURST	= 2'b01;				//INCR burst type is usually used, except for keyhole bursts
	assign MAXI_DATA_ARLOCK	= 1'b0;
	assign MAXI_DATA_ARCACHE	= 4'b0010;				//Update value to 4'b0011 if coherent accesses to be used via the Zynq ACP port. Not Allocated, Modifiable, not Bufferable. Not Bufferable since this example is meant to test memory, not intermediate cache. 
	assign MAXI_DATA_ARPROT	= 3'h0;
	assign MAXI_DATA_ARQOS	= 4'h0;
	assign MAXI_DATA_ARVALID	= axi_arvalid;
	assign MAXI_DATA_RREADY	= axi_rready;
	
	// Transport configuration/status data. positions are in bytes
	reg [31:0] hostBufferFirstPageAddress = 0;
	wire [31:0] hostBufferCurrPageAddress;
	wire [31:0] hb_writePtrPageSubAddr;
	reg [MAXI_DATA_ADDR_WIDTH-1:0] hostBufferTotalSize = 0;
	reg [31:0] hostBufferNumPages = 0;
	reg [4:0] hostBufferPageSizeLB2 = 0;
	reg configured = 0;
	reg blockForRead = BLOCK_FOR_READ;
	
	
	reg [MAXI_DATA_ADDR_WIDTH-1:0] hb_writePtr = 0;
	reg [MAXI_DATA_ADDR_WIDTH-1:0] hb_hostReadPtr = 0;
	reg [31:0] hostBufferLaps = 0;
	
	
	
	
	// AXI OUTPUT ENGINE
	localparam [2:0] UNCONFIGURED = 0,
		WAITING_FOR_DATA1 = 1,
		WAITING_FOR_DATA2 = 2,
		PREPARING_BURST = 3,
		SENDING_ADDR = 4,
		SENDING_DATA = 5;
	reg [2:0] state = UNCONFIGURED;
	
	reg [12:0] sendBytesRemaining = 0;
	reg [12:0] transferSizeTmp = 0;
	reg [12:0] transferSizeTmp2 = 0;
	reg [12:0] transferSize = 0;
	reg [12:0] nextBeatSize = 0;
	reg [31:0] lastByteToWritePtr = 0;
	reg [31:0] alignedLastByteToWritePtr = 0;
	reg [31:0] alignedWritePointer = 0;
	
	reg axi_wvalid_tmp = 0;
	reg axi_awvalid_tmp = 0;
	
	
	wire [31:0] rc_lbWritePointer;
	reg [31:0] rc_lbReadPointer = 0;
	
	wire [31:0] lbUnreadBytes = (rc_lbWritePointer >= rc_lbReadPointer) ? rc_lbWritePointer - rc_lbReadPointer : RAM_SIZE_BYTES - rc_lbReadPointer + rc_lbWritePointer;
	reg [13:0] hostBufferWriteableBytes = 0;
	
	reg [15:0] rctr;
	reg [RANK_BITS-1:0] rpCurrRank = 0;
	reg [NUM_BR_ROWS_LB2-1:0] rpCurrSubRow = 0;
	reg [NUM_BR_COLS_LB2-1:0] rpCurrCol = 0;
	reg [BRAM_BYTES_PER_COL_LB2-1:0] rpCurrColSubByte = 0;
	reg [BRNUM_BITS-1:0] rpAlignedStartBrNum = 0;
	reg [BRNUM_BITS-1:0] rpCurrBrNum = 0;
	
	wire resetFifo = state == UNCONFIGURED;
	reg resetFifoReg = 1;
	
	
	reg sendingFirstBeat = 0;
	wire [clogb2(AXI_DATA_BYTES)-1:0] bytesReadFromLclBuffer = (sendingFirstBeat || (axi_wvalid && MAXI_DATA_WREADY)) ? nextBeatSize : 0;
								

	//reg [31:0] lbReadPointerPreup = 0;
	wire [31:0] lbReadPointerPreup = rc_lbReadPointer + bytesReadFromLclBuffer;


	//reg [31:0] lbNextReadPointer = 0;
	wire [31:0] lbNextReadPointer = (lbReadPointerPreup >= RAM_SIZE_BYTES) ? lbReadPointerPreup - RAM_SIZE_BYTES : lbReadPointerPreup;
	
	reg axiResetNr = 0;
	
	always @(posedge axiClk) begin
		resetFifoReg <= resetFifo;
		axiResetNr <= axiResetN;
		
		// main state machine 
		if (~axiResetNr) begin
			state <= UNCONFIGURED;
			axi_awvalid <= 0;
			axi_wvalid <= 0;
			sendingFirstBeat <= 0;
		end else case (state)
			UNCONFIGURED: begin
				axi_awvalid <= 0;
				axi_wvalid <= 0;
				hb_writePtr <= 0;
				hostBufferLaps <= 0;
				sendingFirstBeat <= 0;
				
				if (configured) // the host has written an address. we can start operating
					state <= WAITING_FOR_DATA1;
			end
			
			WAITING_FOR_DATA1: begin
				// move write pointer to beginning of buffer if needed
				if (!configured)
					state <= UNCONFIGURED;
				else if (hb_writePtr >= hostBufferTotalSize) begin
					if (hb_hostReadPtr || !blockForRead) begin
						hb_writePtr <= 0;
						hostBufferLaps <= hostBufferLaps + 1;
					end
				end else
					state <= WAITING_FOR_DATA2;
						
				// determine max number of bytes that can be transferred in this transaction based on position of
				// host buffer read/write pointers, AXI burst length limit, and 4kb boundaries
				if ((hb_writePtr >= hb_hostReadPtr) || !blockForRead)
					hostBufferWriteableBytes <= min(min(hostBufferTotalSize - hb_writePtr, AXI_DATA_BYTES * AXI_BRST_LIM), 13'd4096- {1'b0, hb_writePtr[11:0]});
				else if (hb_hostReadPtr > (hb_writePtr + AXI_DATA_BYTES)) // always leave at least AXI_DATA_BYTES between read and write ptr so that we don't need to worry about strobing
					hostBufferWriteableBytes <= min(min(hb_hostReadPtr - hb_writePtr - AXI_DATA_BYTES, AXI_DATA_BYTES * AXI_BRST_LIM), 13'd4096- {1'b0, hb_writePtr[11:0]});
				else
					hostBufferWriteableBytes <= 0;
			end
			
			WAITING_FOR_DATA2: begin
				// determine transfer size by limit calculated earlier and actual size of available data
				transferSizeTmp = min(hostBufferWriteableBytes, lbUnreadBytes);
				
				// if AXI and FIFO width match, we dont allow partial elements to be transferred
				if ((FIFO_VARIABLE_INPUT_WIDTH == 0) && (FIFO_INPUT_WIDTH_BYTES*8 == AXI_DATA_BYTES))
					transferSizeTmp2[12:clogb2(AXI_DATA_BYTES-1)] = transferSizeTmp[12:clogb2(AXI_DATA_BYTES-1)];
				else
					transferSizeTmp2 = transferSizeTmp;
					
				// the second tmp variable is just so that writes to transferSize are non blocking
				transferSize <= transferSizeTmp2;
				
				// figure out first beat alignment
				alignedWritePointer <= alignedAddress(hb_writePtrPageSubAddr);
				nextBeatSize <= min(AXI_DATA_BYTES - (hb_writePtrPageSubAddr - alignedAddress(hb_writePtrPageSubAddr)),transferSizeTmp2);
				
				if (transferSizeTmp2) begin
					state <= PREPARING_BURST;
					sendingFirstBeat <= 1;
				end else
					state <= WAITING_FOR_DATA1;
			end
			
			PREPARING_BURST: begin
				lastByteToWritePtr = hb_writePtrPageSubAddr + transferSize - 1;
				alignedLastByteToWritePtr = alignedAddress(lastByteToWritePtr);
				
				axi_awaddr = {hostBufferCurrPageAddress, 12'h000} + alignedWritePointer;
				axi_burstLength = (alignedLastByteToWritePtr - alignedWritePointer) >> clogb2(AXI_DATA_BYTES-1);
				
				sendBytesRemaining <= transferSize - nextBeatSize;
				nextBeatSize <= min(AXI_DATA_BYTES, transferSize - nextBeatSize);
				axi_awvalid <= 1;
				sendingFirstBeat <= 0;
				
				axi_wlast <= (axi_burstLength < 1) && MAXI_DATA_AWREADY;
				axi_wvalid <= MAXI_DATA_AWREADY;
				
				state <= MAXI_DATA_AWREADY ? SENDING_DATA : SENDING_ADDR;
			end
			
			SENDING_ADDR: begin
				if (MAXI_DATA_AWREADY) begin
					axi_awvalid <= 0;
					state <= SENDING_DATA;
					axi_wvalid <= 1;
					axi_wlast <= axi_burstLength < 1;
				end
			end
			
			SENDING_DATA: begin
				
				if (MAXI_DATA_WREADY) begin
					// the slave accepted the data we presented last clock
					if (sendBytesRemaining) begin
						// we have more data to send. offer it up!
						sendBytesRemaining <= sendBytesRemaining - nextBeatSize;
						nextBeatSize <= min(AXI_DATA_BYTES, sendBytesRemaining - nextBeatSize);
						
						axi_wlast <= nextBeatSize == sendBytesRemaining;
						axi_wvalid_tmp = 1;
					end else begin
						// no more data to send! we are done!
						axi_wlast <= 0;
						axi_wvalid_tmp = 0;
						
						if (axi_wvalid)
							hb_writePtr <= hb_writePtr + transferSize;
					end
				end else begin
					// the slave hasnt accepted the data we offered last clk yet
					axi_wlast <= axi_wlast;
					axi_wvalid_tmp = 1;
				end
				
				
				if (MAXI_DATA_AWREADY)
					axi_awvalid_tmp = 0;
				else
					axi_awvalid_tmp = axi_awvalid;
				
				axi_awvalid <= axi_awvalid_tmp;
				axi_wvalid <= axi_wvalid_tmp;
				
				if(~axi_awvalid_tmp && ~axi_wvalid_tmp && (sendBytesRemaining < 1))
					state <= WAITING_FOR_DATA1;
			end
		endcase
		
		if (resetFifo)
			rc_lbReadPointer <= 0;
		else
			rc_lbReadPointer <= lbNextReadPointer;
		
		if (bytesReadFromLclBuffer) begin
			// we are taking advantage of the fact that AXI writes are always address aligned and that the width
			// of our bram buffer is always an integer multiple of the axi width to simplify the logic here
			{rpCurrRank, rpCurrSubRow, rpCurrCol, rpCurrColSubByte} = alignedAddress(rc_lbReadPointer);
			rpAlignedStartBrNum = (rpCurrRank << NUM_BR_COLS_LB2) + rpCurrCol;
			
			for(rctr = 0; rctr < AXI_DATA_BYTES; rctr=rctr+1) begin
				rpCurrBrNum = rpAlignedStartBrNum + (rctr >> BRAM_BYTES_PER_COL_LB2);
				axi_wdata[rctr*8+:8] <= bramRdData[rpCurrBrNum][rctr[BRAM_BYTES_PER_COL_LB2-1:0]*8+:8];
			end
		end
	end



	// AXI latency tracker
	reg aw_valid_p = 1;
	reg wlast_p = 1;

	reg aw_valid_RE = 0;
	reg wlast_RE = 0;

	reg reqStarted = 0;
	reg [15:0] transactionTimer = 0;
	reg [15:0] thisReqToDataLatency = 0;

	reg [15:0] lastReqToDataLatency = 0;
	reg [15:0] lastDataDuration = 0;

	reg [15:0] maxReqToDataLatency = 0;
	reg [15:0] maxDataDuration = 0;

	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0ActiveWriteAddress = s0WriteActive ? s0WriteAddress : 0;

	always @(posedge axiClk) begin
		aw_valid_p <= axi_awvalid;
		wlast_p <= MAXI_DATA_WLAST && MAXI_DATA_WREADY;
		
		aw_valid_RE <= axi_awvalid && ~aw_valid_p;
		wlast_RE <= MAXI_DATA_WLAST && MAXI_DATA_WREADY && ~wlast_p;

		if (aw_valid_RE) begin
			transactionTimer <= 1;
			reqStarted <= 1;
		end else if (reqStarted && MAXI_DATA_WREADY) begin
			reqStarted <= 0;
			thisReqToDataLatency <= transactionTimer;
			transactionTimer <= 1;
		end else
			transactionTimer <= transactionTimer + (!(&transactionTimer)); // saturating add
		
		if (wlast_RE) begin
			lastReqToDataLatency <= thisReqToDataLatency;
			lastDataDuration <= transactionTimer;
		end else if (s0ActiveWriteAddress == 192) begin
			lastReqToDataLatency <= 0;
			lastDataDuration <= 0;
		end 

		if (s0ActiveWriteAddress == 192)
			maxReqToDataLatency <= 0;
		else if (lastReqToDataLatency > maxReqToDataLatency)
			maxReqToDataLatency <= lastReqToDataLatency;

		if (s0ActiveWriteAddress == 192)
			maxDataDuration <= 0;
		else if (lastDataDuration > maxDataDuration)
			maxDataDuration <= lastDataDuration;
	end
	

	
	// axi config slave
	// receives configuration data and commands from host
	reg [31:0] lbMaxUnreadBytes = 0;
	
	reg [31:0] consecDataAvail = 0;
	reg [63:0] bytesTransferred = 0;
	reg lbEmpty = 0;
	reg lbWasEmpty = 0;
	
	reg [MAXI_DATA_ADDR_WIDTH-1:0] hb_writePtrCache = 0;
	
	reg [31:0] writeSGPageListAddr = 0;
	reg [31:0] writeSGPageListData = 0;
	reg writeSGPageList = 0;
	
	reg [31:0] tempBits = 0;

	wire [31:0] oflowCount_ac;
	
	always @(posedge axiClk) begin
		if (~axiResetNr) begin
			hostBufferFirstPageAddress <= 0;
			lbMaxUnreadBytes <= 0;
			hb_hostReadPtr <= 0;
			configured <= 0;
		end else begin
		
			//performance monitor
			lbEmpty = lbUnreadBytes == 0;
			lbWasEmpty <= lbEmpty;
			
			if (~lbEmpty && lbWasEmpty) begin
				consecDataAvail <= 0;
				bytesTransferred <= 0;
			end else if (~lbEmpty) begin
				consecDataAvail <= consecDataAvail + 1;
				bytesTransferred <= bytesTransferred + bytesReadFromLclBuffer;
			end
		
			case (s0ReadAddress)
				0: s0ReadData <= 32'h_F1F0_1002; // FIFO, F2M, v2
				
				4: s0ReadData <= 32'h_CACA_0002; // Scatter gather page list, v2
				
				8: s0ReadData <= SG_PAGE_LIST_LENGTH;
				
				12: s0ReadData <= MAXI_DATA_ADDR_WIDTH;
			
				16: s0ReadData <= hostBufferFirstPageAddress;
				
				20: s0ReadData <= hostBufferTotalSize;
				
				24: s0ReadData <= HI(hostBufferTotalSize);
				
				28: s0ReadData <= hostBufferNumPages;
				
				32: s0ReadData <= hostBufferPageSizeLB2;
				
				36: s0ReadData <= writeSGPageListAddr;
				
				40: s0ReadData <= FIFO_VARIABLE_INPUT_WIDTH;
				
				
				100: s0ReadData <= hostBufferLaps;
				
				104: s0ReadData <= hb_writePtrCache;
				
				108: s0ReadData <= HI(hb_writePtrCache);
				
				112: s0ReadData <= hb_hostReadPtr;
				
				116: s0ReadData <= HI(hb_hostReadPtr);
				
				120: s0ReadData <= lbUnreadBytes;
				
				124: s0ReadData <= 1337; // sanity check
				
				128: s0ReadData <= state;
				
				132: s0ReadData <= blockForRead;
				
				136: s0ReadData <= rc_lbWritePointer;
				
				140: s0ReadData <= rc_lbReadPointer;
				
				144: s0ReadData <= RAM_SIZE_BYTES;
				
				148: s0ReadData <= NUM_BR_COLS;
				
				152: s0ReadData <= NUM_BR_RANKS;
				
				156: s0ReadData <= NUM_BLOCK_RAMS;
				
				160: s0ReadData <= FIFO_ACTUAL_DEPTH;
				
				164: s0ReadData <= lbMaxUnreadBytes;
				
			//	168:
				
				172: s0ReadData <= consecDataAvail;
				
				176: s0ReadData <= bytesTransferred;
				
				180: s0ReadData <= HI(bytesTransferred);

				184: s0ReadData <= oflowCount_ac;

				188: s0ReadData <= {lastDataDuration, lastReqToDataLatency};
				192: s0ReadData <= {maxDataDuration, maxReqToDataLatency};
				
			/*	200: s0ReadData <= currPage;
				
				204: s0ReadData <= currSglBr;
				
				208: s0ReadData <= writeSGPageListAddr[31:9];
				
				212: s0ReadData <= sgPageListReadData[0];
				
				216: s0ReadData <= sgPageListReadData[1];
				
				220: s0ReadData <= sgPageListReadData[2];
				
				224: s0ReadData <= sgPageListReadData[3];
				
				228: s0ReadData <= hostBufferCurrPageAddress;
				
			*/	default: s0ReadData <= 32'hF1F0_E1D1;
			endcase
		
			if (s0WriteActive && (s0WriteAddress == 164))
				lbMaxUnreadBytes <= 0;
			else
				lbMaxUnreadBytes <= max(lbUnreadBytes, lbMaxUnreadBytes);
		
			case (s0ActiveWriteAddress)
				16: begin // Host buffer address
					hostBufferFirstPageAddress <= s0WriteData;
					hostBufferTotalSize <= 0;
					configured <= 0;
					
					writeSGPageListAddr <= 0;
					writeSGPageListData <= s0WriteData;
				end
				
				20: tempBits <= s0WriteData;
				
				24: hostBufferTotalSize <= {s0WriteData, tempBits};
				
				28: begin
					hostBufferNumPages <= s0WriteData;
					configured <= s0WriteData == 1;
				end
				
				32: hostBufferPageSizeLB2 <= s0WriteData;
				
				36: begin
					writeSGPageListAddr <= writeSGPageListAddr + 1;
					writeSGPageListData <= s0WriteData;
					
					configured <= writeSGPageListAddr == (hostBufferNumPages - 2);
				end
				
				//40: FIFO_VARIABLE_INPUT_WIDTH
				
				104: hb_writePtrCache <= hb_writePtr;
			
				132: blockForRead <= s0WriteData;
				
				112: tempBits <= s0WriteData;
				
			endcase
			
			if (resetFifo)
				hb_hostReadPtr <= 0;
			else if (s0ActiveWriteAddress == 116)
				hb_hostReadPtr <= {s0WriteData, tempBits};
			
			writeSGPageList <= s0WriteActive && ((s0WriteAddress == 16) || (s0WriteAddress == 36));
		end
	end
	
	
	
	
	// input/output clock crossing values
	SBCCi reset_crss(.srcV(resetFifoReg), .srcClk(axiClk), .dstV(wc_resetFifo), .dstClk(inputClk));
	SWCCi #(.WW(32), .CONTINUOUS(0)) writePointer_crss(.srcV(wc_lbWritePointer), .srcClk(inputClk), .dstV(rc_lbWritePointer), .dstClk(axiClk), .dstRst(~axiResetNr));
	SWCCi #(.WW(32)) readPointer_crss(.srcV(rc_lbReadPointer), .srcClk(axiClk), .dstV(wc_lbReadPointer), .dstClk(inputClk), .dstRst(wc_resetFifo));
	SWCCi #(.WW(32)) oflowCount_crss(.srcV(oflowCount), .srcClk(inputClk), .dstV(oflowCount_ac), .dstClk(axiClk), .dstRst(~axiResetNr));
	
	
	// br read address logic
	wire [RANK_BITS-1:0] rpStartRank;
	wire [NUM_BR_ROWS_LB2-1:0] rpStartSubRow;
	wire [NUM_BR_COLS_LB2-1:0] rpStartCol;
	
	// assign {rpStartRank, rpStartSubRow, rpStartCol} = lbNextReadPointer[31:2];
	// use lbReadPointerPreup instead of lbNextReadPointer to help meet timing. the only difference is that lbNextReadPointer takes buffer
	// wrap around into account. Since the lcl buffer will always be a multiple of 4096, an axi transaction will never wrap around. therefore
	// it is never important to have correct data available on the next clock cycle when wrap around occurs.
	assign {rpStartRank, rpStartSubRow, rpStartCol} = lbReadPointerPreup[31:2];
	
	// generate local buffer block rams
	generate
		genvar gBrCtr;
		
		for (gBrCtr=0; gBrCtr<NUM_BLOCK_RAMS; gBrCtr=gBrCtr+1) begin : generate_block_rams
			RAMB18E2 #(
				// CASCADE_ORDER_A, CASCADE_ORDER_B: "FIRST", "MIDDLE", "LAST", "NONE"
				.CASCADE_ORDER_A("NONE"),
				.CASCADE_ORDER_B("NONE"),
				// CLOCK_DOMAINS: "COMMON", "INDEPENDENT"
				.CLOCK_DOMAINS("INDEPENDENT"),
				// Collision check: "ALL", "GENERATE_X_ONLY", "NONE", "WARNING_ONLY"
				.SIM_COLLISION_CHECK("ALL"),
				// DOA_REG, DOB_REG: Optional output register (0, 1)
				.DOA_REG(0),
				.DOB_REG(0),
				// ENADDRENA/ENADDRENB: Address enable pin enable, "TRUE", "FALSE"
				.ENADDRENA("FALSE"),
				.ENADDRENB("FALSE"),
				// INIT_A, INIT_B: Initial values on output ports
				.INIT_A(18'h00000),
				.INIT_B(18'h00000),
				// Initialization File: RAM initialization file
				.INIT_FILE("NONE"),
				// Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
				.IS_CLKARDCLK_INVERTED(1'b0),
				.IS_CLKBWRCLK_INVERTED(1'b0),
				.IS_ENARDEN_INVERTED(1'b0),
				.IS_ENBWREN_INVERTED(1'b0),
				.IS_RSTRAMARSTRAM_INVERTED(1'b0),
				.IS_RSTRAMB_INVERTED(1'b0),
				.IS_RSTREGARSTREG_INVERTED(1'b0),
				.IS_RSTREGB_INVERTED(1'b0),
				// RDADDRCHANGE: Disable memory access when output value does not change ("TRUE", "FALSE")
				.RDADDRCHANGEA("FALSE"),
				.RDADDRCHANGEB("FALSE"),
				// READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
				.READ_WIDTH_A(36), // 0-9
				.READ_WIDTH_B(0), // 0-9
				.WRITE_WIDTH_A(0), // 0-9
				.WRITE_WIDTH_B(36), // 0-9
				// RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG", "REGCE")
				.RSTREG_PRIORITY_A("RSTREG"),
				.RSTREG_PRIORITY_B("RSTREG"),
				// SRVAL_A, SRVAL_B: Set/reset value for output
				.SRVAL_A(18'h00000),
				.SRVAL_B(18'h00000),
				// Sleep Async: Sleep function asynchronous or synchronous ("TRUE", "FALSE")
				.SLEEP_ASYNC("FALSE"),
				// WriteMode: "WRITE_FIRST", "NO_CHANGE", "READ_FIRST"
				.WRITE_MODE_A("READ_FIRST"),
				.WRITE_MODE_B("READ_FIRST")
			) RAMB18E2_inst (
				// Cascade Signals outputs: Multi-BRAM cascade signals
				.CASDOUTA(), // 16-bit output: Port A cascade output data
				.CASDOUTB(), // 16-bit output: Port B cascade output data
				.CASDOUTPA(), // 2-bit output: Port A cascade output parity data
				.CASDOUTPB(), // 2-bit output: Port B cascade output parity data
				// Port A Data outputs: Port A data
				.DOUTADOUT(bramRdData[gBrCtr][15:0]), // 16-bit output: Port A data/LSB data
				.DOUTPADOUTP(), // 2-bit output: Port A parity/LSB parity
				// Port B Data outputs: Port B data
				.DOUTBDOUT(bramRdData[gBrCtr][31:16]), // 16-bit output: Port B data/MSB data
				.DOUTPBDOUTP(), // 2-bit output: Port B parity/MSB parity
				// Cascade Signals inputs: Multi-BRAM cascade signals
				.CASDIMUXA(1'b0), // 1-bit input: Port A input data (0=DINA, 1=CASDINA)
				.CASDIMUXB(1'b0), // 1-bit input: Port B input data (0=DINB, 1=CASDINB)
				.CASDINA(16'd0), // 16-bit input: Port A cascade input data
				.CASDINB(16'd0), // 16-bit input: Port B cascade input data
				.CASDINPA(2'd0), // 2-bit input: Port A cascade input parity data
				.CASDINPB(2'd0), // 2-bit input: Port B cascade input parity data
				.CASDOMUXA(1'b0), // 1-bit input: Port A unregistered data (0=BRAM data, 1=CASDINA)
				.CASDOMUXB(1'b0), // 1-bit input: Port B unregistered data (0=BRAM data, 1=CASDINB)
				.CASDOMUXEN_A(1'b1), // 1-bit input: Port A unregistered output data enable
				.CASDOMUXEN_B(1'b1), // 1-bit input: Port B unregistered output data enable
				.CASOREGIMUXA(1'b0), // 1-bit input: Port A registered data (0=BRAM data, 1=CASDINA)
				.CASOREGIMUXB(1'b0), // 1-bit input: Port B registered data (0=BRAM data, 1=CASDINB)
				.CASOREGIMUXEN_A(1'b1), // 1-bit input: Port A registered output data enable
				.CASOREGIMUXEN_B(1'b1), // 1-bit input: Port B registered output data enable
				// Port A Address/Control Signals inputs: Port A address and control signals
				.ADDRARDADDR({rpStartSubRow, 5'd0}), // 14-bit input: A/Read port address
				.ADDRENA(1'b1), // 1-bit input: Active-High A/Read port address enable
				.CLKARDCLK(axiClk), // 1-bit input: A/Read port clock
				.ENARDEN(1'b1), // 1-bit input: Port A enable/Read enable
				.REGCEAREGCE(1'b0), // 1-bit input: Port A register enable/Register enable
				.RSTRAMARSTRAM(1'b0), // 1-bit input: Port A set/reset
				.RSTREGARSTREG(1'b0), // 1-bit input: Port A register set/reset
				.WEA(2'b11), // 2-bit input: Port A write enable
				// Port A Data inputs: Port A data
				.DINADIN(bramWrData[gBrCtr][15:0]), // 16-bit input: Port A data/LSB data
				.DINPADINP(2'd0), // 2-bit input: Port A parity/LSB parity
				// Port B Address/Control Signals inputs: Port B address and control signals
				.ADDRBWRADDR({bramWrAddr[gBrCtr], 5'd0}), // 14-bit input: B/Write port address
				.ADDRENB(1'b1), // 1-bit input: Active-High B/Write port address enable
				.CLKBWRCLK(inputClk), // 1-bit input: B/Write port clock
				.ENBWREN(1'b1), // 1-bit input: Port B enable/Write enable
				.REGCEB(1'b0), // 1-bit input: Port B register enable
				.RSTRAMB(1'b0), // 1-bit input: Port B set/reset
				.RSTREGB(1'b0), // 1-bit input: Port B register set/reset
				.SLEEP(1'b0), // 1-bit input: Sleep Mode
				.WEBWE(bramWE[gBrCtr]), // 4-bit input: Port B write enable/Write enable
				// Port B Data inputs: Port B data
				.DINBDIN(bramWrData[gBrCtr][31:16]), // 16-bit input: Port B data/MSB data
				.DINPBDINP(2'd0) // 2-bit input: Port B parity/MSB parity
			);
		end 
	endgenerate
	
	
	
	
	
	wire [31:0] sgPageListReadData[SG_LIST_NUM_BRAMS-1:0];
	wire [31:0] currPage = hb_writePtr >> hostBufferPageSizeLB2;
	assign hb_writePtrPageSubAddr = hb_writePtr - (currPage << hostBufferPageSizeLB2);
	
	wire [22:0] currSglBr = currPage[31:9];
	assign hostBufferCurrPageAddress = sgPageListReadData[currSglBr];
	
	// generate scatter gather list block rams
	genvar sgl_i;
	generate
		for (sgl_i=0; sgl_i<SG_LIST_NUM_BRAMS; sgl_i=sgl_i+1) begin : generate_sgl_block_rams
			RAMB18E2 #(
				// CASCADE_ORDER_A, CASCADE_ORDER_B: "FIRST", "MIDDLE", "LAST", "NONE"
				.CASCADE_ORDER_A("NONE"),
				.CASCADE_ORDER_B("NONE"),
				// CLOCK_DOMAINS: "COMMON", "INDEPENDENT"
				.CLOCK_DOMAINS("COMMON"),
				// Collision check: "ALL", "GENERATE_X_ONLY", "NONE", "WARNING_ONLY"
				.SIM_COLLISION_CHECK("ALL"),
				// DOA_REG, DOB_REG: Optional output register (0, 1)
				.DOA_REG(0),
				.DOB_REG(0),
				// ENADDRENA/ENADDRENB: Address enable pin enable, "TRUE", "FALSE"
				.ENADDRENA("FALSE"),
				.ENADDRENB("FALSE"),
				// INIT_A, INIT_B: Initial values on output ports
				.INIT_A(18'h00000),
				.INIT_B(18'h00000),
				// Initialization File: RAM initialization file
				.INIT_FILE("NONE"),
				// Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
				.IS_CLKARDCLK_INVERTED(1'b0),
				.IS_CLKBWRCLK_INVERTED(1'b0),
				.IS_ENARDEN_INVERTED(1'b0),
				.IS_ENBWREN_INVERTED(1'b0),
				.IS_RSTRAMARSTRAM_INVERTED(1'b0),
				.IS_RSTRAMB_INVERTED(1'b0),
				.IS_RSTREGARSTREG_INVERTED(1'b0),
				.IS_RSTREGB_INVERTED(1'b0),
				// RDADDRCHANGE: Disable memory access when output value does not change ("TRUE", "FALSE")
				.RDADDRCHANGEA("FALSE"),
				.RDADDRCHANGEB("FALSE"),
				// READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
				.READ_WIDTH_A(36), // 0-9
				.READ_WIDTH_B(0), // 0-9
				.WRITE_WIDTH_A(0), // 0-9
				.WRITE_WIDTH_B(36), // 0-9
				// RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG", "REGCE")
				.RSTREG_PRIORITY_A("RSTREG"),
				.RSTREG_PRIORITY_B("RSTREG"),
				// SRVAL_A, SRVAL_B: Set/reset value for output
				.SRVAL_A(18'h00000),
				.SRVAL_B(18'h00000),
				// Sleep Async: Sleep function asynchronous or synchronous ("TRUE", "FALSE")
				.SLEEP_ASYNC("FALSE"),
				// WriteMode: "WRITE_FIRST", "NO_CHANGE", "READ_FIRST"
				.WRITE_MODE_A("READ_FIRST"),
				.WRITE_MODE_B("READ_FIRST")
			) RAMB18E2_inst (
				// Cascade Signals outputs: Multi-BRAM cascade signals
				.CASDOUTA(), // 16-bit output: Port A cascade output data
				.CASDOUTB(), // 16-bit output: Port B cascade output data
				.CASDOUTPA(), // 2-bit output: Port A cascade output parity data
				.CASDOUTPB(), // 2-bit output: Port B cascade output parity data
				// Port A Data outputs: Port A data
				.DOUTADOUT(sgPageListReadData[sgl_i][15:0]), // 16-bit output: Port A data/LSB data
				.DOUTPADOUTP(), // 2-bit output: Port A parity/LSB parity
				// Port B Data outputs: Port B data
				.DOUTBDOUT(sgPageListReadData[sgl_i][31:16]), // 16-bit output: Port B data/MSB data
				.DOUTPBDOUTP(), // 2-bit output: Port B parity/MSB parity
				// Cascade Signals inputs: Multi-BRAM cascade signals
				.CASDIMUXA(1'b0), // 1-bit input: Port A input data (0=DINA, 1=CASDINA)
				.CASDIMUXB(1'b0), // 1-bit input: Port B input data (0=DINB, 1=CASDINB)
				.CASDINA(16'd0), // 16-bit input: Port A cascade input data
				.CASDINB(16'd0), // 16-bit input: Port B cascade input data
				.CASDINPA(2'd0), // 2-bit input: Port A cascade input parity data
				.CASDINPB(2'd0), // 2-bit input: Port B cascade input parity data
				.CASDOMUXA(1'b0), // 1-bit input: Port A unregistered data (0=BRAM data, 1=CASDINA)
				.CASDOMUXB(1'b0), // 1-bit input: Port B unregistered data (0=BRAM data, 1=CASDINB)
				.CASDOMUXEN_A(1'b1), // 1-bit input: Port A unregistered output data enable
				.CASDOMUXEN_B(1'b1), // 1-bit input: Port B unregistered output data enable
				.CASOREGIMUXA(1'b0), // 1-bit input: Port A registered data (0=BRAM data, 1=CASDINA)
				.CASOREGIMUXB(1'b0), // 1-bit input: Port B registered data (0=BRAM data, 1=CASDINB)
				.CASOREGIMUXEN_A(1'b1), // 1-bit input: Port A registered output data enable
				.CASOREGIMUXEN_B(1'b1), // 1-bit input: Port B registered output data enable
				// Port A Address/Control Signals inputs: Port A address and control signals
				.ADDRARDADDR({currPage[8:0], 5'd0}), // 14-bit input: A/Read port address
				.ADDRENA(1'b1), // 1-bit input: Active-High A/Read port address enable
				.CLKARDCLK(axiClk), // 1-bit input: A/Read port clock
				.ENARDEN(1'b1), // 1-bit input: Port A enable/Read enable
				.REGCEAREGCE(1'b0), // 1-bit input: Port A register enable/Register enable
				.RSTRAMARSTRAM(1'b0), // 1-bit input: Port A set/reset
				.RSTREGARSTREG(1'b0), // 1-bit input: Port A register set/reset
				.WEA(2'b11), // 2-bit input: Port A write enable
				// Port A Data inputs: Port A data
				.DINADIN(writeSGPageListData[15:0]), // 16-bit input: Port A data/LSB data
				.DINPADINP(2'd0), // 2-bit input: Port A parity/LSB parity
				// Port B Address/Control Signals inputs: Port B address and control signals
				.ADDRBWRADDR({writeSGPageListAddr[8:0], 5'd0}), // 14-bit input: B/Write port address
				.ADDRENB(1'b1), // 1-bit input: Active-High B/Write port address enable
				.CLKBWRCLK(axiClk), // 1-bit input: B/Write port clock
				.ENBWREN(1'b1), // 1-bit input: Port B enable/Write enable
				.REGCEB(1'b0), // 1-bit input: Port B register enable
				.RSTRAMB(1'b0), // 1-bit input: Port B set/reset
				.RSTREGB(1'b0), // 1-bit input: Port B register set/reset
				.SLEEP(1'b0), // 1-bit input: Sleep Mode
				.WEBWE({4{(writeSGPageListAddr[31:9] == sgl_i) && writeSGPageList}}), // 4-bit input: Port B write enable/Write enable
				// Port B Data inputs: Port B data
				.DINBDIN(writeSGPageListData[31:16]), // 16-bit input: Port B data/MSB data
				.DINPBDINP(2'd0) // 2-bit input: Port B parity/MSB parity
			);
		end 
	endgenerate
	
	
	
	// Inst SAXIL_CFG
	SAXIL #(.DATA_WIDTH(SAXIL_CFG_DATA_WIDTH), .ADDR_WIDTH(SAXIL_CFG_ADDR_WIDTH)) SAXIL_CFG_Inst (
		.ACLK(axiClk),
		.ARESETN(axiResetNr),
		
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


	// Debug signals
	SBCCi oflowLatch_crss(.srcV(oflowOccurredLatch), .srcClk(inputClk), .dstV(dbg_oflowOccurredLatch), .dstClk(axiClk));
	assign dbg_oflowCount = oflowCount_ac;
	assign dbg_lclBufWritePointer = rc_lbWritePointer;
	assign dbg_lclBufReadPointer = rc_lbReadPointer;
	assign dbg_lclBufUnreadBytes = lbUnreadBytes;
	assign dbg_state = state;
	assign dbg_axi_awvalid = axi_awvalid;
	assign dbg_axi_wvalid = axi_wvalid;
	assign dbg_axi_wlen = axi_burstLength;
	assign dbg_axi_awready = MAXI_DATA_AWREADY;
	assign dbg_axi_wready = MAXI_DATA_WREADY;
	assign dbg_axi_wlast = axi_wlast;
	assign dbg_hb_writePtr = hb_writePtr;
	assign dbg_hb_hostReadPtr = hb_hostReadPtr;
	assign dbg_hostBufferWriteableBytes = hostBufferWriteableBytes;

endmodule
