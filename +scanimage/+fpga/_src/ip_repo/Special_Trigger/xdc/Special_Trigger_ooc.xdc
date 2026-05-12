
create_clock -period 10 -name wr_clk [get_ports sampleClkTimebase]
create_clock -period 8 -name rd_clk [get_ports axiClk]
