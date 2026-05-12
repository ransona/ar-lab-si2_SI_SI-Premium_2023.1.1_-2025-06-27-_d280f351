
# SPI bus timing constraints
# The set_output_delay -max should be the setup requirement of the external device.
# The set_output_delay -min should be the negative of the hold requirement.

set cgSpiClk [get_clocks cg_spi_clk]


#set prt  [get_ports -scoped_to_current_instance spiClk]
#set net  [get_nets -segments -of_objects $prt]
#set pin  [get_pins -of_objects $net -filter {IS_LEAF && (DIRECTION == "IN")}]
#set cell [get_cells -of_objects $pin]
#set pin  [get_pins -of_objects $cell -filter {DIRECTION == "OUT"}]
#set net  [get_nets -segments -of_objects $pin]
#set spiClkPort [get_ports -of_objects $net]

#set prt  [get_ports -scoped_to_current_instance sdi]
#set net  [get_nets -segments -of_objects $prt]
#set pin  [get_pins -of_objects $net -filter {(REF_NAME == "IBUF") && (DIRECTION == "OUT")}]
#set cell [get_cells -of_objects $pin]
#set pin  [get_pins -of_objects $cell -filter {DIRECTION == "IN"}]
#set net  [get_nets -segments -of_objects $pin]
#set sdiPort [get_ports -of_objects $net]

#set prt  [get_ports -scoped_to_current_instance cs]
#set net  [get_nets -segments -of_objects $prt]
#set pin  [get_pins -of_objects $net -filter {IS_LEAF && (DIRECTION == "IN")}]
#set cell [get_cells -of_objects $pin]
#set pin  [get_pins -of_objects $cell -filter {DIRECTION == "OUT"}]
#set net  [get_nets -segments -of_objects $pin]
#set csPort [get_ports -of_objects $net]

#set prt  [get_ports -scoped_to_current_instance sdo]
#set net  [get_nets -segments -of_objects $prt]
#set pin  [get_pins -of_objects $net -filter {IS_LEAF && (DIRECTION == "IN")}]
#set cell [get_cells -of_objects $pin]
#set pin  [get_pins -of_objects $cell -filter {DIRECTION == "OUT"}]
#set net  [get_nets -segments -of_objects $pin]
#set sdoPort [get_ports -of_objects $net]

set spiClkPort [get_ports spiClk]
set sdiPort [get_ports sdi]
set csPort [get_ports cs]
set sdoPort [get_ports sdo]

set_output_delay -clock cg_spi_clk 2 $spiClkPort

set_input_delay -clock cg_spi_clk -max 16.0 $sdiPort -clock_fall
set_input_delay -clock cg_spi_clk -min  0.0 $sdiPort -clock_fall

set_output_delay -clock cg_spi_clk -max  6.0 $csPort
set_output_delay -clock cg_spi_clk -min -0.1 $csPort

set_output_delay -clock cg_spi_clk -max  6.0 $sdoPort
set_output_delay -clock cg_spi_clk -min -0.1 $sdoPort

# these should really all be multicycle paths but the timing reqs are really easy
# to meet. no need to write complex xdc's
