
# find clocks
set dreg [get_cells ssr_reg[2]*]
set sclk [get_clocks -of_objects [get_cells srcFlag_reg]]
set dclk [get_clocks -of_objects $dreg]

# get the clock periods
set sclk_period     [get_property -min PERIOD $sclk]
set dclk_period     [get_property -min PERIOD $dclk]

set maxdel [expr {min($sclk_period, $dclk_period)/2}]

set_max_delay -from $sclk -to $dreg -datapath_only $maxdel
