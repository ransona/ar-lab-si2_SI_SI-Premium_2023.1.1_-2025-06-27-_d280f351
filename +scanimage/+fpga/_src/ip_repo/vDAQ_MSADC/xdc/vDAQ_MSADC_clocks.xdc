
#create_clock -period 2.000 [get_ports DCLK_N] -name msadc_dclk
create_clock -period 8.000 [get_pins FRCLK_ibuf/I] -name msadc_frclk

create_generated_clock -name msadc_dclk [get_pins msadcClkPll/CLKOUT0]
create_generated_clock -name msadc_samp_clk [get_pins msadcClkPll/CLKOUT1]
