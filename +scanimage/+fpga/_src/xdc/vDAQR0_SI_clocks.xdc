
create_clock -name sysClk200 -period 5 [get_pins sysClk200iBuf/I]
#create_generated_clock -name sysClk100  [get_pins BUFGCE_100/O]

create_clock -name ioClk120 -period 8.333 [get_pins ioClk120Buf/I]
create_generated_clock -name ioClk40  [get_pins clk40bufg/O]
