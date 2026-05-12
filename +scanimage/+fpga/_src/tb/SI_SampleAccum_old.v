//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

module SI_SampleAccum_old #(
	parameter HS_NUM_LOGICAL_CHANNELS = 8,
	parameter NUM_DIVIDERS = 4,
	parameter MASK_ADDR_BITS = 10
)(
	input  wire dataClk,
	input  wire cfgClk,
	input  wire resetSm,
	
	input wire  maskTblWriteEnable,
	input wire [MASK_ADDR_BITS-1:0] maskTblWriteAddr,
	input wire [`ACCUM_BITS-1:0] maskTblWriteData,
	input wire [MASK_ADDR_BITS-1:0] maskSize, // mask size should be set to actual mask size - 1
	
	input wire acqParamUniformSampling,
	input wire [11:0] acqParamUniformBinSize,
	
	input  wire [`STATE_MACHINE_OUT_LSZ:0] stateMachineDataIn,
	input  wire [`LOGICAL_CHANNEL_BUF_LSZ:0] logicalChannelsIn,
	
	output wire [`STATE_MACHINE_OUT_LSZ:0] stateMachineDataOut,
	output wire [`ACCUM_BUF_LSZ:0] logicalChannelsAccumOut,
	output wire [`ACCUM_BITS-1:0] divisor,
	output wire pixelClock,
	output wire accumDone,
	
	input  wire [16:0] acqParamDummyVal
);
	reg [`STATE_MACHINE_OUT_LSZ:0] stateMachineDataReg = 0;
	assign stateMachineDataOut = stateMachineDataReg;
	
	
	wire startOfLine = stateMachineDataIn[`STATE_MACHINE_OUT_SOL_BIT];
	wire endOfLine = stateMachineDataIn[`STATE_MACHINE_OUT_EOL_BIT];
	wire acquireSample = stateMachineDataIn[`STATE_MACHINE_OUT_ACQ_CLK_BIT];
	
	
	// mask storage/read
	reg [`ACCUM_BITS-1:0] firstBinSize = 0;
	wire [`ACCUM_BITS-1:0] maskReadData;
	reg [MASK_ADDR_BITS-1:0] currBinReadPtr = 0;
	wire [MASK_ADDR_BITS-1:0] nextBinReadPtr;
	
	
	// calculation of divisor and bin size is common for all channels. logic here
	reg [`ACCUM_BITS-1:0] accumCount = 0;
	reg [`ACCUM_BITS-1:0] currBinSize = 0;
	reg [`ACCUM_BITS-1:0] divisorR = 0;

	assign divisor = divisorR;
	
	reg outputValid = 0;
	wire accumStart = startOfLine || outputValid;
	wire accumEnd = endOfLine || (acquireSample && (((accumCount+1) == currBinSize) || (accumStart && acquireSample && (currBinSize == 1))));
	assign accumDone = outputValid;
	
	wire goToFirstBin = resetSm || (accumEnd && (currBinReadPtr == maskSize));
	assign nextBinReadPtr = goToFirstBin ? 0 : currBinReadPtr + accumEnd;
	
	assign pixelClock = acquireSample && (accumCount < (currBinSize>>1));
	
	always @(posedge dataClk) begin
		
		if (accumEnd || resetSm)
			accumCount <= 0;
		else
			accumCount <= accumCount + acquireSample;
		
		outputValid <= accumEnd;
		divisorR <= accumEnd ? currBinSize : divisorR;
		
		if (acqParamUniformSampling)
			currBinSize <= acqParamUniformBinSize;
		else if (goToFirstBin)
			currBinSize <= firstBinSize;
		else if (accumEnd)
			currBinSize <= maskReadData;
		
		currBinReadPtr <= nextBinReadPtr;
		
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
	
	
	
	// mask storage
	localparam MASK_TBL_NUM_RANKS = 1<<(MASK_ADDR_BITS-5);
	wire [`ACCUM_BITS-1:0] maskTblRowDataOut [MASK_TBL_NUM_RANKS-1:0];
	
	wire [MASK_ADDR_BITS-1:0] maskTblOffsetWriteAddr = maskTblWriteAddr - 1;
	wire [MASK_ADDR_BITS-6:0] maskTblOffsetWriteRank = maskTblOffsetWriteAddr[MASK_ADDR_BITS-1:5];
	wire writeMaskTbl = maskTblWriteEnable && (maskTblWriteAddr > 0);

	reg [MASK_ADDR_BITS-1:0] maskTblOffsetWriteAddrR = 0;
	reg [`ACCUM_BITS-1:0] maskTblWriteDataR = 0;
	
	always @(posedge cfgClk) begin
		// pipeline write
		maskTblOffsetWriteAddrR <= maskTblOffsetWriteAddr;
		maskTblWriteDataR <= maskTblWriteData;

		// first mask bin size save
		if (maskTblWriteEnable && !maskTblWriteAddr)
			firstBinSize <= maskTblWriteData;
	end
	
	assign maskReadData = maskTblRowDataOut[currBinReadPtr[MASK_ADDR_BITS-1:5]];
	
	genvar maskTblRankNo;
	genvar maskTblBitNo;
	generate
		for (maskTblRankNo = 0; maskTblRankNo < MASK_TBL_NUM_RANKS; maskTblRankNo=maskTblRankNo+1) begin:gen_mask_table
			for (maskTblBitNo = 0; maskTblBitNo < `ACCUM_BITS; maskTblBitNo=maskTblBitNo+1) begin:gen_mask_table_rank

				reg bitWe = 0;

				always @(posedge cfgClk)
					bitWe <= ((MASK_TBL_NUM_RANKS == 1) || (maskTblOffsetWriteRank == maskTblRankNo)) && writeMaskTbl;
				
				RAM32X1D RAM32X1D_inst (
					.DPO(maskTblRowDataOut[maskTblRankNo][maskTblBitNo]), // Read-only 1-bit data output
					.SPO(), // Rw/ 1-bit data output
					.A0(maskTblOffsetWriteAddrR[0]), // Rw/ address[0] input bit
					.A1(maskTblOffsetWriteAddrR[1]), // Rw/ address[1] input bit
					.A2(maskTblOffsetWriteAddrR[2]), // Rw/ address[2] input bit
					.A3(maskTblOffsetWriteAddrR[3]), // Rw/ address[3] input bit
					.A4(maskTblOffsetWriteAddrR[4]), // Rw/ address[4] input bit
					.D(maskTblWriteDataR[maskTblBitNo]), // Write 1-bit data input
					.DPRA0(currBinReadPtr[0]), // Read-only address[0] input bit
					.DPRA1(currBinReadPtr[1]), // Read-only address[1] input bit
					.DPRA2(currBinReadPtr[2]), // Read-only address[2] input bit
					.DPRA3(currBinReadPtr[3]), // Read-only address[3] input bit
					.DPRA4(currBinReadPtr[4]), // Read-only address[4] input bit
					.WCLK(cfgClk), // Write clock input
					.WE(bitWe) // Write enable input
				);
			end
		end
	endgenerate
	
endmodule
