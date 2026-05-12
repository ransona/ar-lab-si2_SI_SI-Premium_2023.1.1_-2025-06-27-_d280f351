//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module HSD_LSADC (
	input  wire clk120,
	input  wire spiClkEn,
	output wire dataClk,
	
	input  wire [3:0] startConv,
	output wire [3:0] convDone,
	output wire [63:0] data,
	
	// SPI bus to device
	output wire spiClk,
	output wire [3:0] cnv,
	inout wire [3:0] sdi
);
	wire mmcmFbClk;
	reg [3:0] mmcmReset = 15;
	wire spiClkG;
	wire spiClkPhaseRef;
	wire [3:0]captureClk;
	wire [3:0]captureClk_b;
	wire cnvClk;
	
	// Generate SPI and capture clocks
	always @(posedge clk120)
		if(mmcmReset)
			mmcmReset <= mmcmReset - 1;
	
	MMCME3_BASE #(
        .CLKFBOUT_MULT_F(8.375), // Multiply value for all CLKOUT (2.000-64.000)
        .CLKIN1_PERIOD(8.333), // Input clock period in ns units, ps resolution (i.e. 33.333 is 30 MHz).
        .CLKOUT0_DIVIDE_F(9), // Divide amount for CLKOUT0 (1.000-128.000)
        .CLKOUT1_PHASE(100),
        .CLKOUT2_PHASE(100),
        .CLKOUT3_PHASE(100),
        .CLKOUT4_PHASE(95),
        .CLKOUT5_PHASE(90),
        .CLKOUT6_PHASE(2.500), // phase resolution is 2.5 deg (45 / CLKOUTn_DIVIDE)
        .CLKOUT1_DIVIDE(18),
        .CLKOUT2_DIVIDE(18),
        .CLKOUT3_DIVIDE(18),
        .CLKOUT4_DIVIDE(18),
        .CLKOUT5_DIVIDE(18),
        .CLKOUT6_DIVIDE(18)
    ) mmcm_inst (
        .CLKOUT0(spiClkG), // 1-bit output: CLKOUT0
        .CLKOUT1(captureClk_b[0]), // 1-bit output: CLKOUT1
        .CLKOUT2(captureClk_b[1]), // 1-bit output: CLKOUT2
        .CLKOUT3(captureClk_b[2]), // 1-bit output: CLKOUT3
        .CLKOUT4(captureClk_b[3]), // 1-bit output: CLKOUT4
        .CLKOUT5(spiClkPhaseRef), // 1-bit output: CLKOUT5
        .CLKOUT6(cnvClk), // 1-bit output: CLKOUT6
        .CLKFBOUT(mmcmFbClk), // 1-bit output: Feedback clock
        .CLKIN1(clk120), // 1-bit input: Clock
        .RST(mmcmReset > 0), // 1-bit input: Reset
        .CLKFBIN(mmcmFbClk) // 1-bit input: Feedback clock
    );

	
	(* IOB = "TRUE" *)
	reg spiClkR_o = 0;
	OBUF spiClk_buf(.I(spiClkR_o), .O(spiClk));
	
	always @(posedge spiClkG)
		spiClkR_o <= spiClkPhaseRef && spiClkEn;
	
	
	assign dataClk = cnvClk;

	
	// Generate cnv signal and capture data for each channel
	genvar i;
	generate
		for (i = 0; i < 4; i = i+1) begin : gen_adc_chans
			
			wire cnv_b;
			wire sdi_b;
			wire sdo;
			
			(* IOB = "TRUE" *)
			reg sdir = 0;
			
			OBUF cnv_buf(.I(cnv_b), .O(cnv[i]));
			IOBUF sdi_buf(.I(1'b1), .O(sdi_b), .IO(sdi[i]), .T(~sdo));
			
			BUFGCE captureClk_bufg(.I(captureClk_b[i]), .O(captureClk[i]));
			
			always @(posedge captureClk[i])
				sdir <= sdi_b;
			
			HSD_LSADC_Chan adc_chan_inst (
				.dataClk(cnvClk),
				.startConv(startConv[i]),
				.convDone(convDone[i]),
				.data(data[i*16+:16]),
				.cnv(cnv_b),
				.sdi(~sdir),
				.sdo(sdo)
			);
		end
	endgenerate
	
endmodule

