
set_property IOSTANDARD LVCMOS33 [get_ports CS[*]]
set_property IOSTANDARD LVCMOS33 [get_ports LDAC[*]]
set_property IOSTANDARD LVCMOS33 [get_ports RST[*]]
set_property IOSTANDARD LVCMOS33 [get_ports SDO[*]]
set_property IOSTANDARD LVCMOS33 [get_ports CLK]

set_property SLEW  FAST [get_ports CS[*]]
set_property SLEW  FAST [get_ports LDAC[*]]
set_property SLEW  FAST [get_ports RST[*]]
set_property SLEW  FAST [get_ports SDO[*]]
set_property SLEW  FAST [get_ports CLK]

set_property PACKAGE_PIN AJ8 [get_ports CS[0]]
set_property PACKAGE_PIN AL8 [get_ports LDAC[0]]
set_property PACKAGE_PIN AM9 [get_ports RST[0]]
set_property PACKAGE_PIN AJ9 [get_ports SDO[0]]
set_property PACKAGE_PIN AK11 [get_ports CS[1]]
set_property PACKAGE_PIN AF13 [get_ports LDAC[1]]
set_property PACKAGE_PIN AJ13 [get_ports RST[1]]
set_property PACKAGE_PIN AH13 [get_ports SDO[1]]
set_property PACKAGE_PIN AK13 [get_ports CS[2]]
set_property PACKAGE_PIN AL12 [get_ports LDAC[2]]
set_property PACKAGE_PIN AK12 [get_ports RST[2]]
set_property PACKAGE_PIN AL13 [get_ports SDO[2]]
set_property PACKAGE_PIN AK8 [get_ports CS[3]]
set_property PACKAGE_PIN AN12 [get_ports LDAC[3]]
set_property PACKAGE_PIN AM12 [get_ports RST[3]]
set_property PACKAGE_PIN AE13 [get_ports SDO[3]]
set_property PACKAGE_PIN AH8 [get_ports CS[4]]
set_property PACKAGE_PIN AP13 [get_ports LDAC[4]]
set_property PACKAGE_PIN AN13 [get_ports RST[4]]
set_property PACKAGE_PIN AN11 [get_ports SDO[4]]
set_property PACKAGE_PIN AP9 [get_ports CLK]


# timing exc
set_false_path -through [get_ports spiClkEn]
set_false_path -through [get_ports loadSample[*]]
set_false_path -through [get_ports data[*]]
set_false_path -through [get_ports triggerImmediately[*]]
set_false_path -through [get_ports asyncTrigger[*]]
set_false_path -through [get_ports reset_i[*]]


# SPI bus timing constraints
# The set_output_delay -max should be the setup requirement of the external device.
# The set_output_delay -min should be the negative of the hold requirement.

create_generated_clock -name lsdac_spi_clk -divide_by 1 -source [get_pins spiClkR_reg/C] [get_ports CLK]

# dont care
set_output_delay -clock lsdac_spi_clk 2 [get_ports CLK]
set_output_delay -clock lsdac_spi_clk 2 [get_ports LDAC[*]]
set_output_delay -clock lsdac_spi_clk 2 [get_ports RST[*]]


# multicycle path beacuse rising edge of SPI clock (which is when DAC will sample the data) is
# two clock cycles after falling edge

set_multicycle_path 2 -from [get_cells gen_dac_chans[*].chanInst/csR_reg]
set_multicycle_path 1 -from [get_cells gen_dac_chans[*].chanInst/csR_reg] -hold

set_multicycle_path 2 -from [get_cells gen_dac_chans[*].chanInst/sdoR_reg]
set_multicycle_path 1 -from [get_cells gen_dac_chans[*].chanInst/sdoR_reg] -hold


# hold time is positive because hold req is from previous clock edge, not current clock edge.
# therefor instead of -hold_req, it is -hold_req+clk_period

set_output_delay -clock lsdac_spi_clk -max 10 [get_ports CS[*]]
set_output_delay -clock lsdac_spi_clk -min 3.333 [get_ports CS[*]]

set_output_delay -clock lsdac_spi_clk -max 10 [get_ports SDO[*]]
set_output_delay -clock lsdac_spi_clk -min 3.333 [get_ports SDO[*]]