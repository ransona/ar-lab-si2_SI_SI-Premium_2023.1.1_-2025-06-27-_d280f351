# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "SHOW_CFG_PORTS" -parent ${Page_0}


}

proc update_PARAM_VALUE.DC_OFFSET_DISABLE { PARAM_VALUE.DC_OFFSET_DISABLE } {
	# Procedure called to update DC_OFFSET_DISABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DC_OFFSET_DISABLE { PARAM_VALUE.DC_OFFSET_DISABLE } {
	# Procedure called to validate DC_OFFSET_DISABLE
	return true
}

proc update_PARAM_VALUE.FILTER_FREQ { PARAM_VALUE.FILTER_FREQ } {
	# Procedure called to update FILTER_FREQ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FILTER_FREQ { PARAM_VALUE.FILTER_FREQ } {
	# Procedure called to validate FILTER_FREQ
	return true
}

proc update_PARAM_VALUE.POST_AMP_GAIN { PARAM_VALUE.POST_AMP_GAIN } {
	# Procedure called to update POST_AMP_GAIN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.POST_AMP_GAIN { PARAM_VALUE.POST_AMP_GAIN } {
	# Procedure called to validate POST_AMP_GAIN
	return true
}

proc update_PARAM_VALUE.POWER_MODE { PARAM_VALUE.POWER_MODE } {
	# Procedure called to update POWER_MODE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.POWER_MODE { PARAM_VALUE.POWER_MODE } {
	# Procedure called to validate POWER_MODE
	return true
}

proc update_PARAM_VALUE.SHOW_CFG_PORTS { PARAM_VALUE.SHOW_CFG_PORTS } {
	# Procedure called to update SHOW_CFG_PORTS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SHOW_CFG_PORTS { PARAM_VALUE.SHOW_CFG_PORTS } {
	# Procedure called to validate SHOW_CFG_PORTS
	return true
}

proc update_PARAM_VALUE.VGA1_GAIN { PARAM_VALUE.VGA1_GAIN } {
	# Procedure called to update VGA1_GAIN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.VGA1_GAIN { PARAM_VALUE.VGA1_GAIN } {
	# Procedure called to validate VGA1_GAIN
	return true
}

proc update_PARAM_VALUE.VGA2_GAIN { PARAM_VALUE.VGA2_GAIN } {
	# Procedure called to update VGA2_GAIN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.VGA2_GAIN { PARAM_VALUE.VGA2_GAIN } {
	# Procedure called to validate VGA2_GAIN
	return true
}

proc update_PARAM_VALUE.VGA3_GAIN { PARAM_VALUE.VGA3_GAIN } {
	# Procedure called to update VGA3_GAIN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.VGA3_GAIN { PARAM_VALUE.VGA3_GAIN } {
	# Procedure called to validate VGA3_GAIN
	return true
}


proc update_MODELPARAM_VALUE.FILTER_FREQ { MODELPARAM_VALUE.FILTER_FREQ PARAM_VALUE.FILTER_FREQ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FILTER_FREQ}] ${MODELPARAM_VALUE.FILTER_FREQ}
}

proc update_MODELPARAM_VALUE.POWER_MODE { MODELPARAM_VALUE.POWER_MODE PARAM_VALUE.POWER_MODE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.POWER_MODE}] ${MODELPARAM_VALUE.POWER_MODE}
}

proc update_MODELPARAM_VALUE.VGA1_GAIN { MODELPARAM_VALUE.VGA1_GAIN PARAM_VALUE.VGA1_GAIN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.VGA1_GAIN}] ${MODELPARAM_VALUE.VGA1_GAIN}
}

proc update_MODELPARAM_VALUE.VGA2_GAIN { MODELPARAM_VALUE.VGA2_GAIN PARAM_VALUE.VGA2_GAIN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.VGA2_GAIN}] ${MODELPARAM_VALUE.VGA2_GAIN}
}

proc update_MODELPARAM_VALUE.VGA3_GAIN { MODELPARAM_VALUE.VGA3_GAIN PARAM_VALUE.VGA3_GAIN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.VGA3_GAIN}] ${MODELPARAM_VALUE.VGA3_GAIN}
}

proc update_MODELPARAM_VALUE.POST_AMP_GAIN { MODELPARAM_VALUE.POST_AMP_GAIN PARAM_VALUE.POST_AMP_GAIN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.POST_AMP_GAIN}] ${MODELPARAM_VALUE.POST_AMP_GAIN}
}

proc update_MODELPARAM_VALUE.DC_OFFSET_DISABLE { MODELPARAM_VALUE.DC_OFFSET_DISABLE PARAM_VALUE.DC_OFFSET_DISABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DC_OFFSET_DISABLE}] ${MODELPARAM_VALUE.DC_OFFSET_DISABLE}
}

proc update_MODELPARAM_VALUE.SHOW_CFG_PORTS { MODELPARAM_VALUE.SHOW_CFG_PORTS PARAM_VALUE.SHOW_CFG_PORTS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SHOW_CFG_PORTS}] ${MODELPARAM_VALUE.SHOW_CFG_PORTS}
}

