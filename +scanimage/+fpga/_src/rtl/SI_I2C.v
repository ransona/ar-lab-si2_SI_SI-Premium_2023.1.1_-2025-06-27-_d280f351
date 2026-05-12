//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module SI_I2C (
	// clk/reset
	input  wire clk,
	input  wire resetSm,
	input  wire startSm,
	
	// params/settings
	input  wire [4:0] debounce,
	input  wire [6:0] myAddress,
	input  wire [4:0] sdaChIdx,
	input  wire [4:0] sclChIdx,
	
	// input signals
	input  wire [31:0] DIO_I,
	
	// output signals
	output wire ackAtv,
	
	// output data
	output wire dataValid,
	output wire packetStart,
	output wire packetEnd,
	output wire [7:0] packetData
);
	wire sda;
	wire sdaFE;
	wire sdaRE;
	wire sclRE;
	wire sclFE;
	wire scl;
	
	inputDebounce sdaInput(.clk(clk), .sigIn(DIO_I[sdaChIdx]), .sigOut(sda), .sigOutRE(sdaRE), .sigOutFE(sdaFE), .debounceTime(debounce));
	inputDebounce sclInput(.clk(clk), .sigIn(DIO_I[sclChIdx]), .sigOut(scl), .sigOutRE(sclRE), .sigOutFE(sclFE), .debounceTime(debounce));
	
	reg idle = 1;
	reg [6:0] packetData_o = 0;
	assign packetData = {packetData_o, sda};
	
	reg addrRead = 1;
	reg [3:0] bitCtr = 0;
	
	wire messageStart = scl && sdaFE;
	wire addrCheckTime = addrRead && (bitCtr == 4);
	wire assertAckTime = sclFE && (bitCtr == 2);
	wire deassertAckTime = sclFE && (bitCtr == 1);
	
	reg [6:0] addrReg = 0;
	wire [6:0] packetAddress = {addrReg[6:1], sda};
	wire correctAddress = packetAddress == myAddress;
	reg sendMsg = 0;

	reg ackAtvR = 0;
	assign ackAtv = ackAtvR;
	
	always @(posedge clk) begin
		if (idle || resetSm) begin
			bitCtr <= 0;
			sendMsg <= 0;
			
			idle <= resetSm || ~startSm;
		end else if (packetEnd) begin
			bitCtr <= 0;
			sendMsg <= 0;
		end else if (bitCtr) begin
		
			if (sclRE) begin
				if (addrCheckTime && correctAddress)
					sendMsg <= 1;

				if (addrCheckTime && ~correctAddress) begin
					bitCtr <= 0;
					sendMsg <= 0;
				end else
					bitCtr <= bitCtr - 1;
				
				if (bitCtr >= 4)
					if (addrRead)
						addrReg[bitCtr-4] <= sda;
					else
						packetData_o[bitCtr-4] <= sda;

			end else if (sclFE && (bitCtr == 1)) begin
				addrRead <= 0;
				bitCtr <= 10;
			end
		
		end else if (messageStart) begin
			addrRead <= 1;
			bitCtr <= 10;
		end
		
		
		if (idle || resetSm || deassertAckTime || packetEnd || !bitCtr)
			ackAtvR <= 0;
		else if (assertAckTime)
			ackAtvR <= 1;
	end
	
	assign packetStart = sclRE && addrCheckTime && correctAddress;
	assign packetEnd = scl && sdaRE && sendMsg;
	assign dataValid = packetStart || packetEnd || (sclRE && (bitCtr == 3) && ~addrRead);
	
endmodule
