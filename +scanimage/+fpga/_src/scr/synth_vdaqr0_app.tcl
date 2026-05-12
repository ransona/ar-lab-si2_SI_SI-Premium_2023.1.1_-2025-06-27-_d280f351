# wait on block design and other out-of-context runs
wait_on_runs

# set up and launch synthesis
set BUILD_NAME vDAQR0_SI
set PROJ_NAME  ${BUILD_NAME}_app_synth

set sproj [get_projects -quiet $PROJ_NAME]
if {[llength $sproj]} {
    current_project $sproj
    close_project
}

set_msg_config -id "BD 41-1661" -new_severity INFO

# note: get_ips -exclude_bd_ips is not available in Vivado 2017
set IP_FILES [get_property NAME [get_ips -filter {NAME !~ vDAQR0_BD*}]]
set SOURCE_FILES [get_files -of_objects [get_filesets -quiet "sources_1 $IP_FILES"] -filter {IS_GENERATED == FALSE}]
cd [get_property directory [current_project]]

create_project -in_memory -part xcku035-ffva1156-1-c
save_project_as ${BUILD_NAME}_app_synth ./${BUILD_NAME}.runs/${BUILD_NAME}_app_synth/ -force

add_files $SOURCE_FILES

read_xdc -ref vDAQR0_SI ./xdc/vDAQR0_SI_clocks.xdc
read_xdc -mode out_of_context ./xdc/vDAQR0_ooc.xdc


set_property top vDAQR0_AppWrapper [current_fileset]
synth_design -mode out_of_context


puts ""
puts "Writing ${BUILD_NAME}_App_synth.dcp"
file mkdir ./outputs
write_checkpoint -force ./outputs/${BUILD_NAME}_App_synth.dcp
