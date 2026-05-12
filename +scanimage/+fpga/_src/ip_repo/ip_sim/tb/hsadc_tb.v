//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module vDAQ_HSADC_tb();

    reg aclk = 1;
    reg arstn = 0;
    reg adc_sdo = 0;
    reg adc_ts = 1;

    reg [12:0] awaddr = 0;
    reg        awvalid = 0;
    reg [31:0] wdata = 0;
    reg        wvalid = 0;

    reg [12:0] araddr = 0;
    reg        arvalid = 0;
    
    wire sdio = adc_ts ? 1'hZ : adc_sdo;

    always begin
        #4
        aclk <= ~aclk;
    end

    initial begin
        #160
        arstn <= 1;

        // #24
        // awaddr <= 12;
        // wdata <= {8'd5, 8'd87};
        // awvalid <= 1;
        // wvalid <= 1;
        // #8
        // awvalid <= 0;
        // wvalid <= 0;

        // #24
        // awaddr <= 8;
        // wdata <= {2'd1, 1'b0, 15'h4765}; // # words, rd?, addr
        // awvalid <= 1;
        // wvalid <= 1;
        // #8
        // awvalid <= 0;
        // wvalid <= 0;

        #48
        araddr <= 4;
        arvalid <= 1;
        #8
        arvalid <= 0;

        #24
        araddr <= 1024+44;
        arvalid <= 1;
        #8
        arvalid <= 0;

        #24
        araddr <= 2048;
        arvalid <= 1;
    end


    vDAQ_HSADC hsadc (
        .axiClk(aclk),
        .axiResetN(arstn),
        
        // SAXIL control/config bus
        .SAXIL_CFG_AWADDR(awaddr),
        .SAXIL_CFG_AWVALID(awvalid),
        .SAXIL_CFG_WDATA(wdata),
        .SAXIL_CFG_WSTRB(4'hF),
        .SAXIL_CFG_WVALID(wvalid),
        .SAXIL_CFG_BREADY(1),
        .SAXIL_CFG_ARADDR(araddr),
        .SAXIL_CFG_ARVALID(arvalid),
        .SAXIL_CFG_RREADY(1),
        
        .adc_sdio(sdio)
    );

endmodule

