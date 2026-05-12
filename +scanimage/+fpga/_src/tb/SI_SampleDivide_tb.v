//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
`include "SI_Defines.v"

`define TOTAL_LATENCY 5

module SI_SampleDivide_tb #(
    parameter HS_NUM_LOGICAL_CHANNELS = 4
)();
	
	reg clk = 1;
    always #5 clk <= ~clk;
    
    // input test variables
    wire signed [`ACCUM_BUF_LSZ:0] rawAccumInputs;
    reg signed [`ACCUM_CHANNEL_LSZ:0] accumInputs[HS_NUM_LOGICAL_CHANNELS-1:0];
    reg [5:0] dCtr = 0;
    reg valid = 0;
    reg endOfLine = 0;

    // wire [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] divisorIn = 1'b1 << `ACCUM_FIXED_POINT_PRECISION;
    wire [`ACCUM_COEFFICIENT_FIXED_POINT_LSZ:0] divisorIn = 4369;  // 1/15 with 16 bits of precision
    wire [HS_NUM_LOGICAL_CHANNELS-1:0] disableDivide = {HS_NUM_LOGICAL_CHANNELS{1'b0}};

    // initialize test inputs
    reg [5:0] chIdx;
    initial begin
        for (chIdx = 0; chIdx < HS_NUM_LOGICAL_CHANNELS; chIdx = chIdx + 1)
            accumInputs[chIdx] = 0;
    end

    // delay the accum inputs for easy viewing
    wire [`ACCUM_CHANNEL_LSZ:0] delayedAccumInputs[HS_NUM_LOGICAL_CHANNELS-1:0];
    reg  [`ACCUM_CHANNEL_LSZ:0] delayedAccumInputsArray[HS_NUM_LOGICAL_CHANNELS-1:0][`TOTAL_LATENCY-1:0];

    reg  [`ACCUM_CHANNEL_LSZ:0] sizeFixedValue;
    
    // fluctuate test values throughout test
    always @(posedge clk) begin
        accumInputs[0] <= accumInputs[0] + 1;
        accumInputs[1] <= accumInputs[0] << 1;
        accumInputs[2] <= $random;

        sizeFixedValue = $urandom_range(65535*4,0);
        sizeFixedValue = {{`ACCUM_BITS{sizeFixedValue[19]}}, sizeFixedValue[19:0]};
        accumInputs[3] <= sizeFixedValue;

        valid <= $urandom_range(100,0) < 20;
        endOfLine <= $urandom_range(100,0) < 2;
    end

    SI_SampleMultiply #(
        .HS_NUM_LOGICAL_CHANNELS(HS_NUM_LOGICAL_CHANNELS),
        .NUM_DIVIDERS(4)
    ) div (
        .clk(clk),

        .accumStateMachineDataIn({endOfLine,1'b0}),
        .logicalChannelsAccumIn(rawAccumInputs),
        .coefficientIn(divisorIn),
        .accumDone(valid),
        .disableDivide(disableDivide),

        .outputPixelData(rawOutputPixelData)
    );

    // split/unpack output data for easy viewing
    wire [HS_NUM_LOGICAL_CHANNELS*`LOGICAL_CHANNEL_WIDTH-1:0] rawOutputPixelData;
    wire [`LOGICAL_CHANNEL_LSZ:0] outputPixelData[HS_NUM_LOGICAL_CHANNELS-1:0];

    generate
        genvar genChIdx;
        for (genChIdx = 0; genChIdx < HS_NUM_LOGICAL_CHANNELS; genChIdx = genChIdx + 1) begin
            assign rawAccumInputs[genChIdx*`ACCUM_CHANNEL_WIDTH+:`ACCUM_CHANNEL_WIDTH] = accumInputs[genChIdx];
            assign outputPixelData[genChIdx] = rawOutputPixelData[genChIdx*`LOGICAL_CHANNEL_WIDTH+:`LOGICAL_CHANNEL_WIDTH];

            assign delayedAccumInputs[genChIdx] = delayedAccumInputsArray[genChIdx][0];

            always @(posedge clk) begin
                delayedAccumInputsArray[genChIdx][`TOTAL_LATENCY-1] <= accumInputs[genChIdx];

                for (dCtr = 0; dCtr <= `TOTAL_LATENCY-2; dCtr = dCtr + 1) begin
                    delayedAccumInputsArray[genChIdx][dCtr] <= delayedAccumInputsArray[genChIdx][dCtr+1];
                end
            end
        end
    endgenerate
	
endmodule
