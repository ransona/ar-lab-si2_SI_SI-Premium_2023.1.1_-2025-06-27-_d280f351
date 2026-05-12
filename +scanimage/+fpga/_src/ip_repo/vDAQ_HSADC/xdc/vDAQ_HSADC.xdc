
set_property IOSTANDARD LVCMOS18 [get_ports clckg_*]

set_property PACKAGE_PIN C21 [get_ports clckg_sclk]
set_property PACKAGE_PIN C22 [get_ports clckg_csb]
set_property PACKAGE_PIN A20 [get_ports clckg_mosi]
set_property PACKAGE_PIN D20 [get_ports clckg_miso]
set_property PACKAGE_PIN B20 [get_ports clckg_sync]


set_property IOSTANDARD LVCMOS18 [get_ports adc_sclk]
set_property IOSTANDARD LVCMOS18 [get_ports adc_csb]
set_property IOSTANDARD LVCMOS18 [get_ports adc_sdio]
set_property IOSTANDARD LVCMOS18 [get_ports adc_pdwn]
set_property IOSTANDARD LVCMOS18 [get_ports adc_gpio_a[*]]
set_property IOSTANDARD LVCMOS18 [get_ports adc_gpio_b[*]]

set_property PACKAGE_PIN D24 [get_ports adc_sclk]
set_property PACKAGE_PIN D23 [get_ports adc_csb]
set_property PACKAGE_PIN C24 [get_ports adc_sdio]
set_property PACKAGE_PIN D28 [get_ports adc_pdwn]
set_property PACKAGE_PIN E23 [get_ports adc_gpio_a[0]]
set_property PACKAGE_PIN E22 [get_ports adc_gpio_a[1]]
set_property PACKAGE_PIN B21 [get_ports adc_gpio_b[0]]
set_property PACKAGE_PIN B22 [get_ports adc_gpio_b[1]]


set_property PACKAGE_PIN P6 [get_ports adc_refclk_p]
set_property PACKAGE_PIN P5 [get_ports adc_refclk_n]

set_property PACKAGE_PIN E25 [get_ports sysref_p]
set_property PACKAGE_PIN D25 [get_ports sysref_n]
set_property IOSTANDARD LVDS [get_ports sysref_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports sysref_p]

set_property PACKAGE_PIN C26 [get_ports adc_syncb_p]
set_property PACKAGE_PIN B26 [get_ports adc_syncb_n]
set_property IOSTANDARD LVDS [get_ports adc_syncb_p]



# Clock cfg SPI bus timing constraints
# SPI clock is sufficiently slow to rough these in

# these should really all be multicycle paths but the timing reqs
# are really easy to meet. no need to write complex xdc's

#create_generated_clock -name hsadc_cg_spi_clk -divide_by 16 -source [get_pins CLK_CFG/spiClkG_reg/C] [get_pins CLK_CFG/spiClkG_reg/Q]

#set_output_delay -clock hsadc_cg_spi_clk 2 [get_ports clckg_sclk]

#set_input_delay -clock hsadc_cg_spi_clk -max 16.0 [get_ports clckg_miso] -clock_fall
#set_input_delay -clock hsadc_cg_spi_clk -min  0.0 [get_ports clckg_miso] -clock_fall

#set_output_delay -clock hsadc_cg_spi_clk -max  6.0 [get_ports clckg_csb]
#set_output_delay -clock hsadc_cg_spi_clk -min -0.1 [get_ports clckg_csb]

#set_output_delay -clock hsadc_cg_spi_clk -max  6.0 [get_ports clckg_mosi]
#set_output_delay -clock hsadc_cg_spi_clk -min -0.1 [get_ports clckg_mosi]



# ADC cfg SPI bus timing constraints
# SPI clock is sufficiently slow to rough these in

# these should really all be multicycle paths but the timing reqs
# are really easy to meet. no need to write complex xdc's

#create_generated_clock -name hsadc_spi_clk -divide_by 4 -source [get_pins spiClkG_reg/C] [get_pins spiClkG_reg/Q]

#set_output_delay -clock hsadc_spi_clk 2 [get_ports adc_sclk]

#set_input_delay -clock hsadc_spi_clk -max 16.0 [get_ports adc_sdio] -clock_fall
#set_input_delay -clock hsadc_spi_clk -min  0.0 [get_ports adc_sdio] -clock_fall

#set_output_delay -clock hsadc_spi_clk -max  6.0 [get_ports adc_csb]
#set_output_delay -clock hsadc_spi_clk -min -0.1 [get_ports adc_csb]

#set_output_delay -clock hsadc_spi_clk -max  6.0 [get_ports adc_sdio]
#set_output_delay -clock hsadc_spi_clk -min -0.1 [get_ports adc_sdio]



# sample buffer timing constraints
set smpClk [get_clocks -of_objects [get_pins sampleClkPll/CLKOUT0]]
set smpClkPeriod [get_property -min PERIOD $smpClk]
set dataMaxDelay [expr {$smpClkPeriod * 0.75}]

set_max_delay -from [get_cells -include_replicated_objects channel*_lclBuf_reg[*][*]] -datapath_only $dataMaxDelay
set_max_delay -from [get_cells -include_replicated_objects syncTrigReset_lclBuf_reg*] -datapath_only $dataMaxDelay

set_max_delay -from [get_cells lclBufValid_reg] -to [get_cells lclBufValidCC_reg[0]] -datapath_only 2.0
set_max_delay -from [get_cells sampleClkPll] -to [get_cells lockedCC_reg[0]] -datapath_only 2.0

# This implementation will only allow fsx4 mode to reduce resource utilization and aid timing cloture
#set_false_path -from [get_cells -include_replicated_objects fsx4_mode_reg*]
#set_false_path -from [get_cells -include_replicated_objects singleChannel_mode_reg*]

set_false_path -from [get_cells -include_replicated_objects syncTriggerPeriod_reg*]
set_false_path -from [get_cells -include_replicated_objects sampleClkRst_reg*]

#set_false_path -from [get_cells -include_replicated_objects remap_reg]
set_false_path -from [get_cells serialDataResetN_cc_reg]
#set_false_path -from [get_cells serialData_cc_reg[*]]
set_false_path -from [get_cells serialDataValid_cc_reg]
set_false_path -from [get_cells rx_start_of_frame_cc_reg[*]]
set_false_path -from [get_cells rx_end_of_frame_cc_reg[*]]
set_false_path -from [get_cells rx_start_of_multiframe_cc_reg[*]]
set_false_path -from [get_cells rx_end_of_multiframe_cc_reg[*]]
set_false_path -from [get_cells rx_frame_error_cc_reg[*]]

set_false_path -through [get_pins jesd204_phy_inst/common*_qpll*_lock_out] -to [get_cells cfgReadData_reg[*]]
set_false_path -through [get_pins sampleClkPll/LOCKED] -to [get_cells cfgReadData_reg[*]]

set_false_path -through [get_ports thermal_pd]

