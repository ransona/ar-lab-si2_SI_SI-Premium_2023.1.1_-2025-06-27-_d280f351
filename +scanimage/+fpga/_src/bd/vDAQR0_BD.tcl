
################################################################
# This is a generated script based on design: vDAQR0_BD
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2017.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source vDAQR0_BD_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcku035-ffva1156-1-c
}


# CHANGE DESIGN NAME HERE
set design_name vDAQR0_BD

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: dma_axi
proc create_hier_cell_dma_axi { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_dma_axi() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S03_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S04_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S05_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S06_AXI

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn

  # Create instance: axi_crossbar_0, and set properties
  set axi_crossbar_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_0 ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {7} \
CONFIG.STRATEGY {2} \
 ] $axi_crossbar_0

  # Create instance: axi_register_slice_0, and set properties
  set axi_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 axi_register_slice_0 ]
  set_property -dict [ list \
CONFIG.REG_AR {1} \
CONFIG.REG_AW {1} \
CONFIG.REG_B {1} \
 ] $axi_register_slice_0

  # Create interface connections
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net S03_AXI_1 [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
  connect_bd_intf_net -intf_net S05_AXI_1 [get_bd_intf_pins S04_AXI] [get_bd_intf_pins axi_crossbar_0/S04_AXI]
  connect_bd_intf_net -intf_net S06_AXI_1 [get_bd_intf_pins S06_AXI] [get_bd_intf_pins axi_crossbar_0/S06_AXI]
  connect_bd_intf_net -intf_net S07_AXI_1 [get_bd_intf_pins S05_AXI] [get_bd_intf_pins axi_crossbar_0/S05_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_register_slice_0/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_register_slice_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_register_slice_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: wg_axi
proc create_hier_cell_wg_axi { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_wg_axi() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S03_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S04_AXI

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn

  # Create instance: axi_crossbar_0, and set properties
  set axi_crossbar_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_0 ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {5} \
CONFIG.STRATEGY {2} \
 ] $axi_crossbar_0

  # Create instance: axi_register_slice_0, and set properties
  set axi_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 axi_register_slice_0 ]
  set_property -dict [ list \
CONFIG.REG_AR {1} \
CONFIG.REG_AW {1} \
CONFIG.REG_B {1} \
 ] $axi_register_slice_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S04_AXI] [get_bd_intf_pins axi_crossbar_0/S04_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_MAXI_DATA [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_1_MAXI_DATA [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_2_MAXI_DATA [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI1 [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_register_slice_0/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_register_slice_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_register_slice_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: wa_axi
proc create_hier_cell_wa_axi { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_wa_axi() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S03_AXI

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn

  # Create instance: axi_crossbar_0, and set properties
  set axi_crossbar_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_0 ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {4} \
CONFIG.STRATEGY {2} \
 ] $axi_crossbar_0

  # Create instance: axi_register_slice_0, and set properties
  set axi_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 axi_register_slice_0 ]
  set_property -dict [ list \
CONFIG.REG_AR {1} \
CONFIG.REG_AW {1} \
CONFIG.REG_B {1} \
 ] $axi_register_slice_0

  # Create interface connections
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_0_MAXI_DATA [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_1_MAXI_DATA [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_2_MAXI_DATA [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_3_MAXI_DATA [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_register_slice_0/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_register_slice_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_register_slice_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: d_axi
proc create_hier_cell_d_axi { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_d_axi() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S03_AXI

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn

  # Create instance: axi_crossbar_0, and set properties
  set axi_crossbar_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_0 ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {4} \
CONFIG.STRATEGY {2} \
 ] $axi_crossbar_0

  # Create instance: axi_register_slice_0, and set properties
  set axi_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 axi_register_slice_0 ]
  set_property -dict [ list \
CONFIG.REG_AR {1} \
CONFIG.REG_AW {1} \
CONFIG.REG_B {1} \
 ] $axi_register_slice_0

  # Create interface connections
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_0_MAXI_DATA [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_1_MAXI_DATA [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_2_MAXI_DATA [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_3_MAXI_DATA [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_register_slice_0/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_register_slice_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_register_slice_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: ch_axi
proc create_hier_cell_ch_axi { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_ch_axi() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S03_AXI

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn

  # Create instance: axi_crossbar_0, and set properties
  set axi_crossbar_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_0 ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {4} \
CONFIG.STRATEGY {2} \
 ] $axi_crossbar_0

  # Create instance: axi_register_slice_0, and set properties
  set axi_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 axi_register_slice_0 ]
  set_property -dict [ list \
CONFIG.REG_AR {1} \
CONFIG.REG_AW {1} \
CONFIG.REG_B {1} \
 ] $axi_register_slice_0

  # Create interface connections
  connect_bd_intf_net -intf_net CH0_FIFO_MAXI_DATA_OUT [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net CH1_FIFO_MAXI_DATA_OUT [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net CH2_FIFO_MAXI_DATA_OUT [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
  connect_bd_intf_net -intf_net CH3_FIFO_MAXI_DATA_OUT [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_register_slice_0/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_register_slice_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_register_slice_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: PCIE_AXI
proc create_hier_cell_PCIE_AXI { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_PCIE_AXI() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M01_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M02_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M03_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M04_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M05_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M06_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M07_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M08_AXI
  create_bd_intf_pin -mode Slave -vlnv vidriotech.com:vidrio:vDAQ_PCIE_AXI_rtl:1.0 PCIE_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S03_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S04_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S05_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S06_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S07_AXI

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst aresetn_40
  create_bd_pin -dir I -type clk ioClk40

  # Create instance: axi_interconnect_4, and set properties
  set axi_interconnect_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_4 ]
  set_property -dict [ list \
CONFIG.NUM_MI {9} \
CONFIG.S00_HAS_REGSLICE {1} \
 ] $axi_interconnect_4

  # Create instance: dma_axi
  create_hier_cell_dma_axi $hier_obj dma_axi

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: vDAQ_PCIE_AXI_0, and set properties
  set vDAQ_PCIE_AXI_0 [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:vDAQ_PCIE_AXI:1.0 vDAQ_PCIE_AXI_0 ]
  set_property -dict [ list \
CONFIG.USE_SLAVE_BUS {true} \
 ] $vDAQ_PCIE_AXI_0

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins M08_AXI] [get_bd_intf_pins axi_interconnect_4/M08_AXI]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins M07_AXI] [get_bd_intf_pins axi_interconnect_4/M07_AXI]
  connect_bd_intf_net -intf_net PCIE_AXI_1 [get_bd_intf_pins PCIE_AXI] [get_bd_intf_pins vDAQ_PCIE_AXI_0/PCIE_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins S01_AXI] [get_bd_intf_pins dma_axi/S00_AXI]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins S02_AXI] [get_bd_intf_pins dma_axi/S01_AXI]
  connect_bd_intf_net -intf_net S03_AXI_1 [get_bd_intf_pins S03_AXI] [get_bd_intf_pins dma_axi/S02_AXI]
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins S04_AXI] [get_bd_intf_pins dma_axi/S03_AXI]
  connect_bd_intf_net -intf_net S05_AXI_1 [get_bd_intf_pins S05_AXI] [get_bd_intf_pins dma_axi/S04_AXI]
  connect_bd_intf_net -intf_net S06_AXI_1 [get_bd_intf_pins S06_AXI] [get_bd_intf_pins dma_axi/S06_AXI]
  connect_bd_intf_net -intf_net S07_AXI_1 [get_bd_intf_pins S07_AXI] [get_bd_intf_pins dma_axi/S05_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M00_AXI [get_bd_intf_pins M00_AXI] [get_bd_intf_pins axi_interconnect_4/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M01_AXI [get_bd_intf_pins M01_AXI] [get_bd_intf_pins axi_interconnect_4/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M02_AXI [get_bd_intf_pins M02_AXI] [get_bd_intf_pins axi_interconnect_4/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M03_AXI [get_bd_intf_pins M03_AXI] [get_bd_intf_pins axi_interconnect_4/M03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M04_AXI [get_bd_intf_pins M04_AXI] [get_bd_intf_pins axi_interconnect_4/M04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M05_AXI [get_bd_intf_pins M05_AXI] [get_bd_intf_pins axi_interconnect_4/M05_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M06_AXI [get_bd_intf_pins M06_AXI] [get_bd_intf_pins axi_interconnect_4/M06_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins dma_axi/M_AXI] [get_bd_intf_pins vDAQ_PCIE_AXI_0/SAXI]
  connect_bd_intf_net -intf_net vDAQ_PCIE_AXI_0_MAXI [get_bd_intf_pins axi_interconnect_4/S00_AXI] [get_bd_intf_pins vDAQ_PCIE_AXI_0/MAXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_interconnect_4/ACLK] [get_bd_pins axi_interconnect_4/M00_ACLK] [get_bd_pins axi_interconnect_4/M01_ACLK] [get_bd_pins axi_interconnect_4/M02_ACLK] [get_bd_pins axi_interconnect_4/M03_ACLK] [get_bd_pins axi_interconnect_4/M06_ACLK] [get_bd_pins axi_interconnect_4/M07_ACLK] [get_bd_pins axi_interconnect_4/M08_ACLK] [get_bd_pins axi_interconnect_4/S00_ACLK] [get_bd_pins dma_axi/aclk] [get_bd_pins vDAQ_PCIE_AXI_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_interconnect_4/ARESETN] [get_bd_pins axi_interconnect_4/M00_ARESETN] [get_bd_pins axi_interconnect_4/M01_ARESETN] [get_bd_pins axi_interconnect_4/M02_ARESETN] [get_bd_pins axi_interconnect_4/M03_ARESETN] [get_bd_pins axi_interconnect_4/M06_ARESETN] [get_bd_pins axi_interconnect_4/M07_ARESETN] [get_bd_pins axi_interconnect_4/M08_ARESETN] [get_bd_pins axi_interconnect_4/S00_ARESETN] [get_bd_pins dma_axi/aresetn] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins vDAQ_PCIE_AXI_0/aresetn]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins axi_interconnect_4/M04_ARESETN] [get_bd_pins axi_interconnect_4/M05_ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins aresetn_40] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net sysClk40_1 [get_bd_pins ioClk40] [get_bd_pins axi_interconnect_4/M04_ACLK] [get_bd_pins axi_interconnect_4/M05_ACLK] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: DAQ
proc create_hier_cell_DAQ { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_DAQ() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI2
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI4
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  # Create pins
  create_bd_pin -dir IO -from 8 -to 0 LSADC_IO
  create_bd_pin -dir IO -from 20 -to 0 LSDAC_IO
  create_bd_pin -dir I ao_watchdog_trigger
  create_bd_pin -dir I -type clk axiClk
  create_bd_pin -dir I -type rst axiResetN
  create_bd_pin -dir I -from 44 -to 0 ext_triggers
  create_bd_pin -dir I -type clk ioClk120
  create_bd_pin -dir I lsadcSpiClkEn
  create_bd_pin -dir I lsdacSpiClkEn
  create_bd_pin -dir O -from 7 -to 0 outputLines0
  create_bd_pin -dir O -from 7 -to 0 outputLines1
  create_bd_pin -dir O -from 7 -to 0 outputLines2
  create_bd_pin -dir O -from 7 -to 0 outputLines3
  create_bd_pin -dir IO -from 12 -to 0 peer_triggers
  create_bd_pin -dir I -type clk sampleClkTimebase

  # Create instance: Digital_Waveform_Gen_0, and set properties
  set Digital_Waveform_Gen_0 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Digital_Waveform_Gen:1.0 Digital_Waveform_Gen_0 ]
  set_property -dict [ list \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {9} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Digital_Waveform_Gen_0

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Digital_Waveform_Gen_0/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
 ] [get_bd_intf_pins /DAQ/Digital_Waveform_Gen_0/SAXI_CFG]

  # Create instance: Digital_Waveform_Gen_1, and set properties
  set Digital_Waveform_Gen_1 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Digital_Waveform_Gen:1.0 Digital_Waveform_Gen_1 ]
  set_property -dict [ list \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {10} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Digital_Waveform_Gen_1

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Digital_Waveform_Gen_1/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
 ] [get_bd_intf_pins /DAQ/Digital_Waveform_Gen_1/SAXI_CFG]

  # Create instance: Digital_Waveform_Gen_2, and set properties
  set Digital_Waveform_Gen_2 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Digital_Waveform_Gen:1.0 Digital_Waveform_Gen_2 ]
  set_property -dict [ list \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {11} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Digital_Waveform_Gen_2

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Digital_Waveform_Gen_2/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
 ] [get_bd_intf_pins /DAQ/Digital_Waveform_Gen_2/SAXI_CFG]

  # Create instance: Digital_Waveform_Gen_3, and set properties
  set Digital_Waveform_Gen_3 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Digital_Waveform_Gen:1.0 Digital_Waveform_Gen_3 ]
  set_property -dict [ list \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {12} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Digital_Waveform_Gen_3

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Digital_Waveform_Gen_3/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
 ] [get_bd_intf_pins /DAQ/Digital_Waveform_Gen_3/SAXI_CFG]

  # Create instance: LSADC, and set properties
  set LSADC [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:vDAQR0_LSADC:1.0 LSADC ]

  # Create instance: LSDAC, and set properties
  set LSDAC [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:vDAQR0_LSDAC:1.0 LSDAC ]

  # Create instance: Slow_Waveform_Acq_0, and set properties
  set Slow_Waveform_Acq_0 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_0 ]
  set_property -dict [ list \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_0

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Acq_0/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Acq_0/SAXIL_CFG]

  # Create instance: Slow_Waveform_Acq_1, and set properties
  set Slow_Waveform_Acq_1 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_1 ]
  set_property -dict [ list \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {1} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Acq_1

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Acq_1/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Acq_1/SAXIL_CFG]

  # Create instance: Slow_Waveform_Acq_2, and set properties
  set Slow_Waveform_Acq_2 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_2 ]
  set_property -dict [ list \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {2} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Acq_2

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Acq_2/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Acq_2/SAXIL_CFG]

  # Create instance: Slow_Waveform_Acq_3, and set properties
  set Slow_Waveform_Acq_3 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_3 ]
  set_property -dict [ list \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {3} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_3

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Acq_3/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Acq_3/SAXIL_CFG]

  # Create instance: Slow_Waveform_Gen_0, and set properties
  set Slow_Waveform_Gen_0 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_0 ]
  set_property -dict [ list \
CONFIG.EXT_VAL_TRIGGER_PORT {true} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {4} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_0

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Gen_0/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Gen_0/SAXIL_CFG]

  # Create instance: Slow_Waveform_Gen_1, and set properties
  set Slow_Waveform_Gen_1 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_1 ]
  set_property -dict [ list \
CONFIG.EXT_VAL_TRIGGER_PORT {true} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {5} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_1

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Gen_1/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Gen_1/SAXIL_CFG]

  # Create instance: Slow_Waveform_Gen_2, and set properties
  set Slow_Waveform_Gen_2 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_2 ]
  set_property -dict [ list \
CONFIG.EXT_VAL_TRIGGER_PORT {true} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {6} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_2

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Gen_2/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Gen_2/SAXIL_CFG]

  # Create instance: Slow_Waveform_Gen_3, and set properties
  set Slow_Waveform_Gen_3 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_3 ]
  set_property -dict [ list \
CONFIG.EXT_VAL_TRIGGER_PORT {true} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {7} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_3

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Gen_3/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Gen_3/SAXIL_CFG]

  # Create instance: Slow_Waveform_Gen_4, and set properties
  set Slow_Waveform_Gen_4 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_4 ]
  set_property -dict [ list \
CONFIG.EXT_VAL_TRIGGER_PORT {true} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.NUM_EXT_TRIGGERS {45} \
CONFIG.NUM_PEER_TRIGGERS {13} \
CONFIG.PEER_TRIGGER_IDX {8} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_4

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Gen_4/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /DAQ/Slow_Waveform_Gen_4/SAXIL_CFG]

  # Create instance: axi_interconnect_3, and set properties
  set axi_interconnect_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_3 ]
  set_property -dict [ list \
CONFIG.NUM_MI {9} \
CONFIG.S00_HAS_REGSLICE {1} \
 ] $axi_interconnect_3

  # Create instance: axi_interconnect_4, and set properties
  set axi_interconnect_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_4 ]
  set_property -dict [ list \
CONFIG.NUM_MI {4} \
CONFIG.S00_HAS_REGSLICE {1} \
 ] $axi_interconnect_4

  # Create instance: d_axi
  create_hier_cell_d_axi $hier_obj d_axi

  # Create instance: wa_axi
  create_hier_cell_wa_axi $hier_obj wa_axi

  # Create instance: wg_axi
  create_hier_cell_wg_axi $hier_obj wg_axi

  # Create interface connections
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_interconnect_3/S00_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_interconnect_4/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins Digital_Waveform_Gen_0/MAXI_DATA] [get_bd_intf_pins d_axi/S00_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins Digital_Waveform_Gen_1/MAXI_DATA] [get_bd_intf_pins d_axi/S01_AXI]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins Digital_Waveform_Gen_2/MAXI_DATA] [get_bd_intf_pins d_axi/S02_AXI]
  connect_bd_intf_net -intf_net S03_AXI_1 [get_bd_intf_pins Digital_Waveform_Gen_3/MAXI_DATA] [get_bd_intf_pins d_axi/S03_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_0_ADC [get_bd_intf_pins LSADC/ADC0] [get_bd_intf_pins Slow_Waveform_Acq_0/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_0_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Acq_0/MAXI_DATA] [get_bd_intf_pins wa_axi/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_1_ADC [get_bd_intf_pins LSADC/ADC1] [get_bd_intf_pins Slow_Waveform_Acq_1/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_1_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Acq_1/MAXI_DATA] [get_bd_intf_pins wa_axi/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_2_ADC [get_bd_intf_pins LSADC/ADC2] [get_bd_intf_pins Slow_Waveform_Acq_2/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_2_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Acq_2/MAXI_DATA] [get_bd_intf_pins wa_axi/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_3_ADC [get_bd_intf_pins LSADC/ADC3] [get_bd_intf_pins Slow_Waveform_Acq_3/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_3_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Acq_3/MAXI_DATA] [get_bd_intf_pins wa_axi/S03_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_DAC [get_bd_intf_pins LSDAC/DAC0] [get_bd_intf_pins Slow_Waveform_Gen_0/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_0/MAXI_DATA] [get_bd_intf_pins wg_axi/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_1_DAC [get_bd_intf_pins LSDAC/DAC1] [get_bd_intf_pins Slow_Waveform_Gen_1/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_1_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_1/MAXI_DATA] [get_bd_intf_pins wg_axi/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_2_DAC [get_bd_intf_pins LSDAC/DAC2] [get_bd_intf_pins Slow_Waveform_Gen_2/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_2_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_2/MAXI_DATA] [get_bd_intf_pins wg_axi/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_3_DAC [get_bd_intf_pins LSDAC/DAC3] [get_bd_intf_pins Slow_Waveform_Gen_3/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_3_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_3/MAXI_DATA] [get_bd_intf_pins wg_axi/S03_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_4_DAC [get_bd_intf_pins LSDAC/DAC4] [get_bd_intf_pins Slow_Waveform_Gen_4/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_4_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_4/MAXI_DATA] [get_bd_intf_pins wg_axi/S04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins Slow_Waveform_Gen_0/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M01_AXI [get_bd_intf_pins Slow_Waveform_Gen_1/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M02_AXI [get_bd_intf_pins Slow_Waveform_Gen_2/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M03_AXI [get_bd_intf_pins Slow_Waveform_Gen_3/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M04_AXI [get_bd_intf_pins Slow_Waveform_Gen_4/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_3_M05_AXI [get_bd_intf_pins Slow_Waveform_Acq_0/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M05_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_3_M06_AXI [get_bd_intf_pins Slow_Waveform_Acq_1/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M06_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_3_M07_AXI [get_bd_intf_pins Slow_Waveform_Acq_2/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M07_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_3_M08_AXI [get_bd_intf_pins Slow_Waveform_Acq_3/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M08_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M00_AXI [get_bd_intf_pins Digital_Waveform_Gen_0/SAXI_CFG] [get_bd_intf_pins axi_interconnect_4/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M01_AXI [get_bd_intf_pins Digital_Waveform_Gen_1/SAXI_CFG] [get_bd_intf_pins axi_interconnect_4/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M02_AXI [get_bd_intf_pins Digital_Waveform_Gen_2/SAXI_CFG] [get_bd_intf_pins axi_interconnect_4/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M03_AXI [get_bd_intf_pins Digital_Waveform_Gen_3/SAXI_CFG] [get_bd_intf_pins axi_interconnect_4/M03_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M00_AXI2] [get_bd_intf_pins wa_axi/M_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI1 [get_bd_intf_pins M00_AXI1] [get_bd_intf_pins wg_axi/M_AXI]
  connect_bd_intf_net -intf_net d_axi_M_AXI [get_bd_intf_pins M00_AXI4] [get_bd_intf_pins d_axi/M_AXI]

  # Create port connections
  connect_bd_net -net Digital_Waveform_Gen_0_outputLines [get_bd_pins outputLines0] [get_bd_pins Digital_Waveform_Gen_0/outputLines]
  connect_bd_net -net Digital_Waveform_Gen_1_outputLines [get_bd_pins outputLines1] [get_bd_pins Digital_Waveform_Gen_1/outputLines]
  connect_bd_net -net Digital_Waveform_Gen_2_outputLines [get_bd_pins outputLines2] [get_bd_pins Digital_Waveform_Gen_2/outputLines]
  connect_bd_net -net Digital_Waveform_Gen_3_outputLines [get_bd_pins outputLines3] [get_bd_pins Digital_Waveform_Gen_3/outputLines]
  connect_bd_net -net Net [get_bd_pins LSADC_IO] [get_bd_pins LSADC/BOARD_IO]
  connect_bd_net -net Net2 [get_bd_pins LSDAC_IO] [get_bd_pins LSDAC/BOARD_IO]
  connect_bd_net -net Net3 [get_bd_pins peer_triggers] [get_bd_pins Digital_Waveform_Gen_0/peer_triggers] [get_bd_pins Digital_Waveform_Gen_1/peer_triggers] [get_bd_pins Digital_Waveform_Gen_2/peer_triggers] [get_bd_pins Digital_Waveform_Gen_3/peer_triggers] [get_bd_pins Slow_Waveform_Acq_0/peer_triggers] [get_bd_pins Slow_Waveform_Acq_1/peer_triggers] [get_bd_pins Slow_Waveform_Acq_2/peer_triggers] [get_bd_pins Slow_Waveform_Acq_3/peer_triggers] [get_bd_pins Slow_Waveform_Gen_0/peer_triggers] [get_bd_pins Slow_Waveform_Gen_1/peer_triggers] [get_bd_pins Slow_Waveform_Gen_2/peer_triggers] [get_bd_pins Slow_Waveform_Gen_3/peer_triggers] [get_bd_pins Slow_Waveform_Gen_4/peer_triggers]
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins axiClk] [get_bd_pins Digital_Waveform_Gen_0/axiClk] [get_bd_pins Digital_Waveform_Gen_1/axiClk] [get_bd_pins Digital_Waveform_Gen_2/axiClk] [get_bd_pins Digital_Waveform_Gen_3/axiClk] [get_bd_pins Slow_Waveform_Acq_0/axiClk] [get_bd_pins Slow_Waveform_Acq_1/axiClk] [get_bd_pins Slow_Waveform_Acq_2/axiClk] [get_bd_pins Slow_Waveform_Acq_3/axiClk] [get_bd_pins Slow_Waveform_Gen_0/axiClk] [get_bd_pins Slow_Waveform_Gen_1/axiClk] [get_bd_pins Slow_Waveform_Gen_2/axiClk] [get_bd_pins Slow_Waveform_Gen_3/axiClk] [get_bd_pins Slow_Waveform_Gen_4/axiClk] [get_bd_pins axi_interconnect_3/ACLK] [get_bd_pins axi_interconnect_3/M00_ACLK] [get_bd_pins axi_interconnect_3/M01_ACLK] [get_bd_pins axi_interconnect_3/M02_ACLK] [get_bd_pins axi_interconnect_3/M03_ACLK] [get_bd_pins axi_interconnect_3/M04_ACLK] [get_bd_pins axi_interconnect_3/M05_ACLK] [get_bd_pins axi_interconnect_3/M06_ACLK] [get_bd_pins axi_interconnect_3/M07_ACLK] [get_bd_pins axi_interconnect_3/M08_ACLK] [get_bd_pins axi_interconnect_3/S00_ACLK] [get_bd_pins axi_interconnect_4/ACLK] [get_bd_pins axi_interconnect_4/M00_ACLK] [get_bd_pins axi_interconnect_4/M01_ACLK] [get_bd_pins axi_interconnect_4/M02_ACLK] [get_bd_pins axi_interconnect_4/M03_ACLK] [get_bd_pins axi_interconnect_4/S00_ACLK] [get_bd_pins d_axi/aclk] [get_bd_pins wa_axi/aclk] [get_bd_pins wg_axi/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins axiResetN] [get_bd_pins Digital_Waveform_Gen_0/axiResetN] [get_bd_pins Digital_Waveform_Gen_1/axiResetN] [get_bd_pins Digital_Waveform_Gen_2/axiResetN] [get_bd_pins Digital_Waveform_Gen_3/axiResetN] [get_bd_pins Slow_Waveform_Acq_0/axiResetN] [get_bd_pins Slow_Waveform_Acq_1/axiResetN] [get_bd_pins Slow_Waveform_Acq_2/axiResetN] [get_bd_pins Slow_Waveform_Acq_3/axiResetN] [get_bd_pins Slow_Waveform_Gen_0/axiResetN] [get_bd_pins Slow_Waveform_Gen_1/axiResetN] [get_bd_pins Slow_Waveform_Gen_2/axiResetN] [get_bd_pins Slow_Waveform_Gen_3/axiResetN] [get_bd_pins Slow_Waveform_Gen_4/axiResetN] [get_bd_pins axi_interconnect_3/ARESETN] [get_bd_pins axi_interconnect_3/M00_ARESETN] [get_bd_pins axi_interconnect_3/M01_ARESETN] [get_bd_pins axi_interconnect_3/M02_ARESETN] [get_bd_pins axi_interconnect_3/M03_ARESETN] [get_bd_pins axi_interconnect_3/M04_ARESETN] [get_bd_pins axi_interconnect_3/M05_ARESETN] [get_bd_pins axi_interconnect_3/M06_ARESETN] [get_bd_pins axi_interconnect_3/M07_ARESETN] [get_bd_pins axi_interconnect_3/M08_ARESETN] [get_bd_pins axi_interconnect_3/S00_ARESETN] [get_bd_pins axi_interconnect_4/ARESETN] [get_bd_pins axi_interconnect_4/M00_ARESETN] [get_bd_pins axi_interconnect_4/M01_ARESETN] [get_bd_pins axi_interconnect_4/M02_ARESETN] [get_bd_pins axi_interconnect_4/M03_ARESETN] [get_bd_pins axi_interconnect_4/S00_ARESETN] [get_bd_pins d_axi/aresetn] [get_bd_pins wa_axi/aresetn] [get_bd_pins wg_axi/aresetn]
  connect_bd_net -net ext_triggers_1 [get_bd_pins ext_triggers] [get_bd_pins Digital_Waveform_Gen_0/ext_triggers] [get_bd_pins Digital_Waveform_Gen_1/ext_triggers] [get_bd_pins Digital_Waveform_Gen_2/ext_triggers] [get_bd_pins Digital_Waveform_Gen_3/ext_triggers] [get_bd_pins Slow_Waveform_Acq_0/ext_triggers] [get_bd_pins Slow_Waveform_Acq_1/ext_triggers] [get_bd_pins Slow_Waveform_Acq_2/ext_triggers] [get_bd_pins Slow_Waveform_Acq_3/ext_triggers] [get_bd_pins Slow_Waveform_Gen_0/ext_triggers] [get_bd_pins Slow_Waveform_Gen_1/ext_triggers] [get_bd_pins Slow_Waveform_Gen_2/ext_triggers] [get_bd_pins Slow_Waveform_Gen_3/ext_triggers] [get_bd_pins Slow_Waveform_Gen_4/ext_triggers]
  connect_bd_net -net externalValueTrigger_1 [get_bd_pins ao_watchdog_trigger] [get_bd_pins Slow_Waveform_Gen_0/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_1/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_2/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_3/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_4/externalValueTrigger]
  connect_bd_net -net ioClk120_1 [get_bd_pins ioClk120] [get_bd_pins LSADC/clk120] [get_bd_pins LSDAC/sysClk120]
  connect_bd_net -net lsadcSpiClkEn_1 [get_bd_pins lsadcSpiClkEn] [get_bd_pins LSADC/spiClkEn]
  connect_bd_net -net spiClkEn1_1 [get_bd_pins lsdacSpiClkEn] [get_bd_pins LSDAC/spiClkEn]
  connect_bd_net -net sysClk100_1 [get_bd_pins sampleClkTimebase] [get_bd_pins Digital_Waveform_Gen_0/sampleClkTimebase] [get_bd_pins Digital_Waveform_Gen_1/sampleClkTimebase] [get_bd_pins Digital_Waveform_Gen_2/sampleClkTimebase] [get_bd_pins Digital_Waveform_Gen_3/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_0/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_1/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_2/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_3/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_0/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_1/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_2/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_3/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_4/sampleClkTimebase]
  connect_bd_net -net vDAQ_LSADC_INTF_dataClk [get_bd_pins LSADC/dataClk] [get_bd_pins Slow_Waveform_Acq_0/adcClk] [get_bd_pins Slow_Waveform_Acq_1/adcClk] [get_bd_pins Slow_Waveform_Acq_2/adcClk] [get_bd_pins Slow_Waveform_Acq_3/adcClk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: CH_FIFOS
proc create_hier_cell_CH_FIFOS { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_CH_FIFOS() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 CFG_AXI
  create_bd_intf_pin -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 CH0_FIFO
  create_bd_intf_pin -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 CH1_FIFO
  create_bd_intf_pin -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 CH2_FIFO
  create_bd_intf_pin -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 CH3_FIFO
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 DATA_AXI

  # Create pins
  create_bd_pin -dir I -type clk axiClk
  create_bd_pin -dir I -type rst axiResetN
  create_bd_pin -dir I -type clk hsaeClk

  # Create instance: CH0_FIFO, and set properties
  set CH0_FIFO [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:FIFO2MM_Transport:2.0 CH0_FIFO ]
  set_property -dict [ list \
CONFIG.ACTUAL_DEPTH_CALC {8192} \
CONFIG.AVOID_DB_WIDTH_CALC {3} \
CONFIG.AXI_DATA_WIDTH {256} \
CONFIG.FIFO_INPUT_WIDTH_BYTES {2} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.MIN_DB_WIDTH_CALC {2} \
CONFIG.NUM_BR_COLS_PRE_CALC {8} \
CONFIG.NUM_BR_RANKS_CALC {1} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $CH0_FIFO

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /CH_FIFOS/CH0_FIFO/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /CH_FIFOS/CH0_FIFO/SAXIL_CFG]

  # Create instance: CH1_FIFO, and set properties
  set CH1_FIFO [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:FIFO2MM_Transport:2.0 CH1_FIFO ]
  set_property -dict [ list \
CONFIG.ACTUAL_DEPTH_CALC {8192} \
CONFIG.AVOID_DB_WIDTH_CALC {3} \
CONFIG.AXI_DATA_WIDTH {256} \
CONFIG.FIFO_INPUT_WIDTH_BYTES {2} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.MIN_DB_WIDTH_CALC {2} \
CONFIG.NUM_BR_COLS_PRE_CALC {8} \
CONFIG.NUM_BR_RANKS_CALC {1} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $CH1_FIFO

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /CH_FIFOS/CH1_FIFO/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /CH_FIFOS/CH1_FIFO/SAXIL_CFG]

  # Create instance: CH2_FIFO, and set properties
  set CH2_FIFO [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:FIFO2MM_Transport:2.0 CH2_FIFO ]
  set_property -dict [ list \
CONFIG.ACTUAL_DEPTH_CALC {8192} \
CONFIG.AVOID_DB_WIDTH_CALC {3} \
CONFIG.AXI_DATA_WIDTH {256} \
CONFIG.FIFO_INPUT_WIDTH_BYTES {2} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.MIN_DB_WIDTH_CALC {2} \
CONFIG.NUM_BR_COLS_PRE_CALC {8} \
CONFIG.NUM_BR_RANKS_CALC {1} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $CH2_FIFO

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /CH_FIFOS/CH2_FIFO/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /CH_FIFOS/CH2_FIFO/SAXIL_CFG]

  # Create instance: CH3_FIFO, and set properties
  set CH3_FIFO [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:FIFO2MM_Transport:2.0 CH3_FIFO ]
  set_property -dict [ list \
CONFIG.ACTUAL_DEPTH_CALC {8192} \
CONFIG.AVOID_DB_WIDTH_CALC {3} \
CONFIG.AXI_DATA_WIDTH {256} \
CONFIG.FIFO_INPUT_WIDTH_BYTES {2} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.MIN_DB_WIDTH_CALC {2} \
CONFIG.NUM_BR_COLS_PRE_CALC {8} \
CONFIG.NUM_BR_RANKS_CALC {1} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $CH3_FIFO

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /CH_FIFOS/CH3_FIFO/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /CH_FIFOS/CH3_FIFO/SAXIL_CFG]

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
CONFIG.NUM_MI {4} \
CONFIG.S00_HAS_REGSLICE {1} \
 ] $axi_interconnect_0

  # Create instance: ch_axi
  create_hier_cell_ch_axi $hier_obj ch_axi

  # Create interface connections
  connect_bd_intf_net -intf_net CH0_FIFO_MAXI_DATA [get_bd_intf_pins CH0_FIFO/MAXI_DATA] [get_bd_intf_pins ch_axi/S00_AXI]
  connect_bd_intf_net -intf_net CH1_FIFO_MAXI_DATA [get_bd_intf_pins CH1_FIFO/MAXI_DATA] [get_bd_intf_pins ch_axi/S01_AXI]
  connect_bd_intf_net -intf_net CH2_FIFO_MAXI_DATA [get_bd_intf_pins CH2_FIFO/MAXI_DATA] [get_bd_intf_pins ch_axi/S02_AXI]
  connect_bd_intf_net -intf_net CH3_FIFO_MAXI_DATA [get_bd_intf_pins CH3_FIFO/MAXI_DATA] [get_bd_intf_pins ch_axi/S03_AXI]
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins CH0_FIFO] [get_bd_intf_pins CH0_FIFO/FIFO_DATA_IN]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins CH1_FIFO] [get_bd_intf_pins CH1_FIFO/FIFO_DATA_IN]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins CH2_FIFO] [get_bd_intf_pins CH2_FIFO/FIFO_DATA_IN]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins CH3_FIFO] [get_bd_intf_pins CH3_FIFO/FIFO_DATA_IN]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins CFG_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins CH0_FIFO/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins CH1_FIFO/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins CH2_FIFO/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_pins CH3_FIFO/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M03_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins DATA_AXI] [get_bd_intf_pins ch_axi/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins axiClk] [get_bd_pins CH0_FIFO/axiClk] [get_bd_pins CH1_FIFO/axiClk] [get_bd_pins CH2_FIFO/axiClk] [get_bd_pins CH3_FIFO/axiClk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/M03_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins ch_axi/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins axiResetN] [get_bd_pins CH0_FIFO/axiResetN] [get_bd_pins CH1_FIFO/axiResetN] [get_bd_pins CH2_FIFO/axiResetN] [get_bd_pins CH3_FIFO/axiResetN] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins ch_axi/aresetn]
  connect_bd_net -net inputClk_1 [get_bd_pins hsaeClk] [get_bd_pins CH0_FIFO/inputClk] [get_bd_pins CH1_FIFO/inputClk] [get_bd_pins CH2_FIFO/inputClk] [get_bd_pins CH3_FIFO/inputClk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set CH0_FIFO [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 CH0_FIFO ]
  set CH1_FIFO [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 CH1_FIFO ]
  set CH2_FIFO [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 CH2_FIFO ]
  set CH3_FIFO [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 CH3_FIFO ]
  set PCIE_AXI [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:vDAQ_PCIE_AXI_rtl:1.0 PCIE_AXI ]
  set SI_AUX_FIFO [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 SI_AUX_FIFO ]
  set SI_DATA_FIFO [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 SI_DATA_FIFO ]
  set SI_SCOPE_FIFO [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 SI_SCOPE_FIFO ]

  # Create ports
  set CLKCFG_BOARD_IO [ create_bd_port -dir IO -from 5 -to 0 CLKCFG_BOARD_IO ]
  set LSADC_BOARD_IO [ create_bd_port -dir IO -from 8 -to 0 LSADC_BOARD_IO ]
  set LSDAC_BOARD_IO [ create_bd_port -dir IO -from 20 -to 0 LSDAC_BOARD_IO ]
  set MSADC_BOARD_IO [ create_bd_port -dir IO -from 30 -to 0 MSADC_BOARD_IO ]
  set PCIE_SAXIL_readAddress [ create_bd_port -dir O -from 11 -to 0 PCIE_SAXIL_readAddress ]
  set PCIE_SAXIL_readData [ create_bd_port -dir I -from 31 -to 0 PCIE_SAXIL_readData ]
  set PCIE_SAXIL_writeAddress [ create_bd_port -dir O -from 11 -to 0 PCIE_SAXIL_writeAddress ]
  set PCIE_SAXIL_writeData [ create_bd_port -dir O -from 31 -to 0 PCIE_SAXIL_writeData ]
  set PCIE_SAXIL_writeStrobe [ create_bd_port -dir O -from 3 -to 0 PCIE_SAXIL_writeStrobe ]
  set ao_watchdog_trigger [ create_bd_port -dir I ao_watchdog_trigger ]
  set digitalTask0_o [ create_bd_port -dir O -from 7 -to 0 digitalTask0_o ]
  set digitalTask1_o [ create_bd_port -dir O -from 7 -to 0 digitalTask1_o ]
  set digitalTask2_o [ create_bd_port -dir O -from 7 -to 0 digitalTask2_o ]
  set digitalTask3_o [ create_bd_port -dir O -from 7 -to 0 digitalTask3_o ]
  set ext_triggers [ create_bd_port -dir I -from 44 -to 0 ext_triggers ]
  set hsaeClk [ create_bd_port -dir O -type clk hsaeClk ]
  set ioClk40 [ create_bd_port -dir I -type clk ioClk40 ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {40000000} \
 ] $ioClk40
  set ioClk120 [ create_bd_port -dir I -type clk ioClk120 ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {120000000} \
 ] $ioClk120
  set lsadcSpiClkEn [ create_bd_port -dir I lsadcSpiClkEn ]
  set lsdacSpiClkEn [ create_bd_port -dir I lsdacSpiClkEn ]
  set msadcSampleData [ create_bd_port -dir O -from 55 -to 0 -type data msadcSampleData ]
  set pcie_aclk [ create_bd_port -dir I -type clk pcie_aclk ]
  set_property -dict [ list \
CONFIG.ASSOCIATED_RESET {pcie_aresetn} \
CONFIG.CLK_DOMAIN {vDAQ_BD_pcie_aclk} \
CONFIG.FREQ_HZ {125000000} \
 ] $pcie_aclk
  set pcie_aresetn [ create_bd_port -dir I -type rst pcie_aresetn ]
  set peer_triggers [ create_bd_port -dir IO -from 12 -to 0 peer_triggers ]
  set sysClk200 [ create_bd_port -dir I -type clk sysClk200 ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {100000000} \
 ] $sysClk200

  # Create instance: CH_FIFOS
  create_hier_cell_CH_FIFOS [current_bd_instance .] CH_FIFOS

  # Create instance: CLKCFG, and set properties
  set CLKCFG [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:vDAQR0_CLKCFG:1.0 CLKCFG ]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /CLKCFG/SAXIL_CFG]

  # Create instance: DAQ
  create_hier_cell_DAQ [current_bd_instance .] DAQ

  # Create instance: MSADC, and set properties
  set MSADC [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:vDAQ_MSADC:1.0 MSADC ]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /MSADC/SAXIL_CFG]

  # Create instance: PCIE_AXI
  create_hier_cell_PCIE_AXI [current_bd_instance .] PCIE_AXI

  # Create instance: PCIE_SAXIL, and set properties
  set PCIE_SAXIL [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:AXI_Lite_Slave_RTL_Interface:1.0 PCIE_SAXIL ]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /PCIE_SAXIL/SAXIL]

  # Create instance: SI_ACQ_FIFO, and set properties
  set SI_ACQ_FIFO [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:FIFO2MM_Transport:2.0 SI_ACQ_FIFO ]
  set_property -dict [ list \
CONFIG.ACTUAL_DEPTH_CALC {2048} \
CONFIG.AVOID_DB_WIDTH_CALC {9} \
CONFIG.AXI_DATA_WIDTH {256} \
CONFIG.FIFO_DEPTH {1024} \
CONFIG.FIFO_INPUT_WIDTH_BYTES {8} \
CONFIG.FIFO_VARIABLE_INPUT_WIDTH {true} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.MIN_DB_WIDTH_CALC {8} \
CONFIG.NUM_BR_COLS_PRE_CALC {8} \
CONFIG.NUM_BR_RANKS_CALC {1} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $SI_ACQ_FIFO

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /SI_ACQ_FIFO/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /SI_ACQ_FIFO/SAXIL_CFG]

  # Create instance: SI_AUX_FIFO, and set properties
  set SI_AUX_FIFO [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:FIFO2MM_Transport:2.0 SI_AUX_FIFO ]
  set_property -dict [ list \
CONFIG.ACTUAL_DEPTH_CALC {1638} \
CONFIG.AVOID_DB_WIDTH_CALC {11} \
CONFIG.AXI_DATA_WIDTH {256} \
CONFIG.FIFO_INPUT_WIDTH_BYTES {10} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.MIN_DB_WIDTH_CALC {10} \
CONFIG.NUM_BR_COLS_PRE_CALC {8} \
CONFIG.NUM_BR_RANKS_CALC {1} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $SI_AUX_FIFO

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /SI_AUX_FIFO/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /SI_AUX_FIFO/SAXIL_CFG]

  # Create instance: SI_SCOPE_FIFO, and set properties
  set SI_SCOPE_FIFO [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:FIFO2MM_Transport:2.0 SI_SCOPE_FIFO ]
  set_property -dict [ list \
CONFIG.ACTUAL_DEPTH_CALC {3276} \
CONFIG.AVOID_DB_WIDTH_CALC {11} \
CONFIG.AXI_DATA_WIDTH {256} \
CONFIG.DEV_BUF_NUM_BR_CALC {16} \
CONFIG.DEV_BUF_SIZE_KB_CALC {32} \
CONFIG.FIFO_DEPTH {2000} \
CONFIG.FIFO_INPUT_WIDTH_BYTES {10} \
CONFIG.FIFO_VARIABLE_INPUT_WIDTH {true} \
CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
CONFIG.MIN_DB_WIDTH_CALC {10} \
CONFIG.NUM_BR_COLS_PRE_CALC {8} \
CONFIG.NUM_BR_RANKS_CALC {2} \
CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $SI_SCOPE_FIFO

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /SI_SCOPE_FIFO/MAXI_DATA]

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /SI_SCOPE_FIFO/SAXIL_CFG]

  # Create interface connections
  connect_bd_intf_net -intf_net CH0_FIFO_1 [get_bd_intf_ports CH0_FIFO] [get_bd_intf_pins CH_FIFOS/CH0_FIFO]
  connect_bd_intf_net -intf_net CH1_FIFO_1 [get_bd_intf_ports CH1_FIFO] [get_bd_intf_pins CH_FIFOS/CH1_FIFO]
  connect_bd_intf_net -intf_net CH2_FIFO_1 [get_bd_intf_ports CH2_FIFO] [get_bd_intf_pins CH_FIFOS/CH2_FIFO]
  connect_bd_intf_net -intf_net CH3_FIFO_1 [get_bd_intf_ports CH3_FIFO] [get_bd_intf_pins CH_FIFOS/CH3_FIFO]
  connect_bd_intf_net -intf_net DAQ_M00_AXI4 [get_bd_intf_pins DAQ/M00_AXI4] [get_bd_intf_pins PCIE_AXI/S07_AXI]
  connect_bd_intf_net -intf_net PCIE_AXI_1 [get_bd_intf_ports PCIE_AXI] [get_bd_intf_pins PCIE_AXI/PCIE_AXI]
  connect_bd_intf_net -intf_net PCIE_AXI_M01_AXI [get_bd_intf_pins PCIE_AXI/M01_AXI] [get_bd_intf_pins SI_AUX_FIFO/SAXIL_CFG]
  connect_bd_intf_net -intf_net PCIE_AXI_M05_AXI [get_bd_intf_pins MSADC/SAXIL_CFG] [get_bd_intf_pins PCIE_AXI/M05_AXI]
  connect_bd_intf_net -intf_net PCIE_AXI_M06_AXI [get_bd_intf_pins PCIE_AXI/M06_AXI] [get_bd_intf_pins SI_ACQ_FIFO/SAXIL_CFG]
  connect_bd_intf_net -intf_net PCIE_AXI_M07_AXI [get_bd_intf_pins PCIE_AXI/M07_AXI] [get_bd_intf_pins SI_SCOPE_FIFO/SAXIL_CFG]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins CH_FIFOS/CFG_AXI] [get_bd_intf_pins PCIE_AXI/M08_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins DAQ/M00_AXI1] [get_bd_intf_pins PCIE_AXI/S01_AXI]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins DAQ/M00_AXI2] [get_bd_intf_pins PCIE_AXI/S02_AXI]
  connect_bd_intf_net -intf_net SI_ACQ_FIFO_MAXI_DATA [get_bd_intf_pins PCIE_AXI/S04_AXI] [get_bd_intf_pins SI_ACQ_FIFO/MAXI_DATA]
  connect_bd_intf_net -intf_net SI_AUX_FIFO_1 [get_bd_intf_ports SI_AUX_FIFO] [get_bd_intf_pins SI_AUX_FIFO/FIFO_DATA_IN]
  connect_bd_intf_net -intf_net SI_AUX_FIFO_MAXI_DATA [get_bd_intf_pins PCIE_AXI/S03_AXI] [get_bd_intf_pins SI_AUX_FIFO/MAXI_DATA]
  connect_bd_intf_net -intf_net SI_DATA_FIFO_1 [get_bd_intf_ports SI_DATA_FIFO] [get_bd_intf_pins SI_ACQ_FIFO/FIFO_DATA_IN]
  connect_bd_intf_net -intf_net SI_SCOPE_FIFO_1 [get_bd_intf_ports SI_SCOPE_FIFO] [get_bd_intf_pins SI_SCOPE_FIFO/FIFO_DATA_IN]
  connect_bd_intf_net -intf_net SI_SCOPE_FIFO_MAXI_DATA [get_bd_intf_pins PCIE_AXI/S05_AXI] [get_bd_intf_pins SI_SCOPE_FIFO/MAXI_DATA]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins CH_FIFOS/DATA_AXI] [get_bd_intf_pins PCIE_AXI/S06_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M00_AXI [get_bd_intf_pins PCIE_AXI/M00_AXI] [get_bd_intf_pins PCIE_SAXIL/SAXIL]
  connect_bd_intf_net -intf_net axi_interconnect_4_M02_AXI [get_bd_intf_pins DAQ/S00_AXI1] [get_bd_intf_pins PCIE_AXI/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M03_AXI [get_bd_intf_pins DAQ/S00_AXI2] [get_bd_intf_pins PCIE_AXI/M03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M04_AXI [get_bd_intf_pins CLKCFG/SAXIL_CFG] [get_bd_intf_pins PCIE_AXI/M04_AXI]

  # Create port connections
  connect_bd_net -net AXI_Lite_Slave_RTL_Interface_1_readAddress [get_bd_ports PCIE_SAXIL_readAddress] [get_bd_pins PCIE_SAXIL/readAddress]
  connect_bd_net -net AXI_Lite_Slave_RTL_Interface_1_writeAddress [get_bd_ports PCIE_SAXIL_writeAddress] [get_bd_pins PCIE_SAXIL/writeAddress]
  connect_bd_net -net AXI_Lite_Slave_RTL_Interface_1_writeData [get_bd_ports PCIE_SAXIL_writeData] [get_bd_pins PCIE_SAXIL/writeData]
  connect_bd_net -net AXI_Lite_Slave_RTL_Interface_1_writeStrobe [get_bd_ports PCIE_SAXIL_writeStrobe] [get_bd_pins PCIE_SAXIL/writeStrobe]
  connect_bd_net -net DAQ_outputLines [get_bd_ports digitalTask0_o] [get_bd_pins DAQ/outputLines0]
  connect_bd_net -net DAQ_outputLines1 [get_bd_ports digitalTask1_o] [get_bd_pins DAQ/outputLines1]
  connect_bd_net -net DAQ_outputLines2 [get_bd_ports digitalTask2_o] [get_bd_pins DAQ/outputLines2]
  connect_bd_net -net DAQ_outputLines3 [get_bd_ports digitalTask3_o] [get_bd_pins DAQ/outputLines3]
  connect_bd_net -net Net [get_bd_ports LSADC_BOARD_IO] [get_bd_pins DAQ/LSADC_IO]
  connect_bd_net -net Net1 [get_bd_ports LSDAC_BOARD_IO] [get_bd_pins DAQ/LSDAC_IO]
  connect_bd_net -net Net2 [get_bd_ports CLKCFG_BOARD_IO] [get_bd_pins CLKCFG/BOARD_IO]
  connect_bd_net -net Net3 [get_bd_ports MSADC_BOARD_IO] [get_bd_pins MSADC/BOARD_IO]
  connect_bd_net -net Net4 [get_bd_ports peer_triggers] [get_bd_pins DAQ/peer_triggers]
  connect_bd_net -net SYS_SAXIL_readData_1 [get_bd_ports PCIE_SAXIL_readData] [get_bd_pins PCIE_SAXIL/readData]
  connect_bd_net -net ao_watchdog_trigger_1 [get_bd_ports ao_watchdog_trigger] [get_bd_pins DAQ/ao_watchdog_trigger]
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_ports pcie_aclk] [get_bd_pins CH_FIFOS/axiClk] [get_bd_pins DAQ/axiClk] [get_bd_pins PCIE_AXI/aclk] [get_bd_pins PCIE_SAXIL/ACLK] [get_bd_pins SI_ACQ_FIFO/axiClk] [get_bd_pins SI_AUX_FIFO/axiClk] [get_bd_pins SI_SCOPE_FIFO/axiClk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_ports pcie_aresetn] [get_bd_pins CH_FIFOS/axiResetN] [get_bd_pins DAQ/axiResetN] [get_bd_pins PCIE_AXI/aresetn] [get_bd_pins PCIE_SAXIL/ARESETN] [get_bd_pins SI_ACQ_FIFO/axiResetN] [get_bd_pins SI_AUX_FIFO/axiResetN] [get_bd_pins SI_SCOPE_FIFO/axiResetN]
  connect_bd_net -net ext_triggers_1 [get_bd_ports ext_triggers] [get_bd_pins DAQ/ext_triggers]
  connect_bd_net -net lsadcSpiClkEn_1 [get_bd_ports lsadcSpiClkEn] [get_bd_pins DAQ/lsadcSpiClkEn]
  connect_bd_net -net lsdacSpiClkEn_1 [get_bd_ports lsdacSpiClkEn] [get_bd_pins DAQ/lsdacSpiClkEn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins CLKCFG/axiResetN] [get_bd_pins MSADC/axiResetN] [get_bd_pins PCIE_AXI/aresetn_40]
  connect_bd_net -net sampleClkTimebase_1 [get_bd_ports sysClk200] [get_bd_pins DAQ/sampleClkTimebase]
  connect_bd_net -net sysClk120_1 [get_bd_ports ioClk120] [get_bd_pins DAQ/ioClk120]
  connect_bd_net -net sysClk40_1 [get_bd_ports ioClk40] [get_bd_pins CLKCFG/clk40] [get_bd_pins MSADC/clk40] [get_bd_pins PCIE_AXI/ioClk40]
  connect_bd_net -net vDAQ_MSADC_0_sampleClk1 [get_bd_ports hsaeClk] [get_bd_pins CH_FIFOS/hsaeClk] [get_bd_pins MSADC/sampleClk] [get_bd_pins SI_ACQ_FIFO/inputClk] [get_bd_pins SI_AUX_FIFO/inputClk] [get_bd_pins SI_SCOPE_FIFO/inputClk]
  connect_bd_net -net vDAQ_MSADC_0_sampleData [get_bd_ports msadcSampleData] [get_bd_pins MSADC/sampleData]

  # Create address segments
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces SI_ACQ_FIFO/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces SI_AUX_FIFO/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces SI_SCOPE_FIFO/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces CH_FIFOS/CH0_FIFO/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces CH_FIFOS/CH1_FIFO/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces CH_FIFOS/CH2_FIFO/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces CH_FIFOS/CH3_FIFO/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Digital_Waveform_Gen_0/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Digital_Waveform_Gen_1/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Digital_Waveform_Gen_2/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Digital_Waveform_Gen_3/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_0/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_1/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_2/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_3/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_0/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_1/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_2/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_3/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_4/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] SEG_vDAQ_PCIE_AXI_0_reg0
  create_bd_addr_seg -range 0x00001000 -offset 0x00470000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs CH_FIFOS/CH0_FIFO/SAXIL_CFG/reg0] SEG_CH0_FIFO_reg0
  create_bd_addr_seg -range 0x00001000 -offset 0x00471000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs CH_FIFOS/CH1_FIFO/SAXIL_CFG/reg0] SEG_CH1_FIFO_reg0
  create_bd_addr_seg -range 0x00001000 -offset 0x00472000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs CH_FIFOS/CH2_FIFO/SAXIL_CFG/reg0] SEG_CH2_FIFO_reg0
  create_bd_addr_seg -range 0x00001000 -offset 0x00473000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs CH_FIFOS/CH3_FIFO/SAXIL_CFG/reg0] SEG_CH3_FIFO_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x00300000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Digital_Waveform_Gen_0/SAXI_CFG/reg0] SEG_Digital_Waveform_Gen_0_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x00310000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Digital_Waveform_Gen_1/SAXI_CFG/reg0] SEG_Digital_Waveform_Gen_1_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x00320000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Digital_Waveform_Gen_2/SAXI_CFG/reg0] SEG_Digital_Waveform_Gen_2_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x00330000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Digital_Waveform_Gen_3/SAXI_CFG/reg0] SEG_Digital_Waveform_Gen_3_reg0
  create_bd_addr_seg -range 0x00001000 -offset 0x00480000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs SI_ACQ_FIFO/SAXIL_CFG/reg0] SEG_SI_ACQ_FIFO_reg0
  create_bd_addr_seg -range 0x00001000 -offset 0x00481000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs SI_AUX_FIFO/SAXIL_CFG/reg0] SEG_SI_AUX_FIFO_reg0
  create_bd_addr_seg -range 0x00001000 -offset 0x00482000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs SI_SCOPE_FIFO/SAXIL_CFG/reg0] SEG_SI_SCOPE_FIFO_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x00400000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs PCIE_SAXIL/SAXIL/Reg] SEG_SYS_SAXIL_INTF_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00500000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_0/SAXIL_CFG/Reg] SEG_Slow_Waveform_Acq_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00510000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_1/SAXIL_CFG/Reg] SEG_Slow_Waveform_Acq_1_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00520000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_2/SAXIL_CFG/Reg] SEG_Slow_Waveform_Acq_2_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00530000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_3/SAXIL_CFG/Reg] SEG_Slow_Waveform_Acq_3_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00600000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_0/SAXIL_CFG/reg0] SEG_Slow_Waveform_Gen_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00610000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_1/SAXIL_CFG/reg0] SEG_Slow_Waveform_Gen_1_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00620000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_2/SAXIL_CFG/reg0] SEG_Slow_Waveform_Gen_2_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00630000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_3/SAXIL_CFG/reg0] SEG_Slow_Waveform_Gen_3_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00640000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_4/SAXIL_CFG/reg0] SEG_Slow_Waveform_Gen_4_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00440000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs CLKCFG/SAXIL_CFG/reg0] SEG_vDAQR0_CLKCFG_0_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x00460000 [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs MSADC/SAXIL_CFG/reg0] SEG_vDAQ_MSADC_0_reg0


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


