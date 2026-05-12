
# IO Standards
set_property IOSTANDARD LVCMOS18 [get_ports cnv[0]]
set_property IOSTANDARD LVCMOS18 [get_ports sdi[0]]
set_property IOSTANDARD LVCMOS18 [get_ports cnv[1]]
set_property IOSTANDARD LVCMOS18 [get_ports sdi[1]]
set_property IOSTANDARD LVCMOS18 [get_ports cnv[2]]
set_property IOSTANDARD LVCMOS18 [get_ports sdi[2]]
set_property IOSTANDARD LVCMOS18 [get_ports cnv[3]]
set_property IOSTANDARD LVCMOS18 [get_ports sdi[3]]
set_property IOSTANDARD LVCMOS18 [get_ports spiClk]

# LOC IO Pins
set_property PACKAGE_PIN K13 [get_ports cnv[0]]
set_property PACKAGE_PIN C11 [get_ports sdi[0]]
set_property PACKAGE_PIN F12 [get_ports cnv[1]]
set_property PACKAGE_PIN J11 [get_ports sdi[1]]
set_property PACKAGE_PIN L9 [get_ports cnv[2]]
set_property PACKAGE_PIN H8 [get_ports sdi[2]]
set_property PACKAGE_PIN J8 [get_ports cnv[3]]
set_property PACKAGE_PIN L12 [get_ports sdi[3]]
set_property PACKAGE_PIN K11 [get_ports spiClk]

# embolden ios
set_property SLEW  FAST [get_ports spiClk]
set_property SLEW  FAST [get_ports cnv[*]]


# LOC primitives to reliably reach timing closure
#set_property LOC MMCME3_ADV_X1Y2 [get_cells mmcm_inst]
#set_property LOC BUFGCE_X1Y50 [get_cells outputClk_bufg]
#set_property LOC BUFGCE_X1Y54 [get_cells gen_adc_chans[0].captureClk_bufg]
#set_property LOC BUFGCE_X1Y52 [get_cells gen_adc_chans[1].captureClk_bufg]
#set_property LOC BUFGCE_X1Y51 [get_cells gen_adc_chans[2].captureClk_bufg]
#set_property LOC BUFGCE_X1Y49 [get_cells gen_adc_chans[3].captureClk_bufg]


# clocks
create_generated_clock -name lsadc_spi_clk -divide_by 2 -source [get_pins spiClkR_o_reg/C] [get_ports spiClk]
create_generated_clock -name lsadc_spi_capture_clk0 [get_pins mmcm_inst/CLKOUT1]
create_generated_clock -name lsadc_spi_capture_clk1 [get_pins mmcm_inst/CLKOUT2]
create_generated_clock -name lsadc_spi_capture_clk2 [get_pins mmcm_inst/CLKOUT3]
create_generated_clock -name lsadc_spi_capture_clk3 [get_pins mmcm_inst/CLKOUT4]
create_generated_clock -name lsadc_data_clk [get_pins mmcm_inst/CLKOUT6]


# timing exception for async conv start
set_false_path -through [get_ports startConv[*]]
set_false_path -through [get_ports spiClkEn]
set_false_path -from [get_cells gen_adc_chans[*].adc_chan_inst/startFF_reg[*]] -to [get_clocks lsadc_spi_clk]
set_false_path -through [get_pins gen_adc_chans[*].sdi_buf/T]


# dummy output delay for spi clock
set_output_delay -clock lsadc_spi_clk 2 [get_ports spiClk]


# the earliest we can change cnv is 0.05ns after the launching falling clock edge
set_output_delay -clock lsadc_spi_clk -0.05 -min [get_ports cnv[*]]
# the latest we can change cnv is 3.5ns after an spi clock edge
set spi_clk_period [get_property PERIOD [get_clocks lsadc_spi_clk]]
set cnv_output_delay [expr {$spi_clk_period - 3.5}]
set_output_delay -clock lsadc_spi_clk  $cnv_output_delay -max [get_ports cnv[*]]


# the sending device launches data on lsadc_spi_clk. we capture data on lsadc_spi_capture_clk
# lsadc_spi_capture_clk is phase delayed WRT lsadc_spi_clk. We are indicating that when data is
# launched by lsadc_spi_clk, is is captured two edges later on lsadc_spi_capture_clk, not the next edge
set_multicycle_path -setup 2 -from [get_clocks lsadc_spi_clk] -to [get_clocks lsadc_spi_capture_clk*]

# Input delays. From AD7903 datasheet:
# spi_clk falling edge to old data still valid = 3ns;   <- hold time req
# spi_clk falling edge to new data valid = 16ns;        <- setup time req
# we allow cnv to fall 3.5ns after spi clk
# cnv -> data valid is 15ns. therefore:
# spi_clk falling edge to new data valid = 18.5ns;        <- setup time req (another)

#set_input_delay -clock lsadc_spi_clk -max 18.5+longest_prop_delay  [get_ports sdi[*]]  <- can't quite meet this but it works anyway
#set_input_delay -clock lsadc_spi_clk -min  3.0+shortest_prop_delay [get_ports sdi[*]]

# FPGA -> LSADC_CLK0 = 0.677ns, LSADC_SDO0 -> FPGA = 0.617ns, Total prop delay = 1.294ns
# 16+prop delay, 3+prop delay
set_input_delay -clock lsadc_spi_clk -max 19.3 [get_ports sdi[0]]
set_input_delay -clock lsadc_spi_clk -min 4.294 [get_ports sdi[0]]

# FPGA -> LSADC_CLK1 = 0.645ns, LSADC_SDO1 -> FPGA = 0.600ns, Total prop delay = 1.245ns
set_input_delay -clock lsadc_spi_clk -max 19.3 [get_ports sdi[1]]
set_input_delay -clock lsadc_spi_clk -min 4.245 [get_ports sdi[1]]

# FPGA -> LSADC_CLK2 = 0.560ns, LSADC_SDO2 -> FPGA = 0.557ns, Total prop delay = 1.117ns
set_input_delay -clock lsadc_spi_clk -max 19.3 [get_ports sdi[2]]
set_input_delay -clock lsadc_spi_clk -min 4.13 [get_ports sdi[2]]

# FPGA -> LSADC_CLK3 = 0.531ns, LSADC_SDO3 -> FPGA = 0.505, Total prop delay = 1.036ns
set_input_delay -clock lsadc_spi_clk -max 19.3 [get_ports sdi[3]]
set_input_delay -clock lsadc_spi_clk -min 4.036 [get_ports sdi[3]]
