//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ps

module SI_RTB_tb();

	integer periodClkPeriodExtend = 0; //*100ps

	reg sampleClk125 = 1;
	reg [31:0] DIO_I = 0;
    reg signed [12:0] rando = 0;
    wire tbo;
	
	SI_TriggerProcess tp(
		.clk(sampleClk125),
		.DIO_I(DIO_I),
	
		.periodTriggerChIdx(0),
		.periodTriggerDebounce(5),

        .aeTimebaseOut(tbo),

        .acqParamPeriodTriggerSettledThresh(2),
        .acqParamTimebasePulsesPerPeriod(625),
        .acqParamPeriodTriggerMaxPeriod(16000),
        .acqParamSimulatedResonantPeriod(0)
	);
	
	// clk
	always begin
		#4
		sampleClk125 <= ~sampleClk125;
	end

    reg ptb = 1;
    reg [31:0] tbc = 0;
	always begin
		#1
        if (tbo && ~ptb)
            tbc <= tbc + 1;
		ptb = tbo;
	end
	
	// period clk
	always begin
      rando = $random;
		#(63211.125 + rando)
		DIO_I[0] <= ~DIO_I[0];
	end
	
	
endmodule
