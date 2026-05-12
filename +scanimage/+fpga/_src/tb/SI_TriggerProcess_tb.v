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

module SI_TriggerProcess_tb();

	integer periodClkPeriodExtend = 0; //*100ps

	reg sampleClk120 = 1;
	reg [31:0] DIO_I = 0;
	
	reg [15:0] acqParamTriggerHoldoff = 0;
	reg [4:0] acqParamPeriodTriggerChIdx = 31;
	reg [4:0] acqParamStartTriggerChIdx = 31;
	reg [4:0] acqParamNextTriggerChIdx = 31;
	reg [4:0] acqParamStopTriggerChIdx = 31;
	reg [4:0] acqParamPhotonChIdx = 28;
	reg [4:0] acqParamPeriodTriggerDebounce = 0;
	reg [4:0] acqParamTriggerDebounce = 0;
	reg [4:0] acqParamPhotonPulseDebounce = 0;
	reg acqParamLiveHoldoffAdjustEnable = 0;
	reg [15:0] acqParamLiveHoldoffAdjustPeriod = 0;
	
	wire [15:0] acqStatusPeriodTriggerPeriod;
	
	SI_TriggerProcess tp(
		.clk(sampleClk120),
		.DIO_I(DIO_I),
	
		.periodTriggerHoldoff(acqParamTriggerHoldoff),
		.periodTriggerChIdx(acqParamPeriodTriggerChIdx),
		.startTriggerChIdx(acqParamStartTriggerChIdx),
		.nextTriggerChIdx(acqParamNextTriggerChIdx),
		.stopTriggerChIdx(acqParamStopTriggerChIdx),
		.photonChIdx(acqParamPhotonChIdx),
		.periodTriggerDebounce(acqParamPeriodTriggerDebounce),
		.triggerDebounce(acqParamTriggerDebounce),
		.photonPulseDebounce(acqParamPhotonPulseDebounce),
		.liveHoldoffAdjustEnable(acqParamLiveHoldoffAdjustEnable),
		.liveHoldoffAdjustPeriod(acqParamLiveHoldoffAdjustPeriod),
	
		.periodClockPeriod(acqStatusPeriodTriggerPeriod)
	);
	
	// clk
	always begin
		#4.166
		sampleClk120 <= ~sampleClk120;
	end
	
	// period clk
	always begin
		#63160.750
		#(periodClkPeriodExtend)
		DIO_I[0] <= ~DIO_I[0];
		#16
		DIO_I[0] <= ~DIO_I[0];
		#16
		DIO_I[0] <= ~DIO_I[0];
	end
	
	initial begin
		#500000
		// set period clock channel
		acqParamPeriodTriggerChIdx <= 0;
		// observe correct pass through of period clock, period clock RE
		// mid period trigger probably doesn't look very good
		
		
		#500000
		// set period clock debounce
		acqParamPeriodTriggerDebounce <= 3;
		// observe cleaner period clock, proper mid period trigger
		
		
		#500000
		// set trigger holdoff
		acqParamTriggerHoldoff <= 45;
		// observe delay on triggers
		
		
		#500000
		// set live holdoff delay adjust
		acqParamLiveHoldoffAdjustPeriod <= 15168;
		acqParamLiveHoldoffAdjustEnable <= 1;
		// observe no change
		
		
		#500000
		// change resonant period
		periodClkPeriodExtend <= 83;
		// observe period increase by 20 and actual holdoff increase by 10
		
		
		#500000
		// set other channels
		acqParamStartTriggerChIdx = 1;
		acqParamNextTriggerChIdx = 2;
		acqParamStopTriggerChIdx = 3;
		acqParamPhotonChIdx = 4;
		
		//peturb channels and observe response
		#50
		DIO_I[1] <= 1;
		#30
		DIO_I[1] <= 0;
		
		#50
		DIO_I[2] <= 1;
		#30
		DIO_I[2] <= 0;
		
		#50
		DIO_I[3] <= 1;
		#30
		DIO_I[3] <= 0;
		
		#50
		DIO_I[4] <= 1;
		#30
		DIO_I[4] <= 0;
		
		#50
		DIO_I[5] <= 1;
		#30
		DIO_I[5] <= 0;
		
		#50
		DIO_I[6] <= 1;
		#30
		DIO_I[6] <= 0;
		
		#50
		DIO_I[7] <= 1;
		#30
		DIO_I[7] <= 0;
		
	end
	
	
endmodule
