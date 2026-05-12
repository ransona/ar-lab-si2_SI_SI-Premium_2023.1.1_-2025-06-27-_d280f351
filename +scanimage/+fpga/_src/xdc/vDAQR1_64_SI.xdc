
# sys clock
set_property IOSTANDARD LVDS [get_ports SYS_CLK_200_P]
set_property IOSTANDARD LVDS [get_ports SYS_CLK_200_N]
set_property PACKAGE_PIN AA24 [get_ports SYS_CLK_200_P]
set_property PACKAGE_PIN AA25 [get_ports SYS_CLK_200_N]
set_property DIFF_TERM_ADV TERM_100 [get_ports SYS_CLK_200_P]

# module id
set_property IOSTANDARD LVCMOS18 [get_ports MODULE_ID_IO[*]]
set_property PULLTYPE PULLDOWN [get_ports MODULE_ID_IO[*]]
set_property PACKAGE_PIN AC33 [get_ports MODULE_ID_IO[0]]
set_property PACKAGE_PIN AD33 [get_ports MODULE_ID_IO[1]]
set_property PACKAGE_PIN AF33 [get_ports MODULE_ID_IO[2]]
set_property PACKAGE_PIN AG34 [get_ports MODULE_ID_IO[3]]


# get muxed clocks
set pin_i0 [get_pins afeClk_mux/I0]
set pin_o  [get_pins afeClk_mux/O]

set hs_clk [get_clocks -of_objects $pin_i0]
set hs_afe_clk [get_clocks -of_objects $pin_o -filter "MASTER_CLOCK == $hs_clk"]

# generated clocks for sync trig
set clkNets [get_nets -segments -of_objects [get_ports SYNC_TRIGGER_clk]]
set pllCell [get_cells -of_objects $clkNets -filter "PRIMITIVE_SUBGROUP == PLL"]
set inClkPin [get_pins -of_objects $pllCell -filter "NAME =~ */CLKIN"]
set phyClkPin [get_pins -of_objects $pllCell -filter "NAME =~ */CLKOUTPHY"]
set sampClkPin [get_pins -of_objects $pllCell -filter "NAME =~ */CLKOUT0"]

create_generated_clock -name hs_trig_phy_clk -multiply_by 8 -add -master_clock $hs_afe_clk -source $inClkPin $phyClkPin
create_generated_clock -name hs_trig_div_clk -multiply_by 2 -add -master_clock $hs_afe_clk -source $inClkPin $sampClkPin
