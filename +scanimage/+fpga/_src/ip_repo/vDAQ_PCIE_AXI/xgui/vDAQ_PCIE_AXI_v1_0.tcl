# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "USE_MASTER_BUS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "USE_SLAVE_BUS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SHOW_FLASH_PORT" -parent ${Page_0}


}

proc update_PARAM_VALUE.SHOW_FLASH_PORT { PARAM_VALUE.SHOW_FLASH_PORT } {
	# Procedure called to update SHOW_FLASH_PORT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SHOW_FLASH_PORT { PARAM_VALUE.SHOW_FLASH_PORT } {
	# Procedure called to validate SHOW_FLASH_PORT
	return true
}

proc update_PARAM_VALUE.USE_MASTER_BUS { PARAM_VALUE.USE_MASTER_BUS } {
	# Procedure called to update USE_MASTER_BUS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USE_MASTER_BUS { PARAM_VALUE.USE_MASTER_BUS } {
	# Procedure called to validate USE_MASTER_BUS
	return true
}

proc update_PARAM_VALUE.USE_SLAVE_BUS { PARAM_VALUE.USE_SLAVE_BUS } {
	# Procedure called to update USE_SLAVE_BUS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USE_SLAVE_BUS { PARAM_VALUE.USE_SLAVE_BUS } {
	# Procedure called to validate USE_SLAVE_BUS
	return true
}


proc update_MODELPARAM_VALUE.USE_MASTER_BUS { MODELPARAM_VALUE.USE_MASTER_BUS PARAM_VALUE.USE_MASTER_BUS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USE_MASTER_BUS}] ${MODELPARAM_VALUE.USE_MASTER_BUS}
}

proc update_MODELPARAM_VALUE.USE_SLAVE_BUS { MODELPARAM_VALUE.USE_SLAVE_BUS PARAM_VALUE.USE_SLAVE_BUS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USE_SLAVE_BUS}] ${MODELPARAM_VALUE.USE_SLAVE_BUS}
}

proc update_MODELPARAM_VALUE.SHOW_FLASH_PORT { MODELPARAM_VALUE.SHOW_FLASH_PORT PARAM_VALUE.SHOW_FLASH_PORT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SHOW_FLASH_PORT}] ${MODELPARAM_VALUE.SHOW_FLASH_PORT}
}

