
set_false_path -from [get_cells numberOfSamplesToAcq_reg[*]]
set_false_path -from [get_cells allowRetrigger_reg]
set_false_path -from [get_cells finiteAcq_reg]
set_false_path -from [get_cells samplePeriod_reg[*]]
set_false_path -from [get_cells lclBufOverflowCount_reg[*]] -to [get_cells s0ReadData_reg[*]]
set_false_path -from [get_cells waveCaptureEnabled_reg] -to [get_cells s0ReadData_reg[*]]

#set_false_path -from [get_pins generate_lutram[*].RAM32X1D_inst/DP/CLK] -through [get_pins generate_lutram[*].RAM32X1D_inst/DP/O]

set_false_path -from [get_clocks -of_objects [get_ports adcClk]] -to [get_cells lastSample_reg[*]]

set_false_path -to [get_cells trigSyncr_reg[1]]
