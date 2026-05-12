//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_StateMachine #(
	parameter HS_NUM_LOGICAL_CHANNELS = 4
)(
	input  wire dataClk,
	input  wire cfgClk,
	
	input  wire [63:0] systemClock,
	
	input  wire enableSm,
	input  wire resetSm,
	input  wire softStartTrig,
	input  wire softNextTrig,
	input  wire softStopTrig,
	
	input  wire acqPlanWriteEnable,
	input  wire [11:0] acqPlanWriteAddr,
	input  wire [8:0] acqPlanWriteData,
	input  wire [11:0] acqPlanNumSteps,
	
	input  wire [`TRIGGER_PROCESS_OUT_LSZ:0] triggerProcessData,
	input  wire [17:0] periodClockPeriod,

	output wire [`STATE_MACHINE_OUT_LSZ:0] dataOut,
	output wire aeSampleClkOut,
	
	input  wire [`LOGICAL_CHANNEL_BUF_LSZ:0] logicalChannelsIn,
	input  wire logicalChannelDataValid,
	output wire [`LOGICAL_CHANNEL_BUF_LSZ:0] logicalChannelsOut,
	
	input  wire i2cDataValid,
	input  wire i2cPacketStart,
	input  wire i2cPacketEnd,
	input  wire [7:0] i2cPacketData,
	
	output wire writeTriggerEn,
	output wire [79:0] writeTriggerData,
	
	input  wire acqParamEnableBidi,
	input  wire [15:0] acqParamSamplesPerLine,
	input  wire [31:0] acqParamVolumesPerAcq,
	input  wire [31:0] acqParamTotalAcqs,
	input  wire [15:0] acqParamAcqHoldoff,
	input  wire [15:0] acqParamBeamClockDuration,
	
	input  wire acqParamLinearMode,
	input  wire [31:0] acqParamLinearFramesPerVolume,
	input  wire [31:0] acqParamLinearFrameClkHighTime,
	input  wire [31:0] acqParamLinearFrameClkLowTime,

	input wire [31:0] acqParamSampleClkPulsesPerPeriod,
	input wire [15:0] acqParamLinearSampleClkPulseDuration,
	
	output wire [3:0] acqStatusSmState,
	output wire [31:0] acqStatusVolumesDone,
	output wire [15:0] acqStatusLinesDone
);
	reg startOfLine = 0;
	reg lineInProgress = 0;
	reg endOfLine = 0;
	reg acqClock = 0;
	reg lineClock = 0;
	reg beamClock;
	reg roiClock = 0;
	reg sliceClock = 0;
	reg volumeClock = 0;
	
	reg [62:0] currLineTimeStampCache = 0;
	reg [63:0] lastLineTimeStamp = 0;
	
	assign dataOut[`STATE_MACHINE_OUT_SOL_BIT] = startOfLine;
	assign dataOut[`STATE_MACHINE_OUT_EOL_BIT] = endOfLine;
	assign dataOut[`STATE_MACHINE_OUT_ACQ_CLK_BIT] = acqClock;
	assign dataOut[`STATE_MACHINE_OUT_LINE_CLK_BIT] = lineClock;
	assign dataOut[`STATE_MACHINE_OUT_BEAM_CLK_BIT] = beamClock;
	assign dataOut[`STATE_MACHINE_OUT_ROI_CLK_BIT] = roiClock;
	assign dataOut[`STATE_MACHINE_OUT_SLICE_CLK_BIT] = sliceClock;
	assign dataOut[`STATE_MACHINE_OUT_VOLUME_CLK_BIT] = volumeClock;
	assign dataOut[`STATE_MACHINE_OUT_CTL_SAMPLE_CLK_BIT] = aeSampleClkOut;
	assign dataOut[`STATE_MACHINE_OUT_LINE_TS_START_BIT+:64] = lastLineTimeStamp;

	
	localparam [3:0] IDLE = 0,
		WAIT_FOR_TRIGGER = 1,
		ACQUIRE = 2,
		LINEAR_ACQ = 3;
	reg [3:0] state = IDLE;
	assign acqStatusSmState = state;
	
	reg [15:0] samplesDone = 0;
	reg [15:0] linesDone = 0;
	reg [31:0] volumesDone = 0;
	reg [31:0] acqsDone = 0;
	
	assign acqStatusVolumesDone = volumesDone;
	assign acqStatusLinesDone = linesDone;
	
	reg forwardTrigOnly = 1;
	reg [15:0] linesToCollect = 0;
	reg currPlanStepIsAcquire = 0;
	reg currPlanStepFrameClkState = 0;
	
	wire [11:0] acqPlanReadAddr;
	reg  [11:0] pAcqPlanReadAddr = 0;
	wire [8:0] acqPlanReadData;
	reg  advanceAcqPlan = 0;
	reg  [11:0] acqPlanNextStep;
	wire currPlanStepIsLast = !acqPlanNextStep;
	
	reg startReadNewStep = 0;
	
	wire lastSample = samplesDone == (acqParamSamplesPerLine - logicalChannelDataValid);
	
	wire startTrigger = softStartTrig || triggerProcessData[`TRIGGER_PROCESS_OUT_START_TRIGGER_BIT];
	wire nextTrigger = softNextTrig || triggerProcessData[`TRIGGER_PROCESS_OUT_NEXT_TRIGGER_BIT];
	wire stopTrigger = softStopTrig || triggerProcessData[`TRIGGER_PROCESS_OUT_STOP_TRIGGER_BIT];
	
	wire delayedForardLineTrig = triggerProcessData[`TRIGGER_PROCESS_OUT_DEL_PERIOD_TRIGGER_BIT];
	wire delayedReverseLineTrig = triggerProcessData[`TRIGGER_PROCESS_OUT_DEL_MID_PERIOD_TRIGGER_BIT];
	wire delayedAllowedLineTrig = delayedForardLineTrig || (delayedReverseLineTrig && ~forwardTrigOnly);
	
	reg nextTriggerLatch = 0;
	reg stopTriggerLatch = 0;
	reg resetTriggerLatch = 0;
	
	wire nextTriggerPresent = nextTriggerLatch || nextTrigger;
	wire stopTriggerPresent = stopTriggerLatch || stopTrigger;
	wire nextOrStopTriggerPresent = nextTriggerPresent || stopTriggerPresent;
	
	reg acqWasTrigd = 0;
	wire acqIsTrigd = acqWasTrigd || startTrigger || nextTrigger;
	
	reg pSliceClock = 0;
	wire startOfRoi;
	
	
	wire [3:0] auxTriggers = triggerProcessData[`TRIGGER_PROCESS_OUT_AUX_TRIGGER_START_BIT+:4];
	wire auxTriggerActive = |auxTriggers;
	
	assign writeTriggerData = {5'h00, i2cPacketData, i2cPacketEnd, i2cPacketStart, i2cDataValid, auxTriggers, stopTrigger, nextTrigger, startTrigger, startOfRoi, systemClock[55:0]};
	assign writeTriggerEn = !resetSm && state && (startTrigger || nextTrigger || stopTrigger || auxTriggerActive || startOfRoi || i2cDataValid);
	
	wire isLastVolumeOfAcq = (acqParamVolumesPerAcq && (volumesDone == (acqParamVolumesPerAcq - 1))) || nextOrStopTriggerPresent;
	wire endOfAcq = (linesDone == (linesToCollect - 1)) && currPlanStepIsLast && isLastVolumeOfAcq;
	wire isLastAcq = acqParamTotalAcqs && (acqsDone == (acqParamTotalAcqs - 1));
	
	reg [31:0] linearFramesDone = 0;
	wire isLastLinearFrameOfVolume = (acqParamLinearFramesPerVolume && (linearFramesDone == (acqParamLinearFramesPerVolume - 1)));
	
	reg [31:0] frameClkHighCtr = 0;
	reg [31:0] frameClkLowCtr = 0;
	reg linearFrameStart = 0;

	// Beam clock generation
	wire startBeamClk = ((state == WAIT_FOR_TRIGGER) && acqIsTrigd && delayedAllowedLineTrig);
	reg  [15:0] beamOnCtr = 0;
	wire [15:0] beamOnCtrDec = beamOnCtr ? beamOnCtr - logicalChannelDataValid : 0;
	wire [15:0] beamOnCtrPreup = startBeamClk ? acqParamBeamClockDuration : beamOnCtrDec;

	// acq holdoff
	reg  [15:0] acqDelayCtr = 0;
	wire startResAcq = (state == WAIT_FOR_TRIGGER) && ((startBeamClk && (acqParamAcqHoldoff == 0)) || (acqDelayCtr == 1));
	assign startOfRoi = (~roiClock && startResAcq) || (~pSliceClock && (state == LINEAR_ACQ) && sliceClock);
	

	always @(posedge dataClk) begin
		// line acq state machine
		if (resetSm || !state) begin
			startOfLine <= 0;
			endOfLine <= 0;
			lineInProgress <= 0;
			acqDelayCtr <= 0;
			
			acqClock <= 0;
			lineClock <= 0;
			roiClock <= 0;
			sliceClock <= 0;
			volumeClock <= 0;
			
			resetTriggerLatch = 1;
			
			advanceAcqPlan <= 0;
			forwardTrigOnly <= 1;
			currPlanStepIsAcquire <= 1;
			linesDone <= 0;
			volumesDone <= 0;
			acqsDone <= 0;
			
			linearFramesDone <= 0;
			frameClkHighCtr <= 0;
			frameClkLowCtr <= 0;
			linearFrameStart <= 0;
			
			acqWasTrigd <= 0;
			
			if (enableSm && acqParamLinearMode)
				state <= LINEAR_ACQ;
			else if (enableSm)
				state <= WAIT_FOR_TRIGGER;
			else
				state <= IDLE;
		end else case (state)
			WAIT_FOR_TRIGGER: begin
				startOfLine <= 0;
				endOfLine <= 0;
				lineInProgress <= 0;
				
				samplesDone <= 0;
				advanceAcqPlan <= 0;
				
				acqClock <= 0;
				lineClock <= 0;
				roiClock <= currPlanStepIsAcquire && roiClock;
				sliceClock <= currPlanStepFrameClkState && sliceClock;
				volumeClock <= ~currPlanStepIsLast && volumeClock;
				
				acqWasTrigd <= acqIsTrigd;
				resetTriggerLatch = 0;
				
				if (startResAcq) begin
					state <= ACQUIRE;
					currLineTimeStampCache <= systemClock;
				end
				
				if (startBeamClk)
					acqDelayCtr <= acqParamAcqHoldoff;
				else if (acqDelayCtr)
					acqDelayCtr <= acqDelayCtr - 1;
			end
			
			ACQUIRE: begin
				acqDelayCtr <= 0;
				startOfLine <= ~lineInProgress;
				endOfLine <= lastSample;
				forwardTrigOnly <= ~acqParamEnableBidi;
				
				samplesDone <= samplesDone + logicalChannelDataValid;
				
				acqClock <= logicalChannelDataValid;  // TODO: do we really want this toggling based on valid data?
				lineClock <= currPlanStepIsAcquire;
				roiClock <= currPlanStepIsAcquire;
				sliceClock <= currPlanStepIsAcquire;
				volumeClock <= ~currPlanStepIsLast;
				
				if (lastSample) begin
					lastLineTimeStamp <= {endOfAcq, endOfAcq ? systemClock[62:0] : currLineTimeStampCache};
					lineInProgress <= 0;
					
					if (linesDone == (linesToCollect - 1)) begin
						linesDone <= 0;
						advanceAcqPlan <= 1;
						currPlanStepIsAcquire <= ~currPlanStepIsAcquire;
						if (currPlanStepIsLast) begin
							if (isLastVolumeOfAcq) begin
								acqWasTrigd <= nextTriggerPresent;
								forwardTrigOnly <= 1;
								acqsDone <= acqsDone + 1;
								resetTriggerLatch = 1;
								
								if (isLastAcq) begin
									volumesDone <= volumesDone + 1;
									state <= IDLE;
								end else begin
									volumesDone <= 0;
									state <= WAIT_FOR_TRIGGER;
								end
							end else begin
								volumesDone <= volumesDone + 1;
								state <= WAIT_FOR_TRIGGER;
								resetTriggerLatch = 0;
							end
						end else begin
							state <= WAIT_FOR_TRIGGER;
							resetTriggerLatch = 0;
						end
					end else begin
						linesDone <= linesDone + 1;
						state <= WAIT_FOR_TRIGGER;
						advanceAcqPlan <= 0;
						resetTriggerLatch = 0;
					end
				end else begin
					advanceAcqPlan <= 0;
					lineInProgress <= 1;
					resetTriggerLatch = 0;
				end
			end
			
			LINEAR_ACQ: begin
				if (frameClkHighCtr) begin
					frameClkHighCtr <= frameClkHighCtr - logicalChannelDataValid;
					linearFrameStart <= logicalChannelDataValid ? 0 : linearFrameStart;
					
					sliceClock <= logicalChannelDataValid ? frameClkHighCtr > 1 : sliceClock;
					volumeClock <= logicalChannelDataValid ? ~isLastLinearFrameOfVolume || (frameClkHighCtr > 1) : volumeClock;
						
					resetTriggerLatch = 0;
				end else if (frameClkLowCtr > logicalChannelDataValid) begin
					frameClkLowCtr <= frameClkLowCtr - logicalChannelDataValid;
					resetTriggerLatch = 0;
				end else if ((frameClkLowCtr == 1) && logicalChannelDataValid) begin // end of frame
					if (isLastLinearFrameOfVolume) begin
						if (isLastVolumeOfAcq) begin
							if (isLastAcq) begin
								linearFramesDone <= linearFramesDone + 1;
								volumesDone <= volumesDone + 1;
								acqsDone <= acqsDone + 1;
								frameClkLowCtr <= 0;
								state <= IDLE;
							//	acqClock <= 0;
							end else begin	// reset the counters and wait for the next trigger
								linearFramesDone <= 0;
								volumesDone <= 0;
								acqsDone <= acqsDone + 1;
								
								if (nextTriggerPresent) begin
									frameClkHighCtr <= acqParamLinearFrameClkHighTime;
									frameClkLowCtr <= acqParamLinearFrameClkLowTime;
									linearFrameStart <= 1;
									sliceClock <= 1;
									volumeClock <= 1;
								end else begin
									frameClkHighCtr <= 0;
									frameClkLowCtr <= 0;
							//		acqClock <= 0;
								end
							end
							resetTriggerLatch = 1;
						end else begin
							linearFramesDone <= 0;
							volumesDone <= volumesDone + 1;
							frameClkHighCtr <= acqParamLinearFrameClkHighTime;
							frameClkLowCtr <= acqParamLinearFrameClkLowTime;
							linearFrameStart <= 1;
							sliceClock <= 1;
							volumeClock <= 1;
							resetTriggerLatch = 0;
						end
					end else begin
						linearFramesDone <= linearFramesDone + 1;
						frameClkHighCtr <= acqParamLinearFrameClkHighTime;
						frameClkLowCtr <= acqParamLinearFrameClkLowTime;
						linearFrameStart <= 1;
						sliceClock <= 1;
						volumeClock <= 1;
						resetTriggerLatch = 0;
					end
				end else if (!frameClkHighCtr && !frameClkLowCtr) begin
					if (startTrigger || nextTrigger) begin
						frameClkHighCtr <= acqParamLinearFrameClkHighTime;
						frameClkLowCtr <= acqParamLinearFrameClkLowTime;
						linearFrameStart <= 1;
					//	acqClock <= 1;
						sliceClock <= 1;
						volumeClock <= 1;
					end
					resetTriggerLatch = 1;
					acqWasTrigd <= 1;
				end

				acqClock <= (frameClkHighCtr || frameClkLowCtr) && logicalChannelDataValid;
			end
		endcase
		
		pSliceClock <= sliceClock;
		
		
		if (resetTriggerLatch) begin
			nextTriggerLatch <= 0;
			stopTriggerLatch <= 0;
		end else if (acqWasTrigd) begin
			nextTriggerLatch <= nextTriggerPresent;
			stopTriggerLatch <= stopTriggerPresent;
		end
		
		
		// beam clock reg
		beamOnCtr <= beamOnCtrPreup;
		beamClock <= |beamOnCtrPreup;
		
		// acq plan reader
		pAcqPlanReadAddr <= acqPlanReadAddr;
		if (resetSm) begin
			acqPlanNextStep <= 0;
		//	acqPlanReadAddr <= 0;
			startReadNewStep <= 1;
		end else if (startReadNewStep || advanceAcqPlan) begin
			linesToCollect <= {8'd0, acqPlanReadData[6:0], 1'b0};
			currPlanStepFrameClkState <= acqPlanReadData[7];
			
		//	acqPlanReadAddr <= acqPlanReadAddr + 1;
			startReadNewStep <= 0;
			
			if (acqPlanNextStep == (acqPlanNumSteps - 1))
				acqPlanNextStep <= 0;
			else
				acqPlanNextStep <= acqPlanNextStep + 1;
		end else if (~acqPlanReadData[8])// begin
			linesToCollect[15:8] <= acqPlanReadData[7:0];
	//		acqPlanReadAddr <= acqPlanReadAddr + 1;
	//	end else if (!acqPlanNextStep && acqPlanReadAddr)
	//		acqPlanReadAddr <= 0;
	end
	
	
	assign acqPlanReadAddr = resetSm ? 0 : (
		(startReadNewStep || advanceAcqPlan || ~acqPlanReadData[8]) ? pAcqPlanReadAddr + 1 : (
			!acqPlanNextStep ? 0 : pAcqPlanReadAddr
		)
	);


	// Apply pipeline delay to channel data
	reg [`LOGICAL_CHANNEL_BUF_LSZ:0] logicalChannelsR = 0;
	assign logicalChannelsOut = logicalChannelsR;

	always @(posedge dataClk)
		logicalChannelsR <= logicalChannelsIn;

	
	// The acquisition plan buffer contains an array of 9 bit entries that describe a repeating acquisition sequence.
	// Each plan step can be described by a single or multiple array entries. There are always an even number of plan
	// steps. Steps represent alternating periods of acquisition and pause. Each step specifies how many resonant periods
	// it should last.
	// arrayEntry[8:0] = {newEntry, frameClockState, numperiods[6:0]};
	// newEntry - when 1 indicates that this is a new entry; when 0 indicates this is an addendum to the previous entry
	// frameClockState - specifies the state the frame should be during this acqPlan step
	RAMB36E2 #(
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
		.READ_WIDTH_A(9), // 0-9
		.READ_WIDTH_B(9), // 0-9
		.WRITE_WIDTH_A(9), // 0-9
		.WRITE_WIDTH_B(9), // 0-9
		// RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG", "REGCE")
		.RSTREG_PRIORITY_A("RSTREG"),
		.RSTREG_PRIORITY_B("RSTREG"),
		// SRVAL_A, SRVAL_B: Set/reset value for output
		.SRVAL_A(18'h00000),
		.SRVAL_B(18'h00000),
		// Sleep Async: Sleep function asynchronous or synchronous ("TRUE", "FALSE")
		.SLEEP_ASYNC("FALSE"),
		// WriteMode: "WRITE_FIRST", "NO_CHANGE", "READ_FIRST"
		.WRITE_MODE_A("NO_CHANGE"),
		.WRITE_MODE_B("NO_CHANGE")
	) acqPlanBuffer (
		// Cascade Signals outputs: Multi-BRAM cascade signals
		.CASDOUTA(), // 16-bit output: Port A cascade output data
		.CASDOUTB(), // 16-bit output: Port B cascade output data
		.CASDOUTPA(), // 2-bit output: Port A cascade output parity data
		.CASDOUTPB(), // 2-bit output: Port B cascade output parity data
		// Port A Data outputs: Port A data
		.DOUTADOUT(acqPlanReadData[7:0]), // 16-bit output: Port A data/LSB data
		.DOUTPADOUTP(acqPlanReadData[8]), // 2-bit output: Port A parity/LSB parity
		// Port B Data outputs: Port B data
		.DOUTBDOUT(), // 16-bit output: Port B data/MSB data
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
		.ADDRARDADDR({acqPlanReadAddr, 3'd0}), // 15-bit input: A/Read port address
		.ADDRENA(1'b1), // 1-bit input: Active-High A/Read port address enable
		.CLKARDCLK(dataClk), // 1-bit input: A/Read port clock
		.ENARDEN(1'b1), // 1-bit input: Port A enable/Read enable
		.REGCEAREGCE(1'b0), // 1-bit input: Port A register enable/Register enable
		.RSTRAMARSTRAM(1'b0), // 1-bit input: Port A set/reset
		.RSTREGARSTREG(1'b0), // 1-bit input: Port A register set/reset
		.WEA(2'b00), // 2-bit input: Port A write enable
		// Port A Data inputs: Port A data
		.DINADIN(), // 16-bit input: Port A data/LSB data
		.DINPADINP(), // 2-bit input: Port A parity/LSB parity
		// Port B Address/Control Signals inputs: Port B address and control signals
		.ADDRBWRADDR({acqPlanWriteAddr, 3'd0}), // 15-bit input: B/Write port address
		.ADDRENB(1'b1), // 1-bit input: Active-High B/Write port address enable
		.CLKBWRCLK(cfgClk), // 1-bit input: B/Write port clock
		.ENBWREN(acqPlanWriteEnable), // 1-bit input: Port B enable/Write enable
		.REGCEB(1'b0), // 1-bit input: Port B register enable
		.RSTRAMB(1'b0), // 1-bit input: Port B set/reset
		.RSTREGB(1'b0), // 1-bit input: Port B register set/reset
		.SLEEP(1'b0), // 1-bit input: Sleep Mode
		.WEBWE({7'd0, acqPlanWriteEnable}), // 4-bit input: Port B write enable/Write enable
		// Port B Data inputs: Port B data
		.DINBDIN({24'd0, acqPlanWriteData[7:0]}), // 16-bit input: Port B data/MSB data
		.DINPBDINP({3'b0, acqPlanWriteData[8]}) // 2-bit input: Port B parity/MSB parity
	);


	// SampleClk generation
	wire sampleClkTrigger = acqParamLinearMode ? linearFrameStart && logicalChannelDataValid : delayedForardLineTrig && acqIsTrigd;

	reg [15:0] pulseCtr = 0;
	reg [31:0] sampleClkPulsesRemaining = 0;
	reg [15:0] sampleClkLongPulsesRemaining = 0;

	wire divideResultReady;
	wire [15:0] divideRemainder;
	wire [15:0] divideResult;
	reg  [15:0] shortPulseDuration = 0;
	reg  [15:0] thisPulseDurationReg = 0;

	wire enablePipeline = ~acqParamLinearMode || logicalChannelDataValid;

	wire startPulseNow = (sampleClkPulsesRemaining > 0) && (pulseCtr < 2) && enablePipeline; 
	wire startLongPulseNow = startPulseNow && (sampleClkLongPulsesRemaining >= (sampleClkPulsesRemaining >> 1));
	wire [15:0] thisPulseDuration = acqParamLinearMode ? acqParamLinearSampleClkPulseDuration : (shortPulseDuration + startLongPulseNow);
	wire [31:0] sampleClkPulsesRemainingPreup = sampleClkPulsesRemaining - startPulseNow + (sampleClkTrigger ? acqParamSampleClkPulsesPerPeriod: 0);

	reg startDivide = 0;
	wire dividerReady;

	wire aeSampleClkOutP = pulseCtr > (thisPulseDurationReg >> 1);
	reg  aeSampleClkOutR = 0;
	assign aeSampleClkOut = aeSampleClkOutR;

	always @(posedge dataClk) begin
		aeSampleClkOutR <= aeSampleClkOutP;

		if (resetSm)
			sampleClkPulsesRemaining <= 0;
		else
			sampleClkPulsesRemaining <= sampleClkPulsesRemainingPreup;
		
		if (resetSm)
			sampleClkLongPulsesRemaining <= 0;
		else if (divideResultReady)
			sampleClkLongPulsesRemaining <= divideRemainder;
		else
			sampleClkLongPulsesRemaining <= sampleClkLongPulsesRemaining - startLongPulseNow;
		
		if (resetSm)
			pulseCtr <= 0;
		else if (startPulseNow) begin
			pulseCtr <= thisPulseDuration;
			thisPulseDurationReg <= thisPulseDuration;
		end else if (pulseCtr)
			pulseCtr <= pulseCtr - enablePipeline;
		
		if (divideResultReady)
			shortPulseDuration <= divideResult;
		
		if (delayedForardLineTrig)
			startDivide <= 1;
		else if(dividerReady)
			startDivide <= 0;
	end

	// we want to make sure that everywhere the dividend (period) is used, it is 18 bits
	// 18 bits of the dividend will equal 500 hz
	wire [15:0] divisor = sampleClkPulsesRemainingPreup > acqParamSampleClkPulsesPerPeriod ? sampleClkPulsesRemainingPreup : acqParamSampleClkPulsesPerPeriod;

	// This is calculating
	//   (period in dataClk ticks) / (sample clock pulses per period) = short pulse duration in ticks
	//   remainder of the division = pulses remaining
	ResonantPeriodDividerCore periodDivider(
		.aclk(dataClk),                                      // input wire aclk
		.s_axis_dividend_tvalid(startDivide),  // input wire s_axis_dividend_tvalid
		.s_axis_dividend_tready(dividerReady),  // output wire s_axis_dividend_tready
		.s_axis_dividend_tdata(periodClockPeriod),    // input wire [17 : 0] s_axis_dividend_tdata
		.s_axis_divisor_tvalid(startDivide),    // input wire s_axis_divisor_tvalid
		.s_axis_divisor_tready(),    // output wire s_axis_divisor_tready
		.s_axis_divisor_tdata(divisor),      // input wire [15 : 0] s_axis_divisor_tdata
		.m_axis_dout_tvalid(divideResultReady),          // output wire m_axis_dout_tvalid
		.m_axis_dout_tdata({divideResult, divideRemainder})            // output wire [31 : 0] m_axis_dout_tdata
	);
	
endmodule
