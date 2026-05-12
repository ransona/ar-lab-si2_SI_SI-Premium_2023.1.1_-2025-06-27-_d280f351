# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "SHOW_SPI_ENABLE_PORT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SHOW_DBG_PORT" -parent ${Page_0}


}

proc update_PARAM_VALUE.SHOW_DBG_PORT { PARAM_VALUE.SHOW_DBG_PORT } {
	# Procedure called to update SHOW_DBG_PORT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SHOW_DBG_PORT { PARAM_VALUE.SHOW_DBG_PORT } {
	# Procedure called to validate SHOW_DBG_PORT
	return true
}

proc update_PARAM_VALUE.SHOW_SPI_ENABLE_PORT { PARAM_VALUE.SHOW_SPI_ENABLE_PORT } {
	# Procedure called to update SHOW_SPI_ENABLE_PORT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SHOW_SPI_ENABLE_PORT { PARAM_VALUE.SHOW_SPI_ENABLE_PORT } {
	# Procedure called to validate SHOW_SPI_ENABLE_PORT
	return true
}


proc update_MODELPARAM_VALUE.SHOW_SPI_ENABLE_PORT { MODELPARAM_VALUE.SHOW_SPI_ENABLE_PORT PARAM_VALUE.SHOW_SPI_ENABLE_PORT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SHOW_SPI_ENABLE_PORT}] ${MODELPARAM_VALUE.SHOW_SPI_ENABLE_PORT}
}

proc update_MODELPARAM_VALUE.SHOW_DBG_PORT { MODELPARAM_VALUE.SHOW_DBG_PORT PARAM_VALUE.SHOW_DBG_PORT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SHOW_DBG_PORT}] ${MODELPARAM_VALUE.SHOW_DBG_PORT}
}

