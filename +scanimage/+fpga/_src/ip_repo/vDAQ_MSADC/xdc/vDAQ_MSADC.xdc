
# Constrain path for the async reset on the mmcm for the IDELAYCTRL ref clk
set_max_delay -from [get_cells idelayCtrlRst_reg] -to [get_cells gen_idc[*].IDELAYCTRL_inst] -datapath_only 6.000

# Ignore timing analysis for the cached delay calibration results to the AXI read buffer
set_false_path -from [get_clocks msadc_samp_clk] -through [get_nets -of_objects [get_cells delayVal_reg*]] -to [get_cells s0ReadData_reg[*]]
set_false_path -from [get_clocks msadc_samp_clk] -through [get_nets -of_objects [get_cells firstGoodDelVal_reg*]] -to [get_cells s0ReadData_reg[*]]
set_false_path -from [get_clocks msadc_samp_clk] -through [get_nets -of_objects [get_cells lastGoodDelVal_reg*]] -to [get_cells s0ReadData_reg[*]]
set_false_path -from [get_cells calRunsCompleted_reg[*]] -to [get_cells s0ReadData_reg[*]]
set_false_path -from [get_cells testPatternOn_reg] -to [get_cells s0ReadData_reg[*]]
set_false_path -from [get_cells calBitNum_reg[*]] -to [get_cells s0ReadData_reg[*]]
set_false_path -from [get_cells msadcClkPll] -to [get_cells s0ReadData_reg[*]]

set_false_path -from [get_cells boardRev_reg]
set_false_path -from [get_cells testPatternOn_reg] -through [get_ports ch*Data[*]]



# SPI bus timing constraints
# The set_output_delay -max should be the setup requirement of the external device.
# The set_output_delay -min should be the negative of the hold requirement.

create_generated_clock -name msadc_spi_clk -divide_by 2 -source [get_pins adcSpiClkG_reg/C] [get_ports spi_adc_clk]
create_generated_clock -name msadc_vga_spi_clk -divide_by 2 -source [get_pins vgaSpiClkG_reg/C] [get_ports spi_vga_clk]

set_output_delay -clock msadc_spi_clk 2.0 [get_ports spi_adc_clk]
set_output_delay -clock msadc_vga_spi_clk 2.0 [get_ports spi_vga_clk]

set_input_delay -clock msadc_spi_clk -max 5.0 [get_ports spi_adc_sdio] -clock_fall
set_input_delay -clock msadc_spi_clk -min 0.0 [get_ports spi_adc_sdio] -clock_fall

set_output_delay -clock msadc_spi_clk -max 2.0 [get_ports spi_adc_sdio]
set_output_delay -clock msadc_spi_clk -min 1.0 [get_ports spi_adc_sdio]

set_output_delay -clock msadc_spi_clk -max 2.0 [get_ports spi_adc_cs]
set_output_delay -clock msadc_spi_clk -min 1.0 [get_ports spi_adc_cs]


set_input_delay -clock msadc_vga_spi_clk -max 5.0 [get_ports spi_vga_miso] -clock_fall
set_input_delay -clock msadc_vga_spi_clk -min 0.0 [get_ports spi_vga_miso] -clock_fall

set_output_delay -clock msadc_vga_spi_clk -max 5.0 [get_ports spi_vga_mosi]
set_output_delay -clock msadc_vga_spi_clk -min 1.0 [get_ports spi_vga_mosi]

set_output_delay -clock msadc_vga_spi_clk -max 5.0 [get_ports spi_vga_cs12]
set_output_delay -clock msadc_vga_spi_clk -min 1.0 [get_ports spi_vga_cs12]

set_output_delay -clock msadc_vga_spi_clk -max 5.0 [get_ports spi_vga_cs34]
set_output_delay -clock msadc_vga_spi_clk -min 1.0 [get_ports spi_vga_cs34]



# LOCs to aide implementation
set_property LOC BITSLICE_CONTROL_X0Y24 [get_cells gen_idc[0].IDELAYCTRL_inst]
set_property LOC BITSLICE_CONTROL_X0Y25 [get_cells gen_idc[1].IDELAYCTRL_inst]
set_property LOC BITSLICE_CONTROL_X0Y26 [get_cells gen_idc[2].IDELAYCTRL_inst]
set_property LOC BITSLICE_CONTROL_X0Y30 [get_cells gen_idc[3].IDELAYCTRL_inst]
set_property LOC BITSLICE_CONTROL_X0Y31 [get_cells gen_idc[4].IDELAYCTRL_inst]



# LOC constraints for IO pins
set_property IOSTANDARD LVDS [get_ports CHA_D0_N]
set_property IOSTANDARD LVDS [get_ports CHA_D0_P]
set_property IOSTANDARD LVDS [get_ports CHA_D1_N]
set_property IOSTANDARD LVDS [get_ports CHA_D1_P]
set_property IOSTANDARD LVDS [get_ports CHB_D0_N]
set_property IOSTANDARD LVDS [get_ports CHB_D0_P]
set_property IOSTANDARD LVDS [get_ports CHB_D1_N]
set_property IOSTANDARD LVDS [get_ports CHB_D1_P]
set_property IOSTANDARD LVDS [get_ports CHC_D0_N]
set_property IOSTANDARD LVDS [get_ports CHC_D0_P]
set_property IOSTANDARD LVDS [get_ports CHC_D1_N]
set_property IOSTANDARD LVDS [get_ports CHC_D1_P]
set_property IOSTANDARD LVDS [get_ports CHD_D0_N]
set_property IOSTANDARD LVDS [get_ports CHD_D0_P]
set_property IOSTANDARD LVDS [get_ports CHD_D1_N]
set_property IOSTANDARD LVDS [get_ports CHD_D1_P]
set_property IOSTANDARD LVDS [get_ports DCLK_N]
set_property IOSTANDARD LVDS [get_ports DCLK_P]
set_property IOSTANDARD LVDS [get_ports FRCLK_N]
set_property IOSTANDARD LVDS [get_ports FRCLK_P]
set_property IOSTANDARD LVCMOS18 [get_ports board_rev]
set_property IOSTANDARD LVCMOS18 [get_ports adc_pwrdwn]
set_property IOSTANDARD LVCMOS18 [get_ports spi_adc_clk]
set_property IOSTANDARD LVCMOS18 [get_ports spi_adc_cs]
set_property IOSTANDARD LVCMOS18 [get_ports spi_adc_sdio]
set_property IOSTANDARD LVCMOS18 [get_ports adc_sync]
set_property IOSTANDARD LVCMOS18 [get_ports spi_vga_clk]
set_property IOSTANDARD LVCMOS18 [get_ports spi_vga_cs12]
set_property IOSTANDARD LVCMOS18 [get_ports spi_vga_cs34]
set_property IOSTANDARD LVCMOS18 [get_ports spi_vga_miso]
set_property IOSTANDARD LVCMOS18 [get_ports spi_vga_mosi]

set_property PACKAGE_PIN AB24 [get_ports CHA_D0_P]
set_property PACKAGE_PIN AC24 [get_ports CHA_D0_N]
set_property PACKAGE_PIN AC26 [get_ports CHA_D1_P]
set_property PACKAGE_PIN AC27 [get_ports CHA_D1_N]
set_property PACKAGE_PIN AC22 [get_ports CHB_D0_P]
set_property PACKAGE_PIN AC23 [get_ports CHB_D0_N]
set_property PACKAGE_PIN AA22 [get_ports CHB_D1_P]
set_property PACKAGE_PIN AB22 [get_ports CHB_D1_N]
set_property PACKAGE_PIN Y26 [get_ports CHC_D0_P]
set_property PACKAGE_PIN Y27 [get_ports CHC_D0_N]
set_property PACKAGE_PIN AA27 [get_ports CHC_D1_P]
set_property PACKAGE_PIN AB27 [get_ports CHC_D1_N]
set_property PACKAGE_PIN AB25 [get_ports CHD_D0_P]
set_property PACKAGE_PIN AB26 [get_ports CHD_D0_N]
set_property PACKAGE_PIN AA20 [get_ports CHD_D1_P]
set_property PACKAGE_PIN AB20 [get_ports CHD_D1_N]
set_property PACKAGE_PIN W23 [get_ports DCLK_P]
set_property PACKAGE_PIN W24 [get_ports DCLK_N]
set_property PACKAGE_PIN Y23 [get_ports FRCLK_P]
set_property PACKAGE_PIN AA23 [get_ports FRCLK_N]
set_property PACKAGE_PIN U25 [get_ports board_rev]
set_property PACKAGE_PIN U27 [get_ports adc_pwrdwn]
set_property PACKAGE_PIN W28 [get_ports spi_adc_clk]
set_property PACKAGE_PIN U24 [get_ports spi_adc_cs]
set_property PACKAGE_PIN Y28 [get_ports spi_adc_sdio]
set_property PACKAGE_PIN U26 [get_ports adc_sync]
set_property PACKAGE_PIN W21 [get_ports spi_vga_clk]
set_property PACKAGE_PIN V21 [get_ports spi_vga_cs12]
set_property PACKAGE_PIN V22 [get_ports spi_vga_cs34]
set_property PACKAGE_PIN T23 [get_ports spi_vga_miso]
set_property PACKAGE_PIN T22 [get_ports spi_vga_mosi]

# Termination
set_property DIFF_TERM_ADV TERM_100 [get_ports CH*_D*_N]
set_property DIFF_TERM_ADV TERM_100 [get_ports DCLK_N]
set_property DIFF_TERM_ADV TERM_100 [get_ports FRCLK_N]
set_property PULLTYPE PULLDOWN [get_ports board_rev]


