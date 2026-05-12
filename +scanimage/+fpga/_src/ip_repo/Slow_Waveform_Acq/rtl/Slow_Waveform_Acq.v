//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

// ip will operate in two modes. while idle host can request a sample update at any time. while in buffered modes sample updates
// are streamed to fifo. if in buffered mode but not triggered, host can request sample update. if trigger arrives while host req
// is being serviced, the first sample after the trigger will be the one being serviced then normal sampling resumes

module Slow_Waveform_Acq #(
	parameter SAMPLE_WIDTH_BYTES		= 2,
	parameter AXI_DATA_WIDTH    		= 256,
	parameter MAXI_DATA_ADDR_WIDTH 		= 40,
	
	parameter NUM_EXT_TRIGGERS    		= 48,
	parameter NUM_PEER_TRIGGERS    		= 26,
	parameter PEER_TRIGGER_IDX    		= 0,
	parameter ACQ_N_BITS    			= 40,
	
	parameter SG_PAGE_LIST_LENGTH      	= 2048, // must be multiple of 512

	parameter LOCAL_BUFFER_TYPE			= "BLOCK_RAM",
	parameter SHOW_DBG_PORTS			= 0,
	
	// these should not be changed
	localparam SAXIL_CFG_DATA_WIDTH		= 32,
	localparam SAXIL_CFG_ADDR_WIDTH		= 10
)(
	output wire startConv,
	input  wire convDone,
	input  wire [SAMPLE_WIDTH_BYTES*8-1:0] adcData,
	
	input  wire [NUM_EXT_TRIGGERS-1:0] ext_triggers,
	inout  wire [NUM_PEER_TRIGGERS-1:0] peer_triggers,
	
	input wire adcClk,
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
	output wire  MAXI_DATA_RREADY,

	// Debug ports
	output wire [15:0] dbg_lclBufferWritePointer,
	output wire [15:0] dbg_lclBufferReadPointer,
	output wire        dbg_writeFifo,
	output wire        dbg_cantWrite,
	output wire        dbg_oflowOccurred,
	output wire        dbg_sendNow,
	output wire [12:0] dbg_sendBytesRemaining,
	output wire  [7:0] dbg_axi_wlen,
	output wire        dbg_axi_awvalid,
	output wire        dbg_axi_wvalid,
	output wire        dbg_axi_wlast,
	output wire        dbg_axi_awready,
	output wire        dbg_axi_wready,
	output wire [MAXI_DATA_ADDR_WIDTH-1:0] dbg_hostBufReadPointer,
	output wire [MAXI_DATA_ADDR_WIDTH-1:0] dbg_hostBufWritePointer,

	output wire        dbg_startBufferedSamp_tbc,
	output wire        dbg_startUsrReq_tbc,
	output wire        dbg_startConvNow_tbc,
	output wire [15:0] dbg_sampleTimer_tbc,
	output wire        dbg_convDone_tbc
);
	localparam AXI_DATA_BYTES = AXI_DATA_WIDTH / 8;
	localparam LOCAL_BUFFER_ROWS = 512;
	localparam LOCAL_BUFFER_SIZE_BYTES = AXI_DATA_BYTES * LOCAL_BUFFER_ROWS;
	localparam LOCAL_BUFFER_SIZE_BYTES_LB2 = clogb2(LOCAL_BUFFER_SIZE_BYTES-1);
	localparam AXI_DATA_BYTES_LB2 = clogb2(AXI_DATA_BYTES-1);
	localparam SAMPLE_SEND_THRESH_BYTES = 512;
	localparam SG_LIST_NUM_BRAMS = SG_PAGE_LIST_LENGTH / 512;

	// these parameters must be set according to the timebase rate
	localparam DEFAULT_SAMPLE_PERIOD = 200;
	localparam CNV_PULSE_TICKS = 6;
	
	// function that returns the ceiling of the log base 2
	function [63:0] clogb2;
		input [63:0] bit_depth;
	begin
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			bit_depth = bit_depth >> 1;
		end
	endfunction
	
	// function that returns the minimum of two numbers
	function [63:0] min;
		input [63:0] a,b;
		min = (a<b)?a:b;
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

	
	/****************************************\
			Sample acquisition engine
	\****************************************/
	reg axiResetNr = 0;
	
	wire resetSm_ac;
	wire resetSm_oc;
	OSCCi resetReqCC(.srcV(resetSm_ac), .srcClk(axiClk), .dstV(resetSm_oc), .dstClk(sampleClkTimebase));

	wire rc_resetn;
	wire resetSm = ~rc_resetn || resetSm_oc;
	SBCCi reset_crss(.srcV(axiResetNr), .srcClk(axiClk), .dstV(rc_resetn), .dstClk(sampleClkTimebase));
	
	wire triggerReq_ac;
	wire triggerReq;
	OSCCi softTrigCC(.srcV(triggerReq_ac), .srcClk(axiClk), .dstV(triggerReq), .dstClk(sampleClkTimebase));
	
	wire usrSampleUpdateReq_ac;
	wire usrSampleUpdateReq;
	reg usrSampleUpdatePending = 0;
	OSCCi usrSampleUpdateReqCC(.srcV(usrSampleUpdateReq_ac), .srcClk(axiClk), .dstV(usrSampleUpdateReq), .dstClk(sampleClkTimebase));
	
	wire startWc_ac;
	wire startWaveCapture;
	OSCCi startWcCC(.srcV(startWc_ac), .srcClk(axiClk), .dstV(startWaveCapture), .dstClk(sampleClkTimebase));
	
	wire stopWc_ac;
	wire stopWaveCapture;
	reg wcStopped = 0;
	OSCCi stopWcCC(.srcV(stopWc_ac), .srcClk(axiClk), .dstV(stopWaveCapture), .dstClk(sampleClkTimebase));
	
	reg [5:0] triggerId = 0;
	reg triggerIdSet = 0;
	reg triggerPolarity = 0;
	reg peerTrigEn = 0;
	wire [5:0] triggerId_tbc;
	wire triggerIdSet_tbc;
	wire triggerPolarity_tbc;
	wire peerTrigEn_tbc;
	wire trigSettingUpdated;
	reg [1:0] trigSettingUpdatedR = 0;
	SWCCi #(.WW(9), .CONTINUOUS(0)) tiggerInfoCC(.srcV({peerTrigEn, triggerPolarity, triggerIdSet, triggerId}), .srcClk(axiClk), .dstV({peerTrigEn_tbc, triggerPolarity_tbc, triggerIdSet_tbc, triggerId_tbc}), .dstClk(sampleClkTimebase), .dstRst(~rc_resetn), .newVal(trigSettingUpdated));
	
	// acq params
	reg [ACQ_N_BITS-1:0] numberOfSamplesToAcq;
	reg allowRetrigger = 0;
	reg finiteAcq = 1;
	reg [15:0] samplePeriod = DEFAULT_SAMPLE_PERIOD;
	
	reg waveCaptureEnabled = 0;
	reg [ACQ_N_BITS-1:0] acqSamplesRemaining = 0;
	reg acqSamplesRemainingIsZero = 1;
	reg [2:0] pendingWrites = 0;
	wire waitingForWrites = pendingWrites > 0;
	reg waitingForWritesReg;
	
	reg [SAMPLE_WIDTH_BYTES*8-1:0] lastSample = 0;
	reg [31:0] numUpdates = 0;
	reg [31:0] numStarts = 0;
	
	reg [6:0] resetCtr = 0;
	reg samplePending = 0;
	
	reg [15:0] sampleTimer = 0;
	
	(* ASYNC_REG = "TRUE" *)
	reg [1:0] trigSyncr = 0;
	
	reg allowTrigger = 0;
	reg pTrig = 1;
	wire myTrigger = triggerIdSet_tbc && (trigSyncr[0] ^ triggerPolarity_tbc) && ~trigSettingUpdated;
	wire triggerPresentP = triggerReq || (myTrigger && ~pTrig);
	reg  [NUM_PEER_TRIGGERS-1:0] peer_triggersR = 0;
	wire triggerPresent = peerTrigEn_tbc ? peer_triggersR[triggerId_tbc] : peer_triggersR[PEER_TRIGGER_IDX];
	reg  triggerPresentR = 0;
	wire ackTrigger = acqSamplesRemainingIsZero && waveCaptureEnabled && triggerPresentR && allowTrigger;
	wire [ACQ_N_BITS-1:0] acqSamplesRemainingPreup = ackTrigger ? (finiteAcq ? numberOfSamplesToAcq : 1) : acqSamplesRemaining;
	
	assign peer_triggers[PEER_TRIGGER_IDX] = triggerPresentP;
	
	wire startBufferedSamp = !sampleTimer && acqSamplesRemainingPreup && waveCaptureEnabled && ~wcStopped;
	wire startUsrReq = acqSamplesRemainingIsZero && (~ackTrigger) && !samplePending && usrSampleUpdatePending;
	
	wire startConvNow = !resetCtr && (startUsrReq || startBufferedSamp);
	reg  [clogb2(CNV_PULSE_TICKS)-1:0] startConvPulseGen = 0;
	reg  startConvPulseGenR = 0;
	assign startConv = startConvPulseGenR;
	wire convDone_tbc;
	OSCCi convDoneCC(.srcV(convDone), .srcClk(adcClk), .dstV(convDone_tbc), .dstClk(sampleClkTimebase));
	
	reg writeFifo = 0;
	
	wire bufferedInputDone = waveCaptureEnabled && ~allowTrigger && acqSamplesRemainingIsZero && !pendingWrites;

	always @(posedge sampleClkTimebase) begin
		if (trigSettingUpdated)
			trigSettingUpdatedR <= 3;
		else if (trigSettingUpdatedR)
			trigSettingUpdatedR <= trigSettingUpdatedR - 1;

		peer_triggersR <= peer_triggers;
		triggerPresentR <= triggerPresent;
		
		pTrig <= myTrigger || trigSettingUpdated || trigSettingUpdatedR;
		waitingForWritesReg <= waitingForWrites;
		
		trigSyncr <= {ext_triggers[triggerId_tbc], trigSyncr[1]};
		
		if (startConvPulseGen) begin
			startConvPulseGen <= startConvPulseGen - 1;
			startConvPulseGenR <= startConvPulseGen > 1;
		end else if (startConvNow) begin
			startConvPulseGen <= CNV_PULSE_TICKS;
			startConvPulseGenR <= 1;
		end
		
		if (resetSm) begin
			resetCtr <= 65;
			samplePending <= 0;
			pendingWrites <= 0;
			acqSamplesRemaining <= 0;
			acqSamplesRemainingIsZero <= 1;
			sampleTimer <= 0;
			waveCaptureEnabled <= 0;
			allowTrigger <= 1;
			writeFifo <= 0;
			wcStopped <= 0;
		end else if (resetCtr)
			resetCtr <= resetCtr - 1;
		else begin
			samplePending <= startConvNow || (samplePending && ~convDone_tbc);
			usrSampleUpdatePending <= ~startConvNow && (usrSampleUpdateReq || usrSampleUpdatePending);
			
			if (startConvPulseGen == CNV_PULSE_TICKS)
				numStarts <= numStarts + 1;
			
			if (convDone_tbc) begin
				lastSample <= adcData;
				numUpdates <= numUpdates + 1;
			end
			
			writeFifo <= convDone_tbc && waveCaptureEnabled && pendingWrites && ~wcStopped;
			pendingWrites <= pendingWrites + startBufferedSamp - (pendingWrites && convDone_tbc);
			
			if (sampleTimer)
				sampleTimer <= sampleTimer - 1;
			else if (acqSamplesRemainingPreup) begin
				acqSamplesRemaining <= acqSamplesRemainingPreup - finiteAcq;
				acqSamplesRemainingIsZero <= (acqSamplesRemainingPreup - finiteAcq) == 0;
				sampleTimer <= samplePeriod-1;
			end
			
			waveCaptureEnabled <= waveCaptureEnabled || startWaveCapture;
			allowTrigger <= allowTrigger && (~ackTrigger || allowRetrigger);
			wcStopped <= stopWaveCapture;
		end
	end
	
	
	
	/****************************************\
			Sample buffer write engine
	\****************************************/
	reg [LOCAL_BUFFER_SIZE_BYTES_LB2:0] lclBufWritePointer = 0;
	reg [LOCAL_BUFFER_SIZE_BYTES_LB2:0] lclBufReadPointer = 0;
	
	wire waitingForWrites_ac;
	SBCCi writesCC(.srcV(waitingForWritesReg), .srcClk(sampleClkTimebase), .dstV(waitingForWrites_ac), .dstClk(axiClk));

	wire writeFifo_ac;
	reg  writeFifoDel = 0;
	OSCCi writeFifoCC(.srcV(writeFifo), .srcClk(sampleClkTimebase), .dstV(writeFifo_ac), .dstClk(axiClk));
	
	// only allow writing the sample buffer up to one row before read pointer. this avoids
	// the need to strobe out bytes before the read pointer when sending to host buffer
	wire lclBufferSpaceAvailable = (lclBufReadPointer > lclBufWritePointer) ? (lclBufReadPointer - lclBufWritePointer) > (SAMPLE_WIDTH_BYTES + AXI_DATA_BYTES) : (LOCAL_BUFFER_SIZE_BYTES - lclBufWritePointer) >= SAMPLE_WIDTH_BYTES;
	reg [31:0] lclBufOverflowCount = 0;
	
	wire lclBufWritePointerOverRange = lclBufWritePointer >= LOCAL_BUFFER_SIZE_BYTES;
	
	wire cantWrite = ~lclBufferSpaceAvailable || lclBufWritePointerOverRange;
	wire lclBufWE = ~resetSm_ac && ~cantWrite && writeFifoDel;
	
	always @(posedge axiClk) begin
		writeFifoDel <= writeFifo_ac && ~resetSm_ac;

		if (resetSm_ac) begin
			lclBufWritePointer <= 0;
			lclBufOverflowCount <= 0;
		end else if (writeFifoDel && cantWrite)
			lclBufOverflowCount <= lclBufOverflowCount + 1;
		else if (writeFifoDel)
			lclBufWritePointer <= lclBufWritePointer + SAMPLE_WIDTH_BYTES;
		else if (lclBufWritePointerOverRange && (lclBufReadPointer > 0))
			lclBufWritePointer <= 0;
	end
	
	
	
	/****************************************\
			Host data transfer engine
	\****************************************/
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
	
	
	// Transport configuration/status data. positions are in bytes
	reg [31:0] hostBufferFirstPageAddress = 0;
	reg [MAXI_DATA_ADDR_WIDTH-1:0] hostBufferTotalSize = 0;
	reg [31:0] hostBufferNumPages = 0;
	reg [4:0] hostBufferPageSizeLB2 = 0;
	reg configured = 0;
	
	wire [31:0] hostBufferCurrPageAddress;
	wire [31:0] hostBufferWritePtrPageSubAddr;
	
	reg [4:0] writesDoneDelayReg = 0;
	wire writesDone = writesDoneDelayReg[0];
	
	reg smResetPending = 0;
	reg smResetNow = 0;
	
	wire [ACQ_N_BITS-1:0] acqSamplesRemaining_ac;
	SWCCi #(.WW(ACQ_N_BITS)) acqSamps_crss(.srcV(acqSamplesRemaining), .srcClk(sampleClkTimebase), .dstV(acqSamplesRemaining_ac), .dstClk(axiClk), .dstRst(~axiResetNr));
	
	reg [LOCAL_BUFFER_SIZE_BYTES_LB2:0] pLclBufWritePointer = 0;
	reg [31:0] lclBufferLaps = 0;
	wire [31:0] lclBufferLapsPreup = lclBufferLaps + (lclBufWritePointer < pLclBufWritePointer);
	wire [43:0] totalBytesCollected = lclBufferLapsPreup * LOCAL_BUFFER_SIZE_BYTES + lclBufWritePointer;
	
	reg enableForceUpdate = 0;
	reg [31:0] forceUpdateIntervalBytes = 0;
	reg [43:0] lastUpdateByteCount = 0;
	reg [43:0] nextForceUpdateBytes = 0;
	wire needForceUpdate = enableForceUpdate && (totalBytesCollected >= nextForceUpdateBytes) && (lastUpdateByteCount < nextForceUpdateBytes);
	
	wire [31:0] lclBufUnreadBytes = lclBufWritePointer >= lclBufReadPointer ? lclBufWritePointer - lclBufReadPointer : lclBufWritePointer + LOCAL_BUFFER_SIZE_BYTES - lclBufReadPointer;
	wire sendNow = (lclBufUnreadBytes >= SAMPLE_SEND_THRESH_BYTES) || (lclBufUnreadBytes && !acqSamplesRemaining_ac && writesDone) || needForceUpdate;
	
	reg [MAXI_DATA_ADDR_WIDTH-1:0] hostBufWritePointer = 0;
	reg [MAXI_DATA_ADDR_WIDTH-1:0] hostBufReadPointer = 0;
	reg [31:0] hostBufferLaps = 0;
	reg [MAXI_DATA_ADDR_WIDTH-1:0] hb_writePtrCache = 0;
	
	reg [12:0] transferSize = 0;
	reg [12:0] sendBytesRemaining = 0;
	wire lastBeat = sendBytesRemaining <= AXI_DATA_BYTES;
	wire [clogb2(AXI_DATA_BYTES-1)-1:0] alignOffset = hostBufWritePointer - alignedAddress(hostBufWritePointer);
	reg [clogb2(AXI_DATA_BYTES-1):0] nextBeatSize = 0;

	wire sendCriteria1 = hostBufWritePointer >= hostBufReadPointer;
	wire sendCriteria2 = hostBufReadPointer > (hostBufWritePointer + SAMPLE_WIDTH_BYTES + AXI_DATA_BYTES);

	reg sendingFirstBeat = 0;
	wire [12:0] bytesSentLastClk = (sendingFirstBeat || (axi_wvalid && MAXI_DATA_WREADY)) ? nextBeatSize : 0;

	wire [LOCAL_BUFFER_SIZE_BYTES_LB2:0] lclBufReadPointerPreup = lclBufReadPointer + bytesSentLastClk;
	wire [LOCAL_BUFFER_SIZE_BYTES_LB2:0] lclBufReadPointerPreup2 = (lclBufReadPointerPreup >= LOCAL_BUFFER_SIZE_BYTES) ? 0 : lclBufReadPointerPreup;
	
	wire [12:0] axiBoundaryLimit = 13'd4096 - {1'b0, hostBufWritePointer[11:0]};
	wire [MAXI_DATA_ADDR_WIDTH-1:0] writeEndPtr = hostBufWritePointer + sendBytesRemaining - 1;
	wire [7:0] axi_burstLength = (writeEndPtr >> clogb2(AXI_DATA_BYTES-1)) - (hostBufWritePointer >> clogb2(AXI_DATA_BYTES-1));
	
	wire [AXI_DATA_WIDTH-1:0] lclBufReadData;
	
	always @(posedge axiClk) begin
		axiResetNr <= axiResetN;
		if (~axiResetNr || smResetNow) begin
			smResetPending <= 0;
			smResetNow <= ~configured || ~startWc_ac;
			
			pLclBufWritePointer <= 0;
			lclBufferLaps <= 0;
			lclBufReadPointer <= 0;
			lastUpdateByteCount <= 0;
			nextForceUpdateBytes <= 0;
			hostBufWritePointer <= 0;
			hostBufferLaps <= 0;
			sendBytesRemaining <= 0;
			sendingFirstBeat <= 0;
		end else begin
			pLclBufWritePointer <= lclBufWritePointer;
			lclBufferLaps <= lclBufferLapsPreup;
			
			if (lastUpdateByteCount >= nextForceUpdateBytes)
				nextForceUpdateBytes <= nextForceUpdateBytes + forceUpdateIntervalBytes;
				
			writesDoneDelayReg <= {~waitingForWrites_ac, writesDoneDelayReg[4:1]}; // delay writes done signal to allow write pointer time to cross clock domains
			
			if (axi_awvalid && ~axi_wvalid) begin
				smResetPending <= resetSm_ac || smResetPending;
				
				axi_wvalid <= MAXI_DATA_AWREADY;
				axi_wlast <= (axi_wlen < 1) && MAXI_DATA_AWREADY;
				axi_awvalid <= ~MAXI_DATA_AWREADY;
			end else if (axi_wvalid) begin
				smResetPending <= resetSm_ac || smResetPending;
				
				if (MAXI_DATA_AWREADY)
					axi_awvalid <= 0;
				
				if (MAXI_DATA_WREADY) begin
					axi_wvalid <= sendBytesRemaining > 0;
					axi_wlast <= (sendBytesRemaining > 0) && lastBeat;
					axi_wdata <= lclBufReadData;
					
					sendBytesRemaining <= sendBytesRemaining - nextBeatSize;
					nextBeatSize <= min(AXI_DATA_BYTES, sendBytesRemaining - nextBeatSize);
					lclBufReadPointer <= lclBufReadPointerPreup2;
					
					if (axi_wlast) begin
						hostBufWritePointer <= hostBufWritePointer + transferSize;
						lastUpdateByteCount <= lastUpdateByteCount + transferSize;
					end
				end
				
			end else if (resetSm_ac || smResetPending || ~configured)
				// order here so that we do not enter reset state mid-axi transfer
				smResetNow <= 1;
			else if (sendingFirstBeat) begin
				axi_awaddr <= {hostBufferCurrPageAddress, 12'h000} + alignedAddress(hostBufferWritePtrPageSubAddr);
				axi_wlen <= axi_burstLength;
				axi_wstrb <= {AXI_DATA_WIDTH{1'b1}};
				axi_wdata <= lclBufReadData;
				axi_awvalid <= 1;
				
				axi_wvalid <= MAXI_DATA_AWREADY;
				axi_wlast <= (axi_burstLength < 1) && MAXI_DATA_AWREADY;
				
				lclBufReadPointer <= lclBufReadPointerPreup2;
				
				transferSize <= sendBytesRemaining;
				sendBytesRemaining <= sendBytesRemaining - nextBeatSize;
				nextBeatSize <= min(AXI_DATA_BYTES, sendBytesRemaining - nextBeatSize);
				sendingFirstBeat <= 0;
				
			end else begin
				if ((hostBufWritePointer >= hostBufferTotalSize) && (hostBufReadPointer > 0)) begin
					hostBufWritePointer <= 0;
					hostBufferLaps <= hostBufferLaps + 1;
				end
				
				nextBeatSize <= min(AXI_DATA_BYTES - alignOffset, lclBufUnreadBytes);

				if (sendCriteria1)
					sendBytesRemaining <= min(hostBufferTotalSize - hostBufWritePointer, min(axiBoundaryLimit, lclBufUnreadBytes));
				else if (sendCriteria2)
					sendBytesRemaining <= min(hostBufReadPointer - hostBufWritePointer - SAMPLE_WIDTH_BYTES - AXI_DATA_BYTES, min(axiBoundaryLimit, lclBufUnreadBytes));
				
				sendingFirstBeat <= sendNow && (sendCriteria1 || sendCriteria2) && hostBufWritePointer < hostBufferTotalSize;
			end
		end
	end



	// AXI latency tracker sigs
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
	
	
	// clock crossings
	wire [SAMPLE_WIDTH_BYTES*8-1:0] lastSample_ac;
	SWCCi #(.WW(SAMPLE_WIDTH_BYTES*8)) lastSampleCC(.srcV(lastSample), .srcClk(sampleClkTimebase), .dstV(lastSample_ac), .dstClk(axiClk), .dstRst(~axiResetNr));
	
	wire [31:0] numUpdates_ac;
	SWCCi #(.WW(32)) numUpdatesCC(.srcV(numUpdates), .srcClk(sampleClkTimebase), .dstV(numUpdates_ac), .dstClk(axiClk), .dstRst(~axiResetNr));
	
	wire [31:0] numStarts_ac;
	SWCCi #(.WW(32)) numStartsCC(.srcV(numStarts), .srcClk(sampleClkTimebase), .dstV(numStarts_ac), .dstClk(axiClk), .dstRst(~axiResetNr));
	
	wire bufferedInputDone_ac;
	SBCCi bidCC(.srcV(bufferedInputDone), .srcClk(sampleClkTimebase), .dstV(bufferedInputDone_ac), .dstClk(axiClk));
	
	/****************************************\
			SAXIL_CFG slave intf
	\****************************************/
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0ReadAddress;
	reg [SAXIL_CFG_DATA_WIDTH-1:0] s0ReadData = 0;
	wire s0WriteActive;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0WriteAddress;
	wire [SAXIL_CFG_DATA_WIDTH-1:0] s0WriteData;
	wire [SAXIL_CFG_ADDR_WIDTH-1:0] s0ActiveWriteAddress = s0WriteActive ? s0WriteAddress : 0;
	
	assign usrSampleUpdateReq_ac = (s0ActiveWriteAddress == 16) && (s0WriteData[2:0] == 1);
	assign triggerReq_ac = (s0ActiveWriteAddress == 16) && (s0WriteData[2:0] == 2);
	assign resetSm_ac = (s0ActiveWriteAddress == 16) && (s0WriteData[2:0] == 3);
	assign startWc_ac = (s0ActiveWriteAddress == 16) && (s0WriteData[2:0] == 4);
	assign stopWc_ac = (s0ActiveWriteAddress == 16) && (s0WriteData[2:0] == 5);
	
	reg [31:0] writeSGPageListAddr = 0;
	reg [31:0] writeSGPageListData = 0;
	reg writeSGPageList = 0;
	
	reg [31:0] tempBits = 0;
	reg [ACQ_N_BITS-1:0] acqSamplesRemainingCache;
	
	reg [63:0] ownerUuid = 0;
	
	always @(posedge axiClk) begin
		if (~axiResetNr) begin
			hostBufferFirstPageAddress <= 0;
			hostBufferTotalSize <= 0;
			hostBufferNumPages <= 0;
			hostBufferPageSizeLB2 <= 0;
			configured <= 0;
			hostBufReadPointer <= 0;
		end else begin
	
			case (s0ReadAddress)
				0: s0ReadData <= 32'hFA5F_FECC;
			
				4: s0ReadData <= lastSample_ac;
			
				8: s0ReadData <= numUpdates_ac;
			
				12: s0ReadData <= numStarts_ac;
			
			//	16: cmd reg
			
				20: s0ReadData <= ACQ_N_BITS;
			
				24:	s0ReadData <= peerTrigEn ? triggerId : 16'hFFFF;
			
				28: s0ReadData <= triggerIdSet ? triggerId : 16'hFFFF;
			
				32: s0ReadData <= allowRetrigger;
			
				36: s0ReadData <= samplePeriod;
				
				40: s0ReadData <= forceUpdateIntervalBytes;
				
				44: s0ReadData <= waveCaptureEnabled;
				
				48: s0ReadData <= bufferedInputDone_ac;
				
				52: s0ReadData <= triggerPolarity;
				
				56: s0ReadData <= PEER_TRIGGER_IDX;
				
				60: s0ReadData <= writesDone;
				
				64: s0ReadData <= lclBufUnreadBytes;
				
				68: s0ReadData <= lclBufOverflowCount;
				
				72: s0ReadData <= lclBufferLaps;
			
				80: s0ReadData <= numberOfSamplesToAcq;
			
				84: s0ReadData <= HI(numberOfSamplesToAcq);
				
				88: s0ReadData <= acqSamplesRemainingCache;
				
				92: s0ReadData <= HI(acqSamplesRemainingCache);
				
				
				104: s0ReadData <= ownerUuid[31:0];
				108: s0ReadData <= ownerUuid[63:32];
				
				
				200: s0ReadData <= 32'h_F1F0_1002; // FIFO, F2M, v2
				
				204: s0ReadData <= 32'h_CACA_0002; // Scatter gather page list, v2
				
				208: s0ReadData <= SG_PAGE_LIST_LENGTH;
				
				212: s0ReadData <= MAXI_DATA_ADDR_WIDTH;
			
				216: s0ReadData <= hostBufferFirstPageAddress;
				
				220: s0ReadData <= hostBufferTotalSize;
				
				224: s0ReadData <= HI(hostBufferTotalSize);
				
				228: s0ReadData <= hostBufferNumPages;
				
				232: s0ReadData <= hostBufferPageSizeLB2;
				
				236: s0ReadData <= writeSGPageListAddr;
				
				300: s0ReadData <= hostBufferLaps;
				
				304: s0ReadData <= hb_writePtrCache;
				
				308: s0ReadData <= HI(hb_writePtrCache);
				
				312: s0ReadData <= hostBufReadPointer;
				
				316: s0ReadData <= HI(hostBufReadPointer);
				
				336: s0ReadData <= lclBufWritePointer;
				
				340: s0ReadData <= lclBufReadPointer;
				
				344: s0ReadData <= LOCAL_BUFFER_SIZE_BYTES;

				388: s0ReadData <= {lastDataDuration, lastReqToDataLatency};
				392: s0ReadData <= {maxDataDuration, maxReqToDataLatency};
				
				default: s0ReadData <= 32'hFAAF_FEFF;
			endcase
		
			case (s0ActiveWriteAddress)
			
			//	16: cmd reg
			
				24: begin
					triggerIdSet <= 0;
					peerTrigEn <= s0WriteData < 16'hFFFF;
					triggerId <= s0WriteData;
				end
			
				28: begin
					peerTrigEn <= 0;
					triggerIdSet <= s0WriteData < 16'hFFFF;
					triggerId <= s0WriteData;
				end
			
				32: allowRetrigger <= s0WriteData;
			
				36: samplePeriod <= s0WriteData;
			
				40: begin
					forceUpdateIntervalBytes <= s0WriteData;
					enableForceUpdate <= s0WriteData > 0;
				end
			
				52: triggerPolarity <= s0WriteData;
			
			//	56: PEER_TRIGGER_IDX
				
				80: tempBits <= s0WriteData;
		
				84: begin
					numberOfSamplesToAcq <= {s0WriteData, tempBits};
					finiteAcq <= {s0WriteData, tempBits} > 0;
				end
				
				88: acqSamplesRemainingCache <= acqSamplesRemaining_ac;
					
			//	96:  {lastDataDuration, lastReqToDataLatency};
			//	100: {maxDataDuration, maxReqToDataLatency};
				

				104: ownerUuid[31:0] <= s0WriteData;
				108: ownerUuid[63:32] <= s0WriteData;
				
				
				216: begin // Host buffer address
					hostBufferFirstPageAddress <= s0WriteData;
					hostBufferTotalSize <= 0;
					configured <= 0;
					
					writeSGPageListAddr <= 0;
					writeSGPageListData <= s0WriteData;
				end
				
				220: tempBits <= s0WriteData;
				
				224: hostBufferTotalSize <= {s0WriteData, tempBits};
				
				228: begin
					hostBufferNumPages <= s0WriteData;
					configured <= s0WriteData == 1;
				end
				
				232: hostBufferPageSizeLB2 <= s0WriteData;
				
				236: begin
					writeSGPageListAddr <= writeSGPageListAddr + 1;
					writeSGPageListData <= s0WriteData;
					
					configured <= writeSGPageListAddr == (hostBufferNumPages - 2);
				end
				
				304: hb_writePtrCache <= hostBufWritePointer;
				
				312: tempBits <= s0WriteData;
				
			endcase
			
			if (resetSm_ac)
				hostBufReadPointer <= 0;
			else if ((s0ActiveWriteAddress == 316))
				hostBufReadPointer <= {s0WriteData, tempBits};
			
			writeSGPageList <= s0WriteActive && ((s0WriteAddress == 216) || (s0WriteAddress == 236));
		end
	end


	// AXI latency tracker
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
		end else if (s0ActiveWriteAddress == 100) begin
			lastReqToDataLatency <= 0;
			lastDataDuration <= 0;
		end 

		if (s0ActiveWriteAddress == 100)
			maxReqToDataLatency <= 0;
		else if (lastReqToDataLatency > maxReqToDataLatency)
			maxReqToDataLatency <= lastReqToDataLatency;

		if (s0ActiveWriteAddress == 100)
			maxDataDuration <= 0;
		else if (lastDataDuration > maxDataDuration)
			maxDataDuration <= lastDataDuration;
	end



	// Debug data
	assign dbg_lclBufferWritePointer = lclBufWritePointer;
	assign dbg_lclBufferReadPointer = lclBufReadPointer;
	assign dbg_writeFifo = writeFifoDel;
	assign dbg_cantWrite = cantWrite;
	assign dbg_oflowOccurred = writeFifoDel && cantWrite;
	assign dbg_sendNow = sendNow;
	assign dbg_sendBytesRemaining = sendBytesRemaining;
	assign dbg_axi_wlen = axi_wlen;
	assign dbg_axi_awvalid = axi_awvalid;
	assign dbg_axi_wvalid = axi_wvalid;
	assign dbg_axi_wlast = axi_wlast;
	assign dbg_axi_awready = MAXI_DATA_AWREADY;
	assign dbg_axi_wready = MAXI_DATA_WREADY;
	assign dbg_hostBufReadPointer = hostBufReadPointer;
	assign dbg_hostBufWritePointer = hostBufWritePointer;

	assign dbg_startBufferedSamp_tbc = startBufferedSamp;
	assign dbg_startUsrReq_tbc = startUsrReq;
	assign dbg_startConvNow_tbc = startConvNow;
	assign dbg_sampleTimer_tbc = sampleTimer;
	assign dbg_convDone_tbc = convDone_tbc;
	
	// Local buffer
	// inputs: lclBufReadPointer, lclBufWritePointer, lastSample_ac, lclBufWE
	// outputs: lclBufReadData

	generate
		if (LOCAL_BUFFER_TYPE == "BLOCK_RAM") begin
			// Local sample buffer implemented with Block RAM
			localparam BLOCKRAM_ROWS = 512;
			localparam BLOCKRAM_ROWS_LB2 = clogb2(BLOCKRAM_ROWS-1);
			localparam BLOCKRAM_WIDTH_BYTES = 4;
			localparam BLOCKRAM_NUM_COLS = AXI_DATA_BYTES / BLOCKRAM_WIDTH_BYTES;
			// Block RAMs are massive. For now we won't do multiple ranks

			wire [LOCAL_BUFFER_SIZE_BYTES_LB2-AXI_DATA_BYTES_LB2:0] lclBufferReadRow = lclBufReadPointerPreup2[LOCAL_BUFFER_SIZE_BYTES_LB2:AXI_DATA_BYTES_LB2];
			wire [LOCAL_BUFFER_SIZE_BYTES_LB2-AXI_DATA_BYTES_LB2:0] lclBufferWriteRow = lclBufWritePointer[LOCAL_BUFFER_SIZE_BYTES_LB2:AXI_DATA_BYTES_LB2];
			wire [AXI_DATA_WIDTH-1:0] lclBufWriteData = {AXI_DATA_BYTES/SAMPLE_WIDTH_BYTES{lastSample_ac}};

			genvar colNo;
			
			for (colNo = 0; colNo < BLOCKRAM_NUM_COLS; colNo=colNo+1) begin:generate_blockram_cols

				wire writeSample0 = lclBufWE && (lclBufWritePointer[AXI_DATA_BYTES_LB2-1:0] == (colNo*BLOCKRAM_WIDTH_BYTES));
				wire writeSample1 = lclBufWE && (lclBufWritePointer[AXI_DATA_BYTES_LB2-1:0] == (colNo*BLOCKRAM_WIDTH_BYTES + 2));
				wire [3:0] byteWriteEn = {writeSample1, writeSample1, writeSample0, writeSample0};

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
					.DOUTADOUT(lclBufReadData[colNo*32+:16]), // 16-bit output: Port A data/LSB data
					.DOUTPADOUTP(), // 2-bit output: Port A parity/LSB parity
					// Port B Data outputs: Port B data
					.DOUTBDOUT(lclBufReadData[((colNo*32)+16)+:16]), // 16-bit output: Port B data/MSB data
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
					.CLKARDCLK(axiClk), // 1-bit input: A/Read port clock
					.ENARDEN(1'b1), // 1-bit input: Port A enable/Read enable
					.REGCEAREGCE(1'b0), // 1-bit input: Port A register enable/Register enable
					.RSTRAMARSTRAM(1'b0), // 1-bit input: Port A set/reset
					.RSTREGARSTREG(1'b0), // 1-bit input: Port A register set/reset
					.WEA(2'b11), // 2-bit input: Port A write enable
					// Port A Data inputs: Port A data
					.DINADIN(lclBufWriteData[colNo*32+:16]), // 16-bit input: Port A data/LSB data
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
					.WEBWE(byteWriteEn), // 4-bit input: Port B write enable/Write enable
					// Port B Data inputs: Port B data
					.DINBDIN(lclBufWriteData[((colNo*32)+16)+:16]), // 16-bit input: Port B data/MSB data
					.DINPBDINP(2'd0) // 2-bit input: Port B parity/MSB parity
				);
			end

		end else begin
			// Local sample buffer implemented with LUTRAM
			// right now only supports one rank
			wire [AXI_DATA_BYTES_LB2-1:0] lclBufWritePointerSubAddr = lclBufWritePointer[AXI_DATA_BYTES_LB2-1:0];
			wire [AXI_DATA_WIDTH-1:0] lclBufWriteData = {AXI_DATA_BYTES/SAMPLE_WIDTH_BYTES{lastSample_ac}};

			genvar bitNum;

			for (bitNum = 0; bitNum < AXI_DATA_WIDTH; bitNum=bitNum+1) begin:generate_lutram
				wire thisBitInWriteRange = (bitNum >= lclBufWritePointerSubAddr*8) && (bitNum < (lclBufWritePointerSubAddr*8 + SAMPLE_WIDTH_BYTES*8));
				
				RAM32X1D RAM32X1D_inst (
					.DPO(lclBufReadData[bitNum]), // Read-only 1-bit data output
					.SPO(), // Rw/ 1-bit data output
					.A0(lclBufWritePointer[AXI_DATA_BYTES_LB2]), // Rw/ address[0] input bit
					.A1(lclBufWritePointer[AXI_DATA_BYTES_LB2+1]), // Rw/ address[1] input bit
					.A2(lclBufWritePointer[AXI_DATA_BYTES_LB2+2]), // Rw/ address[2] input bit
					.A3(lclBufWritePointer[AXI_DATA_BYTES_LB2+3]), // Rw/ address[3] input bit
					.A4(lclBufWritePointer[AXI_DATA_BYTES_LB2+4]), // Rw/ address[4] input bit
					.D(lclBufWriteData[bitNum]), // Write 1-bit data input
					.DPRA0(lclBufReadPointer[AXI_DATA_BYTES_LB2]), // Read-only address[0] input bit
					.DPRA1(lclBufReadPointer[AXI_DATA_BYTES_LB2+1]), // Read-only address[1] input bit
					.DPRA2(lclBufReadPointer[AXI_DATA_BYTES_LB2+2]), // Read-only address[2] input bit
					.DPRA3(lclBufReadPointer[AXI_DATA_BYTES_LB2+3]), // Read-only address[3] input bit
					.DPRA4(lclBufReadPointer[AXI_DATA_BYTES_LB2+4]), // Read-only address[4] input bit
					.WCLK(axiClk), // Write clock input
					.WE(lclBufWE && thisBitInWriteRange) // Write enable input
				);
			end
		end
	endgenerate

	
	
	// Scatter gather info storage
	wire [31:0] sgPageListReadData[SG_LIST_NUM_BRAMS-1:0];
	wire [31:0] currPage = hostBufWritePointer >> hostBufferPageSizeLB2;
	assign hostBufferWritePtrPageSubAddr = hostBufWritePointer - (currPage << hostBufferPageSizeLB2);
	
	wire [22:0] currSglBr = currPage[31:9];
	assign hostBufferCurrPageAddress = sgPageListReadData[currSglBr];
	
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
