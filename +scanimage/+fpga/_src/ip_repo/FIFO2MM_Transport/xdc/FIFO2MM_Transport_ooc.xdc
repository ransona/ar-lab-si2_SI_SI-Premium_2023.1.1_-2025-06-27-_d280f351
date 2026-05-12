

create_clock -period 5 -name wr_clk [get_ports inputClk]

create_clock -period 5 -name rd_clk [get_ports axiClk]


