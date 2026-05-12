//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ps

module SI_i2c_tb();

	reg sampleClk125 = 1;

	reg sda = 1;
	reg scl = 1;
	reg rst = 1;
	reg strt = 0;
	
	SI_I2C i2c(
		.clk(sampleClk125),
		.resetSm(rst),
		.startSm(strt),

		.debounce(5),
		.myAddress(35),
		.sdaChIdx(0),
		.sclChIdx(1),

		.DIO_I({scl,sda})
	);
	
	// clk
	always begin
		#4
		sampleClk125 <= ~sampleClk125;
	end

	reg [6:0] ctr = 0;
	localparam [86:0] sdaStream = 'b100000111111111111000111000000000111111000111000111111000000000111111000000000111000001;
	localparam [86:0] sclStream = 'b110010010010010010010010010010010010010010010010010010010010010010010010010010010010011;

	always begin
		#50
        sda <= sdaStream[ctr];
        scl <= sclStream[ctr];
		ctr<=ctr+1;
	end

	initial begin
		#16
		rst <= 0;

		#16
		strt <= 1;

		#8
		strt <= 0;
	end
	
	
endmodule
