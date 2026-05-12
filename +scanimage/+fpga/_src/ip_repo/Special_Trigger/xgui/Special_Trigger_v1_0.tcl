# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "NUM_EXT_TRIGGERS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NUM_PEER_TRIGGERS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PEER_TRIGGER_IDX" -parent ${Page_0}


}

proc update_PARAM_VALUE.NUM_EXT_TRIGGERS { PARAM_VALUE.NUM_EXT_TRIGGERS } {
	# Procedure called to update NUM_EXT_TRIGGERS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_EXT_TRIGGERS { PARAM_VALUE.NUM_EXT_TRIGGERS } {
	# Procedure called to validate NUM_EXT_TRIGGERS
	return true
}

proc update_PARAM_VALUE.NUM_PEER_TRIGGERS { PARAM_VALUE.NUM_PEER_TRIGGERS } {
	# Procedure called to update NUM_PEER_TRIGGERS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_PEER_TRIGGERS { PARAM_VALUE.NUM_PEER_TRIGGERS } {
	# Procedure called to validate NUM_PEER_TRIGGERS
	return true
}

proc update_PARAM_VALUE.PEER_TRIGGER_IDX { PARAM_VALUE.PEER_TRIGGER_IDX } {
	# Procedure called to update PEER_TRIGGER_IDX when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PEER_TRIGGER_IDX { PARAM_VALUE.PEER_TRIGGER_IDX } {
	# Procedure called to validate PEER_TRIGGER_IDX
	return true
}


proc update_MODELPARAM_VALUE.NUM_EXT_TRIGGERS { MODELPARAM_VALUE.NUM_EXT_TRIGGERS PARAM_VALUE.NUM_EXT_TRIGGERS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_EXT_TRIGGERS}] ${MODELPARAM_VALUE.NUM_EXT_TRIGGERS}
}

proc update_MODELPARAM_VALUE.NUM_PEER_TRIGGERS { MODELPARAM_VALUE.NUM_PEER_TRIGGERS PARAM_VALUE.NUM_PEER_TRIGGERS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_PEER_TRIGGERS}] ${MODELPARAM_VALUE.NUM_PEER_TRIGGERS}
}

proc update_MODELPARAM_VALUE.PEER_TRIGGER_IDX { MODELPARAM_VALUE.PEER_TRIGGER_IDX PARAM_VALUE.PEER_TRIGGER_IDX } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PEER_TRIGGER_IDX}] ${MODELPARAM_VALUE.PEER_TRIGGER_IDX}
}

