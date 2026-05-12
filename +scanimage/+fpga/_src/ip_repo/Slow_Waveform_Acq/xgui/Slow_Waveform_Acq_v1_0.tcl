# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  #Adding Group
  set IP_Settings [ipgui::add_group $IPINST -name "IP Settings" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "ACQ_N_BITS" -parent ${IP_Settings}
  ipgui::add_param $IPINST -name "NUM_EXT_TRIGGERS" -parent ${IP_Settings}
  ipgui::add_param $IPINST -name "NUM_PEER_TRIGGERS" -parent ${IP_Settings}
  ipgui::add_param $IPINST -name "PEER_TRIGGER_IDX" -parent ${IP_Settings}

  #Adding Group
  set AXI_Parameters [ipgui::add_group $IPINST -name "AXI Parameters" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "AXI_DATA_WIDTH" -parent ${AXI_Parameters} -widget comboBox
  ipgui::add_param $IPINST -name "MAXI_DATA_ADDR_WIDTH" -parent ${AXI_Parameters}

  #Adding Group
  set DMA_Parameters [ipgui::add_group $IPINST -name "DMA Parameters" -parent ${Page_0}]
  set_property tooltip {DMA Parameters} ${DMA_Parameters}
  ipgui::add_param $IPINST -name "SG_PAGE_LIST_LENGTH" -parent ${DMA_Parameters} -widget comboBox


  ipgui::add_param $IPINST -name "SHOW_DBG_PORTS"

}

proc update_PARAM_VALUE.ACQ_N_BITS { PARAM_VALUE.ACQ_N_BITS } {
	# Procedure called to update ACQ_N_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ACQ_N_BITS { PARAM_VALUE.ACQ_N_BITS } {
	# Procedure called to validate ACQ_N_BITS
	return true
}

proc update_PARAM_VALUE.AXI_DATA_WIDTH { PARAM_VALUE.AXI_DATA_WIDTH } {
	# Procedure called to update AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_DATA_WIDTH { PARAM_VALUE.AXI_DATA_WIDTH } {
	# Procedure called to validate AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.LOCAL_BUFFER_TYPE { PARAM_VALUE.LOCAL_BUFFER_TYPE } {
	# Procedure called to update LOCAL_BUFFER_TYPE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LOCAL_BUFFER_TYPE { PARAM_VALUE.LOCAL_BUFFER_TYPE } {
	# Procedure called to validate LOCAL_BUFFER_TYPE
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

proc update_PARAM_VALUE.SAMPLE_WIDTH_BYTES { PARAM_VALUE.SAMPLE_WIDTH_BYTES } {
	# Procedure called to update SAMPLE_WIDTH_BYTES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SAMPLE_WIDTH_BYTES { PARAM_VALUE.SAMPLE_WIDTH_BYTES } {
	# Procedure called to validate SAMPLE_WIDTH_BYTES
	return true
}

proc update_PARAM_VALUE.SG_PAGE_LIST_LENGTH { PARAM_VALUE.SG_PAGE_LIST_LENGTH } {
	# Procedure called to update SG_PAGE_LIST_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SG_PAGE_LIST_LENGTH { PARAM_VALUE.SG_PAGE_LIST_LENGTH } {
	# Procedure called to validate SG_PAGE_LIST_LENGTH
	return true
}

proc update_PARAM_VALUE.SHOW_DBG_PORTS { PARAM_VALUE.SHOW_DBG_PORTS } {
	# Procedure called to update SHOW_DBG_PORTS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SHOW_DBG_PORTS { PARAM_VALUE.SHOW_DBG_PORTS } {
	# Procedure called to validate SHOW_DBG_PORTS
	return true
}


proc update_MODELPARAM_VALUE.SAMPLE_WIDTH_BYTES { MODELPARAM_VALUE.SAMPLE_WIDTH_BYTES PARAM_VALUE.SAMPLE_WIDTH_BYTES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SAMPLE_WIDTH_BYTES}] ${MODELPARAM_VALUE.SAMPLE_WIDTH_BYTES}
}

proc update_MODELPARAM_VALUE.AXI_DATA_WIDTH { MODELPARAM_VALUE.AXI_DATA_WIDTH PARAM_VALUE.AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.MAXI_DATA_ADDR_WIDTH { MODELPARAM_VALUE.MAXI_DATA_ADDR_WIDTH PARAM_VALUE.MAXI_DATA_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAXI_DATA_ADDR_WIDTH}] ${MODELPARAM_VALUE.MAXI_DATA_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.SG_PAGE_LIST_LENGTH { MODELPARAM_VALUE.SG_PAGE_LIST_LENGTH PARAM_VALUE.SG_PAGE_LIST_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SG_PAGE_LIST_LENGTH}] ${MODELPARAM_VALUE.SG_PAGE_LIST_LENGTH}
}

proc update_MODELPARAM_VALUE.ACQ_N_BITS { MODELPARAM_VALUE.ACQ_N_BITS PARAM_VALUE.ACQ_N_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ACQ_N_BITS}] ${MODELPARAM_VALUE.ACQ_N_BITS}
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

proc update_MODELPARAM_VALUE.LOCAL_BUFFER_TYPE { MODELPARAM_VALUE.LOCAL_BUFFER_TYPE PARAM_VALUE.LOCAL_BUFFER_TYPE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LOCAL_BUFFER_TYPE}] ${MODELPARAM_VALUE.LOCAL_BUFFER_TYPE}
}

proc update_MODELPARAM_VALUE.SHOW_DBG_PORTS { MODELPARAM_VALUE.SHOW_DBG_PORTS PARAM_VALUE.SHOW_DBG_PORTS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SHOW_DBG_PORTS}] ${MODELPARAM_VALUE.SHOW_DBG_PORTS}
}

