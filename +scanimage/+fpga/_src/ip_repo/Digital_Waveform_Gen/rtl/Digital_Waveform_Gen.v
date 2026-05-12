//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

/*\ 
|*| host buffer must always be in multiples of chunks. actual waveform can end halfway through a chunk but the buffer must be bigger.
|*| host buffer should also be aligned to 4*chunk size
\*/

module Digital_Waveform_Gen #(
	parameter AXI_DATA_WIDTH    		= 256,
	parameter MAXI_DATA_ADDR_WIDTH 		= 32,
	
	parameter NUM_EXT_TRIGGERS    		= 48,
	parameter NUM_PEER_TRIGGERS    		= 26,
	parameter PEER_TRIGGER_IDX    		= 0,
	parameter WAVE_LENGTH_BITS			= 40,
	parameter SAMPLE_PERIOD_WIDTH		= 20,
	
	parameter SG_PAGE_LIST_LENGTH      	= 2048, // must be multiple of 512
	
	parameter SAXI_CFG_PROTOCOL			= "AXI4",
	parameter SAXI_CFG_DATA_WIDTH		= 256,

	parameter LOCAL_BUFFER_TYPE			= "BLOCK_RAM",
	
	// do not change
	localparam SAXI_CFG_ADDR_WIDTH		= 8,
	localparam SAXI_CFG_MM_SIZE			= 236
)(
	output wire [7:0] outputLines,
	
	input  wire [NUM_EXT_TRIGGERS-1:0] ext_triggers,
	inout  wire [NUM_PEER_TRIGGERS-1:0] peer_triggers,
	
	input wire axiClk,
	input wire axiResetN,
	input wire sampleClkTimebase,
	
	
	// SAXIL control/config bus
	input  wire [SAXI_CFG_ADDR_WIDTH-1:0] SAXI_CFG_ARADDR,
	input  wire [1:0] SAXI_CFG_ARBURST,
	input  wire [7:0] SAXI_CFG_ARLEN,
	input  wire [2:0] SAXI_CFG_ARPROT,
	output wire SAXI_CFG_ARREADY,
	input  wire [2:0] SAXI_CFG_ARSIZE,
	input  wire SAXI_CFG_ARVALID,
	input  wire [SAXI_CFG_ADDR_WIDTH-1:0] SAXI_CFG_AWADDR,
	input  wire [1:0] SAXI_CFG_AWBURST,
	input  wire [7:0] SAXI_CFG_AWLEN,
	input  wire [2:0] SAXI_CFG_AWPROT,
	output wire SAXI_CFG_AWREADY,
	input  wire [2:0] SAXI_CFG_AWSIZE,
	input  wire SAXI_CFG_AWVALID,
	input  wire SAXI_CFG_BREADY,
	output wire [1:0] SAXI_CFG_BRESP,
	output wire SAXI_CFG_BVALID,
	output wire [SAXI_CFG_DATA_WIDTH-1:0] SAXI_CFG_RDATA,
	output wire SAXI_CFG_RLAST,
	input  wire SAXI_CFG_RREADY,
	output wire [1:0] SAXI_CFG_RRESP,
	output wire SAXI_CFG_RVALID,
	input  wire [SAXI_CFG_DATA_WIDTH-1:0] SAXI_CFG_WDATA,
	input  wire SAXI_CFG_WLAST,
	output wire SAXI_CFG_WREADY,
	input  wire [SAXI_CFG_DATA_WIDTH/8-1:0] SAXI_CFG_WSTRB,
	input  wire SAXI_CFG_WVALID,
	
	
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
	output wire  MAXI_DATA_RREADY
);
	localparam SAMPLE_WIDTH_BYTES = 1;
	localparam WAVE_LENGTH_ACTUAL_BITS = min(WAVE_LENGTH_BITS,MAXI_DATA_ADDR_WIDTH-1);
	localparam NUM_LOCAL_CHUNKS = 4; // to change this, lots of other things need to change too; this is integral to the logic
	localparam NUM_LOCAL_CHUNKS_LB2 = clogb2(NUM_LOCAL_CHUNKS-1);
	localparam CHUNK_BURST_LEN = 128; // if block ram implementation is selected, this should be 128. Less is just a waste of a block ram
	localparam CHUNK_BURST_LEN_LB2 = clogb2(CHUNK_BURST_LEN-1);
	localparam LCL_BUFFER_NUM_ROWS_LB2 = NUM_LOCAL_CHUNKS_LB2 + CHUNK_BURST_LEN_LB2;
	localparam AXI_DATA_BYTES = AXI_DATA_WIDTH / 8;
	localparam AXI_DATA_BYTES_LB2 = clogb2(AXI_DATA_BYTES-1);
	localparam MAX_BURST_LEN = 4096 / AXI_DATA_BYTES;
	localparam CHUNK_SIZE_BYTES_LB2 = CHUNK_BURST_LEN_LB2 + AXI_DATA_BYTES_LB2;
	localparam CHUNK_NUM_BITS = WAVE_LENGTH_ACTUAL_BITS-CHUNK_SIZE_BYTES_LB2-1;
	localparam SAMPLE_BYTES_LB2 = clogb2(SAMPLE_WIDTH_BYTES-1);
	localparam SAMPLES_PER_ROW_LB2 = AXI_DATA_BYTES_LB2-SAMPLE_BYTES_LB2;
	localparam SG_LIST_NUM_BRAMS = SG_PAGE_LIST_LENGTH / 512;


	// this parameter must be set according to the timebase rate
	localparam DEFAULT_SAMPLE_PERIOD = 20;
	
	
	// function that returns the minimum of two numbers
	function [63:0] min;
		input [63:0] a,b;
		min = (a<b)?a:b;
	endfunction
	
	// function that returns the ceiling of the log base 2
	function [63:0] clogb2;
		input [63:0] bit_depth;
	begin
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			bit_depth = bit_depth >> 1;
		end
	endfunction
	
	
	// MAXI_DATA bus internal signals
	reg [7:0] axi_wlen = 0;
	reg axi_awvalid = 0;
	reg axi_wlast = 0;
	reg axi_wvalid = 0;
	reg [MAXI_DATA_ADDR_WIDTH-1:0] 	axi_awaddr = 0;
	reg [MAXI_DATA_ADDR_WIDTH-1:0] 	axi_araddr = 0;
	reg [7:0] axi_rlen = 0;
	reg [AXI_DATA_WIDTH-1:0] 	axi_wdata = 0;
	reg [AXI_DATA_BYTES-1:0] 	axi_wstrb = 0;
	reg axi_arvalid = 0;
	reg axi_rready = 0;
	
	// MAXI_DATA bus I/O Connection assignments
	assign MAXI_DATA_AWADDR	 = axi_awaddr;
	assign MAXI_DATA_AWLEN	 = axi_wlen;					// Burst LENgth is number of transaction beats, minus 1
	assign MAXI_DATA_AWSIZE	 = clogb2(AXI_DATA_BYTES-1);	// Size should be DATA_WIDTH, in 2^SIZE bytes, otherwise narrow bursts are used
	assign MAXI_DATA_AWBURST = 2'b01;						// INCR burst type
	assign MAXI_DATA_AWLOCK	 = 1'b0;
	assign MAXI_DATA_AWCACHE = 4'b0001; 					// Device Bufferable. The write response can be obtained from an intermediate point. Was 4'b0010 (Normal Non-cacheable Non-bufferable)
	assign MAXI_DATA_AWPROT	 = 3'h0;
	assign MAXI_DATA_AWQOS	 = 4'h0;
	assign MAXI_DATA_AWVALID = axi_awvalid;
	assign MAXI_DATA_WDATA	 = axi_wdata;
	assign MAXI_DATA_WSTRB	 = axi_wstrb;
	assign MAXI_DATA_WLAST	 = axi_wlast;
	assign MAXI_DATA_WVALID	 = axi_wvalid;
	assign MAXI_DATA_BREADY	 = 1;
	assign MAXI_DATA_ARADDR	 = axi_araddr;
	assign MAXI_DATA_ARLEN	 = axi_rlen;					// Burst LENgth is number of transaction beats, minus 1
	assign MAXI_DATA_ARSIZE	 = clogb2(AXI_DATA_BYTES-1);	// Size should be DATA_WIDTH, in 2^n bytes, otherwise narrow bursts are used
	assign MAXI_DATA_ARBURST = 2'b01;						// INCR burst type is usually used, except for keyhole bursts
	assign MAXI_DATA_ARLOCK	 = 1'b0;
	assign MAXI_DATA_ARCACHE = 4'b0010;						// Update value to 4'b0011 if coherent accesses to be used via the Zynq ACP port. Not Allocated, Modifiable, not Bufferable. Not Bufferable since this example is meant to test memory, not intermediate cache. 
	assign MAXI_DATA_ARPROT	 = 3'h0;
	assign MAXI_DATA_ARQOS	 = 4'h0;
	assign MAXI_DATA_ARVALID = axi_arvalid;
	assign MAXI_DATA_RREADY	 = 1'b1; // axi_rready
	
	
	// Host buffer sg reading info
	wire [31:0] hostBufferFirstPageAddress;
	wire [31:0] hostBufferDesiredPageAddress;
	reg  [31:0] hostBufferDesiredAddr = 0;
	wire [31:0] hostBufferDesiredReadPageSubAddr;
	wire [MAXI_DATA_ADDR_WIDTH-1:0] hostBufferTotalSize;
	wire [31:0] hostBufferNumPages;
	wire [4:0] hostBufferPageSizeLB2;
	reg  addrReq = 0;
	reg  addrReady = 0;
	reg  configured = 0;
	
	// state machine regs
	wire enableBufferedMode;
	reg  initialRead = 1;
	reg  firstUpdate = 1;
	reg  lclBufferChunk1Dirty = 1;
	reg  lclBufferChunk1Updating = 0;
	reg  lclBufferChunk2Dirty = 1;
	reg  lclBufferChunk2Updating = 0;
	reg  lclBufferChunk3Dirty = 1;
	reg  lclBufferChunk3Updating = 0;
	wire [WAVE_LENGTH_ACTUAL_BITS-1:0] waveformLengthSamples;
	reg  [LCL_BUFFER_NUM_ROWS_LB2-1:0] lclBufferWriteRow = 0;
	reg  [CHUNK_NUM_BITS:0] lclBufferChunk2Position = 0;		
	reg  [CHUNK_NUM_BITS:0] lclBufferChunk3Position = 0;
	reg  [CHUNK_NUM_BITS:0] lclBufferChunk2NewPosition = 0;		
	reg  [CHUNK_NUM_BITS:0] lclBufferChunk3NewPosition = 0;
	wire [WAVE_LENGTH_ACTUAL_BITS-1:0] sampleOutputPosition_ac;
	
	
	reg  bufferChanged = 0;
	reg  bufferChangedAck = 0;
	wire bufferChangedRecd = bufferChanged && ~bufferChangedAck;

	wire [WAVE_LENGTH_ACTUAL_BITS-AXI_DATA_BYTES_LB2-1:0] waveformLengthRows = ((waveformLengthSamples * SAMPLE_WIDTH_BYTES) >> AXI_DATA_BYTES_LB2) + (|waveformLengthSamples[AXI_DATA_BYTES_LB2-1:0]);
	wire [CHUNK_NUM_BITS:0] waveformLengthChunks = (waveformLengthRows >> CHUNK_BURST_LEN_LB2) + (|waveformLengthRows[CHUNK_BURST_LEN_LB2-1:0]);
	wire [CHUNK_NUM_BITS:0] sampleOutputChunkPosition_ac = (sampleOutputPosition_ac * SAMPLE_WIDTH_BYTES) >> (AXI_DATA_BYTES_LB2 + CHUNK_BURST_LEN_LB2);
	wire [1:0] lclBufferOutputChunkPosition_ac = {|sampleOutputChunkPosition_ac[CHUNK_NUM_BITS:1], sampleOutputChunkPosition_ac[0]};
	
	wire [CHUNK_NUM_BITS:0] lclBufferChunk2DesiredPosPre = {sampleOutputChunkPosition_ac[CHUNK_NUM_BITS:1] + sampleOutputChunkPosition_ac[0], 1'b0};
	wire [CHUNK_NUM_BITS:0] lclBufferChunk2DesiredPos = (!lclBufferChunk2DesiredPosPre || (lclBufferChunk2DesiredPosPre >= waveformLengthChunks)) ? 2 : lclBufferChunk2DesiredPosPre;
	wire [CHUNK_NUM_BITS:0] lclBufferChunk3DesiredPosPre = {sampleOutputChunkPosition_ac[CHUNK_NUM_BITS:1], 1'b1};
	wire [CHUNK_NUM_BITS:0] lclBufferChunk3DesiredPos = ((lclBufferChunk3DesiredPosPre < 3) || (lclBufferChunk3DesiredPosPre >= waveformLengthChunks)) ? 3 : lclBufferChunk3DesiredPosPre;
	
	wire lclBufferChunk2NeedsUpdate = lclBufferChunk2Position != lclBufferChunk2DesiredPos;
	wire lclBufferChunk3NeedsUpdate = lclBufferChunk3Position != lclBufferChunk3DesiredPos;
	wire lclBufferUpdateChunk2 = lclBufferChunk2NeedsUpdate && ((lclBufferOutputChunkPosition_ac < 3) || ~lclBufferChunk3NeedsUpdate);

	wire lclBufferUpdateChunk2Soft = lclBufferChunk2Dirty && (lclBufferOutputChunkPosition_ac != 2) && ~lclBufferChunk3NeedsUpdate;
	wire lclBufferUpdateChunk3Soft = lclBufferChunk3Dirty && (lclBufferOutputChunkPosition_ac != 3);
	
	// initial read / buffer updatr logic
	wire [CHUNK_NUM_BITS:0] desiredInitialUpdateNumChunks = min(initialRead ? 4 : 2, waveformLengthChunks);
	wire [CHUNK_NUM_BITS-CHUNK_BURST_LEN_LB2:0] desiredInitialUpdateBurstLen = desiredInitialUpdateNumChunks << CHUNK_BURST_LEN_LB2;
	wire [CHUNK_NUM_BITS-CHUNK_BURST_LEN_LB2:0] actualInitialUpdateBurstLen = min(MAX_BURST_LEN, desiredInitialUpdateBurstLen);
	
	/*\  local sample buffer update state machine
	 *   
	 *   The local sample buffer is as wide as the AXI bus and 32 deep. we will load the sample buffer in "chunks".
	 *   A chunk is equal to 8 beats of an AXI transfer, so we can always fit 4 chunks in our buffer. The first two
	 *   chunks will always be the beggining of the buffer. the second two chunks will stay ahead of the output.
	 *
	 *   check that waveformLengthRows and waveformLengthChunks is properly calced. a waveform with 256 samples is 16 rows and 2 chunks. a waveform with 257 samples is 17 rows and 3 chunks!
	 *
	 *   host buffer must always be in multiples of chunks. actual waveform can end halfway through a chunk but the buffer must be bigger. host buffer should also be aligned to 4*chunk size
	\*/
	reg axiResetNr = 0;

	always @(posedge axiClk) begin
		axiResetNr <= axiResetN;

		if (~axiResetNr) begin
			bufferChangedAck <= 0;

			lclBufferChunk1Dirty = 1;
			lclBufferChunk1Updating <= 0;
			lclBufferChunk2Dirty = 0;
			lclBufferChunk2Updating <= 0;
			lclBufferChunk3Dirty = 0;
			lclBufferChunk3Updating <= 0;

			lclBufferChunk2Position <= 0;
			lclBufferChunk3Position <= 0;
			initialRead <= 1;
			axi_rready <= 0;
			axi_arvalid <= 0;
			addrReq <= 0;
			addrReady <= 0;
		end else if (addrReady) begin
			// two clock cycle latency from knowing where in the host buffer i want to read to having the addr from the sg list
			addrReq <= 0;
			addrReady <= 0;
			
			axi_rready <= 1;
			axi_arvalid <= 1;
			axi_araddr <= {hostBufferDesiredPageAddress, 12'h000} + hostBufferDesiredReadPageSubAddr;
		end else if (addrReq)
			addrReady <= 1;
		else if (axi_rready) begin
			bufferChangedAck <= bufferChanged && bufferChangedAck;
			
			// read in progress. increment write address when buffer is written
			if (MAXI_DATA_ARREADY)
				axi_arvalid <= 0;
			
			if (MAXI_DATA_RLAST && MAXI_DATA_RVALID) begin
				axi_rready <= 0;

				firstUpdate <= 0;
				initialRead <= initialRead && lclBufferChunk1Dirty && ~lclBufferChunk1Updating;

				lclBufferChunk1Updating <= 0;
				lclBufferChunk1Dirty <= lclBufferChunk1Dirty && ~lclBufferChunk1Updating;

				lclBufferChunk2Updating <= 0;
				lclBufferChunk2Dirty <= lclBufferChunk2Dirty && ~lclBufferChunk2Updating;

				lclBufferChunk3Updating <= 0;
				lclBufferChunk3Dirty <= lclBufferChunk3Dirty && ~lclBufferChunk3Updating;

				lclBufferChunk2Position <= lclBufferChunk2NewPosition;
				lclBufferChunk3Position <= lclBufferChunk3NewPosition;
			end
			
			if (MAXI_DATA_RVALID)
				lclBufferWriteRow <= lclBufferWriteRow + 1;
			
		end else if (~enableBufferedMode || ~configured) begin
			bufferChangedAck <= 0;

			lclBufferChunk1Dirty = 1;
			lclBufferChunk1Updating <= 0;
			lclBufferChunk2Dirty = 0;
			lclBufferChunk2Updating <= 0;
			lclBufferChunk3Dirty = 0;
			lclBufferChunk3Updating <= 0;

			lclBufferChunk2Position <= 0;
			lclBufferChunk3Position <= 0;
			initialRead <= 1;
			firstUpdate <= 1;
		end else if (bufferChangedRecd || firstUpdate) begin
			bufferChangedAck <= bufferChanged;
			
			// need to update all 4 chunks of the local sample buffer (assuming the waveform is long enough). update as many as possible with a single burst
			axi_rlen <= actualInitialUpdateBurstLen-1;
			hostBufferDesiredAddr <= 0;
			addrReq <= 1;
			lclBufferWriteRow <= 0;

			lclBufferChunk1Dirty <= 1;
			lclBufferChunk1Updating <= MAX_BURST_LEN > CHUNK_BURST_LEN;

			lclBufferChunk2Dirty <= waveformLengthChunks > 2;
			lclBufferChunk2Updating <= actualInitialUpdateBurstLen > (CHUNK_BURST_LEN * 2);
			if (actualInitialUpdateBurstLen > (CHUNK_BURST_LEN * 2))
				lclBufferChunk2NewPosition = 2; // it is being updated
			else if (waveformLengthChunks < 2)
				lclBufferChunk2NewPosition = 2; // it never needs an update so pretend it will be updated
			else if ((desiredInitialUpdateBurstLen > (CHUNK_BURST_LEN * 2)) && (actualInitialUpdateBurstLen < (CHUNK_BURST_LEN * 3)))
				lclBufferChunk2NewPosition = 0; // it needs an update but isn't getting one. mark it dirty
			// otherwise don't change it.

			lclBufferChunk3Dirty <= waveformLengthChunks > 3;
			lclBufferChunk2Updating <= actualInitialUpdateBurstLen > (CHUNK_BURST_LEN * 2);
			if (actualInitialUpdateBurstLen > (CHUNK_BURST_LEN * 2))
				lclBufferChunk3NewPosition = 3; // it is being updated
			else if (waveformLengthChunks < 3)
				lclBufferChunk3NewPosition = 3; // it never needs an update so pretend it will be updated
			else if ((desiredInitialUpdateBurstLen > (CHUNK_BURST_LEN * 3)) && (actualInitialUpdateBurstLen < (CHUNK_BURST_LEN * 4)))
				lclBufferChunk3NewPosition = 0; // it needs an update but isn't getting one. mark it dirty
			// otherwise don't change it.

		end else if (lclBufferChunk1Dirty) begin
			// this case is only hit if a burst is limited to a single chunk. chunk 2 needs an update (either  because this is an initial read or a buffer update)
			axi_rlen <= CHUNK_BURST_LEN-1;
			hostBufferDesiredAddr <= AXI_DATA_BYTES * CHUNK_BURST_LEN;
			addrReq <= 1;
			lclBufferWriteRow <= CHUNK_BURST_LEN;

			lclBufferChunk1Updating <= 1;
		end else if ((MAX_BURST_LEN > CHUNK_BURST_LEN) && lclBufferChunk2NeedsUpdate && lclBufferChunk3NeedsUpdate && (lclBufferChunk2DesiredPos == 2) && (lclBufferChunk3DesiredPos == 3)) begin
			// this case is only hit if a burst is limited to two chunks, after initial read updates chunks 0 and 1
			axi_rlen <= (CHUNK_BURST_LEN*2)-1;
			hostBufferDesiredAddr <= AXI_DATA_BYTES * CHUNK_BURST_LEN * 2;
			addrReq <= 1;
			lclBufferWriteRow <= CHUNK_BURST_LEN * 2;

			lclBufferChunk2NewPosition <= 2;
			lclBufferChunk2NewPosition <= 3;
		end else begin
			bufferChangedAck <= bufferChanged && bufferChangedAck;
			
			// logic for when buffer needs update
			if (lclBufferUpdateChunk2 || lclBufferUpdateChunk2Soft) begin
				// we are behind! catch up
				axi_rlen <= CHUNK_BURST_LEN-1;
				hostBufferDesiredAddr <= lclBufferChunk2DesiredPos << CHUNK_SIZE_BYTES_LB2;
				addrReq <= 1;
				lclBufferWriteRow <= CHUNK_BURST_LEN * 2;
				lclBufferChunk2NewPosition <= lclBufferChunk2DesiredPos;
				lclBufferChunk2Updating <= 1;
			end else if (lclBufferChunk3NeedsUpdate || lclBufferUpdateChunk3Soft) begin
				axi_rlen <= CHUNK_BURST_LEN-1;
				hostBufferDesiredAddr <= lclBufferChunk3DesiredPos << CHUNK_SIZE_BYTES_LB2;
				addrReq <= 1;
				lclBufferWriteRow <= CHUNK_BURST_LEN * 3;
				lclBufferChunk3NewPosition <= lclBufferChunk3DesiredPos;
				lclBufferChunk3Updating <= 1;
			end
		end
	end
	
	
	
	
	wire rc_resetn;
	SBCCi reset_crss(.srcV(axiResetNr), .srcClk(axiClk), .dstV(rc_resetn), .dstClk(sampleClkTimebase));
	
	wire enableBufferedMode_oc;
	SBCCi ebmCrss(.srcV(enableBufferedMode), .srcClk(axiClk), .dstV(enableBufferedMode_oc), .dstClk(sampleClkTimebase));
	
	wire initialRead_oc;
	SBCCi irCrss(.srcV(initialRead), .srcClk(axiClk), .dstV(initialRead_oc), .dstClk(sampleClkTimebase));
	
	
	// sample buffer read logic
	wire [LCL_BUFFER_NUM_ROWS_LB2-1:0] lclBufferReadRow;
	wire [AXI_DATA_WIDTH-1:0] lclBufferDataOut;

	reg  [WAVE_LENGTH_ACTUAL_BITS-1:0] sampleOutputPosition = 0;
	reg  [WAVE_LENGTH_ACTUAL_BITS-1:0] sampleOutputPositionPreup1 = 0;
	reg  [WAVE_LENGTH_ACTUAL_BITS-1:0] sampleOutputPositionPreup2 = 0;
	wire [CHUNK_NUM_BITS:0] sampleOutputChunkPosition = (sampleOutputPosition * SAMPLE_WIDTH_BYTES) >> (AXI_DATA_BYTES_LB2 + CHUNK_BURST_LEN_LB2);
	wire [1:0] lclBufferOutputChunkPosition = {|sampleOutputChunkPosition[CHUNK_NUM_BITS:1], sampleOutputChunkPosition[0]};
	wire [LCL_BUFFER_NUM_ROWS_LB2-1:0] lclBufferReadRowPreup = {lclBufferOutputChunkPosition,sampleOutputPosition[SAMPLES_PER_ROW_LB2+:CHUNK_BURST_LEN_LB2]};
	reg  [LCL_BUFFER_NUM_ROWS_LB2-1:0] lclBufferReadRowReg = 0;
	wire [SAMPLE_WIDTH_BYTES*8-1:0] nextSample = lclBufferDataOut[(sampleOutputPosition[SAMPLES_PER_ROW_LB2-1:0]<<SAMPLE_BYTES_LB2)*8+:SAMPLE_WIDTH_BYTES*8];
	reg  [SAMPLE_WIDTH_BYTES*8-1:0] nextSampleR;
	
	assign lclBufferReadRow = lclBufferReadRowReg;

	// clock cross to axi logic
	reg sampleOuputPositionUpdated = 0;
	reg [WAVE_LENGTH_ACTUAL_BITS-1:0] sampleOutputPositionSend = 0;
	SWCCi #(.WW(WAVE_LENGTH_ACTUAL_BITS)) sampleOutPosCrss(.srcV(sampleOutputPositionSend), .srcClk(sampleClkTimebase), .dstV(sampleOutputPosition_ac), .dstClk(axiClk), .dstRst(~axiResetNr));
	
	// non buffered update request
	wire [SAMPLE_PERIOD_WIDTH-1:0] samplePeriod;
	reg  [SAMPLE_PERIOD_WIDTH-1:0] samplePeriodCtr = 0;
	reg  sampleUpdateReq = 0;
	reg  [SAMPLE_WIDTH_BYTES*8-1:0] sampleUpdateReqData = 0;
	wire sampleUpdateReq_oc;
	
	
	
	reg [5:0] triggerId;
	reg triggerIdSet = 0;
	wire triggerPolarity;
	reg peerTrigEn = 0;
	wire [5:0] triggerId_oc;
	wire triggerIdSet_oc;
	wire triggerPolarity_oc;
	wire peerTrigEn_oc;
	wire trigSettingUpdated;
	reg [1:0] trigSettingUpdatedR = 0;
	SWCCi #(.WW(9), .CONTINUOUS(0)) tiggerInfoCC(.srcV({peerTrigEn, triggerPolarity, triggerIdSet, triggerId}), .srcClk(axiClk), .dstV({peerTrigEn_oc, triggerPolarity_oc, triggerIdSet_oc, triggerId_oc}), .dstClk(sampleClkTimebase), .dstRst(~rc_resetn), .newVal(trigSettingUpdated));
	
	
	reg done = 0;
	wire done_ac;
	wire[WAVE_LENGTH_ACTUAL_BITS-1:0] samplesPerTrigger;
	reg continuousGen = 1;
	reg [WAVE_LENGTH_ACTUAL_BITS-1:0] samplesRemaining = 0;
	reg [WAVE_LENGTH_ACTUAL_BITS-1:0] samplesRemainingPreup1 = 0;
	reg [WAVE_LENGTH_ACTUAL_BITS-1:0] samplesRemainingPreup2 = 0;
	wire allowRetrigger;
	wire allowEarlyTrigger;
	reg [47:0] bufferedSamplesDone = 0;
	
	(* ASYNC_REG = "TRUE" *)
	reg [1:0] trigSyncr = 0;
	
	reg  allowTrigger = 0;
	wire axiTrigReq;
	wire axiTriggerReq_oc;
	reg  triggerLatch = 0;
	reg  pTrig = 1;
	wire myTrigger = trigSyncr[0] ^ triggerPolarity_oc;
	wire triggerPresentP = ((triggerIdSet_oc && myTrigger && ~pTrig && ~trigSettingUpdated) || axiTriggerReq_oc) && allowTrigger;
	reg  [NUM_PEER_TRIGGERS-1:0] peer_triggersR = 0;
	wire triggerPresent = peerTrigEn_oc ? peer_triggersR[triggerId_oc] : peer_triggersR[PEER_TRIGGER_IDX];
	reg  triggerPresentR = 0;
	wire isTrigd = triggerLatch || triggerPresentR;
	
	assign peer_triggers[PEER_TRIGGER_IDX] = triggerPresentP;
	
	OSCCi sampleUpdateReqCrss(.srcV(sampleUpdateReq), .srcClk(axiClk), .dstV(sampleUpdateReq_oc), .dstClk(sampleClkTimebase));
	OSCCi triggerReqCrss(.srcV(axiTrigReq), .srcClk(axiClk), .dstV(axiTriggerReq_oc), .dstClk(sampleClkTimebase));
	SBCCi doneCrss(.srcV(done), .srcClk(sampleClkTimebase), .dstV(done_ac), .dstClk(axiClk));
	
	reg advBuffer = 0;
	
	reg  [SAMPLE_WIDTH_BYTES*8-1:0] outputReg = 0;
	assign outputLines = outputReg;

	// since digital sample rates can be very fast, we need quick detection of dma lagging behind required samples
	// bring in the chunk positions from the axi clock domain
	wire [CHUNK_NUM_BITS:0] lclBufferChunk2Position_sc;		
	wire [CHUNK_NUM_BITS:0] lclBufferChunk3Position_sc;
	SWCCi #(.WW(CHUNK_NUM_BITS+1)) lb_c2_pos_crss(.srcV(lclBufferChunk2Position), .srcClk(axiClk), .dstV(lclBufferChunk2Position_sc), .dstClk(sampleClkTimebase), .dstRst(~rc_resetn));
	SWCCi #(.WW(CHUNK_NUM_BITS+1)) lb_c3_pos_crss(.srcV(lclBufferChunk3Position), .srcClk(axiClk), .dstV(lclBufferChunk3Position_sc), .dstClk(sampleClkTimebase), .dstRst(~rc_resetn));
	
	wire lclBufferC2Error = (lclBufferOutputChunkPosition == 2) && (lclBufferChunk2Position_sc != sampleOutputChunkPosition);
	wire lclBufferC3Error = (lclBufferOutputChunkPosition == 3) && (lclBufferChunk3Position_sc != sampleOutputChunkPosition);
	wire dmaIsLate = lclBufferC2Error || lclBufferC3Error;
	reg  dmaIsLateLatch = 0;
	
	// output state machine
	always @(posedge sampleClkTimebase) begin
		if (trigSettingUpdated)
			trigSettingUpdatedR <= 3;
		else if (trigSettingUpdatedR)
			trigSettingUpdatedR <= trigSettingUpdatedR - 1;
		
		peer_triggersR <= peer_triggers;
		triggerPresentR <= triggerPresent;
		
		pTrig <= myTrigger || trigSettingUpdated || trigSettingUpdatedR;
		
		lclBufferReadRowReg <= lclBufferReadRowPreup;
		nextSampleR <= nextSample;
		
		trigSyncr <= {ext_triggers[triggerId_oc], trigSyncr[1]};
		
		if (~rc_resetn) begin
			sampleOutputPosition <= 0;
			sampleOutputPositionSend <= 0;
			sampleOuputPositionUpdated <= 0;
			triggerLatch <= 0;
			samplePeriodCtr <= 0;
			done <= 0;
			allowTrigger <= 1;
			samplesRemaining <= 0;
			bufferedSamplesDone <= 0;
			outputReg <= 0;
			advBuffer <= 0;
			dmaIsLateLatch <= 0;
		end else if (~enableBufferedMode_oc || initialRead_oc) begin
			sampleOutputPosition <= 0;
			sampleOutputPositionSend <= 0;
			sampleOuputPositionUpdated <= 0;
			triggerLatch <= 0;
			samplePeriodCtr <= 0;
			advBuffer <= 0;
			done <= 0;
			allowTrigger <= 1;
			samplesRemaining <= 0;
			dmaIsLateLatch <= 0;
			
			// on demand output request
			if(sampleUpdateReq_oc)
				outputReg <= sampleUpdateReqData;
		end else begin
			dmaIsLateLatch <= dmaIsLateLatch || dmaIsLate;
			
			// buffered output
			if (dmaIsLateLatch)
				dmaIsLateLatch <= 1; // stop operation
			else if (isTrigd && !samplePeriodCtr) begin
				// sample period timer expired. output the next sample
				samplePeriodCtr <= samplePeriod - 1;
				advBuffer <= 1;
				
				outputReg <= nextSampleR;
			end else begin
				if (samplePeriodCtr)
					samplePeriodCtr <= samplePeriodCtr - 1;
				
				advBuffer <= 0;
				
				// on demand output request
				if(sampleUpdateReq_oc)
					outputReg <= sampleUpdateReqData;
			end
			
			
			if (triggerPresentR) begin
				// trigger arrived
				allowTrigger <= allowRetrigger;
				if (~triggerLatch) begin
					// we were waiting for the trigger. start the new generation
					samplesRemainingPreup1 = samplesPerTrigger | continuousGen; // minimum of one; if samplesPerTrigger=0 this is a continuous gen
					sampleOutputPositionPreup1 = sampleOutputPosition;
				end else if (allowRetrigger && allowEarlyTrigger) begin
					samplesRemainingPreup1 = samplesPerTrigger;
					sampleOutputPositionPreup1 = sampleOutputPosition + samplesRemaining;
				end else begin
					samplesRemainingPreup1 = samplesRemaining;
					sampleOutputPositionPreup1 = sampleOutputPosition;
				end
			end else begin
				samplesRemainingPreup1 = samplesRemaining;
				sampleOutputPositionPreup1 = sampleOutputPosition;
			end
			
			samplesRemainingPreup2 = continuousGen ? samplesRemainingPreup1 : samplesRemainingPreup1 - advBuffer;
			sampleOutputPositionPreup2 = sampleOutputPositionPreup1 + advBuffer;
				
			triggerLatch <= samplesRemainingPreup2 > 0;
			samplesRemaining <= samplesRemainingPreup2;
			done <= !samplesRemaining && ~allowTrigger;
			
			sampleOuputPositionUpdated <= triggerPresentR || advBuffer;
			if (triggerPresentR || advBuffer)
				sampleOutputPosition <= sampleOutputPositionPreup2;
			else if (~sampleOuputPositionUpdated)
				sampleOutputPosition <= sampleOutputPositionSend;
			sampleOutputPositionSend <= (sampleOutputPosition >= waveformLengthSamples) ? sampleOutputPosition - waveformLengthSamples : sampleOutputPosition;
			
			bufferedSamplesDone <= bufferedSamplesDone + advBuffer;
		end
	end
	
	
	
	// error tracking
	wire outputError;
	SBCCi dmaLate_crss(.srcV(dmaIsLateLatch), .srcClk(sampleClkTimebase), .dstV(outputError), .dstClk(axiClk));
	reg  outputErrorLatch = 0;
	reg  [31:0] consecUpdateNeeded = 0;
	reg  [31:0] maxConsecUpdateNeeded = 0;
	
	wire [47:0] bufferedSamplesDone_ac;
	SWCCi #(.WW(48)) bufferedSamplesDoneCrss(.srcV(bufferedSamplesDone), .srcClk(sampleClkTimebase), .dstV(bufferedSamplesDone_ac), .dstClk(axiClk), .dstRst(~axiResetNr));
	
	reg [47:0] bufferedSamplesDoneCache = 0;
	reg [WAVE_LENGTH_ACTUAL_BITS-1:0] sampleOutputPositionCache = 0;
	
	reg [31:0] writeSGPageListAddr = 0;
	reg [31:0] writeSGPageListData = 0;
	reg writeSGPageList = 0;


	// SAXI_CFG slave intf
	wire [SAXI_CFG_MM_SIZE-1:0]   SAXI_CFG_byteWriteEn;
	wire [SAXI_CFG_MM_SIZE*8-1:0] SAXI_CFG_bitWriteData;
	wire [SAXI_CFG_MM_SIZE*8-1:0] SAXI_CFG_bitReadData;
	
	wire bufferedModeUpdated;
	wire userSampleOutputReq;
	wire resetOutputErrorLatch;
	wire [7:0] userSampleOutputReqData;
	wire peerTriggerUpdate;
	wire [5:0] peerTriggerUpdateVal;
	wire extTriggerUpdate;
	wire [5:0] extTriggerUpdateVal;
	wire bufferChangeReq;
	wire cacheSampleOutputPosition;
	wire samplesPerTriggerUpdate;
	wire cacheBufferedSamplesDone;
	wire resetMaxConsecUpdateNeeded;
	wire hostBufferFirstPageAddressUpdate;
	wire updateHostBufferNumPages;
	wire sgPageListWriteReq;
	wire [31:0] sgPageListWriteReqData;
	
	Register_R 	#(.ADDR(0), .W(32)) 	ipIdentifier 			(.bitReadData(SAXI_CFG_bitReadData), .registerValue(32'hD10B_FEF0));
	Register_RW #(.ADDR(4), .W(1)) 		enableBufferedModeR 	(.aclk(axiClk), .reset(~axiResetNr), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue(enableBufferedMode), .partialUpdate(bufferedModeUpdated));
	Register_R 	#(.ADDR(8), .W(32)) 	peerId 					(.bitReadData(SAXI_CFG_bitReadData), .registerValue(PEER_TRIGGER_IDX));
	Register_R  #(.ADDR(12), .W(32)) 	WAVE_LENGTH_BITS_R 		(.bitReadData(SAXI_CFG_bitReadData), .registerValue(WAVE_LENGTH_BITS));
	Register_R  #(.ADDR(20), .W(8)) 	lastSampleSent_R 		(.bitReadData(SAXI_CFG_bitReadData), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .registerValue(outputReg), .cmdActive(userSampleOutputReq), .cmdValue(userSampleOutputReqData));
	Register_R  #(.ADDR(24), .W(32)) 	outputErrorLatch_r 		(.bitReadData(SAXI_CFG_bitReadData), .byteWriteEn(SAXI_CFG_byteWriteEn), .registerValue(outputErrorLatch), .cmdActive(resetOutputErrorLatch));
	Register_RW #(.ADDR(28), .W(SAMPLE_PERIOD_WIDTH), .IV(DEFAULT_SAMPLE_PERIOD)) samplePeriodR (.aclk(axiClk), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue(samplePeriod));
	Register_R  #(.ADDR(40), .W(6)) 	peerTriggerReg 			(.byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue(peerTrigEn ? triggerId : 6'hFF), .cmdActive(peerTriggerUpdate), .cmdValue(peerTriggerUpdateVal));
	Register_R  #(.ADDR(44), .W(6)) 	extTriggerReg 			(.byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue(triggerIdSet ? triggerId : 6'hFF), .cmdActive(extTriggerUpdate), .cmdValue(extTriggerUpdateVal));
	Register_RW #(.ADDR(48), .W(2)) 	triggerPrms_r 			(.aclk(axiClk), .reset(~axiResetNr), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue({allowEarlyTrigger, allowRetrigger}));
	Register_R  #(.ADDR(52), .W(1)) 	done_r 					(.bitReadData(SAXI_CFG_bitReadData), .byteWriteEn(SAXI_CFG_byteWriteEn), .registerValue(done_ac), .cmdActive(axiTrigReq));
	Register_RW #(.ADDR(56), .W(1)) 	triggerPolarity_r 		(.aclk(axiClk), .reset(~axiResetNr), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue(triggerPolarity));
	Register_R  #(.ADDR(60), .W(5)) 	bufferChange_r 			(.bitReadData(SAXI_CFG_bitReadData), .byteWriteEn(SAXI_CFG_byteWriteEn), .registerValue({continuousGen, configured, triggerLatch, initialRead, bufferChangedAck, bufferChanged}), .cmdActive(bufferChangeReq));
	Register_RW #(.ADDR(64), .W(WAVE_LENGTH_ACTUAL_BITS)) waveformLengthSamples_r (.aclk(axiClk), .reset(~axiResetNr), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue(waveformLengthSamples));
	Register_R  #(.ADDR(72), .W(64)) 	sampleOutputPositionCache_r (.bitReadData(SAXI_CFG_bitReadData), .byteWriteEn(SAXI_CFG_byteWriteEn), .registerValue(sampleOutputPositionCache), .cmdActive(cacheSampleOutputPosition));
	Register_RW #(.ADDR(80), .W(64)) 	samplesPerTriggerR 		(.aclk(axiClk), .reset(~axiResetNr), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue(samplesPerTrigger), .partialUpdate(samplesPerTriggerUpdate));
	Register_R  #(.ADDR(88), .W(64)) 	bufferedSamplesDoneCache_r (.bitReadData(SAXI_CFG_bitReadData), .byteWriteEn(SAXI_CFG_byteWriteEn), .registerValue(bufferedSamplesDoneCache), .cmdActive(cacheBufferedSamplesDone));
	Register_R  #(.ADDR(96), .W(32)) 	maxConsecUpdateNeeded_r (.bitReadData(SAXI_CFG_bitReadData), .byteWriteEn(SAXI_CFG_byteWriteEn), .registerValue(maxConsecUpdateNeeded), .cmdActive(resetMaxConsecUpdateNeeded));
	Register_RW #(.ADDR(104), .W(64)) 	ownerUuid 				(.aclk(axiClk), .reset(~axiResetNr), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData));
	Register_RW #(.ADDR(112), .W(64)) 	bufferWriterUuid 		(.aclk(axiClk), .reset(~axiResetNr), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData));
	Register_R  #(.ADDR(148), .W(5)) 	transferInfo_r 			(.bitReadData(SAXI_CFG_bitReadData), .registerValue({axi_rready, lclBufferChunk1Updating, lclBufferChunk1Dirty, initialRead, firstUpdate}));
	Register_R  #(.ADDR(200), .W(32)) 	sgId 					(.bitReadData(SAXI_CFG_bitReadData), .registerValue(32'h_CACA_0002));
	Register_R  #(.ADDR(204), .W(32)) 	sgL 					(.bitReadData(SAXI_CFG_bitReadData), .registerValue(SG_PAGE_LIST_LENGTH));
	Register_R  #(.ADDR(208), .W(32)) 	sgW 					(.bitReadData(SAXI_CFG_bitReadData), .registerValue(MAXI_DATA_ADDR_WIDTH));
	Register_RW #(.ADDR(212), .W(32)) 	hostBufferFirstPageAddressR (.aclk(axiClk), .reset(~axiResetNr), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue(hostBufferFirstPageAddress), .partialUpdate(hostBufferFirstPageAddressUpdate));
	Register_RW #(.ADDR(216), .W(64)) 	hostBufferTotalSizeR 	(.aclk(axiClk), .reset(~axiResetNr || hostBufferFirstPageAddressUpdate), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue(hostBufferTotalSize));
	Register_RW #(.ADDR(224), .W(16)) 	hostBufferNumPagesR 	(.aclk(axiClk), .reset(~axiResetNr || hostBufferFirstPageAddressUpdate), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue(hostBufferNumPages), .partialUpdate(updateHostBufferNumPages));
	Register_RW #(.ADDR(228), .W(5)) 	hostBufferPageSizeLB2_R (.aclk(axiClk), .reset(~axiResetNr || hostBufferFirstPageAddressUpdate), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .bitReadData(SAXI_CFG_bitReadData), .registerValue(hostBufferPageSizeLB2));
	Register_R  #(.ADDR(232), .W(32)) 	sgPageListWriteReg 		(.bitReadData(SAXI_CFG_bitReadData), .byteWriteEn(SAXI_CFG_byteWriteEn), .bitWriteData(SAXI_CFG_bitWriteData), .registerValue(writeSGPageListAddr), .cmdActive(sgPageListWriteReq), .cmdValue(sgPageListWriteReqData));
		
	// axi config slave; receives configuration data and commands from host
	always @(posedge axiClk) begin
		if (~axiResetNr) begin
			triggerIdSet <= 0;
			peerTrigEn <= 0;
		end else if (extTriggerUpdate) begin
			peerTrigEn <= 0;
			triggerIdSet <= extTriggerUpdateVal < 6'hFF;
			triggerId <= extTriggerUpdateVal;
		end else if (peerTriggerUpdate) begin
			triggerIdSet <= 0;
			peerTrigEn <= peerTriggerUpdateVal < 6'hFF;
			triggerId <= peerTriggerUpdateVal;
		end
			
		if (~axiResetNr)
			continuousGen <= 1;
		else if (samplesPerTriggerUpdate)
			continuousGen <= samplesPerTrigger == 0;
		
		if (bufferChangeReq)
			bufferChanged <= 1;
		else
			bufferChanged <= bufferChanged && ~bufferChangedAck;
		
		
		// waveform error/performance logging
		if (~axiResetNr || resetOutputErrorLatch || (bufferedModeUpdated && enableBufferedMode))
			outputErrorLatch <= 0;
		else
			outputErrorLatch <= outputErrorLatch || outputError;
		
		if (~initialRead && (lclBufferChunk2NeedsUpdate || lclBufferChunk3NeedsUpdate))
			consecUpdateNeeded <= consecUpdateNeeded + 1;
		else
			consecUpdateNeeded <= 0;
			
		if(~axiResetNr || resetMaxConsecUpdateNeeded)
			maxConsecUpdateNeeded <= 0;
		else if (consecUpdateNeeded > maxConsecUpdateNeeded)
			maxConsecUpdateNeeded <= consecUpdateNeeded;
		
		
		// non buffered sample reqs
		if (axiResetNr && userSampleOutputReq) begin
			sampleUpdateReq <= 1;
			sampleUpdateReqData <= userSampleOutputReqData;
		end else
			sampleUpdateReq <= 0;
			
			
		if (cacheSampleOutputPosition)
			sampleOutputPositionCache <= sampleOutputPosition_ac;
			
		if (cacheBufferedSamplesDone)
			bufferedSamplesDoneCache <= bufferedSamplesDone_ac;
			
		
		if (~axiResetNr)
			configured <= 0;
		else if (hostBufferFirstPageAddressUpdate) begin
			writeSGPageListAddr <= 0;
			writeSGPageListData <= hostBufferFirstPageAddress;
			
			configured <= 0;
		end else if (updateHostBufferNumPages)
			configured <= hostBufferNumPages == 1;
		else if (sgPageListWriteReq) begin
			writeSGPageListAddr <= writeSGPageListAddr + 1;
			writeSGPageListData <= sgPageListWriteReqData;
			
			configured <= writeSGPageListAddr == (hostBufferNumPages - 2);
		end
		writeSGPageList <= hostBufferFirstPageAddressUpdate || sgPageListWriteReq;
	end
	
	
	
	// Local buffer
	//inputs: lclBufferReadRow, lclBufferWriteRow, MAXI_DATA_RDATA, MAXI_DATA_RVALID
	generate
		if (LOCAL_BUFFER_TYPE == "BLOCK_RAM") begin
			// Local sample buffer implemented with Block RAM
			localparam BLOCKRAM_ROWS = 512;
			localparam BLOCKRAM_ROWS_LB2 = clogb2(BLOCKRAM_ROWS-1);
			localparam BLOCKRAM_WIDTH_BYTES = 4;
			localparam BLOCKRAM_NUM_COLS = AXI_DATA_BYTES / BLOCKRAM_WIDTH_BYTES;
			// Block RAMs are massive. For now we won't do multiple ranks

			genvar colNo;
			
			for (colNo = 0; colNo < BLOCKRAM_NUM_COLS; colNo=colNo+1) begin:generate_blockram_cols
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
					.DOUTADOUT(lclBufferDataOut[colNo*32+:16]), // 16-bit output: Port A data/LSB data
					.DOUTPADOUTP(), // 2-bit output: Port A parity/LSB parity
					// Port B Data outputs: Port B data
					.DOUTBDOUT(lclBufferDataOut[((colNo*32)+16)+:16]), // 16-bit output: Port B data/MSB data
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
					.ADDRARDADDR({lclBufferReadRow, 5'd0}), // 14-bit input: A/Read port address
					.ADDRENA(1'b1), // 1-bit input: Active-High A/Read port address enable
					.CLKARDCLK(sampleClkTimebase), // 1-bit input: A/Read port clock
					.ENARDEN(1'b1), // 1-bit input: Port A enable/Read enable
					.REGCEAREGCE(1'b0), // 1-bit input: Port A register enable/Register enable
					.RSTRAMARSTRAM(1'b0), // 1-bit input: Port A set/reset
					.RSTREGARSTREG(1'b0), // 1-bit input: Port A register set/reset
					.WEA(2'b11), // 2-bit input: Port A write enable
					// Port A Data inputs: Port A data
					.DINADIN(MAXI_DATA_RDATA[colNo*32+:16]), // 16-bit input: Port A data/LSB data
					.DINPADINP(2'd0), // 2-bit input: Port A parity/LSB parity
					// Port B Address/Control Signals inputs: Port B address and control signals
					.ADDRBWRADDR({lclBufferWriteRow, 5'd0}), // 14-bit input: B/Write port address
					.ADDRENB(1'b1), // 1-bit input: Active-High B/Write port address enable
					.CLKBWRCLK(axiClk), // 1-bit input: B/Write port clock
					.ENBWREN(1'b1), // 1-bit input: Port B enable/Write enable
					.REGCEB(1'b0), // 1-bit input: Port B register enable
					.RSTRAMB(1'b0), // 1-bit input: Port B set/reset
					.RSTREGB(1'b0), // 1-bit input: Port B register set/reset
					.SLEEP(1'b0), // 1-bit input: Sleep Mode
					.WEBWE({4{MAXI_DATA_RVALID}}), // 4-bit input: Port B write enable/Write enable
					// Port B Data inputs: Port B data
					.DINBDIN(MAXI_DATA_RDATA[((colNo*32)+16)+:16]), // 16-bit input: Port B data/MSB data
					.DINPBDINP(2'd0) // 2-bit input: Port B parity/MSB parity
				);
			end

		end else begin
			// Local sample buffer implemented with LUTRAM
			localparam LUTRAM_ROWS = 32;
			localparam LUTRAM_ROWS_LB2 = clogb2(LUTRAM_ROWS-1);
			localparam LUTRAM_RANKS = (CHUNK_BURST_LEN * NUM_LOCAL_CHUNKS) >> LUTRAM_ROWS_LB2;
			localparam LUTRAM_RANKS_LB2 = clogb2(LUTRAM_RANKS-1);

			wire [LUTRAM_RANKS_LB2:0] lclBufferReadRank = lclBufferReadRow[LUTRAM_ROWS_LB2+:LUTRAM_RANKS_LB2];
			wire [AXI_DATA_WIDTH-1:0] lclBufferDataOutRR[LUTRAM_RANKS-1:0];
			assign lclBufferDataOut = lclBufferDataOutRR[lclBufferReadRank];

			genvar rankNo;
			genvar bitNo;

			for (rankNo = 0; rankNo < LUTRAM_RANKS; rankNo=rankNo+1) begin:generate_lutram_ranks
				for (bitNo = 0; bitNo < AXI_DATA_WIDTH; bitNo=bitNo+1) begin:generate_lutram_cols

					wire thisRamWe = MAXI_DATA_RVALID && ((lclBufferWriteRow >> LUTRAM_ROWS_LB2) == rankNo);

					RAM32X1D RAM32X1D_inst (
						.DPO(lclBufferDataOutRR[rankNo][bitNo]), // Read-only 1-bit data output
						.SPO(), // Rw/ 1-bit data output
						.A0(lclBufferWriteRow[0]), // Rw/ address[0] input bit
						.A1(lclBufferWriteRow[1]), // Rw/ address[1] input bit
						.A2(lclBufferWriteRow[2]), // Rw/ address[2] input bit
						.A3(lclBufferWriteRow[3]), // Rw/ address[3] input bit
						.A4(lclBufferWriteRow[4]), // Rw/ address[4] input bit
						.D(MAXI_DATA_RDATA[bitNo]), // Write 1-bit data input
						.DPRA0(lclBufferReadRow[0]), // Read-only address[0] input bit
						.DPRA1(lclBufferReadRow[1]), // Read-only address[1] input bit
						.DPRA2(lclBufferReadRow[2]), // Read-only address[2] input bit
						.DPRA3(lclBufferReadRow[3]), // Read-only address[3] input bit
						.DPRA4(lclBufferReadRow[4]), // Read-only address[4] input bit
						.WCLK(axiClk), // Write clock input
						.WE(thisRamWe) // Write enable input
					);
				end
			end
		end
	endgenerate
	
	

	// Scatter gather info storage
	wire [31:0] sgPageListReadData[SG_LIST_NUM_BRAMS-1:0];
	wire [31:0] currPage = hostBufferDesiredAddr >> hostBufferPageSizeLB2;
	assign hostBufferDesiredReadPageSubAddr = hostBufferDesiredAddr - (currPage << hostBufferPageSizeLB2);
	
	wire [22:0] currSglBr = currPage[31:9];
	assign hostBufferDesiredPageAddress = sgPageListReadData[currSglBr];
	
	// generate local buffer block rams
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
	
	
	// Inst SAXI_CFG
	SAXI_MM #(
		.PROTOCOL(SAXI_CFG_PROTOCOL),
		.DATA_WIDTH(SAXI_CFG_DATA_WIDTH),
		.ADDR_WIDTH(SAXI_CFG_ADDR_WIDTH),
		.MM_BYTES(SAXI_CFG_MM_SIZE)
	) SAXI_CFG (
		.aclk(axiClk),
		.aresetn(axiResetNr),
		
		.SAXI_araddr(SAXI_CFG_ARADDR),
		.SAXI_arburst(SAXI_CFG_ARBURST),
		.SAXI_arlen(SAXI_CFG_ARLEN),
		.SAXI_arprot(SAXI_CFG_ARPROT),
		.SAXI_arready(SAXI_CFG_ARREADY),
		.SAXI_arsize(SAXI_CFG_ARSIZE),
		.SAXI_arvalid(SAXI_CFG_ARVALID),
		.SAXI_awaddr(SAXI_CFG_AWADDR),
		.SAXI_awburst(SAXI_CFG_AWBURST),
		.SAXI_awlen(SAXI_CFG_AWLEN),
		.SAXI_awprot(SAXI_CFG_AWPROT),
		.SAXI_awready(SAXI_CFG_AWREADY),
		.SAXI_awsize(SAXI_CFG_AWSIZE),
		.SAXI_awvalid(SAXI_CFG_AWVALID),
		.SAXI_bready(SAXI_CFG_BREADY),
		.SAXI_bresp(SAXI_CFG_BRESP),
		.SAXI_bvalid(SAXI_CFG_BVALID),
		.SAXI_rdata(SAXI_CFG_RDATA),
		.SAXI_rlast(SAXI_CFG_RLAST),
		.SAXI_rready(SAXI_CFG_RREADY),
		.SAXI_rresp(SAXI_CFG_RRESP),
		.SAXI_rvalid(SAXI_CFG_RVALID),
		.SAXI_wdata(SAXI_CFG_WDATA),
		.SAXI_wlast(SAXI_CFG_WLAST),
		.SAXI_wready(SAXI_CFG_WREADY),
		.SAXI_wstrb(SAXI_CFG_WSTRB),
		.SAXI_wvalid(SAXI_CFG_WVALID),
		
		.byteWriteEn(SAXI_CFG_byteWriteEn),
		.bitWriteData(SAXI_CFG_bitWriteData),
		.bitReadData(SAXI_CFG_bitReadData)
	);
	
endmodule
