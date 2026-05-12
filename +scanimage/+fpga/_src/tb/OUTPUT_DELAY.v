//////////////////////////////////////////////////////////////////////////////////
// Company: MBF Bioscience, Vidrio Technologies
// Engineer: Nelson Downs
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module OUTPUT_DELAY #(
	parameter integer MATCH_DELAY = 0,
	parameter integer CURRENT_DELAY = 0,
	parameter integer BIT_WIDTH = 10
)(
	input  wire clock,
	input  wire [BIT_WIDTH-1:0] dataIn,
	output wire [BIT_WIDTH-1:0] delayedDataOut
);
	localparam integer REQUIRED_PIPELINE_DELAY = (MATCH_DELAY > CURRENT_DELAY) ? MATCH_DELAY - CURRENT_DELAY : 0;

	generate
		if (REQUIRED_PIPELINE_DELAY > 0) begin
			reg [BIT_WIDTH-1:0] delayRegs[REQUIRED_PIPELINE_DELAY-1:0];

			genvar i;
			for (i = 1; i < REQUIRED_PIPELINE_DELAY; i = i + 1) begin
				always @(posedge clock)
					delayRegs[i] <= delayRegs[i-1];
			end

			always @(posedge clock)
				delayRegs[0] <= dataIn;

			assign delayedDataOut = delayRegs[REQUIRED_PIPELINE_DELAY-1];
		end else begin
			assign delayedDataOut = dataIn;
		end
	endgenerate
endmodule
