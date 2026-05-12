# wait on block design and other out-of-context runs
wait_on_runs

# set up and launch synthesis
set BUILD_NAME vDAQR1_64_SI
if {$::LRR_ENABLED} {
    set BUILD_NAME ${BUILD_NAME}_LRR
}

set PROJ_NAME  ${BUILD_NAME}_app_synth

set sproj [get_projects -quiet $PROJ_NAME]
if {[llength $sproj]} {
    current_project $sproj
    close_project
}

set_msg_config -id "BD 41-1661" -new_severity INFO

set IP_FILES [get_property NAME [get_ips -exclude_bd_ips]]
set SOURCE_FILES [get_files -of_objects [get_filesets -quiet "sources_1 $IP_FILES"] -filter {IS_GENERATED == FALSE}]
cd [get_property directory [current_project]]

create_project -in_memory -part xcku035-ffva1156-1-c
save_project_as ${BUILD_NAME}_app_synth ./${BUILD_NAME}.runs/${BUILD_NAME}_app_synth/ -force


add_files $SOURCE_FILES

set vDAQR1_ooc_xdc [get_files [read_xdc -mode out_of_context ./xdc/vDAQR1_ooc.xdc]]
set_property PROCESSING_ORDER EARLY $vDAQR1_ooc_xdc

read_xdc -ref vDAQR1_64_SI ./xdc/vDAQR1_64_SI_clocks.xdc


set_property top vDAQR1_64_AppWrapper [current_fileset]

synth_design -mode out_of_context \
        -generic LRR_ENABLED=$::LRR_ENABLED \
        -generic LRR_80kHz_SUPPORT=$::LRR_80_kHz_SUPPORT \
        -generic GIT_HASH=[get_commit_hash]

puts ""
puts "Writing ${BUILD_NAME}_App_synth.dcp"
file mkdir ./outputs
write_checkpoint -force ./outputs/${BUILD_NAME}_App_synth.dcp
