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
`timescale 1 ns / 1 ps

module SI_tb();

	reg sampleClk120 = 1;
	reg resetn = 0;
	reg [31:0] DIO_I = 0;
	
	reg cfgWriteActive = 0;
	reg [16:0] cfgWriteAddr = 0;
	reg [31:0] cfgWriteData = 0;
	
	reg signed [13:0] msadc_ch1Data = 0;
	reg signed [13:0] msadc_ch2Data = 1000;
	reg signed [13:0] msadc_ch3Data = -5000;
	reg signed [13:0] msadc_ch4Data = 243;
	
	reg [9:0] mskI = 3;
	
	
	reg [63:0] systemClock = 0;
	always @(posedge sampleClk120)
		systemClock <= systemClock + 1;
		
	wire dataFifoWr;
	reg  [31:0] dataFifoWrCount = 0;
	
	
	SI hSI (
		.sampleClk(sampleClk120),
		.cfgClk(sampleClk120),
		.resetn(resetn),
		
		.systemClock(systemClock),
	
		.cfgWriteActive(cfgWriteActive),
		.cfgWriteAddr(cfgWriteAddr),
		.cfgWriteData(cfgWriteData),
		.cfgReadAddr(),
		.cfgReadData(),
	
		.adcSamplesIn({msadc_ch4Data, msadc_ch3Data, msadc_ch2Data, msadc_ch1Data}),
	
		.DIO_I({DIO_I[39:24], DIO_I[15:0]}),  // {rtsi 15:0, G1.7:0, G0.7:0} (group 2 is for outputs)
		
		.dataFifoFull(),
		.dataFifoWriteEn(dataFifoWr),
		.dataFifoData(),
	
		.triggerFifoFull(),
		.triggerFifoWriteEn(),
		.triggerFifoData()
	);
	
	// 120 mhz sample clk
	always begin
		#4.166
		sampleClk120 <= ~sampleClk120;
		#4.166
		sampleClk120 <= ~sampleClk120;
		
		//sim analog data
		msadc_ch1Data <= msadc_ch1Data + 1;
		msadc_ch2Data <= msadc_ch2Data - 1;
		msadc_ch3Data <= msadc_ch3Data + 1;
		msadc_ch4Data <= msadc_ch4Data - 1;
		
		if (dataFifoWr)
			dataFifoWrCount <= dataFifoWrCount + 1;
	end
	
	// period clk
	always begin
		// 80k resonant mirror
		#6316.0750
		DIO_I[0] <= ~DIO_I[0];
		#16
		DIO_I[0] <= ~DIO_I[0];
		#16
		DIO_I[0] <= ~DIO_I[0];
	end
	
	initial begin
		#41660
		resetn <= 1;
		// set period clock debounce
		cfgWriteActive <= 1;
		cfgWriteAddr <= 140;
		cfgWriteData <= 4;
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// trigger holdoff
		cfgWriteActive <= 1;
		cfgWriteAddr <= 156;
		cfgWriteData <= 105;
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// trigger holdoff
		cfgWriteActive <= 1;
		cfgWriteAddr <= 156;
		cfgWriteData <= 105;
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// beam holdoff
		cfgWriteActive <= 1;
		cfgWriteAddr <= 180;
		cfgWriteData <= 52;
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// beam duration
		cfgWriteActive <= 1;
		cfgWriteAddr <= 184;
		cfgWriteData <= 1410;
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// samples per line
		cfgWriteActive <= 1;
		cfgWriteAddr <= 168;
		cfgWriteData <= 1300;
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// period trigger settled thresh
		cfgWriteActive <= 1;
		cfgWriteAddr <= 240;
		cfgWriteData <= 2;
		#8.333
		cfgWriteActive <= 0;
		
		
		
		////// acq plan. collect 12, flyback 4
		
		#8.333
		// num steps
		cfgWriteActive <= 1;
		cfgWriteAddr <= 108;
		cfgWriteData <= 2;
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// collect 12
		cfgWriteActive <= 1;
		cfgWriteAddr <= 104;
		cfgWriteData <= {11'd0, 1'b1, 1'b1, 7'd6};
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// flyback 4
		cfgWriteActive <= 1;
		cfgWriteAddr <= 104;
		cfgWriteData <= {11'd1, 1'b1, 1'b0, 7'd2};
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// dummy
		cfgWriteActive <= 1;
		cfgWriteAddr <= 104;
		cfgWriteData <= {11'd2, 1'b1, 1'b0, 7'd0};
		#8.333
		cfgWriteActive <= 0;
		
		
		
		/////// mask
		
		#8.333
		// mask size
		cfgWriteActive <= 1;
		cfgWriteAddr <= 116;
		cfgWriteData <= 51;
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// 28
		cfgWriteActive <= 1;
		cfgWriteAddr <= 112;
		cfgWriteData <= {10'd0, 10'd28};
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// 25
		cfgWriteActive <= 1;
		cfgWriteAddr <= 112;
		cfgWriteData <= {10'd1, 10'd25};
		#8.333
		cfgWriteActive <= 0;
		
		#8.333
		// 22
		cfgWriteActive <= 1;
		cfgWriteAddr <= 112;
		cfgWriteData <= {10'd2, 10'd22};
		#8.333
		cfgWriteActive <= 0;
		
		for (mskI = 3; mskI <= 51; mskI = mskI + 1) begin
			#8.333
			// 49*25
			cfgWriteActive <= 1;
			cfgWriteAddr <= 112;
			cfgWriteData <= {mskI, 10'd25};
			#8.333
			cfgWriteActive <= 0;
		end
		
		#83.33
		// reset sm
		cfgWriteActive <= 1;
		cfgWriteAddr <= 100;
		cfgWriteData <= 38;
		#8.333
		cfgWriteActive <= 0;
		
		#83.33
		// start sm
		cfgWriteActive <= 1;
		cfgWriteAddr <= 100;
		cfgWriteData <= 37;
		#8.333
		cfgWriteActive <= 0;
		
		#83.33
		// soft trig
		cfgWriteActive <= 1;
		cfgWriteAddr <= 100;
		cfgWriteData <= 39;
		#8.333
		cfgWriteActive <= 0;
		
		#41660
		// start trigger
		DIO_I[1] <= 1;
		#83.33
		DIO_I[1] <= 0;
	end
	
	
endmodule
