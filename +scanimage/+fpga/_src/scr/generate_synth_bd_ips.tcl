# Generates BD and user IPs and starts the OOC synthesis runs
# Author: Nelson Downs

set start_time [clock clicks -milliseconds]

# first delete old runs from dirty .xpr file that can cause errors in first-time build
delete_runs -quiet [get_runs -quiet]

# check for IPs that need upgrade
puts "\nChecking for locked IPs that need upgrade..."
set locked_ips [get_ips -quiet -filter {IS_LOCKED || UPGRADE_VERSIONS != ""}]
if {[llength $locked_ips]} {
    puts "Locked IPs found: $locked_ips"
    puts "Upgrading locked IPs..."
    if {[catch { upgrade_ip $locked_ips } err_msg]} {
        puts stderr "ERROR: Failed to upgrade locked IPs"

        return -code error \
            -errorcode $::errorCode \
            -errorinfo $::errorInfo \
            "Failed to upgrade locked IPs.\n$err_msg"
    }
} else {
    puts "All IPs up-to-date."
}

# get BD and user IPs
set bd [get_files -filter {FILE_TYPE == "Block Designs" && NAME =~ "*vDAQ*_BD.bd"}]
if {[catch { get_ips -quiet -exclude_bd_ips } user_ips]} {
    # must be pre-Vivado 2020, so use a filter to exclude BD IPs
    set user_ips [get_ips -quiet -filter "NAME !~ vDAQ*_BD*"]
}

# generate BD and user IPs
puts "\nGenerating all ungenerated OOC targets (e.g. block diagrams, user RTL IPs)..."
set_property synth_checkpoint_mode Hierarchical $bd
generate_target all $bd
generate_target all $user_ips

# export IP files, create new IP runs
export_ip_user_files -of_objects "$bd $user_ips" -no_script -sync -force -quiet

# setup the BD and user IP runs
set bd_runs_tobuild [create_ip_run $bd -quiet]
set ip_runs_tobuild {}
foreach ip $user_ips {
    set ip_run [create_ip_run $ip -quiet]
    if {[llength $ip_run]} {
        lappend ip_runs_tobuild $ip_run
    }
}

# if there were new builds, launch the runs
if {[llength $ip_runs_tobuild] || [llength $bd_runs_tobuild]} {
    puts "\nLaunching OOC synthesis runs..."

    # number of parallel synth jobs = 3/5 number of CPUs available
    set num_jobs [expr {max(int(3.0*[get_number_of_cpu_cores]/5.0),1)}]

    if {[catch {launch_runs "$bd_runs_tobuild $ip_runs_tobuild" -jobs $num_jobs} err_msg]} {
        puts stderr "\n=========================================================================================="
        puts stderr "ERROR: Error launching runs, please try to use the GUI \"Generate Block Design\", then run build again"
        puts stderr "(no need to wait after generating for runs to finish, can immediately relaunch build when TCL becomes available again)\n"

        # report the error with original details
        return -code error \
            -errorcode $::errorCode \
            -errorinfo $::errorInfo \
            "Failed to launch runs.\n$err_msg"
    }

    # output time taken during generation
    set generation_end_time [clock clicks -milliseconds]
    set gen_time_taken_seconds [expr {double($generation_end_time-$start_time)/1000.0}]
    puts "\n=========================================================================================="
    puts "All OOC targets generated."
    puts "Generation time: $gen_time_taken_seconds seconds"

    # export simulations
    puts "\nExporting simulations from generated targets..."

    set PROJECT_NAME [get_project]
    export_simulation -of_objects "$bd $user_ips" \
        -directory $PROJECT_NAME.ip_user_files/sim_scripts \
        -ip_user_files_dir $PROJECT_NAME.ip_user_files \
        -ipstatic_source_dir $PROJECT_NAME.ip_user_files/ipstatic \
        -lib_map_path [list \
            {modelsim=$PROJECT_NAME.cache/compile_simlib/modelsim} \
            {questa=$PROJECT_NAME.cache/compile_simlib/questa} \
            {riviera=$PROJECT_NAME.cache/compile_simlib/riviera} \
            {activehdl=$PROJECT_NAME.cache/compile_simlib/activehdl}] \
        -use_ip_compiled_libs -force -quiet

    # output simulation timing
    set simulation_end_time [clock clicks -milliseconds]
    set sim_time_taken_seconds [expr {double($simulation_end_time-$generation_end_time)/1000.0}]
    puts "All simulations exported."
    puts "Simulation export time: $sim_time_taken_seconds seconds\n"
} else {
    puts "All OOC targets up-to-date.\n"
}
