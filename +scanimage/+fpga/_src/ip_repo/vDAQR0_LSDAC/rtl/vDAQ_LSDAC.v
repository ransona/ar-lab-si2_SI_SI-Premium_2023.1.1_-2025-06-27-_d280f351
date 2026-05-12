//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQ_LSDAC (
	input wire sysClk120,
	input wire reset,
	input wire spiClkEn,
	
	input  wire [4:0]  loadSample,
	input  wire [79:0] data,
	output wire [4:0]  loadComplete,
	input  wire [4:0]  triggerImmediately,
	input  wire [4:0]  asyncTrigger,
	input  wire [4:0]  reset_i,
	
	// SPI bus to devices
	output wire CLK,
	output wire [4:0] CS,
	output wire [4:0] LDAC,
	output wire [4:0] RST,
	output wire [4:0] SDO
);
	(* IOB = "TRUE" *)
	reg spiClkR = 0;
	reg [1:0] sysClk120ctr = 0;
	
	OBUF CLK_buf(.I(spiClkR), .O(CLK));
	
	always @(posedge sysClk120) begin
		sysClk120ctr <= (sysClk120ctr < 2) ? sysClk120ctr + 1 : 0;
		spiClkR <= !sysClk120ctr;
	end
	
	genvar i_dac;
	generate
		for (i_dac = 0; i_dac < 5; i_dac = i_dac+1) begin : gen_dac_chans
			wire CS_b;
			wire LDAC_b;
			wire RST_b;
			wire SDO_b;
			
			OBUF CS_buf(.I(CS_b), .O(CS[i_dac]));
			OBUF LDAC_buf(.I(LDAC_b), .O(LDAC[i_dac]));
			OBUF RST_buf(.I(RST_b), .O(RST[i_dac]));
			OBUF SDO_buf(.I(SDO_b), .O(SDO[i_dac]));
			
			vDAQ_LSDAC_Chan chanInst(
				.sysClk120(sysClk120),
				.sysClk120Lvl(sysClk120ctr == 1),
				.reset(reset || reset_i[i_dac]),
				
				.loadSample(loadSample[i_dac]),
				.data(data[i_dac*16+:16]),
				.loadComplete(loadComplete[i_dac]),
				.triggerImmediately(triggerImmediately[i_dac]),
				.asyncTrigger(asyncTrigger[i_dac]),
				
				// SPI bus to device
				.cs(CS_b),
				.sdo(SDO_b),
				.ldac(LDAC_b),
				.rst(RST_b)
			);
		end
	endgenerate
	

endmodule

