
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/FIFO2MM_Transport_v2_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  #Adding Group
  set FIFO_Parameters [ipgui::add_group $IPINST -name "FIFO Parameters" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "FIFO_INPUT_WIDTH_BYTES" -parent ${FIFO_Parameters}
  ipgui::add_param $IPINST -name "FIFO_VARIABLE_INPUT_WIDTH" -parent ${FIFO_Parameters}
  ipgui::add_static_text $IPINST -name "desc1" -parent ${FIFO_Parameters} -text {When using variable input width, the following conditions can lead to corrupted data:}
  ipgui::add_static_text $IPINST -name "desc2" -parent ${FIFO_Parameters} -text {- Performing a write operation with writeSize = inputWidth - 1}
  ipgui::add_static_text $IPINST -name "desc3" -parent ${FIFO_Parameters} -text {- Performing a write operation wite writeSize != 4*x, followed by a write operation with writeSize > (inputWidth - 3)}
  ipgui::add_static_text $IPINST -name "desc4" -parent ${FIFO_Parameters} -text {Enabling the safe input option will guarantee correct operation under any condition. If design will never create these}
  ipgui::add_static_text $IPINST -name "desc5" -parent ${FIFO_Parameters} -text {error conditions (for instance if writeSize will always be 4*x) safe input can be disabled for reduced resource utilization.}
  ipgui::add_param $IPINST -name "FIFO_SAFE_VARIABLE_INPUT" -parent ${FIFO_Parameters}
  ipgui::add_static_text $IPINST -name "gap" -parent ${FIFO_Parameters} -text {}
  ipgui::add_param $IPINST -name "FIFO_DEPTH" -parent ${FIFO_Parameters}
  ipgui::add_param $IPINST -name "DEV_BUF_SIZE_KB_CALC" -parent ${FIFO_Parameters}
  ipgui::add_param $IPINST -name "ACTUAL_DEPTH_CALC" -parent ${FIFO_Parameters}
  ipgui::add_param $IPINST -name "DEV_BUF_NUM_BR_CALC" -parent ${FIFO_Parameters}
  ipgui::add_static_text $IPINST -name "gap2" -parent ${FIFO_Parameters} -text {}
  ipgui::add_param $IPINST -name "BLOCK_FOR_READ" -parent ${FIFO_Parameters}
  ipgui::add_static_text $IPINST -name "block" -parent ${FIFO_Parameters} -text {Disabling loss-less operation allows FIFO to continue streaming even when host buffer is full. In this case, the oldest data will be overwritten.}

  #Adding Group
  set AXI_Parameters [ipgui::add_group $IPINST -name "AXI Parameters" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "AXI_DATA_WIDTH" -parent ${AXI_Parameters} -widget comboBox
  ipgui::add_param $IPINST -name "MAXI_DATA_ADDR_WIDTH" -parent ${AXI_Parameters}

  #Adding Group
  set DMA_Parameters [ipgui::add_group $IPINST -name "DMA Parameters" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "SG_PAGE_LIST_LENGTH" -parent ${DMA_Parameters} -widget comboBox
  ipgui::add_param $IPINST -name "SG_BRAMS_CALC" -parent ${DMA_Parameters}


  ipgui::add_param $IPINST -name "SHOW_DBG_PORTS"

}

proc update_PARAM_VALUE.ACTUAL_DEPTH_CALC { PARAM_VALUE.ACTUAL_DEPTH_CALC PARAM_VALUE.DEV_BUF_SIZE_KB_CALC PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES } {
	# Procedure called to update ACTUAL_DEPTH_CALC when any of the dependent parameters in the arguments change
	
	set ACTUAL_DEPTH_CALC ${PARAM_VALUE.ACTUAL_DEPTH_CALC}
	set DEV_BUF_SIZE_KB_CALC ${PARAM_VALUE.DEV_BUF_SIZE_KB_CALC}
	set FIFO_INPUT_WIDTH_BYTES ${PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES}
	set values(DEV_BUF_SIZE_KB_CALC) [get_property value $DEV_BUF_SIZE_KB_CALC]
	set values(FIFO_INPUT_WIDTH_BYTES) [get_property value $FIFO_INPUT_WIDTH_BYTES]
	set_property value [gen_USERPARAMETER_ACTUAL_DEPTH_CALC_VALUE $values(DEV_BUF_SIZE_KB_CALC) $values(FIFO_INPUT_WIDTH_BYTES)] $ACTUAL_DEPTH_CALC
}

proc validate_PARAM_VALUE.ACTUAL_DEPTH_CALC { PARAM_VALUE.ACTUAL_DEPTH_CALC } {
	# Procedure called to validate ACTUAL_DEPTH_CALC
	return true
}

proc update_PARAM_VALUE.AVOID_DB_WIDTH_CALC { PARAM_VALUE.AVOID_DB_WIDTH_CALC PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES } {
	# Procedure called to update AVOID_DB_WIDTH_CALC when any of the dependent parameters in the arguments change
	
	set AVOID_DB_WIDTH_CALC ${PARAM_VALUE.AVOID_DB_WIDTH_CALC}
	set FIFO_INPUT_WIDTH_BYTES ${PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES}
	set values(FIFO_INPUT_WIDTH_BYTES) [get_property value $FIFO_INPUT_WIDTH_BYTES]
	set_property value [gen_USERPARAMETER_AVOID_DB_WIDTH_CALC_VALUE $values(FIFO_INPUT_WIDTH_BYTES)] $AVOID_DB_WIDTH_CALC
}

proc validate_PARAM_VALUE.AVOID_DB_WIDTH_CALC { PARAM_VALUE.AVOID_DB_WIDTH_CALC } {
	# Procedure called to validate AVOID_DB_WIDTH_CALC
	return true
}

proc update_PARAM_VALUE.DEV_BUF_NUM_BR_CALC { PARAM_VALUE.DEV_BUF_NUM_BR_CALC PARAM_VALUE.NUM_BR_COLS_CALC PARAM_VALUE.NUM_BR_RANKS_CALC } {
	# Procedure called to update DEV_BUF_NUM_BR_CALC when any of the dependent parameters in the arguments change
	
	set DEV_BUF_NUM_BR_CALC ${PARAM_VALUE.DEV_BUF_NUM_BR_CALC}
	set NUM_BR_COLS_CALC ${PARAM_VALUE.NUM_BR_COLS_CALC}
	set NUM_BR_RANKS_CALC ${PARAM_VALUE.NUM_BR_RANKS_CALC}
	set values(NUM_BR_COLS_CALC) [get_property value $NUM_BR_COLS_CALC]
	set values(NUM_BR_RANKS_CALC) [get_property value $NUM_BR_RANKS_CALC]
	set_property value [gen_USERPARAMETER_DEV_BUF_NUM_BR_CALC_VALUE $values(NUM_BR_COLS_CALC) $values(NUM_BR_RANKS_CALC)] $DEV_BUF_NUM_BR_CALC
}

proc validate_PARAM_VALUE.DEV_BUF_NUM_BR_CALC { PARAM_VALUE.DEV_BUF_NUM_BR_CALC } {
	# Procedure called to validate DEV_BUF_NUM_BR_CALC
	return true
}

proc update_PARAM_VALUE.DEV_BUF_SIZE_KB_CALC { PARAM_VALUE.DEV_BUF_SIZE_KB_CALC PARAM_VALUE.NUM_BR_COLS_CALC PARAM_VALUE.NUM_BR_RANKS_CALC } {
	# Procedure called to update DEV_BUF_SIZE_KB_CALC when any of the dependent parameters in the arguments change
	
	set DEV_BUF_SIZE_KB_CALC ${PARAM_VALUE.DEV_BUF_SIZE_KB_CALC}
	set NUM_BR_COLS_CALC ${PARAM_VALUE.NUM_BR_COLS_CALC}
	set NUM_BR_RANKS_CALC ${PARAM_VALUE.NUM_BR_RANKS_CALC}
	set values(NUM_BR_COLS_CALC) [get_property value $NUM_BR_COLS_CALC]
	set values(NUM_BR_RANKS_CALC) [get_property value $NUM_BR_RANKS_CALC]
	set_property value [gen_USERPARAMETER_DEV_BUF_SIZE_KB_CALC_VALUE $values(NUM_BR_COLS_CALC) $values(NUM_BR_RANKS_CALC)] $DEV_BUF_SIZE_KB_CALC
}

proc validate_PARAM_VALUE.DEV_BUF_SIZE_KB_CALC { PARAM_VALUE.DEV_BUF_SIZE_KB_CALC } {
	# Procedure called to validate DEV_BUF_SIZE_KB_CALC
	return true
}

proc update_PARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT { PARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT PARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH } {
	# Procedure called to update FIFO_SAFE_VARIABLE_INPUT when any of the dependent parameters in the arguments change
	
	set FIFO_SAFE_VARIABLE_INPUT ${PARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT}
	set FIFO_VARIABLE_INPUT_WIDTH ${PARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH}
	set values(FIFO_VARIABLE_INPUT_WIDTH) [get_property value $FIFO_VARIABLE_INPUT_WIDTH]
	if { [gen_USERPARAMETER_FIFO_SAFE_VARIABLE_INPUT_ENABLEMENT $values(FIFO_VARIABLE_INPUT_WIDTH)] } {
		set_property enabled true $FIFO_SAFE_VARIABLE_INPUT
	} else {
		set_property enabled false $FIFO_SAFE_VARIABLE_INPUT
	}
}

proc validate_PARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT { PARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT } {
	# Procedure called to validate FIFO_SAFE_VARIABLE_INPUT
	return true
}

proc update_PARAM_VALUE.MIN_DB_WIDTH_CALC { PARAM_VALUE.MIN_DB_WIDTH_CALC PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES PARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH PARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT } {
	# Procedure called to update MIN_DB_WIDTH_CALC when any of the dependent parameters in the arguments change
	
	set MIN_DB_WIDTH_CALC ${PARAM_VALUE.MIN_DB_WIDTH_CALC}
	set FIFO_INPUT_WIDTH_BYTES ${PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES}
	set FIFO_VARIABLE_INPUT_WIDTH ${PARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH}
	set FIFO_SAFE_VARIABLE_INPUT ${PARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT}
	set values(FIFO_INPUT_WIDTH_BYTES) [get_property value $FIFO_INPUT_WIDTH_BYTES]
	set values(FIFO_VARIABLE_INPUT_WIDTH) [get_property value $FIFO_VARIABLE_INPUT_WIDTH]
	set values(FIFO_SAFE_VARIABLE_INPUT) [get_property value $FIFO_SAFE_VARIABLE_INPUT]
	set_property value [gen_USERPARAMETER_MIN_DB_WIDTH_CALC_VALUE $values(FIFO_INPUT_WIDTH_BYTES) $values(FIFO_VARIABLE_INPUT_WIDTH) $values(FIFO_SAFE_VARIABLE_INPUT)] $MIN_DB_WIDTH_CALC
}

proc validate_PARAM_VALUE.MIN_DB_WIDTH_CALC { PARAM_VALUE.MIN_DB_WIDTH_CALC } {
	# Procedure called to validate MIN_DB_WIDTH_CALC
	return true
}

proc update_PARAM_VALUE.NUM_BR_COLS_CALC { PARAM_VALUE.NUM_BR_COLS_CALC PARAM_VALUE.NUM_BR_COLS_PRE_CALC PARAM_VALUE.AVOID_DB_WIDTH_CALC } {
	# Procedure called to update NUM_BR_COLS_CALC when any of the dependent parameters in the arguments change
	
	set NUM_BR_COLS_CALC ${PARAM_VALUE.NUM_BR_COLS_CALC}
	set NUM_BR_COLS_PRE_CALC ${PARAM_VALUE.NUM_BR_COLS_PRE_CALC}
	set AVOID_DB_WIDTH_CALC ${PARAM_VALUE.AVOID_DB_WIDTH_CALC}
	set values(NUM_BR_COLS_PRE_CALC) [get_property value $NUM_BR_COLS_PRE_CALC]
	set values(AVOID_DB_WIDTH_CALC) [get_property value $AVOID_DB_WIDTH_CALC]
	set_property value [gen_USERPARAMETER_NUM_BR_COLS_CALC_VALUE $values(NUM_BR_COLS_PRE_CALC) $values(AVOID_DB_WIDTH_CALC)] $NUM_BR_COLS_CALC
}

proc validate_PARAM_VALUE.NUM_BR_COLS_CALC { PARAM_VALUE.NUM_BR_COLS_CALC } {
	# Procedure called to validate NUM_BR_COLS_CALC
	return true
}

proc update_PARAM_VALUE.NUM_BR_COLS_PRE_CALC { PARAM_VALUE.NUM_BR_COLS_PRE_CALC PARAM_VALUE.MIN_DB_WIDTH_CALC PARAM_VALUE.AXI_DATA_WIDTH } {
	# Procedure called to update NUM_BR_COLS_PRE_CALC when any of the dependent parameters in the arguments change
	
	set NUM_BR_COLS_PRE_CALC ${PARAM_VALUE.NUM_BR_COLS_PRE_CALC}
	set MIN_DB_WIDTH_CALC ${PARAM_VALUE.MIN_DB_WIDTH_CALC}
	set AXI_DATA_WIDTH ${PARAM_VALUE.AXI_DATA_WIDTH}
	set values(MIN_DB_WIDTH_CALC) [get_property value $MIN_DB_WIDTH_CALC]
	set values(AXI_DATA_WIDTH) [get_property value $AXI_DATA_WIDTH]
	set_property value [gen_USERPARAMETER_NUM_BR_COLS_PRE_CALC_VALUE $values(MIN_DB_WIDTH_CALC) $values(AXI_DATA_WIDTH)] $NUM_BR_COLS_PRE_CALC
}

proc validate_PARAM_VALUE.NUM_BR_COLS_PRE_CALC { PARAM_VALUE.NUM_BR_COLS_PRE_CALC } {
	# Procedure called to validate NUM_BR_COLS_PRE_CALC
	return true
}

proc update_PARAM_VALUE.NUM_BR_RANKS_CALC { PARAM_VALUE.NUM_BR_RANKS_CALC PARAM_VALUE.FIFO_DEPTH PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES PARAM_VALUE.NUM_BR_COLS_CALC } {
	# Procedure called to update NUM_BR_RANKS_CALC when any of the dependent parameters in the arguments change
	
	set NUM_BR_RANKS_CALC ${PARAM_VALUE.NUM_BR_RANKS_CALC}
	set FIFO_DEPTH ${PARAM_VALUE.FIFO_DEPTH}
	set FIFO_INPUT_WIDTH_BYTES ${PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES}
	set NUM_BR_COLS_CALC ${PARAM_VALUE.NUM_BR_COLS_CALC}
	set values(FIFO_DEPTH) [get_property value $FIFO_DEPTH]
	set values(FIFO_INPUT_WIDTH_BYTES) [get_property value $FIFO_INPUT_WIDTH_BYTES]
	set values(NUM_BR_COLS_CALC) [get_property value $NUM_BR_COLS_CALC]
	set_property value [gen_USERPARAMETER_NUM_BR_RANKS_CALC_VALUE $values(FIFO_DEPTH) $values(FIFO_INPUT_WIDTH_BYTES) $values(NUM_BR_COLS_CALC)] $NUM_BR_RANKS_CALC
}

proc validate_PARAM_VALUE.NUM_BR_RANKS_CALC { PARAM_VALUE.NUM_BR_RANKS_CALC } {
	# Procedure called to validate NUM_BR_RANKS_CALC
	return true
}

proc update_PARAM_VALUE.SG_BRAMS_CALC { PARAM_VALUE.SG_BRAMS_CALC PARAM_VALUE.SG_PAGE_LIST_LENGTH } {
	# Procedure called to update SG_BRAMS_CALC when any of the dependent parameters in the arguments change
	
	set SG_BRAMS_CALC ${PARAM_VALUE.SG_BRAMS_CALC}
	set SG_PAGE_LIST_LENGTH ${PARAM_VALUE.SG_PAGE_LIST_LENGTH}
	set values(SG_PAGE_LIST_LENGTH) [get_property value $SG_PAGE_LIST_LENGTH]
	set_property value [gen_USERPARAMETER_SG_BRAMS_CALC_VALUE $values(SG_PAGE_LIST_LENGTH)] $SG_BRAMS_CALC
}

proc validate_PARAM_VALUE.SG_BRAMS_CALC { PARAM_VALUE.SG_BRAMS_CALC } {
	# Procedure called to validate SG_BRAMS_CALC
	return true
}

proc update_PARAM_VALUE.AXI_DATA_WIDTH { PARAM_VALUE.AXI_DATA_WIDTH } {
	# Procedure called to update AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_DATA_WIDTH { PARAM_VALUE.AXI_DATA_WIDTH } {
	# Procedure called to validate AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.BLOCK_FOR_READ { PARAM_VALUE.BLOCK_FOR_READ } {
	# Procedure called to update BLOCK_FOR_READ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BLOCK_FOR_READ { PARAM_VALUE.BLOCK_FOR_READ } {
	# Procedure called to validate BLOCK_FOR_READ
	return true
}

proc update_PARAM_VALUE.FIFO_DEPTH { PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to update FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIFO_DEPTH { PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to validate FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES { PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES } {
	# Procedure called to update FIFO_INPUT_WIDTH_BYTES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES { PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES } {
	# Procedure called to validate FIFO_INPUT_WIDTH_BYTES
	return true
}

proc update_PARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH { PARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH } {
	# Procedure called to update FIFO_VARIABLE_INPUT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH { PARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH } {
	# Procedure called to validate FIFO_VARIABLE_INPUT_WIDTH
	return true
}

proc update_PARAM_VALUE.MAXI_DATA_ADDR_WIDTH { PARAM_VALUE.MAXI_DATA_ADDR_WIDTH } {
	# Procedure called to update MAXI_DATA_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAXI_DATA_ADDR_WIDTH { PARAM_VALUE.MAXI_DATA_ADDR_WIDTH } {
	# Procedure called to validate MAXI_DATA_ADDR_WIDTH
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


proc update_MODELPARAM_VALUE.FIFO_INPUT_WIDTH_BYTES { MODELPARAM_VALUE.FIFO_INPUT_WIDTH_BYTES PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIFO_INPUT_WIDTH_BYTES}] ${MODELPARAM_VALUE.FIFO_INPUT_WIDTH_BYTES}
}

proc update_MODELPARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH { MODELPARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH PARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH}] ${MODELPARAM_VALUE.FIFO_VARIABLE_INPUT_WIDTH}
}

proc update_MODELPARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT { MODELPARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT PARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT}] ${MODELPARAM_VALUE.FIFO_SAFE_VARIABLE_INPUT}
}

proc update_MODELPARAM_VALUE.AXI_DATA_WIDTH { MODELPARAM_VALUE.AXI_DATA_WIDTH PARAM_VALUE.AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.MAXI_DATA_ADDR_WIDTH { MODELPARAM_VALUE.MAXI_DATA_ADDR_WIDTH PARAM_VALUE.MAXI_DATA_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAXI_DATA_ADDR_WIDTH}] ${MODELPARAM_VALUE.MAXI_DATA_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.FIFO_DEPTH { MODELPARAM_VALUE.FIFO_DEPTH PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIFO_DEPTH}] ${MODELPARAM_VALUE.FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.BLOCK_FOR_READ { MODELPARAM_VALUE.BLOCK_FOR_READ PARAM_VALUE.BLOCK_FOR_READ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BLOCK_FOR_READ}] ${MODELPARAM_VALUE.BLOCK_FOR_READ}
}

proc update_MODELPARAM_VALUE.SG_PAGE_LIST_LENGTH { MODELPARAM_VALUE.SG_PAGE_LIST_LENGTH PARAM_VALUE.SG_PAGE_LIST_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SG_PAGE_LIST_LENGTH}] ${MODELPARAM_VALUE.SG_PAGE_LIST_LENGTH}
}

proc update_MODELPARAM_VALUE.SHOW_DBG_PORTS { MODELPARAM_VALUE.SHOW_DBG_PORTS PARAM_VALUE.SHOW_DBG_PORTS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SHOW_DBG_PORTS}] ${MODELPARAM_VALUE.SHOW_DBG_PORTS}
}

