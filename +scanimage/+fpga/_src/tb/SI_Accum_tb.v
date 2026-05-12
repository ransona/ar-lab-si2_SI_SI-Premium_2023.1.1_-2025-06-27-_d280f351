//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
// 
// Create Date:
// Design Name: 
// Module Name:
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 100 ps
`include "SI_Defines.v"

module SI_Accum_tb();
	reg sampleClk125 = 0;
	reg cfgClk200 = 0;

	localparam HS_NUM_LOGICAL_CHANNELS = 1;

	localparam MASK_TABLE_MAX_SIZE = 4096;
	localparam MASK_ADDR_BITS = $clog2(MASK_TABLE_MAX_SIZE);
	reg [MASK_ADDR_BITS-1:0] maskTableSize = 2048;

	reg cfgMaskWriteEnable = 0;
	reg [MASK_ADDR_BITS-1:0] cfgMaskAddr = 0;
	reg [`ACCUM_BITS-1:0] cfgMaskBin = 0;
	reg [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] cfgMaskDivisor = 0;
	wire [`ACCUM_MASK_TABLE_LSZ:0] cfgMaskWriteData = {cfgMaskBin, cfgMaskDivisor};

	reg startOfLine = 0;
	reg endOfLine = 0;
	reg acquireSample = 0;
	wire [`STATE_MACHINE_OUT_LSZ:0] stateMachineData;
	assign stateMachineData[`STATE_MACHINE_OUT_SOL_BIT] = startOfLine;
	assign stateMachineData[`STATE_MACHINE_OUT_EOL_BIT] = endOfLine;
	assign stateMachineData[`STATE_MACHINE_OUT_ACQ_CLK_BIT] = acquireSample;

	reg [`LOGICAL_CHANNEL_BUF_LSZ:0] conditionedChannelIn = 0;

	reg resetSm = 0;

	localparam CFG_INIT_STATE = 0;
	localparam CFG_WRITE_MASK_STATE = 1;
	localparam ACQUIRE_RESET_STATE = 2;
	localparam ACQUIRE_UNRESET_STATE = 3;
	localparam ACQUIRE_SETUP_STATE = 4;
	localparam ACQUIRE_RUN_STATE = 5;

	reg [2:0] simulationState = CFG_INIT_STATE;

	wire [`ACCUM_BUF_LSZ:0] newAccumOut;
	wire [`ACCUM_BUF_LSZ:0] oldAccumOut;

	wire [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] newCoefficientOut;
	wire [`ACCUM_BITS-1:0] oldDivisorOut;
	
	SI_SampleAccum #(
		.MASK_ADDR_BITS(MASK_ADDR_BITS),
		.HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
		.NUM_DIVIDERS(HS_NUM_LOGICAL_CHANNELS)
	) sampleAccum (
		.dataClk(sampleClk125),
		.cfgClk(cfgClk200),
		.resetSm(resetSm),
		
		.maskTblWriteEnable(cfgMaskWriteEnable),
		.maskTblWriteAddr(cfgMaskAddr),
		.maskTblWriteData(cfgMaskWriteData),
		.maskSize(maskTableSize),
		
		.acqParamUniformSampling(0),
		.acqParamUniformBinSize(0),
		.acqParamUniformBinCoefficient(0),
		
		.stateMachineDataIn(stateMachineData),
		.logicalChannelsIn(conditionedChannelIn),
		
		.stateMachineDataOut(),
		.logicalChannelsAccumOut(newAccumOut),
		.coefficient(newCoefficientOut),
		.accumDone(),
		.pixelClock(),
		
		.acqParamDummyVal(0)
	);
	
	SI_SampleAccum_old #(
		.MASK_ADDR_BITS(MASK_ADDR_BITS),
		.HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
		.NUM_DIVIDERS(HS_NUM_LOGICAL_CHANNELS)
	) sampleAccum_old (
		.dataClk(sampleClk125),
		.cfgClk(cfgClk200),
		.resetSm(resetSm),
		
		.maskTblWriteEnable(cfgMaskWriteEnable),
		.maskTblWriteAddr(cfgMaskAddr),
		.maskTblWriteData(cfgMaskBin),
		.maskSize(maskTableSize),
		
		.acqParamUniformSampling(0),
		.acqParamUniformBinSize(0),
		
		.stateMachineDataIn(stateMachineData),
		.logicalChannelsIn(conditionedChannelIn),
		
		.stateMachineDataOut(),
		.logicalChannelsAccumOut(oldAccumOut),
		.divisor(oldDivisorOut),
		.accumDone(),
		.pixelClock(),
		
		.acqParamDummyVal(0)
	);

	wire accumsOutputEqual = newAccumOut == oldAccumOut;
	wire coefficientsOutputEqual = newCoefficientOut == oldDivisorOut;
	
	// sample clk
	always begin
		#4
		sampleClk125 <= ~sampleClk125;
	end

	// cfg clk
	always begin
		#2.5
		cfgClk200 <= ~cfgClk200;
	end

	// sample clk test procedure
	always @(posedge sampleClk125) begin
		// sample generation
		conditionedChannelIn <= $urandom;

		// acquisition state machine
		case (simulationState)
			// first, hold the system in reset for a clock cycle
			ACQUIRE_RESET_STATE: begin
				resetSm <= 1;
				simulationState <= ACQUIRE_UNRESET_STATE;
			end
			ACQUIRE_UNRESET_STATE: begin
				resetSm <= 0;
				simulationState <= ACQUIRE_SETUP_STATE;
			end

			// then start the line, and begin acquisition
			ACQUIRE_SETUP_STATE: begin
				startOfLine <= 1;
				acquireSample <= 1;
				simulationState <= ACQUIRE_RUN_STATE;
			end
			ACQUIRE_RUN_STATE: begin
				startOfLine <= 0;
			end
		endcase
	end

	// cfg clk test procedure
	always @(posedge cfgClk200) begin
		cfgMaskBin <= cfgMaskAddr+1;
		cfgMaskDivisor <= cfgMaskAddr+1;

		case (simulationState)
			CFG_INIT_STATE: begin
				cfgMaskAddr <= 0;
				cfgMaskWriteEnable <= 1;
				simulationState <= CFG_WRITE_MASK_STATE;
			end
			CFG_WRITE_MASK_STATE: begin
				cfgMaskAddr <= cfgMaskAddr + 1;

				if (cfgMaskAddr < maskTableSize)
					cfgMaskWriteEnable <= 1;
				else begin
					cfgMaskWriteEnable <= 0;
					simulationState <= ACQUIRE_RESET_STATE;
				end
			end
		endcase
	end
endmodule
