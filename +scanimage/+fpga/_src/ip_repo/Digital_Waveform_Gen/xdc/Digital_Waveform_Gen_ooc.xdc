
create_clock -period 5 -name wr_clk [get_ports sampleClkTimebase]
create_clock -period 6 -name rd_clk [get_ports axiClk]
