
set BUILD_NAME vDAQR1_SI_64
if {$::LRR_ENABLED} {
    set BUILD_NAME ${BUILD_NAME}_LRR
}

cd [get_property directory [current_project]]
set_msg_config -id "Shape Builder 18-126" -new_severity WARNING
# disable DRC for SYSMON I2C pins; SDA pin (which is RTSI00) is output only to avoid issue
set_property IS_ENABLED 0 [get_drc_checks {RPBF-6}]
# disable DRC for incomplete pin buffering; this is by design
set_property IS_ENABLED 0 [get_drc_checks {RPBF-3}]

create_project -in_memory -part xcku035-ffva1156-1-c
save_project_as ${BUILD_NAME}_implementation ./${BUILD_NAME}.runs/${BUILD_NAME}_tandem_impl/ -force

add_files ./outputs/${BUILD_NAME}_Full_optd.dcp

puts ""
puts ""
puts "Linking Top Design"
link_design

source -notrace ./scr/place_route_gen_vdaqr1_64_outputs.tcl

