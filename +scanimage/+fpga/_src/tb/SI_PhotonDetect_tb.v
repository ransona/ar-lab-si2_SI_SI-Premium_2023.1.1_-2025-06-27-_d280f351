//////////////////////////////////////////////////////////////////////////////////
// Company: Vidrio Technologies
// Engineer: Jonathan King
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns

module SI_PhotonDetect_tb ();

	reg clk = 1;
    reg [31:0] T = 0;
    always #5 clk <= ~clk;
    always #10 T <= T+1;


    reg [383:0] sampleData = 0;


    always @(posedge clk) begin
        if (T == 10)
            sampleData <= {
                12'd431,
                12'd5,
                12'd3,
                12'd8,
                12'd7,
                12'd40,
                12'd812,
                12'd950,
                12'd420,
                12'd45,
                12'd26,
                12'd520,
                12'd860,
                12'd920,
                12'd300,
                12'd37,
                12'd12,
                12'd7,
                12'd6,
                12'd480,
                12'd965,
                12'd960,
                12'd340,
                12'd1120,
                12'd1150,
                12'd320,
                12'd430,
                12'd45,
                12'd310,
                12'd43,
                12'd45,
                12'd4
            };
        else
            sampleData <= 0;
    end


    SI_PhotonDetect det(
        .dataClk(clk),
        .sampleData(sampleData),
        .threshold(300),
        .invert(0),
        .differentiateMode(0),
        .differentiateOrder(1)
    );

endmodule


