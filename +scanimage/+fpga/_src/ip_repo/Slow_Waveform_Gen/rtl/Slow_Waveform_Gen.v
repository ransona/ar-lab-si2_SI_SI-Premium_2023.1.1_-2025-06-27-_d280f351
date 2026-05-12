//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

/*\ 
|*| host buffer must always be in multiples of chunks. actual waveform can end halfway through a chunk but the buffer must be bigger.
|*| host buffer should also be aligned to 4*chunk size
\*/

module Slow_Waveform_Gen #(
	parameter SAMPLE_WIDTH_BYTES		= 2,
	parameter AXI_DATA_WIDTH    		= 256,
	parameter MAXI_DATA_ADDR_WIDTH 		= 32,
	
	parameter EXT_VAL_TRIGGER_PORT      = 0,
	parameter NUM_EXT_TRIGGERS    		= 48,
	parameter NUM_PEER_TRIGGERS    		= 26,
	parameter PEER_TRIGGER_IDX    		= 0,
	parameter WAVE_LENGTH_BITS			= 40,
	
	parameter SG_PAGE_LIST_LENGTH      	= 2048, // must be multiple of 512

	parameter LOCAL_BUFFER_TYPE			= "BLOCK_RAM",
	
	// these should not be changed
	localparam SAXIL_CFG_DATA_WIDTH		= 32,
	localparam SAXIL_CFG_ADDR_WIDTH		= 8
)(
	output wire loadSample,
	output wire [15:0] sampleData,
	output wire triggerImmediately,
	output wire asyncTrigger,
	output wire resetDac,
	
	input  wire externalValueTrigger,
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
	output wire  MAXI_DATA_RREADY
);
	localparam WAVE_LENGTH_ACTUAL_BITS = min(WAVE_LENGTH_BITS,MAXI_DATA_ADDR_WIDTH-1);
	localparam NUM_LOCAL_CHUNKS = 4; // to change this, lots of other things need to change too; this is integral to the logic
	localparam NUM_LOCAL_CHUNKS_LB2 = clogb2(NUM_LOCAL_CHUNKS-1);
	localparam CHUNK_BURST_LEN = 128;  // if block ram implementation is selected, this should be 128. Less is just a waste of a block ram
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

	localparam OUTPUT_MAX = 2**(SAMPLE_WIDTH_BYTES*8)-1;

	// these parameters must be set according to the timebase rate
	localparam DEFAULT_SAMPLE_PERIOD = 200;
	localparam LOAD_DUR_TICKS = 90;
	localparam PULSE_OUT_TICKS = 6;
	
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
	
	// function to return the upper 32 bits of a 64 bit value
	function [31:0] HI;
		input [63:0] val;
		HI = val[63:32];
	endfunction
	
	// saturating 16 bit adder; assumes first parameter is unsigned and second is signed
	function [15:0] saturated_add;
		input [15:0] a;
		input signed [15:0] b;
		reg signed [17:0] a_ext;
		reg signed [17:0] sum_ext;
	begin
		a_ext = {2'b00, a};
		sum_ext = a_ext + b;
		saturated_add = (sum_ext < 0) ? 0 : ((sum_ext > OUTPUT_MAX) ? OUTPUT_MAX : sum_ext);
	end
	endfunction
	
	// saturate
	function [15:0] saturateDelta;
		input [15:0] newVal;
		input [15:0] oldVal;
		input [15:0] maxDelta;
		reg [16:0] oldVal_ext;
		reg [16:0] max_ext;
		reg [16:0] min_ext;
	begin
		oldVal_ext = {1'b00, oldVal};
		max_ext = oldVal_ext + maxDelta;
		min_ext = (oldVal_ext > maxDelta) ? oldVal_ext - maxDelta : 0;
		saturateDelta = (newVal < min_ext) ? min_ext : ((newVal > max_ext) ? max_ext : newVal);
	end
	endfunction


	// SAXIL_CFG slave intf
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0ReadAddress;
	reg [SAXIL_CFG_DATA_WIDTH-1:0] cfgReadData = 0;
	wire cfgWriteActive;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] cfgWriteAddress;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] cfgActiveWriteAddress = cfgWriteActive ? cfgWriteAddress : 255;
	wire [SAXIL_CFG_DATA_WIDTH-1:0] cfgWriteData;
	
	
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
//	assign MAXI_DATA_AWID	 = 'b0;
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
//	assign MAXI_DATA_ARID	 = 'b0;
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
	reg  [31:0] hostBufferFirstPageAddress = 0;
	wire [31:0] hostBufferDesiredPageAddress;
	reg  [31:0] hostBufferDesiredAddr = 0;
	wire [31:0] hostBufferDesiredReadPageSubAddr;
	reg  [MAXI_DATA_ADDR_WIDTH-1:0] hostBufferTotalSize = 0;
	reg  [31:0] hostBufferNumPages = 0;
	reg  [4:0] hostBufferPageSizeLB2 = 0;
	reg  addrReq = 0;
	reg  addrReady = 0;
	reg  configured = 0;
	
	// state machine regs
	reg  enableBufferedMode = 0;
	reg  initialRead = 1;
	reg  firstUpdate = 1;
	reg  lclBufferChunk1Dirty = 1;
	reg  lclBufferChunk1Updating = 0;
	reg  lclBufferChunk2Dirty = 1;
	reg  lclBufferChunk2Updating = 0;
	reg  lclBufferChunk3Dirty = 1;
	reg  lclBufferChunk3Updating = 0;
	reg  [WAVE_LENGTH_ACTUAL_BITS-1:0] waveformLengthSamples = 0;
	reg  [LCL_BUFFER_NUM_ROWS_LB2-1:0] lclBufferWriteRow = 0;
	reg  [CHUNK_NUM_BITS:0] lclBufferChunk2Position = 0;		
	reg  [CHUNK_NUM_BITS:0] lclBufferChunk3Position = 0;
	reg  [CHUNK_NUM_BITS:0] lclBufferChunk2NewPosition = 0;		
	reg  [CHUNK_NUM_BITS:0] lclBufferChunk3NewPosition = 0;
	wire [WAVE_LENGTH_ACTUAL_BITS-1:0] sampleOutputPosition_ac;
	
	
	reg bufferChanged = 0;
	reg bufferChangedAck = 0;
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
	
	(* ASYNC_REG = "TRUE" *) reg [1:0] externalValueTrigger_occ;
	wire externalValueTrigger_oc = externalValueTrigger_occ[0];
	reg  signed [SAMPLE_WIDTH_BYTES*8-1:0] externalValueTriggerValue = 32768;
	reg  enableExternalValueTrigger = 0;
	wire externalValueTriggerNow_oc = enableExternalValueTrigger && externalValueTrigger_oc;

	
	wire bufferedModeReady = enableBufferedMode_oc && ~initialRead_oc && ~externalValueTriggerNow_oc;
	

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
	wire [SAMPLE_WIDTH_BYTES*8-1:0] nextBufferSample = lclBufferDataOut[(sampleOutputPosition[SAMPLES_PER_ROW_LB2-1:0]<<SAMPLE_BYTES_LB2)*8+:SAMPLE_WIDTH_BYTES*8];

	assign lclBufferReadRow = lclBufferReadRowReg;
	
	// clock cross to axi logic
	reg sampleOuputPositionUpdated = 0;
	reg [WAVE_LENGTH_ACTUAL_BITS-1:0] sampleOutputPositionSend = 0;
	SWCCi #(.WW(WAVE_LENGTH_ACTUAL_BITS)) sampleOutPosCrss(.srcV(sampleOutputPositionSend), .srcClk(sampleClkTimebase), .dstV(sampleOutputPosition_ac), .dstClk(axiClk), .dstRst(~axiResetNr));
	
	// non buffered update request
	reg usrUpdateReq = 0;
	reg usrUpdateReqAck = 0;
	reg [15:0] usrUpdateReqData = 0;
	wire usrUpdateReq_oc;
	wire usrUpdateReqAck_ac;
	SBCCi usrUpdateReqCrss(.srcV(usrUpdateReq), .srcClk(axiClk), .dstV(usrUpdateReq_oc), .dstClk(sampleClkTimebase));
	SBCCi usrUpdateReqAckCrss(.srcV(usrUpdateReqAck), .srcClk(sampleClkTimebase), .dstV(usrUpdateReqAck_ac), .dstClk(axiClk));
	
	reg [15:0] samplePeriod = DEFAULT_SAMPLE_PERIOD;
	reg [15:0] samplePeriodCtr = 0;
	
	reg [5:0] triggerId = 0;
	reg triggerIdSet = 0;
	reg triggerPolarity = 0;
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
	reg nextSampleLoaded = 0;
	reg [WAVE_LENGTH_ACTUAL_BITS-1:0] samplesPerTrigger = 0;
	reg continuousGen = 1;
	reg [WAVE_LENGTH_ACTUAL_BITS-1:0] samplesRemaining = 0;
	reg [WAVE_LENGTH_ACTUAL_BITS-1:0] samplesRemainingPreup1 = 0;
	reg [WAVE_LENGTH_ACTUAL_BITS-1:0] samplesRemainingPreup2 = 0;
	reg allowRetrigger = 0;
	reg allowEarlyTrigger = 0;
	reg [3:0] smDelay = 0;
	reg [47:0] bufferedSamplesDone = 0;
	
	(* ASYNC_REG = "TRUE" *)
	reg [1:0] trigSyncr = 0;
	
	reg  allowTrigger = 0;
	reg  triggerReq = 0;
	wire triggerReq_oc;
	reg  triggerReqAck = 0;
	wire triggerReqAck_ac;
	reg  tirggerLatch = 0;
	reg  pTrig = 1;
	wire myTrigger = trigSyncr[0] ^ triggerPolarity_oc;
	wire triggerPresentP = ((triggerIdSet_oc && myTrigger && ~pTrig && ~trigSettingUpdated) || triggerReq_oc) && allowTrigger;
	reg  [NUM_PEER_TRIGGERS-1:0] peer_triggersR = 0;
	wire triggerPresent = peerTrigEn_oc ? peer_triggersR[triggerId_oc] : peer_triggersR[PEER_TRIGGER_IDX];
	reg  triggerPresentR = 0;
	wire isTrigd = tirggerLatch || triggerPresentR;

	wire triggerBufferedSampleNow = isTrigd && !samplePeriodCtr;
	
	assign peer_triggers[PEER_TRIGGER_IDX] = triggerPresentP;
	
	SBCCi triggerReqCrss(.srcV(triggerReq), .srcClk(axiClk), .dstV(triggerReq_oc), .dstClk(sampleClkTimebase));
	SBCCi triggerReqAckCrss(.srcV(triggerReqAck), .srcClk(sampleClkTimebase), .dstV(triggerReqAck_ac), .dstClk(axiClk));
	SBCCi doneCrss(.srcV(done), .srcClk(sampleClkTimebase), .dstV(done_ac), .dstClk(axiClk));
	
	reg usrDacRst = 0;
	reg advBuffer = 0;
	reg loadSampleNow = 0;
	reg triggerImmediatelyR = 0;
	reg asyncTriggerR = 0;
	reg [SAMPLE_WIDTH_BYTES*8-1:0] dacLastLoadedData = 0;

	reg [clogb2(LOAD_DUR_TICKS)-1:0]  loadCtr = 0;
	reg [clogb2(PULSE_OUT_TICKS)-1:0] loadPulseCtr = 0;
	reg [clogb2(PULSE_OUT_TICKS)-1:0] ldacPulseCtr = 0;

	reg loadPulseCtrR = 0;
	reg ldacPulseCtrR = 0;
	
	wire dacIsIdle = !loadCtr && ~loadSampleNow && !ldacPulseCtr;
	
	assign loadSample = loadPulseCtrR;
	assign sampleData = dacLastLoadedData;
	assign resetDac = ~rc_resetn || usrDacRst;
	assign triggerImmediately = triggerImmediatelyR;
	assign asyncTrigger = ldacPulseCtrR;

	
	reg  signed [SAMPLE_WIDTH_BYTES*8-1:0] sampleOffset = 0;
	reg  [SAMPLE_WIDTH_BYTES*8-1:0] lastSampleSent = 32768;
	reg  [SAMPLE_WIDTH_BYTES*8-1:0] desiredSample = 32768;
	reg  offTarget = 0;

	reg  [SAMPLE_WIDTH_BYTES*8-1:0] nextBufferSampleR;
	wire [SAMPLE_WIDTH_BYTES*8-1:0] nextBufferSample_wOffset = saturated_add(nextBufferSampleR, sampleOffset);
	reg  [SAMPLE_WIDTH_BYTES*8-1:0] nextBufferSample_wOffset_R = 0;

	reg  [SAMPLE_WIDTH_BYTES*8-1:0] maxSampleDelta = OUTPUT_MAX;
	wire [SAMPLE_WIDTH_BYTES*8-1:0] nextBufferSample_wOffset_rateLimited = saturateDelta(nextBufferSample_wOffset,lastSampleSent,maxSampleDelta);
	reg  [SAMPLE_WIDTH_BYTES*8-1:0] nextBufferSample_wOffset_rateLimited_R = 0;
	
	reg  usrUpdate = 0;
	reg  usrUpdateReqPresent = 0;
	reg  [15:0] usrUpdateReqDataR = 0;
	reg  [15:0] usrUpdateReqData_rateLimited = 0;
	
	wire [SAMPLE_WIDTH_BYTES*8-1:0] nextCorrectionSample = saturateDelta(desiredSample,lastSampleSent,maxSampleDelta);

	// output state machine
	always @(posedge sampleClkTimebase) begin
		if (trigSettingUpdated)
			trigSettingUpdatedR <= 3;
		else if (trigSettingUpdatedR)
			trigSettingUpdatedR <= trigSettingUpdatedR - 1;
		
		peer_triggersR <= peer_triggers;
		triggerPresentR <= triggerPresent;
		
		pTrig <= myTrigger || trigSettingUpdated || trigSettingUpdatedR;
		
		trigSyncr <= {ext_triggers[triggerId_oc], trigSyncr[1]};

		externalValueTrigger_occ <= {externalValueTrigger, externalValueTrigger_occ[1]};
		
		lclBufferReadRowReg <= lclBufferReadRowPreup;
		nextBufferSampleR <= nextBufferSample;
		nextBufferSample_wOffset_R <= nextBufferSample_wOffset;
		nextBufferSample_wOffset_rateLimited_R <= nextBufferSample_wOffset_rateLimited;

		usrUpdateReqPresent <= usrUpdateReq_oc;
		usrUpdateReqDataR <= usrUpdateReqData;
		usrUpdateReqData_rateLimited <= saturateDelta(usrUpdateReqData,lastSampleSent,maxSampleDelta);

		offTarget <= lastSampleSent != desiredSample;
		
		if (~rc_resetn) begin
			sampleOutputPosition <= 0;
			sampleOutputPositionSend <= 0;
			sampleOuputPositionUpdated <= 0;
			tirggerLatch <= 0;
			nextSampleLoaded <= 0;
			loadSampleNow = 0;
			asyncTriggerR = 0;
			samplePeriodCtr <= 0;
			allowTrigger <= 1;
			done <= 0;
			smDelay <= 0;
			samplesRemaining <= 0;
			bufferedSamplesDone <= 0;
			usrUpdate <= 0;
		end else if (~bufferedModeReady) begin
			sampleOutputPosition <= 0;
			sampleOutputPositionSend <= 0;
			sampleOuputPositionUpdated <= 0;
			tirggerLatch <= 0;
			nextSampleLoaded <= 0;
			samplePeriodCtr <= 0;
			advBuffer = 0;
			allowTrigger <= 1;
			done <= 0;
			smDelay <= 0;
			samplesRemaining <= 0;
			
			triggerReqAck <= 1;
			
			// on demand output request
			if (dacIsIdle && (offTarget || usrUpdateReqPresent) && ~usrUpdateReqAck) begin
				loadSampleNow = 1;
				triggerImmediatelyR <= 1;
				asyncTriggerR = 0;
				dacLastLoadedData <= usrUpdateReqPresent ? usrUpdateReqData_rateLimited : nextCorrectionSample;
				usrUpdateReqAck <= usrUpdateReqPresent;
				usrUpdate <= usrUpdateReqPresent;
			end else begin
				loadSampleNow = 0;
				asyncTriggerR = 0;
				usrUpdate <= 0;
				
				usrUpdateReqAck <= usrUpdateReqPresent && usrUpdateReqAck;
			end
		end else begin
			// buffered output
			if (smDelay) begin
				// state machine delay
				loadSampleNow = 0;
				asyncTriggerR = 0;
				smDelay <= smDelay - 1;
				advBuffer <= 0;
				usrUpdate <= 0;
			end else if (triggerBufferedSampleNow) begin
				// sample period timer expired. trigger the next sample
				asyncTriggerR = dacIsIdle && nextSampleLoaded;
				loadSampleNow = 0;
				smDelay <= 15; // after advancing the buffer position it takes a few clock cycles for the next sample value to be available
				nextSampleLoaded <= 0;
				advBuffer <= 1;
				usrUpdate <= 0;
			end else if (~isTrigd && usrUpdateReqPresent && dacIsIdle) begin
				// we are sitting idle waiting for the trigger and an axi request comes in to change the output
				loadSampleNow = 1;
				triggerImmediatelyR <= 1;
				asyncTriggerR = 0;
				dacLastLoadedData <= usrUpdateReqData_rateLimited;
				usrUpdate <= 1;
				nextSampleLoaded <= 0;
				advBuffer <= 0;
			end else if (offTarget && dacIsIdle) begin
				loadSampleNow = 1;
				triggerImmediatelyR <= 1;
				asyncTriggerR = 0;
				dacLastLoadedData <= nextCorrectionSample;
				nextSampleLoaded <= 0;
				advBuffer <= 0;
				usrUpdate <= 0;
			end else if (~nextSampleLoaded && dacIsIdle) begin
				// preload the DAC shift register with the next sample in the buffer, ready to be triggered
				loadSampleNow = 1;
				triggerImmediatelyR <= 0;
				asyncTriggerR = 0;
				dacLastLoadedData <= nextBufferSample_wOffset_rateLimited_R;
				nextSampleLoaded <= 1;
				advBuffer <= 0;
				usrUpdate <= 0;
			end else begin
				loadSampleNow = 0;
				asyncTriggerR = 0;
				advBuffer <= 0;
				usrUpdate <= 0;
			end
			
			triggerReqAck <= triggerReq_oc;
			
			if (triggerBufferedSampleNow)
				samplePeriodCtr <= samplePeriod - 1;
			else if (samplePeriodCtr)
				samplePeriodCtr <= samplePeriodCtr - 1;
			
			usrUpdateReqAck <= usrUpdateReqPresent;
			
			if (triggerPresentR) begin
				// trigger arrived
				allowTrigger <= allowRetrigger;
				if (~tirggerLatch) begin
					// we were waiting for the trigger. start the new generation
					samplesRemainingPreup1 = samplesPerTrigger | continuousGen; // minimum of one; if samplesPerTrigger=0 this is a continuous gen
					sampleOutputPositionPreup1 = sampleOutputPosition;
				end else if (allowRetrigger && allowEarlyTrigger) begin
					samplesRemainingPreup1 = samplesPerTrigger;
					sampleOutputPositionPreup1 = sampleOutputPosition + samplesRemaining;
				end
			end else begin
				samplesRemainingPreup1 = samplesRemaining;
				sampleOutputPositionPreup1 = sampleOutputPosition;
			end
			
			samplesRemainingPreup2 = continuousGen ? samplesRemainingPreup1 : samplesRemainingPreup1 - advBuffer;
			sampleOutputPositionPreup2 = sampleOutputPositionPreup1 + advBuffer;
				
			tirggerLatch <= samplesRemainingPreup2 > 0;
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
		
		if (asyncTriggerR) begin
			ldacPulseCtr <= PULSE_OUT_TICKS;
			ldacPulseCtrR <= 1;
		end else if (ldacPulseCtr) begin
			ldacPulseCtr <= ldacPulseCtr - 1;
			ldacPulseCtrR <= ldacPulseCtr > 1;
		end
		
		if (loadSampleNow) begin
			loadPulseCtr <= PULSE_OUT_TICKS;
			loadPulseCtrR <= 1;
		end else if (loadPulseCtr) begin
			loadPulseCtr <= loadPulseCtr - 1;
			loadPulseCtrR <= loadPulseCtr > 1;
		end
		
		if (loadSampleNow)
			loadCtr <= LOAD_DUR_TICKS;
		else if (loadCtr)
			loadCtr <= loadCtr - 1;
		
		if (~rc_resetn)
			desiredSample <= 32768;
		else if (externalValueTriggerNow_oc)
			desiredSample <= externalValueTriggerValue;
		else if (bufferedModeReady && triggerBufferedSampleNow)
			desiredSample <= nextBufferSample_wOffset_R;
		else if (usrUpdate)
			desiredSample <= usrUpdateReqDataR;
		
		if (~rc_resetn)
			lastSampleSent <= 32768;
		else if ((ldacPulseCtr == PULSE_OUT_TICKS) || ((loadPulseCtr == PULSE_OUT_TICKS) && triggerImmediatelyR))
			lastSampleSent <= dacLastLoadedData;
	end



	// AXI latency tracker
	reg raddr_valid_p = 1;
	reg rvalid_p = 1;
	reg rlast_p = 1;

	reg raddr_valid_RE = 0;
	reg rvalid_RE = 0;
	reg rlast_RE = 0;

	reg reqStarted = 0;
	reg [31:0] transactionTimer = 0;
	reg [31:0] thisReqToDataLatency = 0;

	reg [31:0] lastReqToDataLatency = 0;
	reg [31:0] lastDataDuration = 0;

	reg [31:0] lastReqToDataLatencyCache = 0;
	reg [31:0] lastDataDurationCache = 0;

	reg [31:0] maxReqToDataLatency = 0;
	reg [31:0] maxDataDuration = 0;

	always @(posedge axiClk) begin
		raddr_valid_p <= axi_arvalid;
		rvalid_p <= MAXI_DATA_RVALID;
		rlast_p <= MAXI_DATA_RVALID && MAXI_DATA_RLAST;
		
		raddr_valid_RE <= axi_arvalid && ~raddr_valid_p;
		rvalid_RE <= MAXI_DATA_RVALID && ~rvalid_p;
		rlast_RE <= axi_rready && MAXI_DATA_RVALID && MAXI_DATA_RLAST && ~rlast_p;

		if (raddr_valid_RE) begin
			transactionTimer <= 1;
			reqStarted <= 1;
		end else if (reqStarted && rvalid_RE) begin
			reqStarted <= 0;
			thisReqToDataLatency <= transactionTimer;
			transactionTimer <= 1;
		end else
			transactionTimer <= transactionTimer + (!(&transactionTimer)); // saturating add

		if (rlast_RE) begin
			lastReqToDataLatency <= thisReqToDataLatency;
			lastDataDuration <= transactionTimer;
		end else if (cfgActiveWriteAddress == 140) begin
			lastReqToDataLatency <= 0;
			lastDataDuration <= 0;
		end

		if (cfgActiveWriteAddress == 140)
			maxReqToDataLatency <= 0;
		else if (lastReqToDataLatency > maxReqToDataLatency)
			maxReqToDataLatency <= lastReqToDataLatency;

		if (cfgActiveWriteAddress == 140)
			maxDataDuration <= 0;
		else if (lastDataDuration > maxDataDuration)
			maxDataDuration <= lastDataDuration;
	end
	
	
	
	// error tracking
	wire chunk2IsLate = lclBufferChunk2NeedsUpdate && (lclBufferOutputChunkPosition_ac == 2);
	wire chunk3IsLate = lclBufferChunk3NeedsUpdate && (lclBufferOutputChunkPosition_ac == 3);
	wire outputError = ~initialRead && (chunk2IsLate || chunk3IsLate);
	reg outputErrorLatch = 0;
	reg [31:0] consecUpdateNeeded = 0;
	reg [31:0] maxConsecUpdateNeeded = 0;
	
	wire [47:0] bufferedSamplesDone_ac;
	SWCCi #(.WW(48)) bufferedSamplesDoneCrss(.srcV(bufferedSamplesDone), .srcClk(sampleClkTimebase), .dstV(bufferedSamplesDone_ac), .dstClk(axiClk), .dstRst(~axiResetNr));
	
	reg [47:0] bufferedSamplesDoneCache = 0;
	reg [WAVE_LENGTH_ACTUAL_BITS-1:0] sampleOutputPositionCache = 0;
	
	reg [31:0] writeSGPageListAddr = 0;
	reg [31:0] writeSGPageListData = 0;
	reg writeSGPageList = 0;
	
	reg [31:0] tempBits = 0;
	
	reg [63:0] ownerUuid = 0;
	reg [63:0] bufferWriterUuid = 0;

	wire [SAMPLE_WIDTH_BYTES*8-1:0] lastSampleSent_ac;
	SWCCi #(.WW(16)) lastSampleCC(.srcV(lastSampleSent), .srcClk(sampleClkTimebase), .dstV(lastSampleSent_ac), .dstClk(axiClk), .dstRst(~axiResetNr));
	wire [SAMPLE_WIDTH_BYTES*8-1:0] lastSampleSentWithoutOffset = saturated_add(lastSampleSent_ac, -sampleOffset);
	
	wire offTarget_ac;
	SBCCi offTargetCC(.srcV(offTarget), .srcClk(sampleClkTimebase), .dstV(offTarget_ac), .dstClk(axiClk));

	reg [2:0] usrDacRstCtr = 0;
	
	(* ASYNC_REG = "TRUE" *) reg [1:0] externalValueTrigger_acc;
	wire externalValueTrigger_ac = externalValueTrigger_acc[0];
	wire externalValueTriggerNow_ac = enableExternalValueTrigger && externalValueTrigger_ac;

	// axi config slave; receives configuration data and commands from host
	always @(posedge axiClk) begin
		externalValueTrigger_acc <= {externalValueTrigger, externalValueTrigger_acc[1]};

		if (~axiResetNr) begin
			enableBufferedMode <= 0;
			waveformLengthSamples <= 0;
			sampleOffset <= 0;
			outputErrorLatch <= 0;
			consecUpdateNeeded <= 0;
			maxConsecUpdateNeeded <= 0;
			usrUpdateReq <= 0;
			maxSampleDelta <= OUTPUT_MAX;
			
			hostBufferFirstPageAddress <= 0;
			hostBufferTotalSize <= 0;
			hostBufferNumPages <= 0;
			hostBufferPageSizeLB2 <= 0;
			writeSGPageList <= 0;
			configured <= 0;
		end else begin
			usrDacRst <= |usrDacRstCtr;
			if (cfgActiveWriteAddress == 160)
				usrDacRstCtr <= 3'b111;
			else if (usrDacRstCtr)
				usrDacRstCtr <= usrDacRstCtr - 1;

			// abort generation if error occurs
			// note, outputError goes true about one sample period before an incorrect sample actually would get output
			if ((enableBufferedMode && outputError) || externalValueTriggerNow_ac)
				enableBufferedMode <= 0;
			else if (cfgActiveWriteAddress == 4)
				enableBufferedMode <= cfgWriteData;
			
			// Clear error state when buffered mode is started
			if ((cfgActiveWriteAddress == 24) || ((cfgActiveWriteAddress == 4) && cfgWriteData))
				outputErrorLatch <= 0;
			else
				outputErrorLatch <= outputErrorLatch || outputError;
			
			if (~initialRead && (lclBufferChunk2NeedsUpdate || lclBufferChunk3NeedsUpdate))
				consecUpdateNeeded <= consecUpdateNeeded + 1;
			else
				consecUpdateNeeded <= 0;
				
			if(cfgActiveWriteAddress == 96)
				maxConsecUpdateNeeded <= 0;
			else if (consecUpdateNeeded > maxConsecUpdateNeeded)
				maxConsecUpdateNeeded <= consecUpdateNeeded;
			
			// non buffered sample reqs
			if (usrUpdateReqAck_ac)
				usrUpdateReq <= 0;
			else if((cfgActiveWriteAddress == 16) || (cfgActiveWriteAddress == 20))
				usrUpdateReq <= 1;
			
			
			if(~usrUpdateReq && (cfgActiveWriteAddress == 16))
				usrUpdateReqData <= lastSampleSentWithoutOffset + cfgWriteData[15:0];
			else if(~usrUpdateReq && (cfgActiveWriteAddress == 20))
				usrUpdateReqData <= cfgWriteData[31] ? cfgWriteData[15:0] : saturated_add(cfgWriteData[15:0], sampleOffset);
			
			// trigger req
			if (triggerReqAck_ac)
				triggerReq <= 0;
			else
				triggerReq <= triggerReq || (cfgActiveWriteAddress == 52);
			
		
			case (s0ReadAddress)
				0: cfgReadData <= 32'hFAAF_FEF2;
				
				8: cfgReadData <= PEER_TRIGGER_IDX;
				
				4: cfgReadData <= enableBufferedMode;
				
				12: cfgReadData <= WAVE_LENGTH_BITS;
				
				16: cfgReadData <= sampleOffset;
				
				20: cfgReadData <= {lastSampleSentWithoutOffset, lastSampleSent_ac};
				
				24: cfgReadData <= outputErrorLatch;
				
				28: cfgReadData <= samplePeriod;
				
				32: cfgReadData <= samplesPerTrigger;
				
				36: cfgReadData <= HI(samplesPerTrigger);
			
				40:	cfgReadData <= peerTrigEn ? triggerId : 16'hFFFF;
				
				44: cfgReadData <= triggerIdSet ? triggerId : 16'hFFFF;
				
				48: cfgReadData <= {allowEarlyTrigger, allowRetrigger};
				
				52: cfgReadData <= done_ac;
				
				56:	cfgReadData <= triggerPolarity;
				
				60: cfgReadData <= {bufferChangedAck, bufferChanged};
				
				64: cfgReadData <= waveformLengthSamples;
				
				68: cfgReadData <= HI(waveformLengthSamples);
				
				72: cfgReadData <= sampleOutputPositionCache;
				
				76: cfgReadData <= HI(sampleOutputPositionCache);
				
				80: cfgReadData <= samplesPerTrigger;
				
				84: cfgReadData <= HI(samplesPerTrigger);
				
				88: cfgReadData <= bufferedSamplesDoneCache;
				
				92: cfgReadData <= HI(bufferedSamplesDoneCache);
				
				96: cfgReadData <= maxConsecUpdateNeeded;
				
				
				104: cfgReadData <= ownerUuid[31:0];
				108: cfgReadData <= ownerUuid[63:32];
				
				112: cfgReadData <= bufferWriterUuid[31:0];
				116: cfgReadData <= bufferWriterUuid[63:32];
				
				120: cfgReadData <= maxSampleDelta;
				124: cfgReadData <= offTarget_ac;

				132: cfgReadData <= lastReqToDataLatencyCache;
				136: cfgReadData <= lastDataDurationCache;

				140: cfgReadData <= maxReqToDataLatency;
				144: cfgReadData <= maxDataDuration;
				
				148: cfgReadData <= {axi_rready, lclBufferChunk1Updating, lclBufferChunk1Dirty, initialRead, firstUpdate};
				152: cfgReadData <= lclBufferChunk2Position;
				156: cfgReadData <= lclBufferChunk3Position;

			//	160: usrDacRst

				164: cfgReadData <= enableExternalValueTrigger;
				168: cfgReadData <= externalValueTriggerValue;
				172: cfgReadData <= externalValueTrigger_ac;

				
				200: cfgReadData <= 32'h_CACA_0002; // Scatter gather page list, v2
				
				204: cfgReadData <= SG_PAGE_LIST_LENGTH;
				
				208: cfgReadData <= MAXI_DATA_ADDR_WIDTH;
			
				212: cfgReadData <= hostBufferFirstPageAddress;
				
				216: cfgReadData <= hostBufferTotalSize;
				
				220: cfgReadData <= HI(hostBufferTotalSize);
				
				224: cfgReadData <= hostBufferNumPages;
				
				228: cfgReadData <= hostBufferPageSizeLB2;
				
				232: cfgReadData <= writeSGPageListAddr;
				
				default: cfgReadData <= 32'hFAAF_FEFF;
			endcase
		
			case (cfgActiveWriteAddress)
			//	4:  enableBufferedMode <= cfgWriteData[0];
			
			//	8: PEER_TRIGGER_IDX
				
				16: sampleOffset <= cfgWriteData[15:0];
				
				28: samplePeriod <= cfgWriteData[15:0];
				
				40: begin
					triggerIdSet <= 0;
					peerTrigEn <= cfgWriteData < 16'hFFFF;
					triggerId <= cfgWriteData;
				end
				
				44: begin
					peerTrigEn <= 0;
					triggerIdSet <= cfgWriteData < 16'hFFFF;
					triggerId <= cfgWriteData;
				end
				
				48: {allowEarlyTrigger, allowRetrigger} <= cfgWriteData[1:0];
				
			//	52: trigger
			
				56: triggerPolarity <= cfgWriteData;
			
			//	60: buffer changed
			
				64: tempBits <= cfgWriteData;
				
				68: waveformLengthSamples <= {cfgWriteData, tempBits};
				
				72: sampleOutputPositionCache <= sampleOutputPosition_ac;
				
			//	76: sampleOutputPosition
				
				80: tempBits <= cfgWriteData;
			
				84: begin
					samplesPerTrigger <= {cfgWriteData, tempBits};
					continuousGen <= {cfgWriteData, tempBits} == 0;
				end
				
				88: bufferedSamplesDoneCache <= bufferedSamplesDone_ac;
				
			//	92: bufferedSamplesDone
			
			//	96: maxConsecUpdateNeeded;
				
				104: ownerUuid[31:0] <= cfgWriteData;
				108: ownerUuid[63:32] <= cfgWriteData;
				
				112: bufferWriterUuid[31:0] <= cfgWriteData;
				116: bufferWriterUuid[63:32] <= cfgWriteData;
				
				120: maxSampleDelta <= cfgWriteData;

				132: begin
					lastReqToDataLatencyCache <= lastReqToDataLatency;
					lastDataDurationCache <= lastDataDuration;
				end
			//	136: lastDataDurationCache;

			//	140: maxReqToDataLatency;
			//	144: maxDataDuration;
				
			//	148: {axi_rready, lclBufferChunk1Updating, lclBufferChunk1Dirty, initialRead, firstUpdate};
			//	152: lclBufferChunk2Position;
			//	156: lclBufferChunk3Position;
				
			//	160: usrDacRst

				164: enableExternalValueTrigger <= cfgWriteData;
				168: externalValueTriggerValue <= cfgWriteData;
			//	172: externalValueTrigger_ac

			
				212: begin // Host buffer address
					hostBufferFirstPageAddress <= cfgWriteData;
					hostBufferTotalSize <= 0;
					configured <= 0;
					
					writeSGPageListAddr <= 0;
					writeSGPageListData <= cfgWriteData;
				end
				
				216: tempBits <= cfgWriteData;
				
				220: hostBufferTotalSize <= {cfgWriteData, tempBits};
				
				224: begin
					hostBufferNumPages <= cfgWriteData;
					configured <= cfgWriteData == 1;
				end
				
				228: hostBufferPageSizeLB2 <= cfgWriteData[4:0];
				
				232: begin
					writeSGPageListAddr <= writeSGPageListAddr + 1;
					writeSGPageListData <= cfgWriteData;
					
					configured <= writeSGPageListAddr == (hostBufferNumPages - 2);
				end
				
			endcase
			
			writeSGPageList <= (cfgActiveWriteAddress == 212) || (cfgActiveWriteAddress == 232);
			
			if (cfgActiveWriteAddress == 60)
				bufferChanged <= cfgWriteData;
			else
				bufferChanged <= bufferChanged && ~bufferChangedAck;
		end
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
	
	
	// Inst SAXIL_CFG
	SAXIL #(.DATA_WIDTH(SAXIL_CFG_DATA_WIDTH), .ADDR_WIDTH(SAXIL_CFG_ADDR_WIDTH)) SAXIL_CFG (
		.ACLK(axiClk),
		.ARESETN(axiResetNr),
		
		.writeAddress(cfgWriteAddress),
		.writeData(cfgWriteData),
		.writeStrobe(),
		.writeActive(cfgWriteActive),
		.readAddress(s0ReadAddress),
		.readData(cfgReadData),
		
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
