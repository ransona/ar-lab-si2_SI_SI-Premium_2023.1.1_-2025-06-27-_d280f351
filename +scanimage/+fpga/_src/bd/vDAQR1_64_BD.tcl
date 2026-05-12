
################################################################
# This is a generated script based on design: vDAQR1_BD
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
set scripts_vivado_version 2020.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source vDAQR1_BD_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcku035-ffva1156-1-c
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name vDAQR1_BD

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
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

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

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
vidriotechnologies.com:vidrio:vDAQR1_CLKCFG:1.0\
vidriotechnologies.com:vidrio:vDAQ_HSADC:1.0\
vidriotechnologies.com:vidrio:AXI_Lite_Slave_RTL_Interface:1.0\
vidriotechnologies.com:vidrio:FIFO2MM_Transport:2.0\
vidriotech.com:vidrio:Digital_Waveform_Gen:1.0\
vidriotechnologies.com:vidrio:vDAQR1_LSADC:1.0\
vidriotechnologies.com:vidrio:vDAQR1_LSDAC:1.0\
vidriotech.com:vidrio:Slow_Waveform_Acq:1.0\
vidriotech.com:vidrio:Slow_Waveform_Gen:1.0\
xilinx.com:ip:proc_sys_reset:5.0\
vidriotechnologies.com:vidrio:vDAQ_PCIE_AXI:1.0\
xilinx.com:ip:axi_crossbar:2.1\
xilinx.com:ip:axi_register_slice:2.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: dma_axi
proc create_hier_cell_dma_axi { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_dma_axi() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S07_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S08_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S09_AXI


  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn

  # Create instance: axi_crossbar_0, and set properties
  set axi_crossbar_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_0 ]
  set_property -dict [ list \
   CONFIG.M00_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_READ_ISSUING {8} \
   CONFIG.M01_A00_ADDR_WIDTH {0} \
   CONFIG.M01_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_READ_ISSUING {8} \
   CONFIG.M01_WRITE_ISSUING {8} \
   CONFIG.M02_A00_ADDR_WIDTH {0} \
   CONFIG.M02_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_READ_ISSUING {8} \
   CONFIG.M02_WRITE_ISSUING {8} \
   CONFIG.M03_A00_ADDR_WIDTH {0} \
   CONFIG.M03_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_READ_ISSUING {8} \
   CONFIG.M03_WRITE_ISSUING {8} \
   CONFIG.M04_A00_ADDR_WIDTH {0} \
   CONFIG.M04_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_READ_ISSUING {8} \
   CONFIG.M04_WRITE_ISSUING {8} \
   CONFIG.M05_A00_ADDR_WIDTH {0} \
   CONFIG.M05_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_READ_ISSUING {8} \
   CONFIG.M05_WRITE_ISSUING {8} \
   CONFIG.M06_A00_ADDR_WIDTH {0} \
   CONFIG.M06_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_READ_ISSUING {8} \
   CONFIG.M06_WRITE_ISSUING {8} \
   CONFIG.M07_A00_ADDR_WIDTH {0} \
   CONFIG.M07_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_READ_ISSUING {8} \
   CONFIG.M07_WRITE_ISSUING {8} \
   CONFIG.M08_A00_ADDR_WIDTH {0} \
   CONFIG.M08_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_READ_ISSUING {8} \
   CONFIG.M08_WRITE_ISSUING {8} \
   CONFIG.M09_A00_ADDR_WIDTH {0} \
   CONFIG.M09_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_READ_ISSUING {8} \
   CONFIG.M09_WRITE_ISSUING {8} \
   CONFIG.M10_A00_ADDR_WIDTH {0} \
   CONFIG.M10_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_READ_ISSUING {8} \
   CONFIG.M10_WRITE_ISSUING {8} \
   CONFIG.M11_A00_ADDR_WIDTH {0} \
   CONFIG.M11_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_READ_ISSUING {8} \
   CONFIG.M11_WRITE_ISSUING {8} \
   CONFIG.M12_A00_ADDR_WIDTH {0} \
   CONFIG.M12_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_READ_ISSUING {8} \
   CONFIG.M12_WRITE_ISSUING {8} \
   CONFIG.M13_A00_ADDR_WIDTH {0} \
   CONFIG.M13_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_READ_ISSUING {8} \
   CONFIG.M13_WRITE_ISSUING {8} \
   CONFIG.M14_A00_ADDR_WIDTH {0} \
   CONFIG.M14_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_READ_ISSUING {8} \
   CONFIG.M14_WRITE_ISSUING {8} \
   CONFIG.M15_A00_ADDR_WIDTH {0} \
   CONFIG.M15_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_READ_ISSUING {8} \
   CONFIG.M15_WRITE_ISSUING {8} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {10} \
   CONFIG.S00_READ_ACCEPTANCE {4} \
   CONFIG.S00_WRITE_ACCEPTANCE {4} \
   CONFIG.S01_BASE_ID {0x00000004} \
   CONFIG.S01_READ_ACCEPTANCE {4} \
   CONFIG.S01_WRITE_ACCEPTANCE {4} \
   CONFIG.S02_BASE_ID {0x00000008} \
   CONFIG.S02_READ_ACCEPTANCE {4} \
   CONFIG.S03_BASE_ID {0x0000000c} \
   CONFIG.S03_READ_ACCEPTANCE {4} \
   CONFIG.S04_BASE_ID {0x00000010} \
   CONFIG.S04_READ_ACCEPTANCE {4} \
   CONFIG.S05_BASE_ID {0x00000014} \
   CONFIG.S05_READ_ACCEPTANCE {4} \
   CONFIG.S05_WRITE_ACCEPTANCE {4} \
   CONFIG.S06_BASE_ID {0x00000018} \
   CONFIG.S06_READ_ACCEPTANCE {4} \
   CONFIG.S06_WRITE_ACCEPTANCE {4} \
   CONFIG.S07_BASE_ID {0x0000001c} \
   CONFIG.S07_READ_ACCEPTANCE {4} \
   CONFIG.S07_WRITE_ACCEPTANCE {4} \
   CONFIG.S08_BASE_ID {0x00000020} \
   CONFIG.S08_READ_ACCEPTANCE {4} \
   CONFIG.S08_WRITE_ACCEPTANCE {4} \
   CONFIG.S09_BASE_ID {0x00000024} \
   CONFIG.S09_READ_ACCEPTANCE {4} \
   CONFIG.S10_BASE_ID {0x00000028} \
   CONFIG.S10_READ_ACCEPTANCE {4} \
   CONFIG.S11_BASE_ID {0x0000002c} \
   CONFIG.S11_READ_ACCEPTANCE {4} \
   CONFIG.S11_WRITE_ACCEPTANCE {4} \
   CONFIG.S12_BASE_ID {0x00000030} \
   CONFIG.S12_READ_ACCEPTANCE {4} \
   CONFIG.S12_WRITE_ACCEPTANCE {4} \
   CONFIG.S13_BASE_ID {0x00000034} \
   CONFIG.S13_READ_ACCEPTANCE {4} \
   CONFIG.S13_WRITE_ACCEPTANCE {4} \
   CONFIG.S14_BASE_ID {0x00000038} \
   CONFIG.S14_READ_ACCEPTANCE {4} \
   CONFIG.S14_WRITE_ACCEPTANCE {4} \
   CONFIG.S15_BASE_ID {0x0000003c} \
   CONFIG.S15_READ_ACCEPTANCE {4} \
   CONFIG.S15_WRITE_ACCEPTANCE {4} \
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
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net S03_AXI_1 [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
  connect_bd_intf_net -intf_net S04_AXI_2 [get_bd_intf_pins S04_AXI] [get_bd_intf_pins axi_crossbar_0/S04_AXI]
  connect_bd_intf_net -intf_net S06_AXI_1 [get_bd_intf_pins S05_AXI] [get_bd_intf_pins axi_crossbar_0/S05_AXI]
  connect_bd_intf_net -intf_net S07_AXI_1 [get_bd_intf_pins S06_AXI] [get_bd_intf_pins axi_crossbar_0/S06_AXI]
  connect_bd_intf_net -intf_net S08_AXI_1 [get_bd_intf_pins S07_AXI] [get_bd_intf_pins axi_crossbar_0/S07_AXI]
  connect_bd_intf_net -intf_net S09_AXI_1 [get_bd_intf_pins S08_AXI] [get_bd_intf_pins axi_crossbar_0/S08_AXI]
  connect_bd_intf_net -intf_net S10_AXI_1 [get_bd_intf_pins S09_AXI] [get_bd_intf_pins axi_crossbar_0/S09_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_register_slice_0/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_register_slice_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_register_slice_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: wg_axi_2
proc create_hier_cell_wg_axi_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_wg_axi_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
   CONFIG.M00_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_READ_ISSUING {8} \
   CONFIG.M00_WRITE_ISSUING {8} \
   CONFIG.M01_A00_ADDR_WIDTH {0} \
   CONFIG.M01_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_READ_ISSUING {8} \
   CONFIG.M01_WRITE_ISSUING {8} \
   CONFIG.M02_A00_ADDR_WIDTH {0} \
   CONFIG.M02_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_READ_ISSUING {8} \
   CONFIG.M02_WRITE_ISSUING {8} \
   CONFIG.M03_A00_ADDR_WIDTH {0} \
   CONFIG.M03_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_READ_ISSUING {8} \
   CONFIG.M03_WRITE_ISSUING {8} \
   CONFIG.M04_A00_ADDR_WIDTH {0} \
   CONFIG.M04_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_READ_ISSUING {8} \
   CONFIG.M04_WRITE_ISSUING {8} \
   CONFIG.M05_A00_ADDR_WIDTH {0} \
   CONFIG.M05_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_READ_ISSUING {8} \
   CONFIG.M05_WRITE_ISSUING {8} \
   CONFIG.M06_A00_ADDR_WIDTH {0} \
   CONFIG.M06_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_READ_ISSUING {8} \
   CONFIG.M06_WRITE_ISSUING {8} \
   CONFIG.M07_A00_ADDR_WIDTH {0} \
   CONFIG.M07_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_READ_ISSUING {8} \
   CONFIG.M07_WRITE_ISSUING {8} \
   CONFIG.M08_A00_ADDR_WIDTH {0} \
   CONFIG.M08_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_READ_ISSUING {8} \
   CONFIG.M08_WRITE_ISSUING {8} \
   CONFIG.M09_A00_ADDR_WIDTH {0} \
   CONFIG.M09_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_READ_ISSUING {8} \
   CONFIG.M09_WRITE_ISSUING {8} \
   CONFIG.M10_A00_ADDR_WIDTH {0} \
   CONFIG.M10_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_READ_ISSUING {8} \
   CONFIG.M10_WRITE_ISSUING {8} \
   CONFIG.M11_A00_ADDR_WIDTH {0} \
   CONFIG.M11_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_READ_ISSUING {8} \
   CONFIG.M11_WRITE_ISSUING {8} \
   CONFIG.M12_A00_ADDR_WIDTH {0} \
   CONFIG.M12_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_READ_ISSUING {8} \
   CONFIG.M12_WRITE_ISSUING {8} \
   CONFIG.M13_A00_ADDR_WIDTH {0} \
   CONFIG.M13_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_READ_ISSUING {8} \
   CONFIG.M13_WRITE_ISSUING {8} \
   CONFIG.M14_A00_ADDR_WIDTH {0} \
   CONFIG.M14_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_READ_ISSUING {8} \
   CONFIG.M14_WRITE_ISSUING {8} \
   CONFIG.M15_A00_ADDR_WIDTH {0} \
   CONFIG.M15_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_READ_ISSUING {8} \
   CONFIG.M15_WRITE_ISSUING {8} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_READ_ACCEPTANCE {4} \
   CONFIG.S00_WRITE_ACCEPTANCE {4} \
   CONFIG.S01_READ_ACCEPTANCE {4} \
   CONFIG.S01_WRITE_ACCEPTANCE {4} \
   CONFIG.S02_READ_ACCEPTANCE {4} \
   CONFIG.S02_WRITE_ACCEPTANCE {4} \
   CONFIG.S03_READ_ACCEPTANCE {4} \
   CONFIG.S03_WRITE_ACCEPTANCE {4} \
   CONFIG.S04_READ_ACCEPTANCE {4} \
   CONFIG.S04_WRITE_ACCEPTANCE {4} \
   CONFIG.S05_READ_ACCEPTANCE {4} \
   CONFIG.S05_WRITE_ACCEPTANCE {4} \
   CONFIG.S06_READ_ACCEPTANCE {4} \
   CONFIG.S06_WRITE_ACCEPTANCE {4} \
   CONFIG.S07_READ_ACCEPTANCE {4} \
   CONFIG.S07_WRITE_ACCEPTANCE {4} \
   CONFIG.S08_READ_ACCEPTANCE {4} \
   CONFIG.S08_WRITE_ACCEPTANCE {4} \
   CONFIG.S09_READ_ACCEPTANCE {4} \
   CONFIG.S09_WRITE_ACCEPTANCE {4} \
   CONFIG.S10_READ_ACCEPTANCE {4} \
   CONFIG.S10_WRITE_ACCEPTANCE {4} \
   CONFIG.S11_READ_ACCEPTANCE {4} \
   CONFIG.S11_WRITE_ACCEPTANCE {4} \
   CONFIG.S12_READ_ACCEPTANCE {4} \
   CONFIG.S12_WRITE_ACCEPTANCE {4} \
   CONFIG.S13_READ_ACCEPTANCE {4} \
   CONFIG.S13_WRITE_ACCEPTANCE {4} \
   CONFIG.S14_READ_ACCEPTANCE {4} \
   CONFIG.S14_WRITE_ACCEPTANCE {4} \
   CONFIG.S15_READ_ACCEPTANCE {4} \
   CONFIG.S15_WRITE_ACCEPTANCE {4} \
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
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_MAXI_DATA [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_3_MAXI_DATA [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_6_MAXI_DATA [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_9_MAXI_DATA [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_register_slice_0/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_register_slice_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_register_slice_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: wg_axi_1
proc create_hier_cell_wg_axi_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_wg_axi_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
   CONFIG.M00_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_READ_ISSUING {8} \
   CONFIG.M00_WRITE_ISSUING {8} \
   CONFIG.M01_A00_ADDR_WIDTH {0} \
   CONFIG.M01_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_READ_ISSUING {8} \
   CONFIG.M01_WRITE_ISSUING {8} \
   CONFIG.M02_A00_ADDR_WIDTH {0} \
   CONFIG.M02_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_READ_ISSUING {8} \
   CONFIG.M02_WRITE_ISSUING {8} \
   CONFIG.M03_A00_ADDR_WIDTH {0} \
   CONFIG.M03_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_READ_ISSUING {8} \
   CONFIG.M03_WRITE_ISSUING {8} \
   CONFIG.M04_A00_ADDR_WIDTH {0} \
   CONFIG.M04_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_READ_ISSUING {8} \
   CONFIG.M04_WRITE_ISSUING {8} \
   CONFIG.M05_A00_ADDR_WIDTH {0} \
   CONFIG.M05_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_READ_ISSUING {8} \
   CONFIG.M05_WRITE_ISSUING {8} \
   CONFIG.M06_A00_ADDR_WIDTH {0} \
   CONFIG.M06_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_READ_ISSUING {8} \
   CONFIG.M06_WRITE_ISSUING {8} \
   CONFIG.M07_A00_ADDR_WIDTH {0} \
   CONFIG.M07_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_READ_ISSUING {8} \
   CONFIG.M07_WRITE_ISSUING {8} \
   CONFIG.M08_A00_ADDR_WIDTH {0} \
   CONFIG.M08_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_READ_ISSUING {8} \
   CONFIG.M08_WRITE_ISSUING {8} \
   CONFIG.M09_A00_ADDR_WIDTH {0} \
   CONFIG.M09_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_READ_ISSUING {8} \
   CONFIG.M09_WRITE_ISSUING {8} \
   CONFIG.M10_A00_ADDR_WIDTH {0} \
   CONFIG.M10_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_READ_ISSUING {8} \
   CONFIG.M10_WRITE_ISSUING {8} \
   CONFIG.M11_A00_ADDR_WIDTH {0} \
   CONFIG.M11_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_READ_ISSUING {8} \
   CONFIG.M11_WRITE_ISSUING {8} \
   CONFIG.M12_A00_ADDR_WIDTH {0} \
   CONFIG.M12_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_READ_ISSUING {8} \
   CONFIG.M12_WRITE_ISSUING {8} \
   CONFIG.M13_A00_ADDR_WIDTH {0} \
   CONFIG.M13_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_READ_ISSUING {8} \
   CONFIG.M13_WRITE_ISSUING {8} \
   CONFIG.M14_A00_ADDR_WIDTH {0} \
   CONFIG.M14_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_READ_ISSUING {8} \
   CONFIG.M14_WRITE_ISSUING {8} \
   CONFIG.M15_A00_ADDR_WIDTH {0} \
   CONFIG.M15_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_READ_ISSUING {8} \
   CONFIG.M15_WRITE_ISSUING {8} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_READ_ACCEPTANCE {4} \
   CONFIG.S00_WRITE_ACCEPTANCE {4} \
   CONFIG.S01_READ_ACCEPTANCE {4} \
   CONFIG.S01_WRITE_ACCEPTANCE {4} \
   CONFIG.S02_READ_ACCEPTANCE {4} \
   CONFIG.S02_WRITE_ACCEPTANCE {4} \
   CONFIG.S03_READ_ACCEPTANCE {4} \
   CONFIG.S03_WRITE_ACCEPTANCE {4} \
   CONFIG.S04_READ_ACCEPTANCE {4} \
   CONFIG.S04_WRITE_ACCEPTANCE {4} \
   CONFIG.S05_READ_ACCEPTANCE {4} \
   CONFIG.S05_WRITE_ACCEPTANCE {4} \
   CONFIG.S06_READ_ACCEPTANCE {4} \
   CONFIG.S06_WRITE_ACCEPTANCE {4} \
   CONFIG.S07_READ_ACCEPTANCE {4} \
   CONFIG.S07_WRITE_ACCEPTANCE {4} \
   CONFIG.S08_READ_ACCEPTANCE {4} \
   CONFIG.S08_WRITE_ACCEPTANCE {4} \
   CONFIG.S09_READ_ACCEPTANCE {4} \
   CONFIG.S09_WRITE_ACCEPTANCE {4} \
   CONFIG.S10_READ_ACCEPTANCE {4} \
   CONFIG.S10_WRITE_ACCEPTANCE {4} \
   CONFIG.S11_READ_ACCEPTANCE {4} \
   CONFIG.S11_WRITE_ACCEPTANCE {4} \
   CONFIG.S12_READ_ACCEPTANCE {4} \
   CONFIG.S12_WRITE_ACCEPTANCE {4} \
   CONFIG.S13_READ_ACCEPTANCE {4} \
   CONFIG.S13_WRITE_ACCEPTANCE {4} \
   CONFIG.S14_READ_ACCEPTANCE {4} \
   CONFIG.S14_WRITE_ACCEPTANCE {4} \
   CONFIG.S15_READ_ACCEPTANCE {4} \
   CONFIG.S15_WRITE_ACCEPTANCE {4} \
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
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_MAXI_DATA [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_3_MAXI_DATA [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_6_MAXI_DATA [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_9_MAXI_DATA [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_register_slice_0/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_register_slice_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_register_slice_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: wg_axi_0
proc create_hier_cell_wg_axi_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_wg_axi_0() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
   CONFIG.M00_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_READ_ISSUING {8} \
   CONFIG.M00_WRITE_ISSUING {8} \
   CONFIG.M01_A00_ADDR_WIDTH {0} \
   CONFIG.M01_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_READ_ISSUING {8} \
   CONFIG.M01_WRITE_ISSUING {8} \
   CONFIG.M02_A00_ADDR_WIDTH {0} \
   CONFIG.M02_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_READ_ISSUING {8} \
   CONFIG.M02_WRITE_ISSUING {8} \
   CONFIG.M03_A00_ADDR_WIDTH {0} \
   CONFIG.M03_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_READ_ISSUING {8} \
   CONFIG.M03_WRITE_ISSUING {8} \
   CONFIG.M04_A00_ADDR_WIDTH {0} \
   CONFIG.M04_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_READ_ISSUING {8} \
   CONFIG.M04_WRITE_ISSUING {8} \
   CONFIG.M05_A00_ADDR_WIDTH {0} \
   CONFIG.M05_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_READ_ISSUING {8} \
   CONFIG.M05_WRITE_ISSUING {8} \
   CONFIG.M06_A00_ADDR_WIDTH {0} \
   CONFIG.M06_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_READ_ISSUING {8} \
   CONFIG.M06_WRITE_ISSUING {8} \
   CONFIG.M07_A00_ADDR_WIDTH {0} \
   CONFIG.M07_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_READ_ISSUING {8} \
   CONFIG.M07_WRITE_ISSUING {8} \
   CONFIG.M08_A00_ADDR_WIDTH {0} \
   CONFIG.M08_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_READ_ISSUING {8} \
   CONFIG.M08_WRITE_ISSUING {8} \
   CONFIG.M09_A00_ADDR_WIDTH {0} \
   CONFIG.M09_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_READ_ISSUING {8} \
   CONFIG.M09_WRITE_ISSUING {8} \
   CONFIG.M10_A00_ADDR_WIDTH {0} \
   CONFIG.M10_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_READ_ISSUING {8} \
   CONFIG.M10_WRITE_ISSUING {8} \
   CONFIG.M11_A00_ADDR_WIDTH {0} \
   CONFIG.M11_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_READ_ISSUING {8} \
   CONFIG.M11_WRITE_ISSUING {8} \
   CONFIG.M12_A00_ADDR_WIDTH {0} \
   CONFIG.M12_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_READ_ISSUING {8} \
   CONFIG.M12_WRITE_ISSUING {8} \
   CONFIG.M13_A00_ADDR_WIDTH {0} \
   CONFIG.M13_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_READ_ISSUING {8} \
   CONFIG.M13_WRITE_ISSUING {8} \
   CONFIG.M14_A00_ADDR_WIDTH {0} \
   CONFIG.M14_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_READ_ISSUING {8} \
   CONFIG.M14_WRITE_ISSUING {8} \
   CONFIG.M15_A00_ADDR_WIDTH {0} \
   CONFIG.M15_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_READ_ISSUING {8} \
   CONFIG.M15_WRITE_ISSUING {8} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_READ_ACCEPTANCE {4} \
   CONFIG.S00_WRITE_ACCEPTANCE {4} \
   CONFIG.S01_READ_ACCEPTANCE {4} \
   CONFIG.S01_WRITE_ACCEPTANCE {4} \
   CONFIG.S02_READ_ACCEPTANCE {4} \
   CONFIG.S02_WRITE_ACCEPTANCE {4} \
   CONFIG.S03_READ_ACCEPTANCE {4} \
   CONFIG.S03_WRITE_ACCEPTANCE {4} \
   CONFIG.S04_READ_ACCEPTANCE {4} \
   CONFIG.S04_WRITE_ACCEPTANCE {4} \
   CONFIG.S05_READ_ACCEPTANCE {4} \
   CONFIG.S05_WRITE_ACCEPTANCE {4} \
   CONFIG.S06_READ_ACCEPTANCE {4} \
   CONFIG.S06_WRITE_ACCEPTANCE {4} \
   CONFIG.S07_READ_ACCEPTANCE {4} \
   CONFIG.S07_WRITE_ACCEPTANCE {4} \
   CONFIG.S08_READ_ACCEPTANCE {4} \
   CONFIG.S08_WRITE_ACCEPTANCE {4} \
   CONFIG.S09_READ_ACCEPTANCE {4} \
   CONFIG.S09_WRITE_ACCEPTANCE {4} \
   CONFIG.S10_READ_ACCEPTANCE {4} \
   CONFIG.S10_WRITE_ACCEPTANCE {4} \
   CONFIG.S11_READ_ACCEPTANCE {4} \
   CONFIG.S11_WRITE_ACCEPTANCE {4} \
   CONFIG.S12_READ_ACCEPTANCE {4} \
   CONFIG.S12_WRITE_ACCEPTANCE {4} \
   CONFIG.S13_READ_ACCEPTANCE {4} \
   CONFIG.S13_WRITE_ACCEPTANCE {4} \
   CONFIG.S14_READ_ACCEPTANCE {4} \
   CONFIG.S14_WRITE_ACCEPTANCE {4} \
   CONFIG.S15_READ_ACCEPTANCE {4} \
   CONFIG.S15_WRITE_ACCEPTANCE {4} \
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
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_MAXI_DATA [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_3_MAXI_DATA [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_6_MAXI_DATA [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_9_MAXI_DATA [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_register_slice_0/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_register_slice_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_register_slice_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: wa_axi_2
proc create_hier_cell_wa_axi_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_wa_axi_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
   CONFIG.M00_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_READ_ISSUING {8} \
   CONFIG.M00_WRITE_ISSUING {8} \
   CONFIG.M01_A00_ADDR_WIDTH {0} \
   CONFIG.M01_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_READ_ISSUING {8} \
   CONFIG.M01_WRITE_ISSUING {8} \
   CONFIG.M02_A00_ADDR_WIDTH {0} \
   CONFIG.M02_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_READ_ISSUING {8} \
   CONFIG.M02_WRITE_ISSUING {8} \
   CONFIG.M03_A00_ADDR_WIDTH {0} \
   CONFIG.M03_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_READ_ISSUING {8} \
   CONFIG.M03_WRITE_ISSUING {8} \
   CONFIG.M04_A00_ADDR_WIDTH {0} \
   CONFIG.M04_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_READ_ISSUING {8} \
   CONFIG.M04_WRITE_ISSUING {8} \
   CONFIG.M05_A00_ADDR_WIDTH {0} \
   CONFIG.M05_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_READ_ISSUING {8} \
   CONFIG.M05_WRITE_ISSUING {8} \
   CONFIG.M06_A00_ADDR_WIDTH {0} \
   CONFIG.M06_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_READ_ISSUING {8} \
   CONFIG.M06_WRITE_ISSUING {8} \
   CONFIG.M07_A00_ADDR_WIDTH {0} \
   CONFIG.M07_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_READ_ISSUING {8} \
   CONFIG.M07_WRITE_ISSUING {8} \
   CONFIG.M08_A00_ADDR_WIDTH {0} \
   CONFIG.M08_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_READ_ISSUING {8} \
   CONFIG.M08_WRITE_ISSUING {8} \
   CONFIG.M09_A00_ADDR_WIDTH {0} \
   CONFIG.M09_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_READ_ISSUING {8} \
   CONFIG.M09_WRITE_ISSUING {8} \
   CONFIG.M10_A00_ADDR_WIDTH {0} \
   CONFIG.M10_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_READ_ISSUING {8} \
   CONFIG.M10_WRITE_ISSUING {8} \
   CONFIG.M11_A00_ADDR_WIDTH {0} \
   CONFIG.M11_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_READ_ISSUING {8} \
   CONFIG.M11_WRITE_ISSUING {8} \
   CONFIG.M12_A00_ADDR_WIDTH {0} \
   CONFIG.M12_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_READ_ISSUING {8} \
   CONFIG.M12_WRITE_ISSUING {8} \
   CONFIG.M13_A00_ADDR_WIDTH {0} \
   CONFIG.M13_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_READ_ISSUING {8} \
   CONFIG.M13_WRITE_ISSUING {8} \
   CONFIG.M14_A00_ADDR_WIDTH {0} \
   CONFIG.M14_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_READ_ISSUING {8} \
   CONFIG.M14_WRITE_ISSUING {8} \
   CONFIG.M15_A00_ADDR_WIDTH {0} \
   CONFIG.M15_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_READ_ISSUING {8} \
   CONFIG.M15_WRITE_ISSUING {8} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_READ_ACCEPTANCE {4} \
   CONFIG.S00_WRITE_ACCEPTANCE {4} \
   CONFIG.S01_READ_ACCEPTANCE {4} \
   CONFIG.S01_WRITE_ACCEPTANCE {4} \
   CONFIG.S02_READ_ACCEPTANCE {4} \
   CONFIG.S02_WRITE_ACCEPTANCE {4} \
   CONFIG.S03_READ_ACCEPTANCE {4} \
   CONFIG.S03_WRITE_ACCEPTANCE {4} \
   CONFIG.S04_READ_ACCEPTANCE {4} \
   CONFIG.S04_WRITE_ACCEPTANCE {4} \
   CONFIG.S05_READ_ACCEPTANCE {4} \
   CONFIG.S05_WRITE_ACCEPTANCE {4} \
   CONFIG.S06_READ_ACCEPTANCE {4} \
   CONFIG.S06_WRITE_ACCEPTANCE {4} \
   CONFIG.S07_READ_ACCEPTANCE {4} \
   CONFIG.S07_WRITE_ACCEPTANCE {4} \
   CONFIG.S08_READ_ACCEPTANCE {4} \
   CONFIG.S08_WRITE_ACCEPTANCE {4} \
   CONFIG.S09_READ_ACCEPTANCE {4} \
   CONFIG.S09_WRITE_ACCEPTANCE {4} \
   CONFIG.S10_READ_ACCEPTANCE {4} \
   CONFIG.S10_WRITE_ACCEPTANCE {4} \
   CONFIG.S11_READ_ACCEPTANCE {4} \
   CONFIG.S11_WRITE_ACCEPTANCE {4} \
   CONFIG.S12_READ_ACCEPTANCE {4} \
   CONFIG.S12_WRITE_ACCEPTANCE {4} \
   CONFIG.S13_READ_ACCEPTANCE {4} \
   CONFIG.S13_WRITE_ACCEPTANCE {4} \
   CONFIG.S14_READ_ACCEPTANCE {4} \
   CONFIG.S14_WRITE_ACCEPTANCE {4} \
   CONFIG.S15_READ_ACCEPTANCE {4} \
   CONFIG.S15_WRITE_ACCEPTANCE {4} \
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
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_MAXI_DATA [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_3_MAXI_DATA [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_6_MAXI_DATA [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_9_MAXI_DATA [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_register_slice_0/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_register_slice_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_register_slice_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: wa_axi_1
proc create_hier_cell_wa_axi_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_wa_axi_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
   CONFIG.M00_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_READ_ISSUING {8} \
   CONFIG.M00_WRITE_ISSUING {8} \
   CONFIG.M01_A00_ADDR_WIDTH {0} \
   CONFIG.M01_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_READ_ISSUING {8} \
   CONFIG.M01_WRITE_ISSUING {8} \
   CONFIG.M02_A00_ADDR_WIDTH {0} \
   CONFIG.M02_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_READ_ISSUING {8} \
   CONFIG.M02_WRITE_ISSUING {8} \
   CONFIG.M03_A00_ADDR_WIDTH {0} \
   CONFIG.M03_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_READ_ISSUING {8} \
   CONFIG.M03_WRITE_ISSUING {8} \
   CONFIG.M04_A00_ADDR_WIDTH {0} \
   CONFIG.M04_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_READ_ISSUING {8} \
   CONFIG.M04_WRITE_ISSUING {8} \
   CONFIG.M05_A00_ADDR_WIDTH {0} \
   CONFIG.M05_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_READ_ISSUING {8} \
   CONFIG.M05_WRITE_ISSUING {8} \
   CONFIG.M06_A00_ADDR_WIDTH {0} \
   CONFIG.M06_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_READ_ISSUING {8} \
   CONFIG.M06_WRITE_ISSUING {8} \
   CONFIG.M07_A00_ADDR_WIDTH {0} \
   CONFIG.M07_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_READ_ISSUING {8} \
   CONFIG.M07_WRITE_ISSUING {8} \
   CONFIG.M08_A00_ADDR_WIDTH {0} \
   CONFIG.M08_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_READ_ISSUING {8} \
   CONFIG.M08_WRITE_ISSUING {8} \
   CONFIG.M09_A00_ADDR_WIDTH {0} \
   CONFIG.M09_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_READ_ISSUING {8} \
   CONFIG.M09_WRITE_ISSUING {8} \
   CONFIG.M10_A00_ADDR_WIDTH {0} \
   CONFIG.M10_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_READ_ISSUING {8} \
   CONFIG.M10_WRITE_ISSUING {8} \
   CONFIG.M11_A00_ADDR_WIDTH {0} \
   CONFIG.M11_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_READ_ISSUING {8} \
   CONFIG.M11_WRITE_ISSUING {8} \
   CONFIG.M12_A00_ADDR_WIDTH {0} \
   CONFIG.M12_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_READ_ISSUING {8} \
   CONFIG.M12_WRITE_ISSUING {8} \
   CONFIG.M13_A00_ADDR_WIDTH {0} \
   CONFIG.M13_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_READ_ISSUING {8} \
   CONFIG.M13_WRITE_ISSUING {8} \
   CONFIG.M14_A00_ADDR_WIDTH {0} \
   CONFIG.M14_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_READ_ISSUING {8} \
   CONFIG.M14_WRITE_ISSUING {8} \
   CONFIG.M15_A00_ADDR_WIDTH {0} \
   CONFIG.M15_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_READ_ISSUING {8} \
   CONFIG.M15_WRITE_ISSUING {8} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_READ_ACCEPTANCE {4} \
   CONFIG.S00_WRITE_ACCEPTANCE {4} \
   CONFIG.S01_READ_ACCEPTANCE {4} \
   CONFIG.S01_WRITE_ACCEPTANCE {4} \
   CONFIG.S02_READ_ACCEPTANCE {4} \
   CONFIG.S02_WRITE_ACCEPTANCE {4} \
   CONFIG.S03_READ_ACCEPTANCE {4} \
   CONFIG.S03_WRITE_ACCEPTANCE {4} \
   CONFIG.S04_READ_ACCEPTANCE {4} \
   CONFIG.S04_WRITE_ACCEPTANCE {4} \
   CONFIG.S05_READ_ACCEPTANCE {4} \
   CONFIG.S05_WRITE_ACCEPTANCE {4} \
   CONFIG.S06_READ_ACCEPTANCE {4} \
   CONFIG.S06_WRITE_ACCEPTANCE {4} \
   CONFIG.S07_READ_ACCEPTANCE {4} \
   CONFIG.S07_WRITE_ACCEPTANCE {4} \
   CONFIG.S08_READ_ACCEPTANCE {4} \
   CONFIG.S08_WRITE_ACCEPTANCE {4} \
   CONFIG.S09_READ_ACCEPTANCE {4} \
   CONFIG.S09_WRITE_ACCEPTANCE {4} \
   CONFIG.S10_READ_ACCEPTANCE {4} \
   CONFIG.S10_WRITE_ACCEPTANCE {4} \
   CONFIG.S11_READ_ACCEPTANCE {4} \
   CONFIG.S11_WRITE_ACCEPTANCE {4} \
   CONFIG.S12_READ_ACCEPTANCE {4} \
   CONFIG.S12_WRITE_ACCEPTANCE {4} \
   CONFIG.S13_READ_ACCEPTANCE {4} \
   CONFIG.S13_WRITE_ACCEPTANCE {4} \
   CONFIG.S14_READ_ACCEPTANCE {4} \
   CONFIG.S14_WRITE_ACCEPTANCE {4} \
   CONFIG.S15_READ_ACCEPTANCE {4} \
   CONFIG.S15_WRITE_ACCEPTANCE {4} \
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
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_MAXI_DATA [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_3_MAXI_DATA [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_6_MAXI_DATA [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_9_MAXI_DATA [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_register_slice_0/M_AXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_register_slice_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_register_slice_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: wa_axi_0
proc create_hier_cell_wa_axi_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_wa_axi_0() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
   CONFIG.M00_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_READ_ISSUING {8} \
   CONFIG.M00_WRITE_ISSUING {8} \
   CONFIG.M01_A00_ADDR_WIDTH {0} \
   CONFIG.M01_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_READ_ISSUING {8} \
   CONFIG.M01_WRITE_ISSUING {8} \
   CONFIG.M02_A00_ADDR_WIDTH {0} \
   CONFIG.M02_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_READ_ISSUING {8} \
   CONFIG.M02_WRITE_ISSUING {8} \
   CONFIG.M03_A00_ADDR_WIDTH {0} \
   CONFIG.M03_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_READ_ISSUING {8} \
   CONFIG.M03_WRITE_ISSUING {8} \
   CONFIG.M04_A00_ADDR_WIDTH {0} \
   CONFIG.M04_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_READ_ISSUING {8} \
   CONFIG.M04_WRITE_ISSUING {8} \
   CONFIG.M05_A00_ADDR_WIDTH {0} \
   CONFIG.M05_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_READ_ISSUING {8} \
   CONFIG.M05_WRITE_ISSUING {8} \
   CONFIG.M06_A00_ADDR_WIDTH {0} \
   CONFIG.M06_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_READ_ISSUING {8} \
   CONFIG.M06_WRITE_ISSUING {8} \
   CONFIG.M07_A00_ADDR_WIDTH {0} \
   CONFIG.M07_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_READ_ISSUING {8} \
   CONFIG.M07_WRITE_ISSUING {8} \
   CONFIG.M08_A00_ADDR_WIDTH {0} \
   CONFIG.M08_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_READ_ISSUING {8} \
   CONFIG.M08_WRITE_ISSUING {8} \
   CONFIG.M09_A00_ADDR_WIDTH {0} \
   CONFIG.M09_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_READ_ISSUING {8} \
   CONFIG.M09_WRITE_ISSUING {8} \
   CONFIG.M10_A00_ADDR_WIDTH {0} \
   CONFIG.M10_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_READ_ISSUING {8} \
   CONFIG.M10_WRITE_ISSUING {8} \
   CONFIG.M11_A00_ADDR_WIDTH {0} \
   CONFIG.M11_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_READ_ISSUING {8} \
   CONFIG.M11_WRITE_ISSUING {8} \
   CONFIG.M12_A00_ADDR_WIDTH {0} \
   CONFIG.M12_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_READ_ISSUING {8} \
   CONFIG.M12_WRITE_ISSUING {8} \
   CONFIG.M13_A00_ADDR_WIDTH {0} \
   CONFIG.M13_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_READ_ISSUING {8} \
   CONFIG.M13_WRITE_ISSUING {8} \
   CONFIG.M14_A00_ADDR_WIDTH {0} \
   CONFIG.M14_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_READ_ISSUING {8} \
   CONFIG.M14_WRITE_ISSUING {8} \
   CONFIG.M15_A00_ADDR_WIDTH {0} \
   CONFIG.M15_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_READ_ISSUING {8} \
   CONFIG.M15_WRITE_ISSUING {8} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_READ_ACCEPTANCE {4} \
   CONFIG.S00_WRITE_ACCEPTANCE {4} \
   CONFIG.S01_READ_ACCEPTANCE {4} \
   CONFIG.S01_WRITE_ACCEPTANCE {4} \
   CONFIG.S02_READ_ACCEPTANCE {4} \
   CONFIG.S02_WRITE_ACCEPTANCE {4} \
   CONFIG.S03_READ_ACCEPTANCE {4} \
   CONFIG.S03_WRITE_ACCEPTANCE {4} \
   CONFIG.S04_READ_ACCEPTANCE {4} \
   CONFIG.S04_WRITE_ACCEPTANCE {4} \
   CONFIG.S05_READ_ACCEPTANCE {4} \
   CONFIG.S05_WRITE_ACCEPTANCE {4} \
   CONFIG.S06_READ_ACCEPTANCE {4} \
   CONFIG.S06_WRITE_ACCEPTANCE {4} \
   CONFIG.S07_READ_ACCEPTANCE {4} \
   CONFIG.S07_WRITE_ACCEPTANCE {4} \
   CONFIG.S08_READ_ACCEPTANCE {4} \
   CONFIG.S08_WRITE_ACCEPTANCE {4} \
   CONFIG.S09_READ_ACCEPTANCE {4} \
   CONFIG.S09_WRITE_ACCEPTANCE {4} \
   CONFIG.S10_READ_ACCEPTANCE {4} \
   CONFIG.S10_WRITE_ACCEPTANCE {4} \
   CONFIG.S11_READ_ACCEPTANCE {4} \
   CONFIG.S11_WRITE_ACCEPTANCE {4} \
   CONFIG.S12_READ_ACCEPTANCE {4} \
   CONFIG.S12_WRITE_ACCEPTANCE {4} \
   CONFIG.S13_READ_ACCEPTANCE {4} \
   CONFIG.S13_WRITE_ACCEPTANCE {4} \
   CONFIG.S14_READ_ACCEPTANCE {4} \
   CONFIG.S14_WRITE_ACCEPTANCE {4} \
   CONFIG.S15_READ_ACCEPTANCE {4} \
   CONFIG.S15_WRITE_ACCEPTANCE {4} \
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
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_MAXI_DATA [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_3_MAXI_DATA [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_6_MAXI_DATA [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_9_MAXI_DATA [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
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
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_d_axi() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
   CONFIG.M00_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M00_READ_ISSUING {8} \
   CONFIG.M00_WRITE_ISSUING {8} \
   CONFIG.M01_A00_ADDR_WIDTH {0} \
   CONFIG.M01_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M01_READ_ISSUING {8} \
   CONFIG.M01_WRITE_ISSUING {8} \
   CONFIG.M02_A00_ADDR_WIDTH {0} \
   CONFIG.M02_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M02_READ_ISSUING {8} \
   CONFIG.M02_WRITE_ISSUING {8} \
   CONFIG.M03_A00_ADDR_WIDTH {0} \
   CONFIG.M03_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M03_READ_ISSUING {8} \
   CONFIG.M03_WRITE_ISSUING {8} \
   CONFIG.M04_A00_ADDR_WIDTH {0} \
   CONFIG.M04_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M04_READ_ISSUING {8} \
   CONFIG.M04_WRITE_ISSUING {8} \
   CONFIG.M05_A00_ADDR_WIDTH {0} \
   CONFIG.M05_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M05_READ_ISSUING {8} \
   CONFIG.M05_WRITE_ISSUING {8} \
   CONFIG.M06_A00_ADDR_WIDTH {0} \
   CONFIG.M06_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M06_READ_ISSUING {8} \
   CONFIG.M06_WRITE_ISSUING {8} \
   CONFIG.M07_A00_ADDR_WIDTH {0} \
   CONFIG.M07_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M07_READ_ISSUING {8} \
   CONFIG.M07_WRITE_ISSUING {8} \
   CONFIG.M08_A00_ADDR_WIDTH {0} \
   CONFIG.M08_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M08_READ_ISSUING {8} \
   CONFIG.M08_WRITE_ISSUING {8} \
   CONFIG.M09_A00_ADDR_WIDTH {0} \
   CONFIG.M09_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M09_READ_ISSUING {8} \
   CONFIG.M09_WRITE_ISSUING {8} \
   CONFIG.M10_A00_ADDR_WIDTH {0} \
   CONFIG.M10_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M10_READ_ISSUING {8} \
   CONFIG.M10_WRITE_ISSUING {8} \
   CONFIG.M11_A00_ADDR_WIDTH {0} \
   CONFIG.M11_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M11_READ_ISSUING {8} \
   CONFIG.M11_WRITE_ISSUING {8} \
   CONFIG.M12_A00_ADDR_WIDTH {0} \
   CONFIG.M12_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M12_READ_ISSUING {8} \
   CONFIG.M12_WRITE_ISSUING {8} \
   CONFIG.M13_A00_ADDR_WIDTH {0} \
   CONFIG.M13_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M13_READ_ISSUING {8} \
   CONFIG.M13_WRITE_ISSUING {8} \
   CONFIG.M14_A00_ADDR_WIDTH {0} \
   CONFIG.M14_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M14_READ_ISSUING {8} \
   CONFIG.M14_WRITE_ISSUING {8} \
   CONFIG.M15_A00_ADDR_WIDTH {0} \
   CONFIG.M15_A00_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A01_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A02_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A03_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A04_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A05_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A06_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A07_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A08_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A09_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A10_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A11_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A12_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A13_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A14_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_A15_BASE_ADDR {0xffffffffffffffff} \
   CONFIG.M15_READ_ISSUING {8} \
   CONFIG.M15_WRITE_ISSUING {8} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_READ_ACCEPTANCE {4} \
   CONFIG.S00_WRITE_ACCEPTANCE {4} \
   CONFIG.S01_READ_ACCEPTANCE {4} \
   CONFIG.S01_WRITE_ACCEPTANCE {4} \
   CONFIG.S02_READ_ACCEPTANCE {4} \
   CONFIG.S02_WRITE_ACCEPTANCE {4} \
   CONFIG.S03_READ_ACCEPTANCE {4} \
   CONFIG.S03_WRITE_ACCEPTANCE {4} \
   CONFIG.S04_READ_ACCEPTANCE {4} \
   CONFIG.S04_WRITE_ACCEPTANCE {4} \
   CONFIG.S05_READ_ACCEPTANCE {4} \
   CONFIG.S05_WRITE_ACCEPTANCE {4} \
   CONFIG.S06_READ_ACCEPTANCE {4} \
   CONFIG.S06_WRITE_ACCEPTANCE {4} \
   CONFIG.S07_READ_ACCEPTANCE {4} \
   CONFIG.S07_WRITE_ACCEPTANCE {4} \
   CONFIG.S08_READ_ACCEPTANCE {4} \
   CONFIG.S08_WRITE_ACCEPTANCE {4} \
   CONFIG.S09_READ_ACCEPTANCE {4} \
   CONFIG.S09_WRITE_ACCEPTANCE {4} \
   CONFIG.S10_READ_ACCEPTANCE {4} \
   CONFIG.S10_WRITE_ACCEPTANCE {4} \
   CONFIG.S11_READ_ACCEPTANCE {4} \
   CONFIG.S11_WRITE_ACCEPTANCE {4} \
   CONFIG.S12_READ_ACCEPTANCE {4} \
   CONFIG.S12_WRITE_ACCEPTANCE {4} \
   CONFIG.S13_READ_ACCEPTANCE {4} \
   CONFIG.S13_WRITE_ACCEPTANCE {4} \
   CONFIG.S14_READ_ACCEPTANCE {4} \
   CONFIG.S14_WRITE_ACCEPTANCE {4} \
   CONFIG.S15_READ_ACCEPTANCE {4} \
   CONFIG.S15_WRITE_ACCEPTANCE {4} \
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
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_MAXI_DATA [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_3_MAXI_DATA [get_bd_intf_pins S01_AXI] [get_bd_intf_pins axi_crossbar_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_6_MAXI_DATA [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_crossbar_0/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_9_MAXI_DATA [get_bd_intf_pins S03_AXI] [get_bd_intf_pins axi_crossbar_0/S03_AXI]
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
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_PCIE_AXI() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DIGITAL_DMA

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

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S03_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S04_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S05_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S06_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S07_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S08_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S09_AXI


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
   CONFIG.SYNCHRONIZATION_STAGES {2} \
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

  # Create interface connections
  connect_bd_intf_net -intf_net DIGITAL_DMA_1 [get_bd_intf_pins DIGITAL_DMA] [get_bd_intf_pins dma_axi/S04_AXI]
  connect_bd_intf_net -intf_net PCIE_AXI_1 [get_bd_intf_pins PCIE_AXI] [get_bd_intf_pins vDAQ_PCIE_AXI_0/PCIE_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins dma_axi/S00_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins S01_AXI] [get_bd_intf_pins dma_axi/S01_AXI]
  connect_bd_intf_net -intf_net S03_AXI_1 [get_bd_intf_pins S03_AXI] [get_bd_intf_pins dma_axi/S02_AXI]
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins S04_AXI] [get_bd_intf_pins dma_axi/S03_AXI]
  connect_bd_intf_net -intf_net S05_AXI_1 [get_bd_intf_pins S05_AXI] [get_bd_intf_pins dma_axi/S09_AXI]
  connect_bd_intf_net -intf_net S06_AXI_1 [get_bd_intf_pins S06_AXI] [get_bd_intf_pins dma_axi/S05_AXI]
  connect_bd_intf_net -intf_net S07_AXI_1 [get_bd_intf_pins S07_AXI] [get_bd_intf_pins dma_axi/S06_AXI]
  connect_bd_intf_net -intf_net S08_AXI_1 [get_bd_intf_pins S08_AXI] [get_bd_intf_pins dma_axi/S07_AXI]
  connect_bd_intf_net -intf_net S09_AXI_1 [get_bd_intf_pins S09_AXI] [get_bd_intf_pins dma_axi/S08_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M00_AXI [get_bd_intf_pins M00_AXI] [get_bd_intf_pins axi_interconnect_4/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M01_AXI [get_bd_intf_pins M01_AXI] [get_bd_intf_pins axi_interconnect_4/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M02_AXI [get_bd_intf_pins M02_AXI] [get_bd_intf_pins axi_interconnect_4/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M03_AXI [get_bd_intf_pins M03_AXI] [get_bd_intf_pins axi_interconnect_4/M03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M04_AXI [get_bd_intf_pins M04_AXI] [get_bd_intf_pins axi_interconnect_4/M04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M05_AXI [get_bd_intf_pins M05_AXI] [get_bd_intf_pins axi_interconnect_4/M05_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M06_AXI [get_bd_intf_pins M06_AXI] [get_bd_intf_pins axi_interconnect_4/M06_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M07_AXI [get_bd_intf_pins M07_AXI] [get_bd_intf_pins axi_interconnect_4/M07_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M08_AXI [get_bd_intf_pins M08_AXI] [get_bd_intf_pins axi_interconnect_4/M08_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins dma_axi/M_AXI] [get_bd_intf_pins vDAQ_PCIE_AXI_0/SAXI]
  connect_bd_intf_net -intf_net vDAQ_PCIE_AXI_0_MAXI [get_bd_intf_pins axi_interconnect_4/S00_AXI] [get_bd_intf_pins vDAQ_PCIE_AXI_0/MAXI]

  # Create port connections
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins aclk] [get_bd_pins axi_interconnect_4/ACLK] [get_bd_pins axi_interconnect_4/M00_ACLK] [get_bd_pins axi_interconnect_4/M01_ACLK] [get_bd_pins axi_interconnect_4/M02_ACLK] [get_bd_pins axi_interconnect_4/M03_ACLK] [get_bd_pins axi_interconnect_4/M05_ACLK] [get_bd_pins axi_interconnect_4/M06_ACLK] [get_bd_pins axi_interconnect_4/M07_ACLK] [get_bd_pins axi_interconnect_4/M08_ACLK] [get_bd_pins axi_interconnect_4/S00_ACLK] [get_bd_pins dma_axi/aclk] [get_bd_pins vDAQ_PCIE_AXI_0/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins aresetn] [get_bd_pins axi_interconnect_4/ARESETN] [get_bd_pins axi_interconnect_4/M00_ARESETN] [get_bd_pins axi_interconnect_4/M01_ARESETN] [get_bd_pins axi_interconnect_4/M02_ARESETN] [get_bd_pins axi_interconnect_4/M03_ARESETN] [get_bd_pins axi_interconnect_4/M05_ARESETN] [get_bd_pins axi_interconnect_4/M06_ARESETN] [get_bd_pins axi_interconnect_4/M07_ARESETN] [get_bd_pins axi_interconnect_4/M08_ARESETN] [get_bd_pins axi_interconnect_4/S00_ARESETN] [get_bd_pins dma_axi/aresetn] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins vDAQ_PCIE_AXI_0/aresetn]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins axi_interconnect_4/M04_ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins aresetn_40] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net sysClk40_1 [get_bd_pins ioClk40] [get_bd_pins axi_interconnect_4/M04_ACLK] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: DAQ
proc create_hier_cell_DAQ { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_DAQ() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI4

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI5

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2


  # Create pins
  create_bd_pin -dir O -from 12 -to 0 LSADC_FW_i
  create_bd_pin -dir I -from 204 -to 0 LSADC_FW_o
  create_bd_pin -dir O -from 240 -to 0 LSDAC_FW_IO
  create_bd_pin -dir I ao_watchdog_trigger
  create_bd_pin -dir I -type clk axiClk
  create_bd_pin -dir I -type rst axiResetN
  create_bd_pin -dir I -from 57 -to 0 ext_triggers
  create_bd_pin -dir I -type clk ioClk80
  create_bd_pin -dir I lsadcSpiClkEn
  create_bd_pin -dir I lsdacSpiClkEn
  create_bd_pin -dir O -from 7 -to 0 outputLines0
  create_bd_pin -dir O -from 7 -to 0 outputLines1
  create_bd_pin -dir O -from 7 -to 0 outputLines2
  create_bd_pin -dir O -from 7 -to 0 outputLines3
  create_bd_pin -dir IO -from 27 -to 0 peer_triggers
  create_bd_pin -dir I -type clk sampleClkTimebase

  # Create instance: Digital_Waveform_Gen_0, and set properties
  set Digital_Waveform_Gen_0 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Digital_Waveform_Gen:1.0 Digital_Waveform_Gen_0 ]
  set_property -dict [ list \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {24} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Digital_Waveform_Gen_0

  # Create instance: Digital_Waveform_Gen_1, and set properties
  set Digital_Waveform_Gen_1 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Digital_Waveform_Gen:1.0 Digital_Waveform_Gen_1 ]
  set_property -dict [ list \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {25} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Digital_Waveform_Gen_1

  # Create instance: Digital_Waveform_Gen_2, and set properties
  set Digital_Waveform_Gen_2 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Digital_Waveform_Gen:1.0 Digital_Waveform_Gen_2 ]
  set_property -dict [ list \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {26} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Digital_Waveform_Gen_2

  # Create instance: Digital_Waveform_Gen_3, and set properties
  set Digital_Waveform_Gen_3 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Digital_Waveform_Gen:1.0 Digital_Waveform_Gen_3 ]
  set_property -dict [ list \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {27} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Digital_Waveform_Gen_3

  # Create instance: LSADC, and set properties
  set LSADC [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:vDAQR1_LSADC:1.0 LSADC ]

  # Create instance: LSDAC, and set properties
  set LSDAC [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:vDAQR1_LSDAC:1.0 LSDAC ]

  # Create instance: Slow_Waveform_Acq_0, and set properties
  set Slow_Waveform_Acq_0 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_0 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_0

  # Create instance: Slow_Waveform_Acq_1, and set properties
  set Slow_Waveform_Acq_1 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_1 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {1} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_1

  # Create instance: Slow_Waveform_Acq_2, and set properties
  set Slow_Waveform_Acq_2 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_2 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {2} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_2

  # Create instance: Slow_Waveform_Acq_3, and set properties
  set Slow_Waveform_Acq_3 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_3 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {3} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_3

  # Create instance: Slow_Waveform_Acq_4, and set properties
  set Slow_Waveform_Acq_4 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_4 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {4} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_4

  # Create instance: Slow_Waveform_Acq_5, and set properties
  set Slow_Waveform_Acq_5 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_5 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {5} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_5

  # Create instance: Slow_Waveform_Acq_6, and set properties
  set Slow_Waveform_Acq_6 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_6 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {6} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_6

  # Create instance: Slow_Waveform_Acq_7, and set properties
  set Slow_Waveform_Acq_7 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_7 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {7} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_7

  # Create instance: Slow_Waveform_Acq_8, and set properties
  set Slow_Waveform_Acq_8 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_8 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {8} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_8

  # Create instance: Slow_Waveform_Acq_9, and set properties
  set Slow_Waveform_Acq_9 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_9 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {9} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_9

  # Create instance: Slow_Waveform_Acq_10, and set properties
  set Slow_Waveform_Acq_10 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_10 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {10} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_10

  # Create instance: Slow_Waveform_Acq_11, and set properties
  set Slow_Waveform_Acq_11 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Acq:1.0 Slow_Waveform_Acq_11 ]
  set_property -dict [ list \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {11} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $Slow_Waveform_Acq_11

  # Create instance: Slow_Waveform_Gen_0, and set properties
  set Slow_Waveform_Gen_0 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_0 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {12} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_0

  # Create instance: Slow_Waveform_Gen_1, and set properties
  set Slow_Waveform_Gen_1 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_1 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {13} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_1

  # Create instance: Slow_Waveform_Gen_2, and set properties
  set Slow_Waveform_Gen_2 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_2 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {14} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_2

  # Create instance: Slow_Waveform_Gen_3, and set properties
  set Slow_Waveform_Gen_3 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_3 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {15} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_3

  # Create instance: Slow_Waveform_Gen_4, and set properties
  set Slow_Waveform_Gen_4 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_4 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {16} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_4

  # Create instance: Slow_Waveform_Gen_5, and set properties
  set Slow_Waveform_Gen_5 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_5 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {17} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_5

  # Create instance: Slow_Waveform_Gen_6, and set properties
  set Slow_Waveform_Gen_6 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_6 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {18} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_6

  # Create instance: Slow_Waveform_Gen_7, and set properties
  set Slow_Waveform_Gen_7 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_7 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {19} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_7

  # Create instance: Slow_Waveform_Gen_8, and set properties
  set Slow_Waveform_Gen_8 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_8 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {20} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_8

  # Create instance: Slow_Waveform_Gen_9, and set properties
  set Slow_Waveform_Gen_9 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_9 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {21} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_9

  # Create instance: Slow_Waveform_Gen_10, and set properties
  set Slow_Waveform_Gen_10 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_10 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {22} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_10

  # Create instance: Slow_Waveform_Gen_11, and set properties
  set Slow_Waveform_Gen_11 [ create_bd_cell -type ip -vlnv vidriotech.com:vidrio:Slow_Waveform_Gen:1.0 Slow_Waveform_Gen_11 ]
  set_property -dict [ list \
   CONFIG.EXT_VAL_TRIGGER_PORT {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.NUM_EXT_TRIGGERS {58} \
   CONFIG.NUM_PEER_TRIGGERS {28} \
   CONFIG.PEER_TRIGGER_IDX {23} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $Slow_Waveform_Gen_11

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {12} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.SYNCHRONIZATION_STAGES {2} \
 ] $axi_interconnect_0

  # Create instance: axi_interconnect_3, and set properties
  set axi_interconnect_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_3 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {12} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.SYNCHRONIZATION_STAGES {2} \
 ] $axi_interconnect_3

  # Create instance: axi_interconnect_4, and set properties
  set axi_interconnect_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_4 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {4} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.SYNCHRONIZATION_STAGES {2} \
 ] $axi_interconnect_4

  # Create instance: d_axi
  create_hier_cell_d_axi $hier_obj d_axi

  # Create instance: wa_axi_0
  create_hier_cell_wa_axi_0 $hier_obj wa_axi_0

  # Create instance: wa_axi_1
  create_hier_cell_wa_axi_1 $hier_obj wa_axi_1

  # Create instance: wa_axi_2
  create_hier_cell_wa_axi_2 $hier_obj wa_axi_2

  # Create instance: wg_axi_0
  create_hier_cell_wg_axi_0 $hier_obj wg_axi_0

  # Create instance: wg_axi_1
  create_hier_cell_wg_axi_1 $hier_obj wg_axi_1

  # Create instance: wg_axi_2
  create_hier_cell_wg_axi_2 $hier_obj wg_axi_2

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_interconnect_3/S00_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_interconnect_4/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins Slow_Waveform_Gen_1/MAXI_DATA] [get_bd_intf_pins wg_axi_1/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_2 [get_bd_intf_pins Digital_Waveform_Gen_0/MAXI_DATA] [get_bd_intf_pins d_axi/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_3 [get_bd_intf_pins Slow_Waveform_Acq_0/MAXI_DATA] [get_bd_intf_pins wa_axi_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_4 [get_bd_intf_pins Slow_Waveform_Acq_1/MAXI_DATA] [get_bd_intf_pins wa_axi_1/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_5 [get_bd_intf_pins Slow_Waveform_Acq_2/MAXI_DATA] [get_bd_intf_pins wa_axi_2/S00_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins Slow_Waveform_Gen_4/MAXI_DATA] [get_bd_intf_pins wg_axi_1/S01_AXI]
  connect_bd_intf_net -intf_net S01_AXI_2 [get_bd_intf_pins Digital_Waveform_Gen_1/MAXI_DATA] [get_bd_intf_pins d_axi/S01_AXI]
  connect_bd_intf_net -intf_net S01_AXI_3 [get_bd_intf_pins Slow_Waveform_Acq_4/MAXI_DATA] [get_bd_intf_pins wa_axi_1/S01_AXI]
  connect_bd_intf_net -intf_net S01_AXI_4 [get_bd_intf_pins Slow_Waveform_Acq_5/MAXI_DATA] [get_bd_intf_pins wa_axi_2/S01_AXI]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins Slow_Waveform_Gen_8/MAXI_DATA] [get_bd_intf_pins wg_axi_1/S02_AXI]
  connect_bd_intf_net -intf_net S02_AXI_2 [get_bd_intf_pins Digital_Waveform_Gen_3/MAXI_DATA] [get_bd_intf_pins d_axi/S02_AXI]
  connect_bd_intf_net -intf_net S02_AXI_3 [get_bd_intf_pins Slow_Waveform_Acq_6/MAXI_DATA] [get_bd_intf_pins wa_axi_0/S02_AXI]
  connect_bd_intf_net -intf_net S02_AXI_4 [get_bd_intf_pins Slow_Waveform_Acq_7/MAXI_DATA] [get_bd_intf_pins wa_axi_1/S02_AXI]
  connect_bd_intf_net -intf_net S02_AXI_5 [get_bd_intf_pins Slow_Waveform_Acq_8/MAXI_DATA] [get_bd_intf_pins wa_axi_2/S02_AXI]
  connect_bd_intf_net -intf_net S03_AXI_1 [get_bd_intf_pins Slow_Waveform_Gen_10/MAXI_DATA] [get_bd_intf_pins wg_axi_1/S03_AXI]
  connect_bd_intf_net -intf_net S03_AXI_2 [get_bd_intf_pins Digital_Waveform_Gen_2/MAXI_DATA] [get_bd_intf_pins d_axi/S03_AXI]
  connect_bd_intf_net -intf_net S03_AXI_3 [get_bd_intf_pins Slow_Waveform_Acq_9/MAXI_DATA] [get_bd_intf_pins wa_axi_0/S03_AXI]
  connect_bd_intf_net -intf_net S03_AXI_4 [get_bd_intf_pins Slow_Waveform_Acq_10/MAXI_DATA] [get_bd_intf_pins wa_axi_1/S03_AXI]
  connect_bd_intf_net -intf_net S03_AXI_5 [get_bd_intf_pins Slow_Waveform_Acq_11/MAXI_DATA] [get_bd_intf_pins wa_axi_2/S03_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_0_ADC [get_bd_intf_pins LSADC/ADC0] [get_bd_intf_pins Slow_Waveform_Acq_0/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_10_ADC [get_bd_intf_pins LSADC/ADC10] [get_bd_intf_pins Slow_Waveform_Acq_10/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_11_ADC [get_bd_intf_pins LSADC/ADC11] [get_bd_intf_pins Slow_Waveform_Acq_11/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_1_ADC [get_bd_intf_pins LSADC/ADC1] [get_bd_intf_pins Slow_Waveform_Acq_1/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_2_ADC [get_bd_intf_pins LSADC/ADC2] [get_bd_intf_pins Slow_Waveform_Acq_2/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_3_ADC [get_bd_intf_pins LSADC/ADC3] [get_bd_intf_pins Slow_Waveform_Acq_3/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_3_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Acq_3/MAXI_DATA] [get_bd_intf_pins wa_axi_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_4_ADC [get_bd_intf_pins LSADC/ADC4] [get_bd_intf_pins Slow_Waveform_Acq_4/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_5_ADC [get_bd_intf_pins LSADC/ADC5] [get_bd_intf_pins Slow_Waveform_Acq_5/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_6_ADC [get_bd_intf_pins LSADC/ADC6] [get_bd_intf_pins Slow_Waveform_Acq_6/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_7_ADC [get_bd_intf_pins LSADC/ADC7] [get_bd_intf_pins Slow_Waveform_Acq_7/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_8_ADC [get_bd_intf_pins LSADC/ADC8] [get_bd_intf_pins Slow_Waveform_Acq_8/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Acq_9_ADC [get_bd_intf_pins LSADC/ADC9] [get_bd_intf_pins Slow_Waveform_Acq_9/ADC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_DAC [get_bd_intf_pins LSDAC/DAC0] [get_bd_intf_pins Slow_Waveform_Gen_0/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_0_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_0/MAXI_DATA] [get_bd_intf_pins wg_axi_0/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_10_DAC [get_bd_intf_pins LSDAC/DAC10] [get_bd_intf_pins Slow_Waveform_Gen_10/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_11_DAC [get_bd_intf_pins LSDAC/DAC11] [get_bd_intf_pins Slow_Waveform_Gen_11/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_11_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_11/MAXI_DATA] [get_bd_intf_pins wg_axi_2/S03_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_1_DAC [get_bd_intf_pins LSDAC/DAC1] [get_bd_intf_pins Slow_Waveform_Gen_1/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_2_DAC [get_bd_intf_pins LSDAC/DAC2] [get_bd_intf_pins Slow_Waveform_Gen_2/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_2_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_2/MAXI_DATA] [get_bd_intf_pins wg_axi_2/S00_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_3_DAC [get_bd_intf_pins LSDAC/DAC3] [get_bd_intf_pins Slow_Waveform_Gen_3/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_3_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_3/MAXI_DATA] [get_bd_intf_pins wg_axi_0/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_4_DAC [get_bd_intf_pins LSDAC/DAC4] [get_bd_intf_pins Slow_Waveform_Gen_4/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_5_DAC [get_bd_intf_pins LSDAC/DAC5] [get_bd_intf_pins Slow_Waveform_Gen_5/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_5_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_5/MAXI_DATA] [get_bd_intf_pins wg_axi_2/S01_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_6_DAC [get_bd_intf_pins LSDAC/DAC6] [get_bd_intf_pins Slow_Waveform_Gen_6/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_6_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_6/MAXI_DATA] [get_bd_intf_pins wg_axi_0/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_7_DAC [get_bd_intf_pins LSDAC/DAC7] [get_bd_intf_pins Slow_Waveform_Gen_7/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_7_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_7/MAXI_DATA] [get_bd_intf_pins wg_axi_2/S02_AXI]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_8_DAC [get_bd_intf_pins LSDAC/DAC8] [get_bd_intf_pins Slow_Waveform_Gen_8/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_9_DAC [get_bd_intf_pins LSDAC/DAC9] [get_bd_intf_pins Slow_Waveform_Gen_9/DAC]
  connect_bd_intf_net -intf_net Slow_Waveform_Gen_9_MAXI_DATA [get_bd_intf_pins Slow_Waveform_Gen_9/MAXI_DATA] [get_bd_intf_pins wg_axi_0/S03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins Slow_Waveform_Acq_11/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins Slow_Waveform_Acq_0/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins Slow_Waveform_Acq_1/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_pins Slow_Waveform_Acq_2/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M04_AXI [get_bd_intf_pins Slow_Waveform_Acq_3/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M05_AXI [get_bd_intf_pins Slow_Waveform_Acq_4/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M05_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M06_AXI [get_bd_intf_pins Slow_Waveform_Acq_5/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M06_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M07_AXI [get_bd_intf_pins Slow_Waveform_Acq_6/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M07_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M08_AXI [get_bd_intf_pins Slow_Waveform_Acq_7/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M08_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M09_AXI [get_bd_intf_pins Slow_Waveform_Acq_8/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M09_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M10_AXI [get_bd_intf_pins Slow_Waveform_Acq_9/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M10_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M11_AXI [get_bd_intf_pins Slow_Waveform_Acq_10/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_0/M11_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins Slow_Waveform_Gen_0/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M01_AXI [get_bd_intf_pins Slow_Waveform_Gen_1/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M02_AXI [get_bd_intf_pins Slow_Waveform_Gen_2/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M03_AXI [get_bd_intf_pins Slow_Waveform_Gen_3/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M04_AXI [get_bd_intf_pins Slow_Waveform_Gen_4/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M05_AXI [get_bd_intf_pins Slow_Waveform_Gen_5/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M05_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M06_AXI [get_bd_intf_pins Slow_Waveform_Gen_6/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M06_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M07_AXI [get_bd_intf_pins Slow_Waveform_Gen_7/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M07_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M08_AXI [get_bd_intf_pins Slow_Waveform_Gen_8/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M08_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M09_AXI [get_bd_intf_pins Slow_Waveform_Gen_9/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M09_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M10_AXI [get_bd_intf_pins Slow_Waveform_Gen_10/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M10_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M11_AXI [get_bd_intf_pins Slow_Waveform_Gen_11/SAXIL_CFG] [get_bd_intf_pins axi_interconnect_3/M11_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M00_AXI [get_bd_intf_pins Digital_Waveform_Gen_0/SAXI_CFG] [get_bd_intf_pins axi_interconnect_4/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M01_AXI [get_bd_intf_pins Digital_Waveform_Gen_1/SAXI_CFG] [get_bd_intf_pins axi_interconnect_4/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M02_AXI [get_bd_intf_pins Digital_Waveform_Gen_2/SAXI_CFG] [get_bd_intf_pins axi_interconnect_4/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M03_AXI [get_bd_intf_pins Digital_Waveform_Gen_3/SAXI_CFG] [get_bd_intf_pins axi_interconnect_4/M03_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M00_AXI1] [get_bd_intf_pins wg_axi_0/M_AXI]
  connect_bd_intf_net -intf_net d_axi_M_AXI [get_bd_intf_pins M00_AXI2] [get_bd_intf_pins d_axi/M_AXI]
  connect_bd_intf_net -intf_net wa_axi_0_M_AXI [get_bd_intf_pins M00_AXI4] [get_bd_intf_pins wa_axi_0/M_AXI]
  connect_bd_intf_net -intf_net wa_axi_1_M_AXI [get_bd_intf_pins M00_AXI6] [get_bd_intf_pins wa_axi_1/M_AXI]
  connect_bd_intf_net -intf_net wa_axi_2_M_AXI [get_bd_intf_pins M00_AXI5] [get_bd_intf_pins wa_axi_2/M_AXI]
  connect_bd_intf_net -intf_net wg_axi_1_M_AXI [get_bd_intf_pins M00_AXI] [get_bd_intf_pins wg_axi_1/M_AXI]
  connect_bd_intf_net -intf_net wg_axi_2_M_AXI [get_bd_intf_pins M00_AXI3] [get_bd_intf_pins wg_axi_2/M_AXI]

  # Create port connections
  connect_bd_net -net Digital_Waveform_Gen_0_outputLines [get_bd_pins outputLines0] [get_bd_pins Digital_Waveform_Gen_0/outputLines]
  connect_bd_net -net Digital_Waveform_Gen_1_outputLines [get_bd_pins outputLines1] [get_bd_pins Digital_Waveform_Gen_1/outputLines]
  connect_bd_net -net Digital_Waveform_Gen_2_outputLines [get_bd_pins outputLines2] [get_bd_pins Digital_Waveform_Gen_2/outputLines]
  connect_bd_net -net Digital_Waveform_Gen_3_outputLines [get_bd_pins outputLines3] [get_bd_pins Digital_Waveform_Gen_3/outputLines]
  connect_bd_net -net LSADC_FW_i1 [get_bd_pins LSADC_FW_i] [get_bd_pins LSADC/FW_i]
  connect_bd_net -net LSADC_FW_o_1 [get_bd_pins LSADC_FW_o] [get_bd_pins LSADC/FW_o]
  connect_bd_net -net LSDAC_FW_IO1 [get_bd_pins LSDAC_FW_IO] [get_bd_pins LSDAC/FW_IO]
  connect_bd_net -net Net [get_bd_pins ao_watchdog_trigger] [get_bd_pins Slow_Waveform_Gen_0/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_1/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_10/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_11/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_2/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_3/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_4/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_5/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_6/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_7/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_8/externalValueTrigger] [get_bd_pins Slow_Waveform_Gen_9/externalValueTrigger]
  connect_bd_net -net Net3 [get_bd_pins peer_triggers] [get_bd_pins Digital_Waveform_Gen_0/peer_triggers] [get_bd_pins Digital_Waveform_Gen_1/peer_triggers] [get_bd_pins Digital_Waveform_Gen_2/peer_triggers] [get_bd_pins Digital_Waveform_Gen_3/peer_triggers] [get_bd_pins Slow_Waveform_Acq_0/peer_triggers] [get_bd_pins Slow_Waveform_Acq_1/peer_triggers] [get_bd_pins Slow_Waveform_Acq_10/peer_triggers] [get_bd_pins Slow_Waveform_Acq_11/peer_triggers] [get_bd_pins Slow_Waveform_Acq_2/peer_triggers] [get_bd_pins Slow_Waveform_Acq_3/peer_triggers] [get_bd_pins Slow_Waveform_Acq_4/peer_triggers] [get_bd_pins Slow_Waveform_Acq_5/peer_triggers] [get_bd_pins Slow_Waveform_Acq_6/peer_triggers] [get_bd_pins Slow_Waveform_Acq_7/peer_triggers] [get_bd_pins Slow_Waveform_Acq_8/peer_triggers] [get_bd_pins Slow_Waveform_Acq_9/peer_triggers] [get_bd_pins Slow_Waveform_Gen_0/peer_triggers] [get_bd_pins Slow_Waveform_Gen_1/peer_triggers] [get_bd_pins Slow_Waveform_Gen_10/peer_triggers] [get_bd_pins Slow_Waveform_Gen_11/peer_triggers] [get_bd_pins Slow_Waveform_Gen_2/peer_triggers] [get_bd_pins Slow_Waveform_Gen_3/peer_triggers] [get_bd_pins Slow_Waveform_Gen_4/peer_triggers] [get_bd_pins Slow_Waveform_Gen_5/peer_triggers] [get_bd_pins Slow_Waveform_Gen_6/peer_triggers] [get_bd_pins Slow_Waveform_Gen_7/peer_triggers] [get_bd_pins Slow_Waveform_Gen_8/peer_triggers] [get_bd_pins Slow_Waveform_Gen_9/peer_triggers]
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins axiClk] [get_bd_pins Digital_Waveform_Gen_0/axiClk] [get_bd_pins Digital_Waveform_Gen_1/axiClk] [get_bd_pins Digital_Waveform_Gen_2/axiClk] [get_bd_pins Digital_Waveform_Gen_3/axiClk] [get_bd_pins Slow_Waveform_Acq_0/axiClk] [get_bd_pins Slow_Waveform_Acq_1/axiClk] [get_bd_pins Slow_Waveform_Acq_10/axiClk] [get_bd_pins Slow_Waveform_Acq_11/axiClk] [get_bd_pins Slow_Waveform_Acq_2/axiClk] [get_bd_pins Slow_Waveform_Acq_3/axiClk] [get_bd_pins Slow_Waveform_Acq_4/axiClk] [get_bd_pins Slow_Waveform_Acq_5/axiClk] [get_bd_pins Slow_Waveform_Acq_6/axiClk] [get_bd_pins Slow_Waveform_Acq_7/axiClk] [get_bd_pins Slow_Waveform_Acq_8/axiClk] [get_bd_pins Slow_Waveform_Acq_9/axiClk] [get_bd_pins Slow_Waveform_Gen_0/axiClk] [get_bd_pins Slow_Waveform_Gen_1/axiClk] [get_bd_pins Slow_Waveform_Gen_10/axiClk] [get_bd_pins Slow_Waveform_Gen_11/axiClk] [get_bd_pins Slow_Waveform_Gen_2/axiClk] [get_bd_pins Slow_Waveform_Gen_3/axiClk] [get_bd_pins Slow_Waveform_Gen_4/axiClk] [get_bd_pins Slow_Waveform_Gen_5/axiClk] [get_bd_pins Slow_Waveform_Gen_6/axiClk] [get_bd_pins Slow_Waveform_Gen_7/axiClk] [get_bd_pins Slow_Waveform_Gen_8/axiClk] [get_bd_pins Slow_Waveform_Gen_9/axiClk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/M03_ACLK] [get_bd_pins axi_interconnect_0/M04_ACLK] [get_bd_pins axi_interconnect_0/M05_ACLK] [get_bd_pins axi_interconnect_0/M06_ACLK] [get_bd_pins axi_interconnect_0/M07_ACLK] [get_bd_pins axi_interconnect_0/M08_ACLK] [get_bd_pins axi_interconnect_0/M09_ACLK] [get_bd_pins axi_interconnect_0/M10_ACLK] [get_bd_pins axi_interconnect_0/M11_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_3/ACLK] [get_bd_pins axi_interconnect_3/M00_ACLK] [get_bd_pins axi_interconnect_3/M01_ACLK] [get_bd_pins axi_interconnect_3/M02_ACLK] [get_bd_pins axi_interconnect_3/M03_ACLK] [get_bd_pins axi_interconnect_3/M04_ACLK] [get_bd_pins axi_interconnect_3/M05_ACLK] [get_bd_pins axi_interconnect_3/M06_ACLK] [get_bd_pins axi_interconnect_3/M07_ACLK] [get_bd_pins axi_interconnect_3/M08_ACLK] [get_bd_pins axi_interconnect_3/M09_ACLK] [get_bd_pins axi_interconnect_3/M10_ACLK] [get_bd_pins axi_interconnect_3/M11_ACLK] [get_bd_pins axi_interconnect_3/S00_ACLK] [get_bd_pins axi_interconnect_4/ACLK] [get_bd_pins axi_interconnect_4/M00_ACLK] [get_bd_pins axi_interconnect_4/M01_ACLK] [get_bd_pins axi_interconnect_4/M02_ACLK] [get_bd_pins axi_interconnect_4/M03_ACLK] [get_bd_pins axi_interconnect_4/S00_ACLK] [get_bd_pins d_axi/aclk] [get_bd_pins wa_axi_0/aclk] [get_bd_pins wa_axi_1/aclk] [get_bd_pins wa_axi_2/aclk] [get_bd_pins wg_axi_0/aclk] [get_bd_pins wg_axi_1/aclk] [get_bd_pins wg_axi_2/aclk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_pins axiResetN] [get_bd_pins Digital_Waveform_Gen_0/axiResetN] [get_bd_pins Digital_Waveform_Gen_1/axiResetN] [get_bd_pins Digital_Waveform_Gen_2/axiResetN] [get_bd_pins Digital_Waveform_Gen_3/axiResetN] [get_bd_pins Slow_Waveform_Acq_0/axiResetN] [get_bd_pins Slow_Waveform_Acq_1/axiResetN] [get_bd_pins Slow_Waveform_Acq_10/axiResetN] [get_bd_pins Slow_Waveform_Acq_11/axiResetN] [get_bd_pins Slow_Waveform_Acq_2/axiResetN] [get_bd_pins Slow_Waveform_Acq_3/axiResetN] [get_bd_pins Slow_Waveform_Acq_4/axiResetN] [get_bd_pins Slow_Waveform_Acq_5/axiResetN] [get_bd_pins Slow_Waveform_Acq_6/axiResetN] [get_bd_pins Slow_Waveform_Acq_7/axiResetN] [get_bd_pins Slow_Waveform_Acq_8/axiResetN] [get_bd_pins Slow_Waveform_Acq_9/axiResetN] [get_bd_pins Slow_Waveform_Gen_0/axiResetN] [get_bd_pins Slow_Waveform_Gen_1/axiResetN] [get_bd_pins Slow_Waveform_Gen_10/axiResetN] [get_bd_pins Slow_Waveform_Gen_11/axiResetN] [get_bd_pins Slow_Waveform_Gen_2/axiResetN] [get_bd_pins Slow_Waveform_Gen_3/axiResetN] [get_bd_pins Slow_Waveform_Gen_4/axiResetN] [get_bd_pins Slow_Waveform_Gen_5/axiResetN] [get_bd_pins Slow_Waveform_Gen_6/axiResetN] [get_bd_pins Slow_Waveform_Gen_7/axiResetN] [get_bd_pins Slow_Waveform_Gen_8/axiResetN] [get_bd_pins Slow_Waveform_Gen_9/axiResetN] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] [get_bd_pins axi_interconnect_0/M04_ARESETN] [get_bd_pins axi_interconnect_0/M05_ARESETN] [get_bd_pins axi_interconnect_0/M06_ARESETN] [get_bd_pins axi_interconnect_0/M07_ARESETN] [get_bd_pins axi_interconnect_0/M08_ARESETN] [get_bd_pins axi_interconnect_0/M09_ARESETN] [get_bd_pins axi_interconnect_0/M10_ARESETN] [get_bd_pins axi_interconnect_0/M11_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_3/ARESETN] [get_bd_pins axi_interconnect_3/M00_ARESETN] [get_bd_pins axi_interconnect_3/M01_ARESETN] [get_bd_pins axi_interconnect_3/M02_ARESETN] [get_bd_pins axi_interconnect_3/M03_ARESETN] [get_bd_pins axi_interconnect_3/M04_ARESETN] [get_bd_pins axi_interconnect_3/M05_ARESETN] [get_bd_pins axi_interconnect_3/M06_ARESETN] [get_bd_pins axi_interconnect_3/M07_ARESETN] [get_bd_pins axi_interconnect_3/M08_ARESETN] [get_bd_pins axi_interconnect_3/M09_ARESETN] [get_bd_pins axi_interconnect_3/M10_ARESETN] [get_bd_pins axi_interconnect_3/M11_ARESETN] [get_bd_pins axi_interconnect_3/S00_ARESETN] [get_bd_pins axi_interconnect_4/ARESETN] [get_bd_pins axi_interconnect_4/M00_ARESETN] [get_bd_pins axi_interconnect_4/M01_ARESETN] [get_bd_pins axi_interconnect_4/M02_ARESETN] [get_bd_pins axi_interconnect_4/M03_ARESETN] [get_bd_pins axi_interconnect_4/S00_ARESETN] [get_bd_pins d_axi/aresetn] [get_bd_pins wa_axi_0/aresetn] [get_bd_pins wa_axi_1/aresetn] [get_bd_pins wa_axi_2/aresetn] [get_bd_pins wg_axi_0/aresetn] [get_bd_pins wg_axi_1/aresetn] [get_bd_pins wg_axi_2/aresetn]
  connect_bd_net -net ext_triggers_1 [get_bd_pins ext_triggers] [get_bd_pins Digital_Waveform_Gen_0/ext_triggers] [get_bd_pins Digital_Waveform_Gen_1/ext_triggers] [get_bd_pins Digital_Waveform_Gen_2/ext_triggers] [get_bd_pins Digital_Waveform_Gen_3/ext_triggers] [get_bd_pins Slow_Waveform_Acq_0/ext_triggers] [get_bd_pins Slow_Waveform_Acq_1/ext_triggers] [get_bd_pins Slow_Waveform_Acq_10/ext_triggers] [get_bd_pins Slow_Waveform_Acq_11/ext_triggers] [get_bd_pins Slow_Waveform_Acq_2/ext_triggers] [get_bd_pins Slow_Waveform_Acq_3/ext_triggers] [get_bd_pins Slow_Waveform_Acq_4/ext_triggers] [get_bd_pins Slow_Waveform_Acq_5/ext_triggers] [get_bd_pins Slow_Waveform_Acq_6/ext_triggers] [get_bd_pins Slow_Waveform_Acq_7/ext_triggers] [get_bd_pins Slow_Waveform_Acq_8/ext_triggers] [get_bd_pins Slow_Waveform_Acq_9/ext_triggers] [get_bd_pins Slow_Waveform_Gen_0/ext_triggers] [get_bd_pins Slow_Waveform_Gen_1/ext_triggers] [get_bd_pins Slow_Waveform_Gen_10/ext_triggers] [get_bd_pins Slow_Waveform_Gen_11/ext_triggers] [get_bd_pins Slow_Waveform_Gen_2/ext_triggers] [get_bd_pins Slow_Waveform_Gen_3/ext_triggers] [get_bd_pins Slow_Waveform_Gen_4/ext_triggers] [get_bd_pins Slow_Waveform_Gen_5/ext_triggers] [get_bd_pins Slow_Waveform_Gen_6/ext_triggers] [get_bd_pins Slow_Waveform_Gen_7/ext_triggers] [get_bd_pins Slow_Waveform_Gen_8/ext_triggers] [get_bd_pins Slow_Waveform_Gen_9/ext_triggers]
  connect_bd_net -net lsadcSpiClkEn_1 [get_bd_pins lsadcSpiClkEn] [get_bd_pins LSADC/spiClkEn]
  connect_bd_net -net spiClkEn1_1 [get_bd_pins lsdacSpiClkEn] [get_bd_pins LSDAC/spiClkEn]
  connect_bd_net -net sysClk100_1 [get_bd_pins sampleClkTimebase] [get_bd_pins Digital_Waveform_Gen_0/sampleClkTimebase] [get_bd_pins Digital_Waveform_Gen_1/sampleClkTimebase] [get_bd_pins Digital_Waveform_Gen_2/sampleClkTimebase] [get_bd_pins Digital_Waveform_Gen_3/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_0/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_1/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_10/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_11/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_2/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_3/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_4/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_5/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_6/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_7/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_8/sampleClkTimebase] [get_bd_pins Slow_Waveform_Acq_9/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_0/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_1/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_10/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_11/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_2/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_3/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_4/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_5/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_6/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_7/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_8/sampleClkTimebase] [get_bd_pins Slow_Waveform_Gen_9/sampleClkTimebase]
  connect_bd_net -net sysClk80_1 -boundary_type lower [get_bd_pins ioClk80]
  connect_bd_net -net vDAQ_LSADC_INTF_dataClk [get_bd_pins LSADC/dataClk] [get_bd_pins Slow_Waveform_Acq_0/adcClk] [get_bd_pins Slow_Waveform_Acq_1/adcClk] [get_bd_pins Slow_Waveform_Acq_10/adcClk] [get_bd_pins Slow_Waveform_Acq_11/adcClk] [get_bd_pins Slow_Waveform_Acq_2/adcClk] [get_bd_pins Slow_Waveform_Acq_3/adcClk] [get_bd_pins Slow_Waveform_Acq_4/adcClk] [get_bd_pins Slow_Waveform_Acq_5/adcClk] [get_bd_pins Slow_Waveform_Acq_6/adcClk] [get_bd_pins Slow_Waveform_Acq_7/adcClk] [get_bd_pins Slow_Waveform_Acq_8/adcClk] [get_bd_pins Slow_Waveform_Acq_9/adcClk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set PCIE_AXI [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:vDAQ_PCIE_AXI_rtl:1.0 PCIE_AXI ]

  set SI_AUX_FIFO_0 [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 SI_AUX_FIFO_0 ]

  set SI_DATA_FIFO_0 [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 SI_DATA_FIFO_0 ]

  set SI_SCOPE_FIFO [ create_bd_intf_port -mode Slave -vlnv vidriotech.com:vidrio:variable_fifo_write_rtl:1.0 SI_SCOPE_FIFO ]


  # Create ports
  set CLKCFG_FW_i [ create_bd_port -dir O -from 5 -to 0 CLKCFG_FW_i ]
  set CLKCFG_FW_o [ create_bd_port -dir I CLKCFG_FW_o ]
  set HSADC_BOARD_IO [ create_bd_port -dir IO -from 18 -to 0 HSADC_BOARD_IO ]
  set HSADC_GTH_RX [ create_bd_port -dir I -from 15 -to 0 HSADC_GTH_RX ]
  set LSADC_FW_i [ create_bd_port -dir O -from 12 -to 0 LSADC_FW_i ]
  set LSADC_FW_o [ create_bd_port -dir I -from 204 -to 0 LSADC_FW_o ]
  set LSDAC_FW_IO [ create_bd_port -dir O -from 240 -to 0 LSDAC_FW_IO ]
  set PCIE_SAXIL_readAddress [ create_bd_port -dir O -from 11 -to 0 PCIE_SAXIL_readAddress ]
  set PCIE_SAXIL_readData [ create_bd_port -dir I -from 31 -to 0 PCIE_SAXIL_readData ]
  set PCIE_SAXIL_writeAddress [ create_bd_port -dir O -from 11 -to 0 PCIE_SAXIL_writeAddress ]
  set PCIE_SAXIL_writeData [ create_bd_port -dir O -from 31 -to 0 PCIE_SAXIL_writeData ]
  set PCIE_SAXIL_writeStrobe [ create_bd_port -dir O -from 3 -to 0 PCIE_SAXIL_writeStrobe ]
  set ao_watchdog_trigger [ create_bd_port -dir I ao_watchdog_trigger ]
  set auxClkIn [ create_bd_port -dir I auxClkIn ]
  set dataClk [ create_bd_port -dir I -type clk -freq_hz 125000000 dataClk ]
  set_property -dict [ list \
   CONFIG.CLK_DOMAIN {vDAQR1_BD_MSADC_0_sampleClk} \
 ] $dataClk
  set digitalTask0_o [ create_bd_port -dir O -from 7 -to 0 digitalTask0_o ]
  set digitalTask1_o [ create_bd_port -dir O -from 7 -to 0 digitalTask1_o ]
  set digitalTask2_o [ create_bd_port -dir O -from 7 -to 0 digitalTask2_o ]
  set digitalTask3_o [ create_bd_port -dir O -from 7 -to 0 digitalTask3_o ]
  set ext_triggers [ create_bd_port -dir I -from 57 -to 0 ext_triggers ]
  set hsadcDataClk [ create_bd_port -dir O -type clk hsadcDataClk ]
  set hsadcDataValid [ create_bd_port -dir O hsadcDataValid ]
  set hsadcSampleDataA [ create_bd_port -dir O -from 383 -to 0 -type data hsadcSampleDataA ]
  set hsadcSampleDataB [ create_bd_port -dir O -from 383 -to 0 -type data hsadcSampleDataB ]
  set ioClk40 [ create_bd_port -dir I -type clk -freq_hz 40000000 ioClk40 ]
  set ioClk80 [ create_bd_port -dir I -type clk -freq_hz 80000000 ioClk80 ]
  set lsadcSpiClkEn [ create_bd_port -dir I lsadcSpiClkEn ]
  set lsdacSpiClkEn [ create_bd_port -dir I lsdacSpiClkEn ]
  set pcie_aclk [ create_bd_port -dir I -type clk -freq_hz 125000000 pcie_aclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {pcie_aresetn:pcie_aresetn} \
   CONFIG.CLK_DOMAIN {vDAQ_BD_pcie_aclk} \
 ] $pcie_aclk
  set pcie_aresetn [ create_bd_port -dir I -type rst pcie_aresetn ]
  set peer_triggers [ create_bd_port -dir IO -from 27 -to 0 peer_triggers ]
  set sysClk200 [ create_bd_port -dir I -type clk -freq_hz 200000000 sysClk200 ]
  set thermal_pd [ create_bd_port -dir I thermal_pd ]

  # Create instance: CLKCFG, and set properties
  set CLKCFG [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:vDAQR1_CLKCFG:1.0 CLKCFG ]

  # Create instance: DAQ
  create_hier_cell_DAQ [current_bd_instance .] DAQ

  # Create instance: HSADC, and set properties
  set HSADC [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:vDAQ_HSADC:1.0 HSADC ]

  # Create instance: PCIE_AXI
  create_hier_cell_PCIE_AXI [current_bd_instance .] PCIE_AXI

  # Create instance: PCIE_SAXIL, and set properties
  set PCIE_SAXIL [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:AXI_Lite_Slave_RTL_Interface:1.0 PCIE_SAXIL ]

  # Create instance: SI_ACQ_FIFO_0, and set properties
  set SI_ACQ_FIFO_0 [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:FIFO2MM_Transport:2.0 SI_ACQ_FIFO_0 ]
  set_property -dict [ list \
   CONFIG.ACTUAL_DEPTH_CALC {512} \
   CONFIG.AVOID_DB_WIDTH_CALC {65} \
   CONFIG.AXI_DATA_WIDTH {256} \
   CONFIG.DEV_BUF_NUM_BR_CALC {16} \
   CONFIG.DEV_BUF_SIZE_KB_CALC {32} \
   CONFIG.FIFO_DEPTH {512} \
   CONFIG.FIFO_INPUT_WIDTH_BYTES {64} \
   CONFIG.FIFO_SAFE_VARIABLE_INPUT {false} \
   CONFIG.FIFO_VARIABLE_INPUT_WIDTH {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.MIN_DB_WIDTH_CALC {64} \
   CONFIG.NUM_BR_COLS_CALC {16} \
   CONFIG.NUM_BR_COLS_PRE_CALC {16} \
   CONFIG.NUM_BR_RANKS_CALC {1} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
 ] $SI_ACQ_FIFO_0

  # Create instance: SI_AUX_FIFO_0, and set properties
  set SI_AUX_FIFO_0 [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:FIFO2MM_Transport:2.0 SI_AUX_FIFO_0 ]
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
 ] $SI_AUX_FIFO_0

  # Create instance: SI_SCOPE_FIFO, and set properties
  set SI_SCOPE_FIFO [ create_bd_cell -type ip -vlnv vidriotechnologies.com:vidrio:FIFO2MM_Transport:2.0 SI_SCOPE_FIFO ]
  set_property -dict [ list \
   CONFIG.ACTUAL_DEPTH_CALC {2473} \
   CONFIG.AVOID_DB_WIDTH_CALC {54} \
   CONFIG.AXI_DATA_WIDTH {256} \
   CONFIG.DEV_BUF_NUM_BR_CALC {64} \
   CONFIG.DEV_BUF_SIZE_KB_CALC {128} \
   CONFIG.FIFO_DEPTH {2000} \
   CONFIG.FIFO_INPUT_WIDTH_BYTES {53} \
   CONFIG.FIFO_VARIABLE_INPUT_WIDTH {true} \
   CONFIG.MAXI_DATA_ADDR_WIDTH {40} \
   CONFIG.MIN_DB_WIDTH_CALC {53} \
   CONFIG.NUM_BR_COLS_CALC {16} \
   CONFIG.NUM_BR_COLS_PRE_CALC {16} \
   CONFIG.NUM_BR_RANKS_CALC {4} \
   CONFIG.SG_PAGE_LIST_LENGTH {8192} \
   CONFIG.SHOW_DBG_PORTS {false} \
 ] $SI_SCOPE_FIFO

  # Create interface connections
  connect_bd_intf_net -intf_net DAQ_M00_AXI3 [get_bd_intf_pins DAQ/M00_AXI3] [get_bd_intf_pins PCIE_AXI/S06_AXI]
  connect_bd_intf_net -intf_net DAQ_M00_AXI4 [get_bd_intf_pins DAQ/M00_AXI4] [get_bd_intf_pins PCIE_AXI/S07_AXI]
  connect_bd_intf_net -intf_net DAQ_M00_AXI5 [get_bd_intf_pins DAQ/M00_AXI5] [get_bd_intf_pins PCIE_AXI/S08_AXI]
  connect_bd_intf_net -intf_net DAQ_M00_AXI6 [get_bd_intf_pins DAQ/M00_AXI6] [get_bd_intf_pins PCIE_AXI/S09_AXI]
  connect_bd_intf_net -intf_net PCIE_AXI_1 [get_bd_intf_ports PCIE_AXI] [get_bd_intf_pins PCIE_AXI/PCIE_AXI]
  connect_bd_intf_net -intf_net PCIE_AXI_M06_AXI [get_bd_intf_pins PCIE_AXI/M05_AXI] [get_bd_intf_pins SI_AUX_FIFO_0/SAXIL_CFG]
  connect_bd_intf_net -intf_net PCIE_AXI_M07_AXI [get_bd_intf_pins PCIE_AXI/M06_AXI] [get_bd_intf_pins SI_ACQ_FIFO_0/SAXIL_CFG]
  connect_bd_intf_net -intf_net PCIE_AXI_M08_AXI [get_bd_intf_pins PCIE_AXI/M07_AXI] [get_bd_intf_pins SI_SCOPE_FIFO/SAXIL_CFG]
  connect_bd_intf_net -intf_net PCIE_AXI_M09_AXI [get_bd_intf_pins HSADC/SAXIL_CFG] [get_bd_intf_pins PCIE_AXI/M08_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins DAQ/M00_AXI] [get_bd_intf_pins PCIE_AXI/S00_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins DAQ/M00_AXI1] [get_bd_intf_pins PCIE_AXI/S01_AXI]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins DAQ/M00_AXI2] [get_bd_intf_pins PCIE_AXI/DIGITAL_DMA]
  connect_bd_intf_net -intf_net S05_AXI_1 [get_bd_intf_pins PCIE_AXI/S05_AXI] [get_bd_intf_pins SI_SCOPE_FIFO/MAXI_DATA]
  connect_bd_intf_net -intf_net SI_ACQ_FIFO_0_MAXI_DATA_OUT [get_bd_intf_pins PCIE_AXI/S04_AXI] [get_bd_intf_pins SI_ACQ_FIFO_0/MAXI_DATA]
  connect_bd_intf_net -intf_net SI_AUX_FIFO_0_1 [get_bd_intf_ports SI_AUX_FIFO_0] [get_bd_intf_pins SI_AUX_FIFO_0/FIFO_DATA_IN]
  connect_bd_intf_net -intf_net SI_AUX_FIFO_0_MAXI_DATA_OUT [get_bd_intf_pins PCIE_AXI/S03_AXI] [get_bd_intf_pins SI_AUX_FIFO_0/MAXI_DATA]
  connect_bd_intf_net -intf_net SI_DATA_FIFO_0_1 [get_bd_intf_ports SI_DATA_FIFO_0] [get_bd_intf_pins SI_ACQ_FIFO_0/FIFO_DATA_IN]
  connect_bd_intf_net -intf_net SI_SCOPE_FIFO_0_1 [get_bd_intf_ports SI_SCOPE_FIFO] [get_bd_intf_pins SI_SCOPE_FIFO/FIFO_DATA_IN]
  connect_bd_intf_net -intf_net axi_interconnect_4_M00_AXI [get_bd_intf_pins PCIE_AXI/M00_AXI] [get_bd_intf_pins PCIE_SAXIL/SAXIL]
  connect_bd_intf_net -intf_net axi_interconnect_4_M01_AXI [get_bd_intf_pins DAQ/S00_AXI] [get_bd_intf_pins PCIE_AXI/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M02_AXI [get_bd_intf_pins DAQ/S00_AXI1] [get_bd_intf_pins PCIE_AXI/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M03_AXI [get_bd_intf_pins DAQ/S00_AXI2] [get_bd_intf_pins PCIE_AXI/M03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_4_M04_AXI [get_bd_intf_pins CLKCFG/SAXIL_CFG] [get_bd_intf_pins PCIE_AXI/M04_AXI]

  # Create port connections
  connect_bd_net -net AXI_Lite_Slave_RTL_Interface_1_readAddress [get_bd_ports PCIE_SAXIL_readAddress] [get_bd_pins PCIE_SAXIL/readAddress]
  connect_bd_net -net AXI_Lite_Slave_RTL_Interface_1_writeAddress [get_bd_ports PCIE_SAXIL_writeAddress] [get_bd_pins PCIE_SAXIL/writeAddress]
  connect_bd_net -net AXI_Lite_Slave_RTL_Interface_1_writeData [get_bd_ports PCIE_SAXIL_writeData] [get_bd_pins PCIE_SAXIL/writeData]
  connect_bd_net -net AXI_Lite_Slave_RTL_Interface_1_writeStrobe [get_bd_ports PCIE_SAXIL_writeStrobe] [get_bd_pins PCIE_SAXIL/writeStrobe]
  connect_bd_net -net CLKCFG_FW_i1 [get_bd_ports CLKCFG_FW_i] [get_bd_pins CLKCFG/FW_i]
  connect_bd_net -net CLKCFG_FW_o_1 [get_bd_ports CLKCFG_FW_o] [get_bd_pins CLKCFG/FW_o]
  connect_bd_net -net DAQ_LSADC_FW_i [get_bd_ports LSADC_FW_i] [get_bd_pins DAQ/LSADC_FW_i]
  connect_bd_net -net DAQ_LSDAC_FW_IO [get_bd_ports LSDAC_FW_IO] [get_bd_pins DAQ/LSDAC_FW_IO]
  connect_bd_net -net DAQ_outputLines [get_bd_ports digitalTask0_o] [get_bd_pins DAQ/outputLines0]
  connect_bd_net -net DAQ_outputLines1 [get_bd_ports digitalTask1_o] [get_bd_pins DAQ/outputLines1]
  connect_bd_net -net DAQ_outputLines2 [get_bd_ports digitalTask2_o] [get_bd_pins DAQ/outputLines2]
  connect_bd_net -net DAQ_outputLines3 [get_bd_ports digitalTask3_o] [get_bd_pins DAQ/outputLines3]
  connect_bd_net -net HSADC_GTH_RX_1 [get_bd_ports HSADC_GTH_RX] [get_bd_pins HSADC/GTH_RX]
  connect_bd_net -net LSADC_FW_o_1 [get_bd_ports LSADC_FW_o] [get_bd_pins DAQ/LSADC_FW_o]
  connect_bd_net -net Net4 [get_bd_ports peer_triggers] [get_bd_pins DAQ/peer_triggers]
  connect_bd_net -net Net5 [get_bd_ports HSADC_BOARD_IO] [get_bd_pins HSADC/BOARD_IO]
  connect_bd_net -net SYS_SAXIL_readData_1 [get_bd_ports PCIE_SAXIL_readData] [get_bd_pins PCIE_SAXIL/readData]
  connect_bd_net -net ao_watchdog_trigger_1 [get_bd_ports ao_watchdog_trigger] [get_bd_pins DAQ/ao_watchdog_trigger]
  connect_bd_net -net auxClkIn_1 [get_bd_ports auxClkIn] [get_bd_pins HSADC/auxClkIn]
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_ports pcie_aclk] [get_bd_pins DAQ/axiClk] [get_bd_pins HSADC/axiClk] [get_bd_pins PCIE_AXI/aclk] [get_bd_pins PCIE_SAXIL/ACLK] [get_bd_pins SI_ACQ_FIFO_0/axiClk] [get_bd_pins SI_AUX_FIFO_0/axiClk] [get_bd_pins SI_SCOPE_FIFO/axiClk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_ports pcie_aresetn] [get_bd_pins DAQ/axiResetN] [get_bd_pins HSADC/axiResetN] [get_bd_pins PCIE_AXI/aresetn] [get_bd_pins PCIE_SAXIL/ARESETN] [get_bd_pins SI_ACQ_FIFO_0/axiResetN] [get_bd_pins SI_AUX_FIFO_0/axiResetN] [get_bd_pins SI_SCOPE_FIFO/axiResetN]
  connect_bd_net -net dataClk_1 [get_bd_ports dataClk] [get_bd_pins SI_ACQ_FIFO_0/inputClk] [get_bd_pins SI_AUX_FIFO_0/inputClk] [get_bd_pins SI_SCOPE_FIFO/inputClk]
  connect_bd_net -net ext_triggers_1 [get_bd_ports ext_triggers] [get_bd_pins DAQ/ext_triggers]
  connect_bd_net -net lsadcSpiClkEn_1 [get_bd_ports lsadcSpiClkEn] [get_bd_pins DAQ/lsadcSpiClkEn]
  connect_bd_net -net lsdacSpiClkEn_1 [get_bd_ports lsdacSpiClkEn] [get_bd_pins DAQ/lsdacSpiClkEn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins CLKCFG/axiResetN] [get_bd_pins PCIE_AXI/aresetn_40]
  connect_bd_net -net sampleClkTimebase_1 [get_bd_ports sysClk200] [get_bd_pins DAQ/sampleClkTimebase]
  connect_bd_net -net sysClk40_1 [get_bd_ports ioClk40] [get_bd_pins CLKCFG/clk40] [get_bd_pins PCIE_AXI/ioClk40]
  connect_bd_net -net sysClk80_1 [get_bd_ports ioClk80] [get_bd_pins DAQ/ioClk80]
  connect_bd_net -net thermal_pd_1 [get_bd_ports thermal_pd] [get_bd_pins HSADC/thermal_pd]
  connect_bd_net -net vDAQ_HSADC_0_dataA [get_bd_ports hsadcSampleDataA] [get_bd_pins HSADC/dataA]
  connect_bd_net -net vDAQ_HSADC_0_dataB [get_bd_ports hsadcSampleDataB] [get_bd_pins HSADC/dataB]
  connect_bd_net -net vDAQ_HSADC_0_dataClk [get_bd_ports hsadcDataClk] [get_bd_pins HSADC/dataClk]
  connect_bd_net -net vDAQ_HSADC_0_dataValid [get_bd_ports hsadcDataValid] [get_bd_pins HSADC/dataValid]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces SI_ACQ_FIFO_0/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces SI_AUX_FIFO_0/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces SI_SCOPE_FIFO/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Digital_Waveform_Gen_0/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Digital_Waveform_Gen_1/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Digital_Waveform_Gen_2/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Digital_Waveform_Gen_3/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_0/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_1/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_2/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_3/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_4/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_5/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_6/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_7/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_8/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_9/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_10/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Acq_11/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_0/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_1/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_2/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_3/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_4/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_5/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_6/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_7/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_8/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_9/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_10/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x010000000000 -target_address_space [get_bd_addr_spaces DAQ/Slow_Waveform_Gen_11/MAXI_DATA] [get_bd_addr_segs PCIE_AXI/vDAQ_PCIE_AXI_0/SAXI/reg0] -force
  assign_bd_address -offset 0x00440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs CLKCFG/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Digital_Waveform_Gen_0/SAXI_CFG/reg0] -force
  assign_bd_address -offset 0x00310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Digital_Waveform_Gen_1/SAXI_CFG/reg0] -force
  assign_bd_address -offset 0x00320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Digital_Waveform_Gen_2/SAXI_CFG/reg0] -force
  assign_bd_address -offset 0x00330000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Digital_Waveform_Gen_3/SAXI_CFG/reg0] -force
  assign_bd_address -offset 0x00470000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs HSADC/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00400000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs PCIE_SAXIL/SAXIL/Reg] -force
  assign_bd_address -offset 0x00480000 -range 0x00001000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs SI_ACQ_FIFO_0/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00481000 -range 0x00001000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs SI_AUX_FIFO_0/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00482000 -range 0x00001000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs SI_SCOPE_FIFO/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_0/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x005A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_10/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x005B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_11/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x00510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_1/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x00520000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_2/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x00530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_3/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x00540000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_4/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x00550000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_5/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x00560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_6/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x00570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_7/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x00580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_8/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x00590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Acq_9/SAXIL_CFG/Reg] -force
  assign_bd_address -offset 0x00600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_0/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x006A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_10/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x006B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_11/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_1/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00620000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_2/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00630000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_3/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00640000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_4/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00650000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_5/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00660000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_6/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00670000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_7/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00680000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_8/SAXIL_CFG/reg0] -force
  assign_bd_address -offset 0x00690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PCIE_AXI/vDAQ_PCIE_AXI_0/MAXI] [get_bd_addr_segs DAQ/Slow_Waveform_Gen_9/SAXIL_CFG/reg0] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


