# Contains useful generic procedures for use in other scripts

# get_number_of_cpu_cores:
#  detect number of CPUs available e.g. for parallel synth jobs
#  from: https://stackoverflow.com/a/29487871
proc get_number_of_cpu_cores {} {
    # Windows puts it in an environment variable
    global tcl_platform env
    if {$tcl_platform(platform) eq "windows"} {
        return $env(NUMBER_OF_PROCESSORS)
    }

    # check for sysctl (OSX, BSD)
    set sysctl [auto_execok "sysctl"]
    if {[llength $sysctl]} {
        if {![catch {exec {*}$sysctl -n "hw.ncpu"} cores]} {
            return $cores
        }
    }

    # assume Linux, which has /proc/cpuinfo
    if {![catch {open "/proc/cpuinfo"} f]} {
        set cores [regexp -all -line {^processor\s} [read $f]]
        close $f
        if {$cores > 0} {
            return $cores
        }
    }

    # 1 by default
    return 1
}

# wait_on_runs:
#  wait for all design runs to finish before continuing
proc wait_on_runs {} {
    set waiting_runs [get_runs -quiet -filter {IS_SYNTHESIS && PROGRESS < 100 && NAME != "synth_1"}]
    foreach run $waiting_runs {[ catch {wait_on_run $run} err ]}
}

# get_commit_hash:
#  get the current git commit hash
proc get_commit_hash {} {
    set git_hash [exec git rev-parse --short HEAD]
    return $git_hash
}
