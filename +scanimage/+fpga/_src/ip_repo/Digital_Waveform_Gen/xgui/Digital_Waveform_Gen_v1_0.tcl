# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  #Adding Group
  set fda [ipgui::add_group $IPINST -name "fda" -parent ${Page_0} -display_name {General Settings}]
  set_property tooltip {General Settings} ${fda}
  ipgui::add_param $IPINST -name "WAVE_LENGTH_BITS" -parent ${fda}
  ipgui::add_param $IPINST -name "NUM_EXT_TRIGGERS" -parent ${fda}
  ipgui::add_param $IPINST -name "NUM_PEER_TRIGGERS" -parent ${fda}
  ipgui::add_param $IPINST -name "PEER_TRIGGER_IDX" -parent ${fda}

  #Adding Group
  set AXI_Parameters [ipgui::add_group $IPINST -name "AXI Parameters" -parent ${Page_0} -display_name {AXI Data Bus Parameters}]
  set_property tooltip {AXI Data Bus Parameters} ${AXI_Parameters}
  ipgui::add_param $IPINST -name "AXI_DATA_WIDTH" -parent ${AXI_Parameters} -widget comboBox
  ipgui::add_param $IPINST -name "MAXI_DATA_ADDR_WIDTH" -parent ${AXI_Parameters}
  ipgui::add_param $IPINST -name "SG_PAGE_LIST_LENGTH" -parent ${AXI_Parameters} -widget comboBox

  #Adding Group
  set AXI_Config_Bus_Parameters [ipgui::add_group $IPINST -name "AXI Config Bus Parameters" -parent ${Page_0}]
  set_property tooltip {AXI Config Bus Parameters} ${AXI_Config_Bus_Parameters}
  ipgui::add_param $IPINST -name "SAXI_CFG_PROTOCOL" -parent ${AXI_Config_Bus_Parameters} -widget comboBox
  ipgui::add_param $IPINST -name "SAXI_CFG_DATA_WIDTH" -parent ${AXI_Config_Bus_Parameters} -widget comboBox



}

proc update_PARAM_VALUE.AXI_DATA_WIDTH { PARAM_VALUE.AXI_DATA_WIDTH } {
	# Procedure called to update AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_DATA_WIDTH { PARAM_VALUE.AXI_DATA_WIDTH } {
	# Procedure called to validate AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.MAXI_DATA_ADDR_WIDTH { PARAM_VALUE.MAXI_DATA_ADDR_WIDTH } {
	# Procedure called to update MAXI_DATA_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAXI_DATA_ADDR_WIDTH { PARAM_VALUE.MAXI_DATA_ADDR_WIDTH } {
	# Procedure called to validate MAXI_DATA_ADDR_WIDTH
	return true
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

proc update_PARAM_VALUE.SAMPLE_PERIOD_WIDTH { PARAM_VALUE.SAMPLE_PERIOD_WIDTH } {
	# Procedure called to update SAMPLE_PERIOD_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SAMPLE_PERIOD_WIDTH { PARAM_VALUE.SAMPLE_PERIOD_WIDTH } {
	# Procedure called to validate SAMPLE_PERIOD_WIDTH
	return true
}

proc update_PARAM_VALUE.SAXI_CFG_DATA_WIDTH { PARAM_VALUE.SAXI_CFG_DATA_WIDTH } {
	# Procedure called to update SAXI_CFG_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SAXI_CFG_DATA_WIDTH { PARAM_VALUE.SAXI_CFG_DATA_WIDTH } {
	# Procedure called to validate SAXI_CFG_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.SAXI_CFG_PROTOCOL { PARAM_VALUE.SAXI_CFG_PROTOCOL } {
	# Procedure called to update SAXI_CFG_PROTOCOL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SAXI_CFG_PROTOCOL { PARAM_VALUE.SAXI_CFG_PROTOCOL } {
	# Procedure called to validate SAXI_CFG_PROTOCOL
	return true
}

proc update_PARAM_VALUE.SG_PAGE_LIST_LENGTH { PARAM_VALUE.SG_PAGE_LIST_LENGTH } {
	# Procedure called to update SG_PAGE_LIST_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SG_PAGE_LIST_LENGTH { PARAM_VALUE.SG_PAGE_LIST_LENGTH } {
	# Procedure called to validate SG_PAGE_LIST_LENGTH
	return true
}

proc update_PARAM_VALUE.WAVE_LENGTH_BITS { PARAM_VALUE.WAVE_LENGTH_BITS } {
	# Procedure called to update WAVE_LENGTH_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WAVE_LENGTH_BITS { PARAM_VALUE.WAVE_LENGTH_BITS } {
	# Procedure called to validate WAVE_LENGTH_BITS
	return true
}


proc update_MODELPARAM_VALUE.AXI_DATA_WIDTH { MODELPARAM_VALUE.AXI_DATA_WIDTH PARAM_VALUE.AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.MAXI_DATA_ADDR_WIDTH { MODELPARAM_VALUE.MAXI_DATA_ADDR_WIDTH PARAM_VALUE.MAXI_DATA_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAXI_DATA_ADDR_WIDTH}] ${MODELPARAM_VALUE.MAXI_DATA_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.WAVE_LENGTH_BITS { MODELPARAM_VALUE.WAVE_LENGTH_BITS PARAM_VALUE.WAVE_LENGTH_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WAVE_LENGTH_BITS}] ${MODELPARAM_VALUE.WAVE_LENGTH_BITS}
}

proc update_MODELPARAM_VALUE.SG_PAGE_LIST_LENGTH { MODELPARAM_VALUE.SG_PAGE_LIST_LENGTH PARAM_VALUE.SG_PAGE_LIST_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SG_PAGE_LIST_LENGTH}] ${MODELPARAM_VALUE.SG_PAGE_LIST_LENGTH}
}

proc update_MODELPARAM_VALUE.SAXI_CFG_PROTOCOL { MODELPARAM_VALUE.SAXI_CFG_PROTOCOL PARAM_VALUE.SAXI_CFG_PROTOCOL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SAXI_CFG_PROTOCOL}] ${MODELPARAM_VALUE.SAXI_CFG_PROTOCOL}
}

proc update_MODELPARAM_VALUE.SAXI_CFG_DATA_WIDTH { MODELPARAM_VALUE.SAXI_CFG_DATA_WIDTH PARAM_VALUE.SAXI_CFG_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SAXI_CFG_DATA_WIDTH}] ${MODELPARAM_VALUE.SAXI_CFG_DATA_WIDTH}
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

proc update_MODELPARAM_VALUE.SAMPLE_PERIOD_WIDTH { MODELPARAM_VALUE.SAMPLE_PERIOD_WIDTH PARAM_VALUE.SAMPLE_PERIOD_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SAMPLE_PERIOD_WIDTH}] ${MODELPARAM_VALUE.SAMPLE_PERIOD_WIDTH}
}

