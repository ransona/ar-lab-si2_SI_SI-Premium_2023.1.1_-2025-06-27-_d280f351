
set_false_path -from [get_cells waveformLengthSamples_reg[*]]
set_false_path -from [get_cells samplePeriod_reg[*]]
set_false_path -from [get_cells sampleOffset_reg[*]]
set_false_path -from [get_cells usrUpdateReqData_reg[*]]
set_false_path -from [get_cells allowEarlyTrigger_reg]
set_false_path -from [get_cells allowRetrigger_reg]
set_false_path -from [get_cells samplesPerTrigger_reg[*]]
set_false_path -from [get_cells continuousGen_reg]
set_false_path -from [get_cells maxSampleDelta_reg[*]]

set_false_path -from [get_cells externalValueTriggerValue_reg[*]]
set_false_path -from [get_cells enableExternalValueTrigger_reg]

# timing paths for reading the next buffer sample dont matter
set_false_path -through [get_pins generate_blockram_cols[*].RAMB18E2_inst/DOUT*DOUT]
set_false_path -from [get_cells nextBufferSampleR_reg[*]]
set_false_path -from [get_cells nextBufferSample_wOffset_R_reg[*]]
set_false_path -from [get_cells nextBufferSample_wOffset_rateLimited_R_reg[*]]

set_false_path -to [get_cells trigSyncr_reg[1]]
set_false_path -to [get_cells externalValueTrigger_occ_reg[1]]
set_false_path -to [get_cells externalValueTrigger_acc_reg[1]]
