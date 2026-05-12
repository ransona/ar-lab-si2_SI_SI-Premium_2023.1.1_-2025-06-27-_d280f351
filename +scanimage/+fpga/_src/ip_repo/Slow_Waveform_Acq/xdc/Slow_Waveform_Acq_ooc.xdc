

create_clock -period 15 -name wr_clk [get_ports adcClk]
create_clock -period 6 -name rd_clk [get_ports axiClk]
create_clock -period 5 -name samp_clk [get_ports sampleClkTimebase]


