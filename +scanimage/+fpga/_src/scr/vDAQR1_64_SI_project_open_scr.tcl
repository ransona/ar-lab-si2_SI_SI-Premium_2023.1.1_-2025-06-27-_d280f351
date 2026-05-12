
cd [get_property directory [current_project]]
source -notrace ./scr/procedure_library.tcl


proc lrr_off {} {
	set ::LRR_ENABLED 0
	set ::LRR_80_kHz_SUPPORT 0
}
lrr_off

proc lrr_on_normal {} {
	set ::LRR_ENABLED 1
	set ::LRR_80_kHz_SUPPORT 0
}

proc lrr_on_80kHz {} {
	lrr_on_normal
	set ::LRR_80_kHz_SUPPORT 1
}


proc generate_vdaqr1_64_si {} {
	source -notrace ./scr/generate_synth_bd_ips.tcl
}

proc synthesize_vdaqr1_64_si_app {} {
	check_and_create_vdaqr1_64_bd
	generate_vdaqr1_64_si
	source -notrace ./scr/synth_vdaqr1_64_app.tcl
}

proc implement_vdaqr1_64_si_design {} {
	source -notrace ./scr/impl_vdaqr1_64_design.tcl
}


proc build_vdaqr1_64_si_design {} {
	synthesize_vdaqr1_64_si_app
	current_project vDAQR1_64_SI
	implement_vdaqr1_64_si_design
}

proc reimplement_vdaqr1_64_si_design {} {
	source -notrace ./scr/re_impl_vdaqr1_64_si_design.tcl
}


proc regen_vdaqr1_64_bd {} {
	remove_files  [get_property DIRECTORY [current_project]]/[get_property NAME [current_project]].srcs/sources_1/bd/vDAQR1_BD/vDAQR1_BD.bd
	file delete -force [get_property DIRECTORY [current_project]]/[get_property NAME [current_project]].srcs/sources_1/bd/vDAQR1_BD

	source -notrace [get_property DIRECTORY [current_project]]/bd/vDAQR1_64_BD.tcl

	regenerate_bd_layout
	regenerate_bd_layout -routing
	save_bd_design
}


proc check_and_create_vdaqr1_64_bd {} {
	set bd_file [get_property DIRECTORY [current_project]]/[get_property NAME [current_project]].srcs/sources_1/bd/vDAQR1_BD/vDAQR1_BD.bd
	if {![file exists $bd_file]} {
		regen_vdaqr1_64_bd
	}
}


proc save_vdaqr1_64_bd {} {
	open_bd_design {./vDAQ_SI.srcs/sources_1/bd/vDAQR1_BD/vDAQR1_BD.bd}
	write_bd_tcl -force ./bd/vDAQR1_64_BD.tcl
}


proc save_and_regen_vdaqr1_bd {} {
	save_vdaqr1_64_bd
	regen_vdaqr1_64_bd
}


proc rerun_proj_open_scr {} {
	cd [get_property directory [current_project]]
	source -notrace ./scr/vDAQR1_64_SI_project_open_scr.tcl
}


proc save_vdaqr1_64_proj {} {
	write_project_tcl ./vDAQR1_64_SI.tcl
}
