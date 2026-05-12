
# Timing exceptions
set_false_path -from [get_cells sysClk200_enR_reg]
set_false_path -from [get_cells sysClk100_enR_reg]
set_false_path -from [get_cells ioClkH_oxenR_reg]
set_false_path -from [get_cells ioClkH_enR_reg]
set_false_path -from [get_cells ioClk40_enR_reg]
set_false_path -from [get_cells lsadcSpiClkEnR_reg]
set_false_path -from [get_cells lsdacSpiClkEnR_reg]

set_false_path -through [get_ports DI[*]]

set_false_path -to [get_cells gen_dio_sync[*].cc_reg[1]]
set_false_path -to [get_cells gen_rtsi_sync[*].cc_reg[1]]

set_false_path -from [get_cells pwmMeasChan_reg[*]]
set_false_path -from [get_cells pwmMeasDebounce_reg[*]]
set_false_path -from [get_cells pwmMeasPeriodMax_reg[*]]

set_false_path -from [get_cells afeSelect_reg*]

set_false_path -from [get_cells scopeParamNumberOfSamples_reg[*]*]
set_false_path -from [get_cells scopeParamDecimationLB2_reg[*]*]
set_false_path -from [get_cells scopeParamTriggerId_reg[*]*]
set_false_path -from [get_cells scopeParamTriggerHoldoff_reg[*]*]
set_false_path -from [get_cells scopeParamTriggerLineNumber_reg[*]*]
set_false_path -from [get_cells scopeParamAeSel_reg*]
set_false_path -from [get_cells hsChanSel_reg*]
#set_false_path -from [get_cells hsSyncTrigPhaseShift_reg[*]*]
#set_false_path -from [get_cells hsSyncTrigIgnorePhysical_reg*]
set_false_path -from [get_cells photonDetectThresholds_reg[*]]
set_false_path -from [get_cells photonDetectInverts_reg[*]]
set_false_path -from [get_cells photonDetectDiffs_reg[*]]
set_false_path -from [get_cells photonDifferentiateOrders_reg[*]]
set_false_path -from [get_cells photonDifferentiateDeadTime_reg[*]]
set_false_path -from [get_cells hsScopeProbePhotons_reg[*]]
#set_false_path -from [get_cells laserClkPeriodSamples_reg*]

set_false_path -from [get_cells scopeFifoWriteWidthR_reg[*]*]

set cfgClk [get_clocks -of_objects [get_cells afeSelect_reg]]

set_false_path -from [get_cells dataScope/writeCount_reg[*]] -to $cfgClk
set_false_path -from [get_cells dataScope/overflowCount_reg[*]] -to $cfgClk
