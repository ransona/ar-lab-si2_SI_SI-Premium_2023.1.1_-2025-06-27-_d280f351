
set_property IOSTANDARD LVCMOS33 [get_ports spiClk]
set_property IOSTANDARD LVCMOS33 [get_ports cs]
set_property IOSTANDARD LVCMOS33 [get_ports sdi]
set_property IOSTANDARD LVCMOS33 [get_ports sdo]
set_property IOSTANDARD LVCMOS33 [get_ports sync]
set_property IOSTANDARD LVCMOS33 [get_ports extClockSelect]


set_property PACKAGE_PIN AP10 [get_ports spiClk]
set_property PACKAGE_PIN AP11 [get_ports cs]
set_property PACKAGE_PIN AH11 [get_ports sdi]
set_property PACKAGE_PIN AG11 [get_ports sdo]
set_property PACKAGE_PIN AM11 [get_ports sync]
set_property PACKAGE_PIN AJ11 [get_ports extClockSelect]




# SPI bus timing constraints
# The set_output_delay -max should be the setup requirement of the external device.
# The set_output_delay -min should be the negative of the hold requirement.

create_generated_clock -name cg_spi_clk -divide_by 4 -source [get_pins spiClkG_reg/C] [get_pins spiClkG_reg/Q]

set_output_delay -clock cg_spi_clk 2 [get_ports spiClk]

set_input_delay -clock cg_spi_clk -max 16.0 [get_ports sdi] -clock_fall
set_input_delay -clock cg_spi_clk -min  0.0 [get_ports sdi] -clock_fall

set_output_delay -clock cg_spi_clk -max  6.0 [get_ports cs]
set_output_delay -clock cg_spi_clk -min -0.1 [get_ports cs]

set_output_delay -clock cg_spi_clk -max  6.0 [get_ports sdo]
set_output_delay -clock cg_spi_clk -min -0.1 [get_ports sdo]

# these should really all be multicycle paths but the timing reqs are really easy
# to meet. no need to write complex xdc's
