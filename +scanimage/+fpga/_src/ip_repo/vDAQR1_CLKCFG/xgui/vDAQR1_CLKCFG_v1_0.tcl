# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Group
  set Behavior [ipgui::add_group $IPINST -name "Behavior"]
  ipgui::add_param $IPINST -name "AUTO_APPLY_CFG_ON_RESET" -parent ${Behavior}

  #Adding Group
  set Default_Clock_Configuration [ipgui::add_group $IPINST -name "Default Clock Configuration"]
  ipgui::add_param $IPINST -name "PDALL" -parent ${Default_Clock_Configuration} -widget comboBox
  ipgui::add_param $IPINST -name "RAO" -parent ${Default_Clock_Configuration}
  ipgui::add_param $IPINST -name "RD" -parent ${Default_Clock_Configuration}
  ipgui::add_param $IPINST -name "BD" -parent ${Default_Clock_Configuration}
  ipgui::add_param $IPINST -name "ND" -parent ${Default_Clock_Configuration}
  ipgui::add_param $IPINST -name "PD" -parent ${Default_Clock_Configuration} -widget comboBox
  ipgui::add_static_text $IPINST -name "Hmm" -parent ${Default_Clock_Configuration} -text {
VCO = Fin x N / R
VCO range: 4300-5400 MHz

Delay in increments of (VCO / P) clock ticks

Fout = VCO / (P x M)}
  #Adding Group
  set Output_0_(Aux) [ipgui::add_group $IPINST -name "Output 0 (Aux)" -parent ${Default_Clock_Configuration} -display_name {Output 0 (Aux FMC)}]
  set_property tooltip {Output 0 (Aux FMC)} ${Output_0_(Aux)}
  ipgui::add_param $IPINST -name "MUTE0" -parent ${Output_0_(Aux)} -widget comboBox
  set DLY0 [ipgui::add_param $IPINST -name "DLY0" -parent ${Output_0_(Aux)}]
  set_property tooltip {Delay (VCO / P clock ticks)} ${DLY0}
  ipgui::add_param $IPINST -name "MD0" -parent ${Output_0_(Aux)} -widget comboBox

  #Adding Group
  set Output_1_(MS_ADC) [ipgui::add_group $IPINST -name "Output 1 (MS ADC)" -parent ${Default_Clock_Configuration}]
  ipgui::add_param $IPINST -name "MUTE1" -parent ${Output_1_(MS_ADC)} -widget comboBox
  set DLY1 [ipgui::add_param $IPINST -name "DLY1" -parent ${Output_1_(MS_ADC)}]
  set_property tooltip {Delay (VCO / P clock ticks)} ${DLY1}
  ipgui::add_param $IPINST -name "MD1" -parent ${Output_1_(MS_ADC)} -widget comboBox

  #Adding Group
  set Output_2_(HS_ADC) [ipgui::add_group $IPINST -name "Output 2 (HS ADC)" -parent ${Default_Clock_Configuration}]
  ipgui::add_param $IPINST -name "MUTE2" -parent ${Output_2_(HS_ADC)} -widget comboBox
  set DLY2 [ipgui::add_param $IPINST -name "DLY2" -parent ${Output_2_(HS_ADC)}]
  set_property tooltip {Delay (VCO / P clock ticks)} ${DLY2}
  ipgui::add_param $IPINST -name "MD2" -parent ${Output_2_(HS_ADC)} -widget comboBox

  #Adding Group
  set Output_3_(Aux_Ext) [ipgui::add_group $IPINST -name "Output 3 (Aux Ext)" -parent ${Default_Clock_Configuration}]
  ipgui::add_param $IPINST -name "MUTE3" -parent ${Output_3_(Aux_Ext)} -widget comboBox
  set DLY3 [ipgui::add_param $IPINST -name "DLY3" -parent ${Output_3_(Aux_Ext)}]
  set_property tooltip {Delay (VCO / P clock ticks)} ${DLY3}
  ipgui::add_param $IPINST -name "MD3" -parent ${Output_3_(Aux_Ext)} -widget comboBox

  #Adding Group
  set Output_4_(Aux_FPGA) [ipgui::add_group $IPINST -name "Output 4 (Aux FPGA)" -parent ${Default_Clock_Configuration}]
  set_property tooltip {Output 4 (Aux FPGA)} ${Output_4_(Aux_FPGA)}
  ipgui::add_param $IPINST -name "MUTE4" -parent ${Output_4_(Aux_FPGA)} -widget comboBox
  set DLY4 [ipgui::add_param $IPINST -name "DLY4" -parent ${Output_4_(Aux_FPGA)}]
  set_property tooltip {Delay (VCO / P clock ticks)} ${DLY4}
  ipgui::add_param $IPINST -name "MD4" -parent ${Output_4_(Aux_FPGA)} -widget comboBox



}

proc update_PARAM_VALUE.ALCCAL { PARAM_VALUE.ALCCAL } {
	# Procedure called to update ALCCAL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ALCCAL { PARAM_VALUE.ALCCAL } {
	# Procedure called to validate ALCCAL
	return true
}

proc update_PARAM_VALUE.ALCEN { PARAM_VALUE.ALCEN } {
	# Procedure called to update ALCEN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ALCEN { PARAM_VALUE.ALCEN } {
	# Procedure called to validate ALCEN
	return true
}

proc update_PARAM_VALUE.ALCMON { PARAM_VALUE.ALCMON } {
	# Procedure called to update ALCMON when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ALCMON { PARAM_VALUE.ALCMON } {
	# Procedure called to validate ALCMON
	return true
}

proc update_PARAM_VALUE.ALCULOK { PARAM_VALUE.ALCULOK } {
	# Procedure called to update ALCULOK when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ALCULOK { PARAM_VALUE.ALCULOK } {
	# Procedure called to validate ALCULOK
	return true
}

proc update_PARAM_VALUE.AUTOCAL { PARAM_VALUE.AUTOCAL } {
	# Procedure called to update AUTOCAL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AUTOCAL { PARAM_VALUE.AUTOCAL } {
	# Procedure called to validate AUTOCAL
	return true
}

proc update_PARAM_VALUE.AUTO_APPLY_CFG_ON_RESET { PARAM_VALUE.AUTO_APPLY_CFG_ON_RESET } {
	# Procedure called to update AUTO_APPLY_CFG_ON_RESET when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AUTO_APPLY_CFG_ON_RESET { PARAM_VALUE.AUTO_APPLY_CFG_ON_RESET } {
	# Procedure called to validate AUTO_APPLY_CFG_ON_RESET
	return true
}

proc update_PARAM_VALUE.BD { PARAM_VALUE.BD } {
	# Procedure called to update BD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BD { PARAM_VALUE.BD } {
	# Procedure called to validate BD
	return true
}

proc update_PARAM_VALUE.BST { PARAM_VALUE.BST } {
	# Procedure called to update BST when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BST { PARAM_VALUE.BST } {
	# Procedure called to validate BST
	return true
}

proc update_PARAM_VALUE.CP { PARAM_VALUE.CP } {
	# Procedure called to update CP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CP { PARAM_VALUE.CP } {
	# Procedure called to validate CP
	return true
}

proc update_PARAM_VALUE.CPDN { PARAM_VALUE.CPDN } {
	# Procedure called to update CPDN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CPDN { PARAM_VALUE.CPDN } {
	# Procedure called to validate CPDN
	return true
}

proc update_PARAM_VALUE.CPMID { PARAM_VALUE.CPMID } {
	# Procedure called to update CPMID when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CPMID { PARAM_VALUE.CPMID } {
	# Procedure called to validate CPMID
	return true
}

proc update_PARAM_VALUE.CPRST { PARAM_VALUE.CPRST } {
	# Procedure called to update CPRST when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CPRST { PARAM_VALUE.CPRST } {
	# Procedure called to validate CPRST
	return true
}

proc update_PARAM_VALUE.CPUP { PARAM_VALUE.CPUP } {
	# Procedure called to update CPUP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CPUP { PARAM_VALUE.CPUP } {
	# Procedure called to validate CPUP
	return true
}

proc update_PARAM_VALUE.CPWIDE { PARAM_VALUE.CPWIDE } {
	# Procedure called to update CPWIDE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CPWIDE { PARAM_VALUE.CPWIDE } {
	# Procedure called to validate CPWIDE
	return true
}

proc update_PARAM_VALUE.DLY0 { PARAM_VALUE.DLY0 } {
	# Procedure called to update DLY0 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DLY0 { PARAM_VALUE.DLY0 } {
	# Procedure called to validate DLY0
	return true
}

proc update_PARAM_VALUE.DLY1 { PARAM_VALUE.DLY1 } {
	# Procedure called to update DLY1 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DLY1 { PARAM_VALUE.DLY1 } {
	# Procedure called to validate DLY1
	return true
}

proc update_PARAM_VALUE.DLY2 { PARAM_VALUE.DLY2 } {
	# Procedure called to update DLY2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DLY2 { PARAM_VALUE.DLY2 } {
	# Procedure called to validate DLY2
	return true
}

proc update_PARAM_VALUE.DLY3 { PARAM_VALUE.DLY3 } {
	# Procedure called to update DLY3 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DLY3 { PARAM_VALUE.DLY3 } {
	# Procedure called to validate DLY3
	return true
}

proc update_PARAM_VALUE.DLY4 { PARAM_VALUE.DLY4 } {
	# Procedure called to update DLY4 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DLY4 { PARAM_VALUE.DLY4 } {
	# Procedure called to validate DLY4
	return true
}

proc update_PARAM_VALUE.FILT { PARAM_VALUE.FILT } {
	# Procedure called to update FILT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FILT { PARAM_VALUE.FILT } {
	# Procedure called to validate FILT
	return true
}

proc update_PARAM_VALUE.INVSTAT { PARAM_VALUE.INVSTAT } {
	# Procedure called to update INVSTAT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INVSTAT { PARAM_VALUE.INVSTAT } {
	# Procedure called to validate INVSTAT
	return true
}

proc update_PARAM_VALUE.LKCT { PARAM_VALUE.LKCT } {
	# Procedure called to update LKCT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LKCT { PARAM_VALUE.LKCT } {
	# Procedure called to validate LKCT
	return true
}

proc update_PARAM_VALUE.LKWIN { PARAM_VALUE.LKWIN } {
	# Procedure called to update LKWIN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LKWIN { PARAM_VALUE.LKWIN } {
	# Procedure called to validate LKWIN
	return true
}

proc update_PARAM_VALUE.MC0 { PARAM_VALUE.MC0 } {
	# Procedure called to update MC0 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MC0 { PARAM_VALUE.MC0 } {
	# Procedure called to validate MC0
	return true
}

proc update_PARAM_VALUE.MC1 { PARAM_VALUE.MC1 } {
	# Procedure called to update MC1 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MC1 { PARAM_VALUE.MC1 } {
	# Procedure called to validate MC1
	return true
}

proc update_PARAM_VALUE.MC2 { PARAM_VALUE.MC2 } {
	# Procedure called to update MC2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MC2 { PARAM_VALUE.MC2 } {
	# Procedure called to validate MC2
	return true
}

proc update_PARAM_VALUE.MC3 { PARAM_VALUE.MC3 } {
	# Procedure called to update MC3 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MC3 { PARAM_VALUE.MC3 } {
	# Procedure called to validate MC3
	return true
}

proc update_PARAM_VALUE.MC4 { PARAM_VALUE.MC4 } {
	# Procedure called to update MC4 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MC4 { PARAM_VALUE.MC4 } {
	# Procedure called to validate MC4
	return true
}

proc update_PARAM_VALUE.MD0 { PARAM_VALUE.MD0 } {
	# Procedure called to update MD0 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MD0 { PARAM_VALUE.MD0 } {
	# Procedure called to validate MD0
	return true
}

proc update_PARAM_VALUE.MD1 { PARAM_VALUE.MD1 } {
	# Procedure called to update MD1 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MD1 { PARAM_VALUE.MD1 } {
	# Procedure called to validate MD1
	return true
}

proc update_PARAM_VALUE.MD2 { PARAM_VALUE.MD2 } {
	# Procedure called to update MD2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MD2 { PARAM_VALUE.MD2 } {
	# Procedure called to validate MD2
	return true
}

proc update_PARAM_VALUE.MD3 { PARAM_VALUE.MD3 } {
	# Procedure called to update MD3 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MD3 { PARAM_VALUE.MD3 } {
	# Procedure called to validate MD3
	return true
}

proc update_PARAM_VALUE.MD4 { PARAM_VALUE.MD4 } {
	# Procedure called to update MD4 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MD4 { PARAM_VALUE.MD4 } {
	# Procedure called to validate MD4
	return true
}

proc update_PARAM_VALUE.MUTE0 { PARAM_VALUE.MUTE0 } {
	# Procedure called to update MUTE0 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MUTE0 { PARAM_VALUE.MUTE0 } {
	# Procedure called to validate MUTE0
	return true
}

proc update_PARAM_VALUE.MUTE1 { PARAM_VALUE.MUTE1 } {
	# Procedure called to update MUTE1 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MUTE1 { PARAM_VALUE.MUTE1 } {
	# Procedure called to validate MUTE1
	return true
}

proc update_PARAM_VALUE.MUTE2 { PARAM_VALUE.MUTE2 } {
	# Procedure called to update MUTE2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MUTE2 { PARAM_VALUE.MUTE2 } {
	# Procedure called to validate MUTE2
	return true
}

proc update_PARAM_VALUE.MUTE3 { PARAM_VALUE.MUTE3 } {
	# Procedure called to update MUTE3 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MUTE3 { PARAM_VALUE.MUTE3 } {
	# Procedure called to validate MUTE3
	return true
}

proc update_PARAM_VALUE.MUTE4 { PARAM_VALUE.MUTE4 } {
	# Procedure called to update MUTE4 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MUTE4 { PARAM_VALUE.MUTE4 } {
	# Procedure called to validate MUTE4
	return true
}

proc update_PARAM_VALUE.ND { PARAM_VALUE.ND } {
	# Procedure called to update ND when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ND { PARAM_VALUE.ND } {
	# Procedure called to validate ND
	return true
}

proc update_PARAM_VALUE.OINV0 { PARAM_VALUE.OINV0 } {
	# Procedure called to update OINV0 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OINV0 { PARAM_VALUE.OINV0 } {
	# Procedure called to validate OINV0
	return true
}

proc update_PARAM_VALUE.OINV1 { PARAM_VALUE.OINV1 } {
	# Procedure called to update OINV1 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OINV1 { PARAM_VALUE.OINV1 } {
	# Procedure called to validate OINV1
	return true
}

proc update_PARAM_VALUE.OINV2 { PARAM_VALUE.OINV2 } {
	# Procedure called to update OINV2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OINV2 { PARAM_VALUE.OINV2 } {
	# Procedure called to validate OINV2
	return true
}

proc update_PARAM_VALUE.OINV3 { PARAM_VALUE.OINV3 } {
	# Procedure called to update OINV3 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OINV3 { PARAM_VALUE.OINV3 } {
	# Procedure called to validate OINV3
	return true
}

proc update_PARAM_VALUE.OINV4 { PARAM_VALUE.OINV4 } {
	# Procedure called to update OINV4 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OINV4 { PARAM_VALUE.OINV4 } {
	# Procedure called to validate OINV4
	return true
}

proc update_PARAM_VALUE.PD { PARAM_VALUE.PD } {
	# Procedure called to update PD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PD { PARAM_VALUE.PD } {
	# Procedure called to validate PD
	return true
}

proc update_PARAM_VALUE.PDALL { PARAM_VALUE.PDALL } {
	# Procedure called to update PDALL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PDALL { PARAM_VALUE.PDALL } {
	# Procedure called to validate PDALL
	return true
}

proc update_PARAM_VALUE.RAO { PARAM_VALUE.RAO } {
	# Procedure called to update RAO when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RAO { PARAM_VALUE.RAO } {
	# Procedure called to validate RAO
	return true
}

proc update_PARAM_VALUE.RD { PARAM_VALUE.RD } {
	# Procedure called to update RD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RD { PARAM_VALUE.RD } {
	# Procedure called to validate RD
	return true
}

proc update_PARAM_VALUE.SAXIL_CFG_ADDR_WIDTH { PARAM_VALUE.SAXIL_CFG_ADDR_WIDTH } {
	# Procedure called to update SAXIL_CFG_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SAXIL_CFG_ADDR_WIDTH { PARAM_VALUE.SAXIL_CFG_ADDR_WIDTH } {
	# Procedure called to validate SAXIL_CFG_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.SAXIL_CFG_DATA_WIDTH { PARAM_VALUE.SAXIL_CFG_DATA_WIDTH } {
	# Procedure called to update SAXIL_CFG_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SAXIL_CFG_DATA_WIDTH { PARAM_VALUE.SAXIL_CFG_DATA_WIDTH } {
	# Procedure called to validate SAXIL_CFG_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.SSYNC { PARAM_VALUE.SSYNC } {
	# Procedure called to update SSYNC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SSYNC { PARAM_VALUE.SSYNC } {
	# Procedure called to validate SSYNC
	return true
}

proc update_PARAM_VALUE.SYNCEN0 { PARAM_VALUE.SYNCEN0 } {
	# Procedure called to update SYNCEN0 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SYNCEN0 { PARAM_VALUE.SYNCEN0 } {
	# Procedure called to validate SYNCEN0
	return true
}

proc update_PARAM_VALUE.SYNCEN1 { PARAM_VALUE.SYNCEN1 } {
	# Procedure called to update SYNCEN1 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SYNCEN1 { PARAM_VALUE.SYNCEN1 } {
	# Procedure called to validate SYNCEN1
	return true
}

proc update_PARAM_VALUE.SYNCEN2 { PARAM_VALUE.SYNCEN2 } {
	# Procedure called to update SYNCEN2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SYNCEN2 { PARAM_VALUE.SYNCEN2 } {
	# Procedure called to validate SYNCEN2
	return true
}

proc update_PARAM_VALUE.SYNCEN3 { PARAM_VALUE.SYNCEN3 } {
	# Procedure called to update SYNCEN3 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SYNCEN3 { PARAM_VALUE.SYNCEN3 } {
	# Procedure called to validate SYNCEN3
	return true
}

proc update_PARAM_VALUE.SYNCEN4 { PARAM_VALUE.SYNCEN4 } {
	# Procedure called to update SYNCEN4 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SYNCEN4 { PARAM_VALUE.SYNCEN4 } {
	# Procedure called to validate SYNCEN4
	return true
}


proc update_MODELPARAM_VALUE.SAXIL_CFG_DATA_WIDTH { MODELPARAM_VALUE.SAXIL_CFG_DATA_WIDTH PARAM_VALUE.SAXIL_CFG_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SAXIL_CFG_DATA_WIDTH}] ${MODELPARAM_VALUE.SAXIL_CFG_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.SAXIL_CFG_ADDR_WIDTH { MODELPARAM_VALUE.SAXIL_CFG_ADDR_WIDTH PARAM_VALUE.SAXIL_CFG_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SAXIL_CFG_ADDR_WIDTH}] ${MODELPARAM_VALUE.SAXIL_CFG_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.INVSTAT { MODELPARAM_VALUE.INVSTAT PARAM_VALUE.INVSTAT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INVSTAT}] ${MODELPARAM_VALUE.INVSTAT}
}

proc update_MODELPARAM_VALUE.SSYNC { MODELPARAM_VALUE.SSYNC PARAM_VALUE.SSYNC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SSYNC}] ${MODELPARAM_VALUE.SSYNC}
}

proc update_MODELPARAM_VALUE.ALCEN { MODELPARAM_VALUE.ALCEN PARAM_VALUE.ALCEN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ALCEN}] ${MODELPARAM_VALUE.ALCEN}
}

proc update_MODELPARAM_VALUE.ALCMON { MODELPARAM_VALUE.ALCMON PARAM_VALUE.ALCMON } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ALCMON}] ${MODELPARAM_VALUE.ALCMON}
}

proc update_MODELPARAM_VALUE.ALCCAL { MODELPARAM_VALUE.ALCCAL PARAM_VALUE.ALCCAL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ALCCAL}] ${MODELPARAM_VALUE.ALCCAL}
}

proc update_MODELPARAM_VALUE.ALCULOK { MODELPARAM_VALUE.ALCULOK PARAM_VALUE.ALCULOK } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ALCULOK}] ${MODELPARAM_VALUE.ALCULOK}
}

proc update_MODELPARAM_VALUE.AUTOCAL { MODELPARAM_VALUE.AUTOCAL PARAM_VALUE.AUTOCAL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AUTOCAL}] ${MODELPARAM_VALUE.AUTOCAL}
}

proc update_MODELPARAM_VALUE.BST { MODELPARAM_VALUE.BST PARAM_VALUE.BST } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BST}] ${MODELPARAM_VALUE.BST}
}

proc update_MODELPARAM_VALUE.FILT { MODELPARAM_VALUE.FILT PARAM_VALUE.FILT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FILT}] ${MODELPARAM_VALUE.FILT}
}

proc update_MODELPARAM_VALUE.LKCT { MODELPARAM_VALUE.LKCT PARAM_VALUE.LKCT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LKCT}] ${MODELPARAM_VALUE.LKCT}
}

proc update_MODELPARAM_VALUE.CPMID { MODELPARAM_VALUE.CPMID PARAM_VALUE.CPMID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CPMID}] ${MODELPARAM_VALUE.CPMID}
}

proc update_MODELPARAM_VALUE.CPWIDE { MODELPARAM_VALUE.CPWIDE PARAM_VALUE.CPWIDE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CPWIDE}] ${MODELPARAM_VALUE.CPWIDE}
}

proc update_MODELPARAM_VALUE.CPRST { MODELPARAM_VALUE.CPRST PARAM_VALUE.CPRST } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CPRST}] ${MODELPARAM_VALUE.CPRST}
}

proc update_MODELPARAM_VALUE.CPUP { MODELPARAM_VALUE.CPUP PARAM_VALUE.CPUP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CPUP}] ${MODELPARAM_VALUE.CPUP}
}

proc update_MODELPARAM_VALUE.CPDN { MODELPARAM_VALUE.CPDN PARAM_VALUE.CPDN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CPDN}] ${MODELPARAM_VALUE.CPDN}
}

proc update_MODELPARAM_VALUE.CP { MODELPARAM_VALUE.CP PARAM_VALUE.CP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CP}] ${MODELPARAM_VALUE.CP}
}

proc update_MODELPARAM_VALUE.RAO { MODELPARAM_VALUE.RAO PARAM_VALUE.RAO } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RAO}] ${MODELPARAM_VALUE.RAO}
}

proc update_MODELPARAM_VALUE.BD { MODELPARAM_VALUE.BD PARAM_VALUE.BD } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BD}] ${MODELPARAM_VALUE.BD}
}

proc update_MODELPARAM_VALUE.LKWIN { MODELPARAM_VALUE.LKWIN PARAM_VALUE.LKWIN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LKWIN}] ${MODELPARAM_VALUE.LKWIN}
}

proc update_MODELPARAM_VALUE.RD { MODELPARAM_VALUE.RD PARAM_VALUE.RD } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RD}] ${MODELPARAM_VALUE.RD}
}

proc update_MODELPARAM_VALUE.ND { MODELPARAM_VALUE.ND PARAM_VALUE.ND } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ND}] ${MODELPARAM_VALUE.ND}
}

proc update_MODELPARAM_VALUE.PD { MODELPARAM_VALUE.PD PARAM_VALUE.PD } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PD}] ${MODELPARAM_VALUE.PD}
}

proc update_MODELPARAM_VALUE.MUTE0 { MODELPARAM_VALUE.MUTE0 PARAM_VALUE.MUTE0 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MUTE0}] ${MODELPARAM_VALUE.MUTE0}
}

proc update_MODELPARAM_VALUE.SYNCEN0 { MODELPARAM_VALUE.SYNCEN0 PARAM_VALUE.SYNCEN0 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SYNCEN0}] ${MODELPARAM_VALUE.SYNCEN0}
}

proc update_MODELPARAM_VALUE.OINV0 { MODELPARAM_VALUE.OINV0 PARAM_VALUE.OINV0 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OINV0}] ${MODELPARAM_VALUE.OINV0}
}

proc update_MODELPARAM_VALUE.MC0 { MODELPARAM_VALUE.MC0 PARAM_VALUE.MC0 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MC0}] ${MODELPARAM_VALUE.MC0}
}

proc update_MODELPARAM_VALUE.MD0 { MODELPARAM_VALUE.MD0 PARAM_VALUE.MD0 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MD0}] ${MODELPARAM_VALUE.MD0}
}

proc update_MODELPARAM_VALUE.DLY0 { MODELPARAM_VALUE.DLY0 PARAM_VALUE.DLY0 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DLY0}] ${MODELPARAM_VALUE.DLY0}
}

proc update_MODELPARAM_VALUE.MUTE1 { MODELPARAM_VALUE.MUTE1 PARAM_VALUE.MUTE1 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MUTE1}] ${MODELPARAM_VALUE.MUTE1}
}

proc update_MODELPARAM_VALUE.SYNCEN1 { MODELPARAM_VALUE.SYNCEN1 PARAM_VALUE.SYNCEN1 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SYNCEN1}] ${MODELPARAM_VALUE.SYNCEN1}
}

proc update_MODELPARAM_VALUE.OINV1 { MODELPARAM_VALUE.OINV1 PARAM_VALUE.OINV1 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OINV1}] ${MODELPARAM_VALUE.OINV1}
}

proc update_MODELPARAM_VALUE.MC1 { MODELPARAM_VALUE.MC1 PARAM_VALUE.MC1 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MC1}] ${MODELPARAM_VALUE.MC1}
}

proc update_MODELPARAM_VALUE.MD1 { MODELPARAM_VALUE.MD1 PARAM_VALUE.MD1 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MD1}] ${MODELPARAM_VALUE.MD1}
}

proc update_MODELPARAM_VALUE.DLY1 { MODELPARAM_VALUE.DLY1 PARAM_VALUE.DLY1 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DLY1}] ${MODELPARAM_VALUE.DLY1}
}

proc update_MODELPARAM_VALUE.MUTE2 { MODELPARAM_VALUE.MUTE2 PARAM_VALUE.MUTE2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MUTE2}] ${MODELPARAM_VALUE.MUTE2}
}

proc update_MODELPARAM_VALUE.SYNCEN2 { MODELPARAM_VALUE.SYNCEN2 PARAM_VALUE.SYNCEN2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SYNCEN2}] ${MODELPARAM_VALUE.SYNCEN2}
}

proc update_MODELPARAM_VALUE.OINV2 { MODELPARAM_VALUE.OINV2 PARAM_VALUE.OINV2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OINV2}] ${MODELPARAM_VALUE.OINV2}
}

proc update_MODELPARAM_VALUE.MC2 { MODELPARAM_VALUE.MC2 PARAM_VALUE.MC2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MC2}] ${MODELPARAM_VALUE.MC2}
}

proc update_MODELPARAM_VALUE.MD2 { MODELPARAM_VALUE.MD2 PARAM_VALUE.MD2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MD2}] ${MODELPARAM_VALUE.MD2}
}

proc update_MODELPARAM_VALUE.DLY2 { MODELPARAM_VALUE.DLY2 PARAM_VALUE.DLY2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DLY2}] ${MODELPARAM_VALUE.DLY2}
}

proc update_MODELPARAM_VALUE.MUTE3 { MODELPARAM_VALUE.MUTE3 PARAM_VALUE.MUTE3 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MUTE3}] ${MODELPARAM_VALUE.MUTE3}
}

proc update_MODELPARAM_VALUE.SYNCEN3 { MODELPARAM_VALUE.SYNCEN3 PARAM_VALUE.SYNCEN3 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SYNCEN3}] ${MODELPARAM_VALUE.SYNCEN3}
}

proc update_MODELPARAM_VALUE.OINV3 { MODELPARAM_VALUE.OINV3 PARAM_VALUE.OINV3 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OINV3}] ${MODELPARAM_VALUE.OINV3}
}

proc update_MODELPARAM_VALUE.MC3 { MODELPARAM_VALUE.MC3 PARAM_VALUE.MC3 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MC3}] ${MODELPARAM_VALUE.MC3}
}

proc update_MODELPARAM_VALUE.MD3 { MODELPARAM_VALUE.MD3 PARAM_VALUE.MD3 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MD3}] ${MODELPARAM_VALUE.MD3}
}

proc update_MODELPARAM_VALUE.DLY3 { MODELPARAM_VALUE.DLY3 PARAM_VALUE.DLY3 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DLY3}] ${MODELPARAM_VALUE.DLY3}
}

proc update_MODELPARAM_VALUE.MUTE4 { MODELPARAM_VALUE.MUTE4 PARAM_VALUE.MUTE4 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MUTE4}] ${MODELPARAM_VALUE.MUTE4}
}

proc update_MODELPARAM_VALUE.SYNCEN4 { MODELPARAM_VALUE.SYNCEN4 PARAM_VALUE.SYNCEN4 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SYNCEN4}] ${MODELPARAM_VALUE.SYNCEN4}
}

proc update_MODELPARAM_VALUE.OINV4 { MODELPARAM_VALUE.OINV4 PARAM_VALUE.OINV4 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OINV4}] ${MODELPARAM_VALUE.OINV4}
}

proc update_MODELPARAM_VALUE.MC4 { MODELPARAM_VALUE.MC4 PARAM_VALUE.MC4 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MC4}] ${MODELPARAM_VALUE.MC4}
}

proc update_MODELPARAM_VALUE.MD4 { MODELPARAM_VALUE.MD4 PARAM_VALUE.MD4 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MD4}] ${MODELPARAM_VALUE.MD4}
}

proc update_MODELPARAM_VALUE.DLY4 { MODELPARAM_VALUE.DLY4 PARAM_VALUE.DLY4 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DLY4}] ${MODELPARAM_VALUE.DLY4}
}

proc update_MODELPARAM_VALUE.AUTO_APPLY_CFG_ON_RESET { MODELPARAM_VALUE.AUTO_APPLY_CFG_ON_RESET PARAM_VALUE.AUTO_APPLY_CFG_ON_RESET } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AUTO_APPLY_CFG_ON_RESET}] ${MODELPARAM_VALUE.AUTO_APPLY_CFG_ON_RESET}
}

proc update_MODELPARAM_VALUE.PDALL { MODELPARAM_VALUE.PDALL PARAM_VALUE.PDALL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PDALL}] ${MODELPARAM_VALUE.PDALL}
}

