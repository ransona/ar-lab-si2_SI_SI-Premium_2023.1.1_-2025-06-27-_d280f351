//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King, Nelson Downs
// Changelog:
//   5/1/23 (Nelson): Implement 2x2048 element BRAM matrix for mask table
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_SampleAccum #(
	parameter HS_NUM_LOGICAL_CHANNELS = 8,
	parameter NUM_DIVIDERS = 4,
	parameter MASK_ADDR_BITS = 10
)(
	input  wire dataClk,
	input  wire cfgClk,
	input  wire resetSm,
	
	input wire maskTblWriteEnable,
	input wire [MASK_ADDR_BITS-1:0] maskTblWriteAddr,
	input wire [`ACCUM_MASK_TABLE_LSZ:0] maskTblWriteData,
	input wire [MASK_ADDR_BITS-1:0] maskSize, // mask size should be set to actual mask size - 1
	
	input wire acqParamUniformSampling,
	input wire [`ACCUM_BITS-1:0] acqParamUniformBinSize,
	input wire [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] acqParamUniformBinCoefficient,
	
	input  wire [`STATE_MACHINE_OUT_LSZ:0] stateMachineDataIn,
	input  wire [`LOGICAL_CHANNEL_BUF_LSZ:0] logicalChannelsIn,
	
	output wire [`STATE_MACHINE_OUT_LSZ:0] stateMachineDataOut,
	output wire [`ACCUM_BUF_LSZ:0] logicalChannelsAccumOut,
	output wire [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] coefficient,
	output wire pixelClock,
	output wire accumDone,
		
	input  wire [16:0] acqParamDummyVal
);
	localparam NUM_ROWS = 2048;
	localparam NUM_COLUMNS = 2;

	reg [`STATE_MACHINE_OUT_LSZ:0] stateMachineDataReg = 0;
	assign stateMachineDataOut = stateMachineDataReg;
		
	wire startOfLine = stateMachineDataIn[`STATE_MACHINE_OUT_SOL_BIT];
	wire endOfLine = stateMachineDataIn[`STATE_MACHINE_OUT_EOL_BIT];
	wire acquireSample = stateMachineDataIn[`STATE_MACHINE_OUT_ACQ_CLK_BIT];
		
	//// mask table reading
	// first (or zeroth, 0th) row storage is in fast LUTRAM:
	reg [`ACCUM_BITS-1:0] firstRowBinSizes[1:0];
	reg [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] firstRowCoefficients[1:0];

	// mask table linear indices (e.g. 0 to 4095):
	reg  [MASK_ADDR_BITS-1:0] currentMaskReadPtr = 0;
	wire [MASK_ADDR_BITS-1:0] nextMaskReadPtr;

	// BRAM matrix index from mask table linear index (e.g. (0,0) to (1,2047))
	// Reading from BRAM:
	//  - We have two columns of BRAM and multiple rows
	//  - Entire rows are read simultaneously
	//  - We cache the columns immediately after we read the row
	//  - As we increment mask table index, we read from cached column data
	//    until we need to read the next BRAM row
	wire [MASK_ADDR_BITS-2:0] bramReadIndex_row = currentMaskReadPtr >> 1;
	wire bramReadIndex_column = currentMaskReadPtr[0];

	// unpacked row output data from the BRAM
	wire [`ACCUM_MASK_TABLE_LSZ:0] bramReadRowData[NUM_COLUMNS-1:0];

	// accumulator counting & mask element storage
	// packed mask table element: {binSize,coefficient}
	reg [`ACCUM_BITS-1:0] accumCount = 0;
	reg [`ACCUM_BITS-1:0] bramRowBinSizes[NUM_COLUMNS-1:1];  // do not store 0th column, that is read immediately
	reg [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] bramRowCoefficients[NUM_COLUMNS-1:1];

	reg [`ACCUM_BITS-1:0] currentBinSize = 0;
	reg [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] currentCoefficient = 0;
	reg [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] lastCoefficient = 0;

	// accumulator state flags
	reg outputValid = 0;
	wire accumStart = startOfLine || outputValid;
	wire accumEnd = endOfLine || (acquireSample && (((accumCount+1) == currentBinSize) || (accumStart && acquireSample && (currentBinSize == 1))));
	assign accumDone = outputValid;
	
	wire goToFirstBin = resetSm || (accumEnd && (currentMaskReadPtr == maskSize));
	assign nextMaskReadPtr = goToFirstBin ? 0 : currentMaskReadPtr + accumEnd;
	
	assign pixelClock = acquireSample && (accumCount < (currentBinSize>>1));
	assign coefficient = lastCoefficient;

	reg [$clog2(NUM_COLUMNS):0] colIndex = 0;
	always @(posedge dataClk) begin
		if (accumEnd || resetSm)
			accumCount <= 0;
		else
			accumCount <= accumCount + acquireSample;
		
		outputValid <= accumEnd;
		lastCoefficient <= accumEnd ? currentCoefficient : lastCoefficient;
		
		if (acqParamUniformSampling) begin
			currentBinSize <= acqParamUniformBinSize;
			currentCoefficient <= acqParamUniformBinCoefficient;
		end else if (goToFirstBin) begin
			// this is the first (0th row index) of the mask table, stored in fast lookup LUTRAM not BRAM
			// cache the other (non-0th column index) bin/coefficient columns
			for (colIndex = 1; colIndex < NUM_COLUMNS; colIndex = colIndex + 1) begin
				bramRowBinSizes[colIndex] <= firstRowBinSizes[colIndex];
				bramRowCoefficients[colIndex] <= firstRowCoefficients[colIndex];
			end
			// retrieve the bin size and coefficient of the 0th column to use right away
			currentBinSize <= firstRowBinSizes[0];
			currentCoefficient <= firstRowCoefficients[0];
		end else if (accumEnd) begin
			// if this is the last column of this row, cache the columns of the next row from BRAM
			// (note the next row in BRAM is the current row index, see mask table writing/storage section for more info)
			if (bramReadIndex_column == NUM_COLUMNS-1) begin
				// store other (non-0th) bin/coefficient columns
				for (colIndex = 1; colIndex < NUM_COLUMNS; colIndex = colIndex + 1) begin
					bramRowBinSizes[colIndex] <= bramReadRowData[colIndex][`ACCUM_COEFFICIENT_FIXED_POINT_WIDTH+:`ACCUM_BITS];
					bramRowCoefficients[colIndex] <= bramReadRowData[colIndex][0+:`ACCUM_COEFFICIENT_FIXED_POINT_WIDTH];
				end
				// use latest BRAM data available for the current (0th) column
				currentBinSize <= bramReadRowData[0][`ACCUM_COEFFICIENT_FIXED_POINT_WIDTH+:`ACCUM_BITS];
				currentCoefficient <= bramReadRowData[0][0+:`ACCUM_COEFFICIENT_FIXED_POINT_WIDTH];
			end else begin
				// read from the next stored BRAM column (e.g. column 1 when we are on column 0)
				currentBinSize <= bramRowBinSizes[bramReadIndex_column+1];
				currentCoefficient <= bramRowCoefficients[bramReadIndex_column+1];
			end
		end
		
		currentMaskReadPtr <= nextMaskReadPtr;
		stateMachineDataReg <= stateMachineDataIn;
	end
	

	// generate accumulators
	genvar chIdx;
	generate
		for (chIdx = 0; chIdx < HS_NUM_LOGICAL_CHANNELS; chIdx = chIdx+1) begin : gen_ch_accum
			wire signed [`LOGICAL_CHANNEL_WIDTH-1:0] chSample = acqParamDummyVal[16] ? acqParamDummyVal[0+:`LOGICAL_CHANNEL_WIDTH] : logicalChannelsIn[chIdx*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH];
			reg signed [`ACCUM_CHANNEL_LSZ:0] chAccum = 0;
			assign logicalChannelsAccumOut[chIdx*`ACCUM_CHANNEL_WIDTH+:`ACCUM_CHANNEL_WIDTH] = chAccum;
			
			always @(posedge dataClk) begin
				if (accumStart && acquireSample)
					chAccum <= chSample;
				else if (acquireSample)
					chAccum <= chAccum + chSample;
				else if (accumStart)
					chAccum <= 0;
			end
		end
	endgenerate
	
	/////// mask table writing & storage
	// BRAM matrix index from mask table vector index
	// -row addresses are offset by 1 since we store the 0th mask table row in fast LUTRAM
	// -e.g., when we are using the 0th row, we are actually loading the 1st row (0th row in BRAM)
	//        when we are using the 1st row, we are actually loading the 2nd row (1st row in BRAM)
	wire [MASK_ADDR_BITS-2:0] maskTblWriteRowAddr = maskTblWriteAddr >> 1;
	wire [MASK_ADDR_BITS-2:0] maskTblOffsetWriteRowAddr = maskTblWriteRowAddr - 1;
	wire bramWriteIndex_column = maskTblWriteAddr[0];
	wire writeMaskTbl = maskTblWriteEnable && (maskTblWriteRowAddr > 0);

	// pipeline write regs for writing to BRAM with mask element input data
	// -two elements per row, each has their own write-enable "writeMaskTblR"
	reg [MASK_ADDR_BITS-2:0] bramWriteIndex_rowR = 0;
	reg [`ACCUM_MASK_TABLE_LSZ:0] bramWriteData_row[1:0];
	reg writeMaskTblR[1:0];
	
	always @(posedge cfgClk) begin
		bramWriteIndex_rowR <= maskTblOffsetWriteRowAddr;
		bramWriteData_row[bramWriteIndex_column] <= maskTblWriteData;
		writeMaskTblR[bramWriteIndex_column] <= writeMaskTbl;

		// clear other columns of writeMaskTblR to prevent address collisions
		// -if we don't do this, the regs can keep their stored values and when they do, wea on the
		//  RAM is left on
		// -at the end of the line, there will be a collision when wea is enabled and the write/read
		//  addresses are the same
		for (colIndex = 0; colIndex < NUM_COLUMNS; colIndex = colIndex + 1)
			if (colIndex != bramWriteIndex_column)
				writeMaskTblR[colIndex] <= 0;

		// save the first (0th index) row to fast lookup LUTRAM
		if (maskTblWriteEnable && maskTblWriteRowAddr == 0) begin
			firstRowBinSizes[bramWriteIndex_column] <= maskTblWriteData[`ACCUM_COEFFICIENT_FIXED_POINT_WIDTH+:`ACCUM_BITS];
			firstRowCoefficients[bramWriteIndex_column] <= maskTblWriteData[0+:`ACCUM_COEFFICIENT_FIXED_POINT_WIDTH];
		end
	end
	
	genvar columnIndex;
	generate
		// create matrix of BRAM vectors, each column with its own write-enable (wea)
		for (columnIndex = 0; columnIndex < NUM_COLUMNS; columnIndex = columnIndex + 1) begin
			SampleAccumBRAMCore maskTableBRAM (
				.clka(cfgClk),                           // input wire clka
				.wea(writeMaskTblR[columnIndex]),        // input wire [0 : 0] wea
				.addra(bramWriteIndex_rowR),             // input wire [10 : 0] addra
				.dina(bramWriteData_row[columnIndex]), // input wire [37 : 0] dina
				.clkb(dataClk),                          // input wire clkb
				.addrb(bramReadIndex_row),               // input wire [10 : 0] addrb
				.doutb(bramReadRowData[columnIndex])     // output wire [37 : 0] doutb
			);
		end
	endgenerate
	
	
endmodule
