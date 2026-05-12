
cd [get_property directory [current_project]]
source -notrace ./scr/procedure_library.tcl


proc generate_vdaqr0_si {} {
	source -notrace ./scr/generate_synth_bd_ips.tcl
}

proc synthesize_vdaqr0_si_app {} {
	check_and_create_vdaqr0_bd
	generate_vdaqr0_si
	source -notrace ./scr/synth_vdaqr0_app.tcl
}


proc implement_vdaqr0_si_design {} {
	source -notrace ./scr/impl_vdaqr0_design.tcl
}


proc build_vdaqr0_si_design {} {
	synthesize_vdaqr0_si_app
	current_project vDAQR0_SI
	implement_vdaqr0_si_design
}

proc reimplement_vdaqr0_si_design {} {
	source -notrace ./scr/re_impl_vdaqr0_si_design.tcl
}


proc regen_vdaqr0_bd {} {
	remove_files  [get_property DIRECTORY [current_project]]/[get_property NAME [current_project]].srcs/sources_1/bd/vDAQR0_BD/vDAQR0_BD.bd
	file delete -force [get_property DIRECTORY [current_project]]/[get_property NAME [current_project]].srcs/sources_1/bd/vDAQR0_BD

	source -notrace [get_property DIRECTORY [current_project]]/bd/vDAQR0_BD.tcl

	regenerate_bd_layout
	regenerate_bd_layout -routing
	save_bd_design
}


proc check_and_create_vdaqr0_bd {} {
	set bd_file [get_property DIRECTORY [current_project]]/[get_property NAME [current_project]].srcs/sources_1/bd/vDAQR0_BD/vDAQR0_BD.bd
	if {![file exists $bd_file]} {
		regen_vdaqr0_bd
	}
}


proc save_vdaqr0_bd {} {
	open_bd_design {./vDAQ_SI.srcs/sources_1/bd/vDAQR0_BD/vDAQR0_BD.bd}
	write_bd_tcl -force ./bd/vDAQR0_BD.tcl
}


proc save_and_regen_vdaqr0_bd {} {
	save_vdaqr0_bd
	regen_vdaqr0_bd
}


proc rerun_proj_open_scr {} {
	cd [get_property directory [current_project]]
	source -notrace ./scr/vDAQR0_SI_project_open_scr.tcl
}


proc save_vdaqr0_proj {} {
	write_project_tcl ./vDAQR0_SI.tcl
}
