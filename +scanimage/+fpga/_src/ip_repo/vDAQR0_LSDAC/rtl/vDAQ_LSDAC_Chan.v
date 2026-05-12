//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQ_LSDAC_Chan (
	input  wire sysClk120,
	input  wire sysClk120Lvl,
	input  wire reset,
	
	input  wire loadSample,
	input  wire [15:0] data,
	output wire loadComplete,
	input  wire triggerImmediately,
	input  wire asyncTrigger,
	
	// SPI bus to device
	output wire cs,
	output wire sdo,
	output wire ldac,
	output wire rst
);
	(* IOB = "TRUE" *)
	reg csR = 1;
	assign cs = csR;
	
	(* IOB = "TRUE" *)
	reg sdoR = 0;
	assign sdo = sdoR;
	
	reg [1:0] rstR = 0;
	assign rst = !rstR;
	
	reg ldacImmediate = 0;
	reg ldacR = 1;
	assign ldac = ldacR && ~asyncTrigger;

	reg [4:0] ctr = 0;
	reg [14:0] dataBuf = 0;
	assign loadComplete = !ctr;


	(* ASYNC_REG = "TRUE" *)
	reg [1:0] loadSyncr;
	wire initiateLoad = loadSyncr[0];

	always @(posedge sysClk120) begin
		loadSyncr <= {loadSample, loadSyncr[1]};
		
		if (reset)
			rstR <= 3;
		else if (rstR)
			rstR <= rstR - 1;
	
		if (reset) begin
			ctr <= 0;
			csR <= 1;
			sdoR <= 1;
			ldacR <= 1;
		end else if (ctr) begin
			ldacR <= 1;
			if (sysClk120Lvl) begin
				ctr <= ctr - 1;
				
				csR <= ctr == 1;
				
				if ((ctr > 1) && (ctr < 17))
					sdoR <= dataBuf[ctr - 2];
			end
		end else if (ldacImmediate) begin
			if (sysClk120Lvl) begin
				ldacImmediate <= 0;
				ldacR <= 0;
			end
		end else if (initiateLoad) begin
			dataBuf <= data[14:0];
			ctr <= 18 + ~sysClk120Lvl;
			ldacImmediate <= triggerImmediately;
			
			if (sysClk120Lvl)
				ldacR <= 1;
			
			sdoR <= data[15];
			csR <= ~sysClk120Lvl;
		end else if (sysClk120Lvl) begin
			ldacR <= 1;
			csR <= 1;
		end
	end

endmodule
