# file: FIRMWARE_QSPI.xdc
# (c) Copyright 2009 - 2012 Xilinx, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of Xilinx, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# Xilinx, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) Xilinx shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or Xilinx had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# Xilinx products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of Xilinx products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
# Set false path on the reset synchronizers
set_false_path -from [get_cells -hierarchical -filter {NAME =~*_FIFO_II/USE_2N_DEPTH.V6_S6_AND_LATER.I_ASYNC_FIFO_BRAM/*rstblk*/*rst_reg_reg[*]}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~*_FIFO_II/USE_2N_DEPTH.V6_S6_AND_LATER.I_ASYNC_FIFO_BRAM/*rstblk*/*PRE}]
##set_false_path -to [get_pins -hierarchical -filter {NAME =~*/*rstblk*/*CLR}]

## IOB constraints ######



#####################################################################################################
# The following section list the board specific constraints (with/without STARTUPE2/E3 primitive)   #
# as per guidance given in product guide.                                                           #
# User should uncomment, update constraints based on board delays and use                           #
#####################################################################################################

#####################################################################################################
# STARTUPE3 primitive included inside IP                                                            #
#####################################################################################################

#### All the delay numbers have to be provided by the user

## CCLK delay is 0.1, 6.7 ns min/max for ultra-scale devices; refer Data sheet
## Consider the max delay for worst case analysis
set cclk_delay 7.5
set USRCCLKO_Pin [get_pins -of_objects [get_nets -segments -of_objects [get_pins FIRMWARE_QSPI_Inst/sck_o]] -filter {IS_LEAF && (DIRECTION == "IN")}]
set STARTUP_cell [get_cells -of_objects $USRCCLKO_Pin]
set DI_pins [get_pins -of_objects $STARTUP_cell -filter {NAME =~ "*DI[*]"}]
set DO_pins [get_pins -of_objects $STARTUP_cell -filter {NAME =~ "*DO[*]"}]
set DTS_pins [get_pins -of_objects $STARTUP_cell -filter {NAME =~ "*DTS[*]"}]

create_generated_clock -name clk_sck -source [get_pins FIRMWARE_QSPI_Inst/ext_spi_clk] -edges {3 5 7} -edge_shift [list $cclk_delay $cclk_delay $cclk_delay] $USRCCLKO_Pin

set_multicycle_path -setup -from clk_sck -to [get_clocks -of_objects [get_pins FIRMWARE_QSPI_Inst/ext_spi_clk]] 2
set_multicycle_path -hold -end -from clk_sck -to [get_clocks -of_objects [get_pins FIRMWARE_QSPI_Inst/ext_spi_clk]] 1
set_multicycle_path -setup -start -from [get_clocks -of_objects [get_pins FIRMWARE_QSPI_Inst/ext_spi_clk]] -to clk_sck 2
set_multicycle_path -hold -from [get_clocks -of_objects [get_pins FIRMWARE_QSPI_Inst/ext_spi_clk]] -to clk_sck 1

## Max delay constraints are used to instruct the tool to place IP near to STARTUPE3 primitive.
## If needed adjust the delays appropriately
set_max_delay -datapath_only -from $DI_pins 1.000
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins FIRMWARE_QSPI_Inst/ext_spi_clk]] -to $USRCCLKO_Pin 1.000
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins FIRMWARE_QSPI_Inst/ext_spi_clk]] -to $DO_pins 1.000
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins FIRMWARE_QSPI_Inst/ext_spi_clk]] -to $DTS_pins 1.000


