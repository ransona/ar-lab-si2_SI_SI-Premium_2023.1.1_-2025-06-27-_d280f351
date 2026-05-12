
create_clock -name sysClk200 -period 5 [get_pins sysClk200iBuf/I]
#create_generated_clock -name sysClk100  [get_pins BUFGCE_100/O]

create_generated_clock -name ioClk40  [get_pins clk40bufg/O]

# muxed afe data clocks and downstream sync trig clocks
set pin_i0 [get_pins afeClk_mux/I0]
set pin_o  [get_pins afeClk_mux/O]

set hs_clk [get_clocks -of_objects $pin_i0]

create_generated_clock -name hs_afe_clk -divide_by 1 -add -master_clock $hs_clk -source $pin_i0 $pin_o
