
set BUILD_NAME vDAQR0_SI

cd [get_property directory [current_project]]
source -notrace ../../../../vDAQ/R0/ddk/vDAQR0_dbs_file.tcl
set_msg_config -id "Shape Builder 18-126" -new_severity WARNING
# disable DRC for incomplete pin buffering; this is by design
set_property IS_ENABLED 0 [get_drc_checks {RPBF-3}]

create_project -in_memory -part xcku035-ffva1156-1-c
save_project_as ${BUILD_NAME}_implementation ./${BUILD_NAME}.runs/${BUILD_NAME}_tandem_impl/ -force

add_files ../../../../vDAQ/R0/ddk/vDAQR0_Base_routed.dcp

puts ""
puts ""
puts "Linking Top Design"
link_design

puts ""
puts ""
puts "Inserting User App"
read_checkpoint -cell userAppInst ./outputs/${BUILD_NAME}_App_synth.dcp

# for now manually apply constraints
puts ""
puts ""
puts "Applying App Constraints"
read_xdc -ref vDAQR0_SI ./xdc/vDAQR0_SI.xdc
read_xdc -ref vDAQ_SI ./xdc/vDAQ_SI.xdc
read_xdc -ref SI ./xdc/SI.xdc
read_xdc -ref OSCC ./xdc/OSCC.xdc
read_xdc -ref SBCC ./xdc/SBCC.xdc
read_xdc -ref SWCC ./xdc/SWCC.xdc
read_xdc -ref CLK_RATE_MEAS ./xdc/CLK_RATE_MEAS.xdc

set_property HD.RECONFIGURABLE 1 [get_cells userAppInst]


puts ""
puts "Writing ${BUILD_NAME}_Full_synthd.dcp"
write_checkpoint -force ./outputs/${BUILD_NAME}_Full_synthd.dcp


puts ""
puts ""
puts "Running Design Optimization"
opt_design -directive Explore


puts ""
puts "Writing ${BUILD_NAME}_Full_optd.dcp"
write_checkpoint -force ./outputs/${BUILD_NAME}_Full_optd.dcp


source -notrace ./scr/place_route_gen_vdaqr0_outputs.tcl

