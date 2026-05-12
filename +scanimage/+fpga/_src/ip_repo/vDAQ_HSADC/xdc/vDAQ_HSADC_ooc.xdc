
create_clock -period 8 -name axiClk_ooc [get_ports axiClk]
create_clock -period 3.7 -name auxClk_ooc [get_ports coreClk]
