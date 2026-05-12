//////////////////////////////////////////////////////////////////////////////////
// Company: MBF Bioscience
// Engineer: Nelson Downs
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 10 ps
`include "SI_Defines.v"

module SI_DataScope_tb();
	// clock
	reg clk = 1;
	always #5 clk <= ~clk;

	localparam FIFO_WIDTH = 424;
	localparam NUM_TRIGGERS = 17;
	
	// copy internal parameters for validation purposes
	localparam NUM_TRIGGER_BYTES = $rtoi($ceil($itor(NUM_TRIGGERS) / 8.0));
	localparam NUM_TRIGGER_BITS  = NUM_TRIGGER_BYTES * 8;

	// inputs
	reg reset = 0;
	reg start = 0;
	reg [31:0] numberOfSamples = 4096;
	reg [5:0]  sampleDecimationLB2 = 0;
	reg [3:0]  trigger = 0;
	reg [`HS_PHYS_CHANNEL_LSZ:0] sampleDataA[`HS_SAMPS_PER_TICK-1:0];
	reg [`HS_PHYS_CHANNEL_LSZ:0] sampleDataB[`HS_SAMPS_PER_TICK-1:0];
	reg chanSel = 0;
	reg [15:0] firstSamplePhase = 0;
	reg [NUM_TRIGGERS-1:0] siTriggerArray = 0;
	reg dataValidIn = 0;

	wire fifoWriteEn;
	wire [FIFO_WIDTH-1:0] fifoWriteData;

	// pack sample data into input buffers
	wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] sampleDataA_packed;
	wire [`HS_PHYS_CHANNEL_BUF_LSZ:0] sampleDataB_packed;

	// unpack out of fifo for validation
	wire [`HS_PHYS_CHANNEL_LSZ:0] sampleData_inFifo[`HS_SAMPS_PER_TICK-1:0];
	wire [NUM_TRIGGER_BITS-1:0] triggerData_inFifo;
	wire [15:0] samplePhase_inFifo;

	// delay input data for validation comparisons
	wire [`HS_PHYS_CHANNEL_LSZ:0] sampleDataA_delayed[`HS_SAMPS_PER_TICK-1:0];
	wire [`HS_PHYS_CHANNEL_LSZ:0] sampleDataB_delayed[`HS_SAMPS_PER_TICK-1:0];
	wire [NUM_TRIGGERS-1:0] triggerData_delayed;
	wire [15:0] samplePhase_delayed;
	localparam PIPELINE_DELAY = 3;

	// validation wires
	wire [`HS_SAMPS_PER_TICK-1:0] sampleDataValid;
	wire triggerDataValid;
	wire samplePhaseValid;
	wire allDataValid;

	genvar samplePackIndex;
	generate
		for (samplePackIndex = 0; samplePackIndex < `HS_SAMPS_PER_TICK; samplePackIndex = samplePackIndex + 1) begin
			// pack input data
			assign sampleDataA_packed[samplePackIndex*`HS_PHYS_CHANNEL_WIDTH+:`HS_PHYS_CHANNEL_WIDTH] = sampleDataA[samplePackIndex];
			assign sampleDataB_packed[samplePackIndex*`HS_PHYS_CHANNEL_WIDTH+:`HS_PHYS_CHANNEL_WIDTH] = sampleDataB[samplePackIndex];

			// unpack output data
			assign sampleData_inFifo[samplePackIndex] = fifoWriteData[samplePackIndex*`HS_PHYS_CHANNEL_WIDTH+:`HS_PHYS_CHANNEL_WIDTH];

			// delay input data
			OUTPUT_DELAY #(
				.MATCH_DELAY(PIPELINE_DELAY),
				.BIT_WIDTH(`HS_PHYS_CHANNEL_WIDTH)
			) delayA(.clock(clk), .dataIn(sampleDataA[samplePackIndex]), .delayedDataOut(sampleDataA_delayed[samplePackIndex]));

			OUTPUT_DELAY #(
				.MATCH_DELAY(PIPELINE_DELAY),
				.BIT_WIDTH(`HS_PHYS_CHANNEL_WIDTH)
			) delayB(.clock(clk), .dataIn(sampleDataB[samplePackIndex]), .delayedDataOut(sampleDataB_delayed[samplePackIndex]));

			// validate samples
			wire [`HS_PHYS_CHANNEL_LSZ:0] selectedChannelData = chanSel ? sampleDataB_delayed[samplePackIndex] : sampleDataA_delayed[samplePackIndex];
			assign sampleDataValid[samplePackIndex] = selectedChannelData == sampleData_inFifo[samplePackIndex];
		end
	endgenerate

	assign triggerData_inFifo = fifoWriteData[`HS_PHYS_CHANNEL_BUF_SIZE+:NUM_TRIGGER_BITS];
	assign samplePhase_inFifo = fifoWriteData[`HS_PHYS_CHANNEL_BUF_SIZE+NUM_TRIGGER_BITS+:16];

	// delay trigger & sample phase data
	OUTPUT_DELAY #(
		.MATCH_DELAY(PIPELINE_DELAY),
		.BIT_WIDTH(NUM_TRIGGERS)
	) delayTrigger(.clock(clk), .dataIn(siTriggerArray), .delayedDataOut(triggerData_delayed));
	assign triggerDataValid = triggerData_inFifo[NUM_TRIGGERS-1:0] == triggerData_delayed;

	OUTPUT_DELAY #(
		.MATCH_DELAY(PIPELINE_DELAY),
		.BIT_WIDTH(16)
	) delaySamplePhase(.clock(clk), .dataIn(firstSamplePhase), .delayedDataOut(samplePhase_delayed));
	assign samplePhaseValid = samplePhase_inFifo == samplePhase_delayed;

	// determine if all data is valid (all sample data valid, trigger data valid, sample phase data valid)
	wire allAnalogDataValid = &sampleDataValid;
	assign allDataValid = allAnalogDataValid && triggerDataValid && samplePhaseValid;

	// design under test
	SI_DataScope_H #(
		.FIFO_WIDTH(FIFO_WIDTH),
		.NUM_TRIGGERS(NUM_TRIGGERS)
	) datascope (
		.clk(clk),
		.reset(reset),
		.start(start),
		.numberOfSamples(numberOfSamples),
		.sampleDecimationLB2(sampleDecimationLB2),
		.trigger(trigger),
		.sampleDataA(sampleDataA_packed),
		.sampleDataB(sampleDataB_packed),
		.chanSel(chanSel),
		.firstSamplePhase(firstSamplePhase),
		.siTriggerArray(siTriggerArray),
		.dataValidIn(dataValidIn),

		.fifoWriteEn(fifoWriteEn),
		.fifoWriteData(fifoWriteData)
	);

	localparam STATE_RESET = 0;
	localparam STATE_UNRESET = 1;
	localparam STATE_START = 2;
	localparam STATE_UNSTART = 3;
	localparam STATE_WAIT_FOR_TRIGGER = 4;
	localparam STATE_TRIGGER = 5;
	localparam STATE_UNTRIGGER = 6;
	reg [3:0] testState = STATE_RESET;

	reg [5:0] sampleIndex = 0;

	localparam WAIT_FOR_TRIGGER_COUNT = 10;
	reg [$clog2(WAIT_FOR_TRIGGER_COUNT)-1:0] triggerWaitCounter = WAIT_FOR_TRIGGER_COUNT;

	// test sequence
	always @(posedge clk) begin
		// simulate fake DC offsets with a little bit of noise
		for (sampleIndex = 0; sampleIndex < `HS_SAMPS_PER_TICK; sampleIndex = sampleIndex + 1) begin
			sampleDataA[sampleIndex] <= $urandom_range(990,1010);
			sampleDataB[sampleIndex] <= $urandom_range(400,420);
		end

		// simulate fake triggers with a counter
		siTriggerArray <= siTriggerArray + 1;
		firstSamplePhase <= firstSamplePhase + 1;

		case (testState)
			STATE_RESET: begin
				reset <= 1;
				testState <= STATE_UNRESET;
			end
			STATE_UNRESET: begin
				reset <= 0;
				testState <= STATE_START;
			end
			STATE_START: begin
				start <= 1;
				testState <= STATE_UNSTART;
			end
			STATE_UNSTART: begin
				start <= 0;

				triggerWaitCounter <= WAIT_FOR_TRIGGER_COUNT;
				testState <= STATE_WAIT_FOR_TRIGGER;
			end
			STATE_WAIT_FOR_TRIGGER: begin
				triggerWaitCounter <= triggerWaitCounter-1;

				if (!triggerWaitCounter)
					testState <= STATE_TRIGGER;
			end
			STATE_TRIGGER: begin
				trigger[0] <= 1;
				testState <= STATE_UNTRIGGER;
			end
			STATE_UNTRIGGER: begin
				trigger[0] <= 0;
				dataValidIn <= 1;
			end

		endcase
	end

endmodule
