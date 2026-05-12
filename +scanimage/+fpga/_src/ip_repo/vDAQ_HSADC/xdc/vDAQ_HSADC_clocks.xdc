
create_clock -period 2.962 -name hsadc_gth_ref_clk [get_pins gthRefClkBuf/I]

# core clk is now in fw
# create_clock -period 3.200 -name hsadc_core_clk [get_ports coreclk_p]

create_generated_clock -source [get_pins sampleClkPll/CLKIN] -name hsadc_data_clk [get_pins sampleClkPll/CLKOUT0]

# max fbw sample rate Fs = 2.500 GHz (78.125 MHz x 32)
# serial lane rate = Fs x 5 = 12.500 GHz
# gth ref clk and jesd204 core clk = Fs/8 = 312.5 MHz (3.2 ns period)
# data clk = Fs/32 = 78.125 MHz - (12.8 ns period)

# max sample rate Fs = 2.700 GHz (84.375 MHz x 32)
# serial lane rate = Fs x 4 = 10.800 GHz
# jesd204 core clk = Fs/10 = 270 MHz (3.703 ns period)
# gth ref clk = Fs/8 = 337.5 MHz (2.962 ns period)
# data clk = Fs/32 = 84.375 MHz - (11.851 ns period)

# setting gth ref clk period to to allow for trying ref_clk_rate = Fs/4
