

puts ""
puts ""
puts "Placing"
#set BUILD_NAME vDAQR0_SI
place_design -directive Explore

puts ""
puts "Pre-route Physical Synthesis"
phys_opt_design -directive Explore

#set BUILD_NAME vDAQR0_SI
puts ""
puts "Writing ${BUILD_NAME}_Full_placed.dcp"
write_checkpoint -force ./outputs/${BUILD_NAME}_Full_placed.dcp


puts ""
puts ""
puts "Routing"
#set BUILD_NAME vDAQR0_SI
route_design -directive Explore -ultrathreads

#set BUILD_NAME vDAQR0_SI
puts ""
puts "Writing ${BUILD_NAME}_Full_routed.dcp"
write_checkpoint -force ./outputs/${BUILD_NAME}_Full_routed.dcp


puts ""
puts ""
puts "First Physical Synthesis"
phys_opt_design -directive AggressiveExplore

puts ""
puts "Final Physical Synthesis"
phys_opt_design -directive ExploreWithHoldFix

#set BUILD_NAME vDAQR0_SI
puts ""
puts "Re-writing ${BUILD_NAME}_Full_routed.dcp"
write_checkpoint -force ./outputs/${BUILD_NAME}_Full_routed.dcp


puts ""
puts ""
puts "Running timing report"
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 30 -input_pins -name timing_1

puts ""
puts ""
puts "Running write_bitstream"
#set BUILD_NAME vDAQR0_SI
write_bitstream -force -bin_file ./outputs/${BUILD_NAME}
write_debug_probes -force ./outputs/${BUILD_NAME}.ltx

source -notrace ../../../../vDAQ/R0/ddk/vDAQR0_dbs_file.tcl
write_dbs ./outputs/${BUILD_NAME} userApp
file copy -force ./outputs/${BUILD_NAME}.dbs ../bitfiles/${BUILD_NAME}.dbs

