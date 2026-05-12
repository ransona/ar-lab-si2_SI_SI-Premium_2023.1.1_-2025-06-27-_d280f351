
create_clock -name pcie_ooc_clk -period 8 [get_ports pcie_aclk]
create_clock -name io_ooc_clk -period 12.5 [get_ports ioClk80]
create_clock -name aux_ooc_clk -period 3.7 [get_ports auxClkIn]
create_clock -name lsadc_ooc_clk -period 15 [get_ports LSADC_o[204]]
