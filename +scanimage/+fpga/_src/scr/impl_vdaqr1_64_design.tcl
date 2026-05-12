
set BUILD_NAME vDAQR1_64_SI
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

add_files ../../../../vDAQ/R1/ddk/vDAQR1_A1_Base.dcp

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
read_xdc -ref vDAQR1_64_SI ./xdc/vDAQR1_64_SI.xdc
read_xdc -ref vDAQ_SI ./xdc/vDAQ_SI.xdc
read_xdc -ref SI ./xdc/SI.xdc
read_xdc -ref OSCC ./xdc/OSCC.xdc
read_xdc -ref SBCC ./xdc/SBCC.xdc
read_xdc -ref SWCC ./xdc/SWCC.xdc
read_xdc -ref CLK_RATE_MEAS ./xdc/CLK_RATE_MEAS.xdc
read_xdc -cell base_io/base/clockCfg/clockCfg ./xdc/vDAQ_CLKCFG.xdc

# override hsadc jesd core clk rate
create_clock -period 3.700 -name aux_clk_in [get_ports {BASE_GPIO[170]}]

set_property HD.RECONFIGURABLE 1 [get_cells userAppInst]

# prevent generation of tandem bitstreams
set_property HD.TANDEM_BITSTREAMS None [current_design]

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


source -notrace ./scr/place_route_gen_vdaqr1_64_outputs.tcl
