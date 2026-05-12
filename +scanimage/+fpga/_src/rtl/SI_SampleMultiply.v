//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King, Nelson Downs
// Changelog:
//   5/1/23 (Nelson): Implement fixed point multiplication instead of division
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

`define MULTIPLIER_LATENCY 4

module SI_SampleMultiply #(
	parameter HS_NUM_LOGICAL_CHANNELS = 8,
	parameter NUM_DIVIDERS = 4,
	parameter ACCUM_COEFFICIENT_FIXED_POINT_PRECISION = 16
)(
	input  wire clk,
	
	input  wire [`STATE_MACHINE_OUT_LSZ:0] accumStateMachineDataIn,
	input  wire [`ACCUM_BUF_LSZ:0] logicalChannelsAccumIn,
	input  wire [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] coefficientIn, // the divisor coefficient in fixed-point notation
	input  wire accumDone,
	
	output wire [`LOGICAL_CHANNEL_BUF_LSZ:0] outputPixelData,
	output wire pixelDataValid,
	output wire endOfLine,
	
	input  wire [NUM_DIVIDERS-1:0] disableDivide
);
	localparam ACCUM_CHANNEL_UPPER_BITS = `ACCUM_CHANNEL_WIDTH - `LOGICAL_CHANNEL_LSZ;

	localparam signed [`ACCUM_CHANNEL_LSZ:0] LOGICAL_CHANNEL_MIN = {{ACCUM_CHANNEL_UPPER_BITS{1'b1}},{`LOGICAL_CHANNEL_LSZ{1'b0}}};
	localparam signed [`ACCUM_CHANNEL_LSZ:0] LOGICAL_CHANNEL_MAX = {{ACCUM_CHANNEL_UPPER_BITS{1'b0}},{`LOGICAL_CHANNEL_LSZ{1'b1}}};

	localparam TOTAL_PIPELINE_LATENCY = `MULTIPLIER_LATENCY + 1;

	localparam [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] ONE_FIXEDPOINT = 1'b1 << ACCUM_COEFFICIENT_FIXED_POINT_PRECISION;

	wire accumEndOfLine = accumStateMachineDataIn[`STATE_MACHINE_OUT_EOL_BIT];
	
	// generate accumulators
	genvar chIdx;
	generate
		for (chIdx = 0; chIdx < HS_NUM_LOGICAL_CHANNELS; chIdx = chIdx+1) begin : gen_ch_accum
			// accumulated signal for this channel
			wire signed [`ACCUM_CHANNEL_LSZ:0] chAccum = logicalChannelsAccumIn[chIdx*`ACCUM_CHANNEL_WIDTH+:`ACCUM_CHANNEL_WIDTH];

			if (chIdx < NUM_DIVIDERS) begin
				// divide by zero not possible with fixed point notation

				// the divisor is now passed in as an fixed-point precision multiplication coefficient
				//  - it can be used to divide accumulated sample values down, or multiply them up based on what the user prefers
				//  - sometimes multiplying up is useful in cases of small values, like photon counting
				wire signed [`ACCUM_MULT_B_SZ-1:0] coefficientFixedPoint = {1'b0, disableDivide[chIdx] ? ONE_FIXEDPOINT : coefficientIn};

				wire signed [`ACCUM_MULT_P_SZ-1:0] multiplierOut;
				wire multiplierOutSignBit = multiplierOut[`ACCUM_MULT_P_SZ-1];

				// convert the final fixed point precision back to normal precision
				wire signed [`ACCUM_CHANNEL_LSZ:0] quotient = {multiplierOutSignBit, multiplierOut[ACCUM_COEFFICIENT_FIXED_POINT_PRECISION+:`ACCUM_CHANNEL_WIDTH-1]};

				SampleAccumMultiplierCore pixelMultiplier(
					.CLK(clk),
					.A(chAccum),				// 28 bits wide
					.B(coefficientFixedPoint),	// 27 bits wide
					.P(multiplierOut)			// 55 bits wide
				);

				// detect if the quotient has overflowed the logical channel bitwidth
				wire quotientOverflowHigh = quotient > LOGICAL_CHANNEL_MAX;
				wire quotientOverflowLow = quotient < LOGICAL_CHANNEL_MIN;

				// saturate if the quotient has overflowed (adds one delay to the pipeline)
				reg [`LOGICAL_CHANNEL_LSZ:0] quotientSaturationProtected = 0;
				always @(posedge clk) begin
					if (quotientOverflowLow)
						quotientSaturationProtected <= LOGICAL_CHANNEL_MIN;
					else if (quotientOverflowHigh)
						quotientSaturationProtected <= LOGICAL_CHANNEL_MAX;
					else
						quotientSaturationProtected <= quotient;
				end

				// assign the pixel data to the saturation protected channels
				assign outputPixelData[chIdx*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH] = quotientSaturationProtected;
			end else begin
				// detect if the accumulated channel has overflowed the logical channel bitwidth
				wire chAccumOverflowHigh = chAccum > LOGICAL_CHANNEL_MAX;
				wire chAccumOverflowLow = chAccum < LOGICAL_CHANNEL_MIN;

				if (NUM_DIVIDERS) begin
					// if there are dividers, data must be delayed to stay syced with channels that have dividers
					reg [`LOGICAL_CHANNEL_LSZ:0] dataDelay[TOTAL_PIPELINE_LATENCY-1:0];
					reg [5:0] dCtr;

					assign outputPixelData[chIdx*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH] = dataDelay[0];

					// TODO: maybe right shift instead of saturating?
					always @(posedge clk) begin
						if (chAccumOverflowLow)
							dataDelay[TOTAL_PIPELINE_LATENCY-1] <= LOGICAL_CHANNEL_MIN;
						else if (chAccumOverflowHigh)
							dataDelay[TOTAL_PIPELINE_LATENCY-1] <= LOGICAL_CHANNEL_MAX;
						else
							dataDelay[TOTAL_PIPELINE_LATENCY-1] <= chAccum;
						
						for (dCtr = 0; dCtr <= (TOTAL_PIPELINE_LATENCY-2); dCtr = dCtr + 1)
							dataDelay[dCtr] <= dataDelay[dCtr+1];
					end

				end else begin
					// if there are no dividers, no need to delay the data
					reg [`LOGICAL_CHANNEL_LSZ:0] dataR = 0;

					assign outputPixelData[chIdx*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH] = dataR;

					// if overflowed, saturate the output (adds one delay to the pipeline)
					always @(posedge clk) begin
						if (chAccumOverflowLow)
							dataR <= LOGICAL_CHANNEL_MIN;
						else if (chAccumOverflowHigh)
							dataR <= LOGICAL_CHANNEL_MAX;
						else
							dataR <= chAccum;
					end
				end
			end
		end
	endgenerate
	
	if (NUM_DIVIDERS) begin
		// if there's dividers (multipliers), we need to delay the relevant info signals by
		// the same pipeline latency
		// the pipeline latency is the multiplier latency + 1 for the saturation protection
		reg [TOTAL_PIPELINE_LATENCY-1:0] pixelDataValidDelay;
		reg [TOTAL_PIPELINE_LATENCY-1:0] eolDelay;
		
		assign pixelDataValid = pixelDataValidDelay[0];
		assign endOfLine = eolDelay[0];

		always @(posedge clk) begin
			pixelDataValidDelay <= {accumDone, pixelDataValidDelay[TOTAL_PIPELINE_LATENCY-1:1]};
			eolDelay <= {accumEndOfLine, eolDelay[TOTAL_PIPELINE_LATENCY-1:1]};
		end
	end else begin
		// only the saturation protection delay in here (1 pipeline delay)
		reg [1:0] pixelDataValidR = 0;
		assign pixelDataValid = pixelDataValidR[0];
		
		reg [1:0] endOfLineR = 0;
		assign endOfLine = endOfLineR[0];

		always @(posedge clk) begin
			pixelDataValidR <= {accumDone, pixelDataValidR[1]};
			endOfLineR <= {accumEndOfLine, endOfLineR[1]};
		end
	end

	
endmodule
