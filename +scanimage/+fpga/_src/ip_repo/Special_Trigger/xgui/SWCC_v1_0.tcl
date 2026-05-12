# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "IV" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WW" -parent ${Page_0}


}

proc update_PARAM_VALUE.IV { PARAM_VALUE.IV } {
	# Procedure called to update IV when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IV { PARAM_VALUE.IV } {
	# Procedure called to validate IV
	return true
}

proc update_PARAM_VALUE.WW { PARAM_VALUE.WW } {
	# Procedure called to update WW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WW { PARAM_VALUE.WW } {
	# Procedure called to validate WW
	return true
}


proc update_MODELPARAM_VALUE.WW { MODELPARAM_VALUE.WW PARAM_VALUE.WW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WW}] ${MODELPARAM_VALUE.WW}
}

proc update_MODELPARAM_VALUE.IV { MODELPARAM_VALUE.IV PARAM_VALUE.IV } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IV}] ${MODELPARAM_VALUE.IV}
}

