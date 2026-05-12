
set BUILD_NAME vDAQR0_SI

cd [get_property directory [current_project]]
set_msg_config -id "Shape Builder 18-126" -new_severity WARNING

create_project -in_memory -part xcku035-ffva1156-1-c
save_project_as ${BUILD_NAME}_implementation ./${BUILD_NAME}.runs/${BUILD_NAME}_tandem_impl/ -force

add_files ./outputs/${BUILD_NAME}_Full_optd.dcp

puts ""
puts ""
puts "Linking Top Design"
link_design

source -notrace ./scr/place_route_gen_vdaqr0_outputs.tcl

