
set sreg [get_cells valSample_reg[*]*]
set dreg [get_cells dstV_reg[*]*]

set sclk			[get_clocks -of_objects $sreg]
set dclk			[get_clocks -of_objects $dreg]
set sclk_period     [get_property -min PERIOD $sclk]
set dclk_period     [get_property -min PERIOD $dclk]
set maxdel			[expr {(($sclk_period < $dclk_period) ? $sclk_period : $dclk_period)/2}]

# Set max delay on cross clock domain path
set_max_delay -from $sreg -to $dreg -datapath_only $maxdel
