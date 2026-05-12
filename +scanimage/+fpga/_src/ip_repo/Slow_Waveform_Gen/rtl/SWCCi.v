//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module SWCCi #(
	parameter [7:0] WW = 32,
	parameter [WW-1:0] IV = 0,
	parameter CONTINUOUS = 1
)(
	input wire [WW-1:0] srcV,
	input wire srcClk,
	output reg [WW-1:0] dstV = IV,
	output wire newVal,
	input wire dstClk,
	input wire dstRst
);
	
	reg scWasEq = 1;
	reg del = 0;
	reg scReq = 0;
	wire scRst;
	wire scAck;
	reg [WW-1:0] valSample = 0;

	wire sendNewVal = CONTINUOUS || (valSample != srcV);
	
	always @(posedge srcClk) begin
		if (scRst) begin
			valSample <= IV;
			scReq <= 0;
			scWasEq <= 1;
		end else if ((scReq == scAck) && sendNewVal) begin
			valSample <= srcV;
			scReq <= ~scReq;
		end
	end
	
	
	wire dcReq;
	reg dcWasEq = 1;
	reg dcAck = 0;
	
	wire nv = ((dcAck != dcReq) && dcWasEq);
	reg nvr = 0;
	assign newVal = nvr;
	
	always @(posedge dstClk) begin
		if (dstRst) begin
			dcAck <= 0;
			dstV <= IV;
			dcWasEq <= 1;
		end else begin
			dcWasEq <= dcAck == dcReq;
			dcAck <= dcReq;
			
			if (nv)
				dstV <= valSample;
				
			nvr <= nv;
		end
	end
	
	SBCCi req_crssr(.srcV(scReq), .srcClk(srcClk), .dstV(dcReq), .dstClk(dstClk));
	SBCCi ack_crssr(.srcV(dcAck), .srcClk(dstClk), .dstV(scAck), .dstClk(srcClk));
	SBCCi rst_crssr(.srcV(dstRst), .srcClk(dstClk), .dstV(scRst), .dstClk(srcClk));
	
endmodule

