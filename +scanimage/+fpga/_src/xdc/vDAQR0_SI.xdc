
set_property IOSTANDARD LVDS [get_ports IO_CLK_120_N]
set_property IOSTANDARD LVDS [get_ports IO_CLK_120_P]
set_property PACKAGE_PIN H12 [get_ports IO_CLK_120_P]
set_property PACKAGE_PIN G12 [get_ports IO_CLK_120_N]
set_property DIFF_TERM_ADV TERM_100 [get_ports IO_CLK_120_P]

set_property IOSTANDARD LVDS [get_ports SYS_CLK_200_N]
set_property IOSTANDARD LVDS [get_ports SYS_CLK_200_P]
set_property PACKAGE_PIN AD31 [get_ports SYS_CLK_200_N]
set_property PACKAGE_PIN AD30 [get_ports SYS_CLK_200_P]
set_property DIFF_TERM_ADV TERM_100 [get_ports SYS_CLK_200_P]

set_property IOSTANDARD LVDS [get_ports EXT_CLK_REF_N]
set_property IOSTANDARD LVDS [get_ports EXT_CLK_REF_P]
set_property PACKAGE_PIN F10 [get_ports EXT_CLK_REF_N]
set_property PACKAGE_PIN G10 [get_ports EXT_CLK_REF_P]
set_property DIFF_TERM_ADV TERM_100 [get_ports EXT_CLK_REF_P]

set_property IOSTANDARD LVCMOS33 [get_ports LED[*]]
set_property PACKAGE_PIN AJ10 [get_ports LED[0]]
set_property PACKAGE_PIN AH9 [get_ports LED[1]]

set_property IOSTANDARD LVCMOS18 [get_ports MODULE_ID[*]]
set_property PULLTYPE PULLDOWN [get_ports MODULE_ID[*]]
set_property PACKAGE_PIN AC33 [get_ports MODULE_ID[0]]
set_property PACKAGE_PIN AD33 [get_ports MODULE_ID[1]]
set_property PACKAGE_PIN AG34 [get_ports MODULE_ID[2]]
set_property PACKAGE_PIN AF33 [get_ports MODULE_ID[3]]

