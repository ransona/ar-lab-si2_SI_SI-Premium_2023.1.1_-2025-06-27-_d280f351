
set_false_path -from [get_cells waveformLengthSamples_r/regVal_reg[*]]
set_false_path -from [get_cells samplePeriodR/regVal_reg[*]]
set_false_path -from [get_cells outputReg_reg[*]]
set_false_path -from [get_cells sampleUpdateReqData_reg[*]]
set_false_path -from [get_cells triggerPrms_r/regVal_reg[*]]
set_false_path -from [get_cells samplesPerTriggerR/regVal_reg[*]]
set_false_path -from [get_cells continuousGen_reg]

set axiClock [get_clocks -of_objects [get_cells configured_reg]]

set_false_path -from [get_cells triggerLatch_reg] -to $axiClock

set_false_path -from [get_pins generate_lutram[*].RAM32X1D_inst/DP/CLK] -through [get_pins generate_lutram[*].RAM32X1D_inst/DP/O]

set_false_path -to [get_cells trigSyncr_reg[1]]
