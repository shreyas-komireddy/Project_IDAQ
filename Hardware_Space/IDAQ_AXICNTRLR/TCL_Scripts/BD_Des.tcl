
################################################################
# This is a generated script based on design: IDAQ_AXISYS
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
set scripts_vivado_version 2024.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source IDAQ_AXISYS_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# LED_SW

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z030ffg676-2
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name IDAQ_AXISYS

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
xilinx.com:ip:processing_system7:5.5\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:user:Intr_Pltfrm:1.0\
xilinx.com:user:RTCC:1.0\
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

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
LED_SW\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
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
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]

  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]

  set UART_0_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART_0_0 ]


  # Create ports
  set ad3542_cs_0 [ create_bd_port -dir O -from 3 -to 0 ad3542_cs_0 ]
  set ad3542_ldac_0 [ create_bd_port -dir O -from 3 -to 0 ad3542_ldac_0 ]
  set ad3542_rst_0 [ create_bd_port -dir O -from 3 -to 0 -type rst ad3542_rst_0 ]
  set ad3542_sclk_0 [ create_bd_port -dir O -from 3 -to 0 ad3542_sclk_0 ]
  set ad3542_sdi_0 [ create_bd_port -dir O -from 3 -to 0 ad3542_sdi_0 ]
  set ad3542_sdo_0 [ create_bd_port -dir I -from 3 -to 0 ad3542_sdo_0 ]
  set ad7328_cs_0 [ create_bd_port -dir O -from 1 -to 0 ad7328_cs_0 ]
  set ad7328_sclk_0 [ create_bd_port -dir O -from 1 -to 0 ad7328_sclk_0 ]
  set ad7328_sdi_0 [ create_bd_port -dir O -from 1 -to 0 ad7328_sdi_0 ]
  set ad7328_sdo_0 [ create_bd_port -dir I -from 1 -to 0 ad7328_sdo_0 ]
  set digi_in_0 [ create_bd_port -dir I -from 15 -to 0 digi_in_0 ]
  set digi_out_0 [ create_bd_port -dir O -from 15 -to 0 digi_out_0 ]
  set cs_0 [ create_bd_port -dir O cs_0 ]
  set miso_0 [ create_bd_port -dir I miso_0 ]
  set mosi_0 [ create_bd_port -dir O mosi_0 ]
  set sclk_0 [ create_bd_port -dir O sclk_0 ]
  set led_out_0 [ create_bd_port -dir O -from 7 -to 0 led_out_0 ]
  set sw_in_0 [ create_bd_port -dir I sw_in_0 ]

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0 ]
  set_property -dict [list \
    CONFIG.PCW_ACT_APU_PERIPHERAL_FREQMHZ {666.666687} \
    CONFIG.PCW_ACT_CAN_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_DCI_PERIPHERAL_FREQMHZ {10.158730} \
    CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_ENET1_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {125.000000} \
    CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_PCAP_PERIPHERAL_FREQMHZ {200.000000} \
    CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_SMC_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_TPIU_PERIPHERAL_FREQMHZ {200.000000} \
    CONFIG.PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {100.000000} \
    CONFIG.PCW_ACT_WDT_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_CLK0_FREQ {125000000} \
    CONFIG.PCW_CLK1_FREQ {10000000} \
    CONFIG.PCW_CLK2_FREQ {10000000} \
    CONFIG.PCW_CLK3_FREQ {10000000} \
    CONFIG.PCW_DDR_RAM_HIGHADDR {0x3FFFFFFF} \
    CONFIG.PCW_EN_EMIO_UART0 {1} \
    CONFIG.PCW_EN_UART0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {125} \
    CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
    CONFIG.PCW_UART0_GRP_FULL_ENABLE {0} \
    CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_UART0_UART0_IO {EMIO} \
    CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_UART_PERIPHERAL_VALID {1} \
    CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {533.333374} \
    CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41K256M16 RE-125} \
  ] $processing_system7_0


  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]

  # Create instance: rst_ps7_0_125M, and set properties
  set rst_ps7_0_125M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_125M ]

  # Create instance: Intr_Pltfrm_0, and set properties
  set Intr_Pltfrm_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:Intr_Pltfrm:1.0 Intr_Pltfrm_0 ]

  # Create instance: RTCC_0, and set properties
  set RTCC_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:RTCC:1.0 RTCC_0 ]

  # Create instance: LED_SW_0, and set properties
  set block_name LED_SW
  set block_cell_name LED_SW_0
  if { [catch {set LED_SW_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $LED_SW_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins Intr_Pltfrm_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins RTCC_0/S00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_UART_0 [get_bd_intf_ports UART_0_0] [get_bd_intf_pins processing_system7_0/UART_0]

  # Create port connections
  connect_bd_net -net Intr_Pltfrm_0_ad3542_cs  [get_bd_pins Intr_Pltfrm_0/ad3542_cs] \
  [get_bd_ports ad3542_cs_0]
  connect_bd_net -net Intr_Pltfrm_0_ad3542_ldac  [get_bd_pins Intr_Pltfrm_0/ad3542_ldac] \
  [get_bd_ports ad3542_ldac_0]
  connect_bd_net -net Intr_Pltfrm_0_ad3542_rst  [get_bd_pins Intr_Pltfrm_0/ad3542_rst] \
  [get_bd_ports ad3542_rst_0]
  connect_bd_net -net Intr_Pltfrm_0_ad3542_sclk  [get_bd_pins Intr_Pltfrm_0/ad3542_sclk] \
  [get_bd_ports ad3542_sclk_0]
  connect_bd_net -net Intr_Pltfrm_0_ad3542_sdi  [get_bd_pins Intr_Pltfrm_0/ad3542_sdi] \
  [get_bd_ports ad3542_sdi_0]
  connect_bd_net -net Intr_Pltfrm_0_ad7328_cs  [get_bd_pins Intr_Pltfrm_0/ad7328_cs] \
  [get_bd_ports ad7328_cs_0]
  connect_bd_net -net Intr_Pltfrm_0_ad7328_sclk  [get_bd_pins Intr_Pltfrm_0/ad7328_sclk] \
  [get_bd_ports ad7328_sclk_0]
  connect_bd_net -net Intr_Pltfrm_0_ad7328_sdi  [get_bd_pins Intr_Pltfrm_0/ad7328_sdi] \
  [get_bd_ports ad7328_sdi_0]
  connect_bd_net -net Intr_Pltfrm_0_digi_out  [get_bd_pins Intr_Pltfrm_0/digi_out] \
  [get_bd_ports digi_out_0]
  connect_bd_net -net Intr_Pltfrm_0_led_out  [get_bd_pins Intr_Pltfrm_0/led_out] \
  [get_bd_pins LED_SW_0/intr_pltf]
  connect_bd_net -net LED_SW_0_led_out  [get_bd_pins LED_SW_0/led_out] \
  [get_bd_ports led_out_0]
  connect_bd_net -net RTCC_0_cs  [get_bd_pins RTCC_0/cs] \
  [get_bd_ports cs_0] \
  [get_bd_pins LED_SW_0/rtcc_in]
  connect_bd_net -net RTCC_0_mosi  [get_bd_pins RTCC_0/mosi] \
  [get_bd_ports mosi_0]
  connect_bd_net -net RTCC_0_sclk  [get_bd_pins RTCC_0/sclk] \
  [get_bd_ports sclk_0]
  connect_bd_net -net ad3542_sdo_0_1  [get_bd_ports ad3542_sdo_0] \
  [get_bd_pins Intr_Pltfrm_0/ad3542_sdo]
  connect_bd_net -net ad7328_sdo_0_1  [get_bd_ports ad7328_sdo_0] \
  [get_bd_pins Intr_Pltfrm_0/ad7328_sdo]
  connect_bd_net -net digi_in_0_1  [get_bd_ports digi_in_0] \
  [get_bd_pins Intr_Pltfrm_0/digi_in]
  connect_bd_net -net miso_0_1  [get_bd_ports miso_0] \
  [get_bd_pins RTCC_0/miso]
  connect_bd_net -net processing_system7_0_FCLK_CLK0  [get_bd_pins processing_system7_0/FCLK_CLK0] \
  [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] \
  [get_bd_pins axi_interconnect_0/ACLK] \
  [get_bd_pins rst_ps7_0_125M/slowest_sync_clk] \
  [get_bd_pins axi_interconnect_0/S00_ACLK] \
  [get_bd_pins Intr_Pltfrm_0/s00_axi_aclk] \
  [get_bd_pins axi_interconnect_0/M00_ACLK] \
  [get_bd_pins axi_interconnect_0/M01_ACLK] \
  [get_bd_pins RTCC_0/s00_axi_aclk]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N  [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
  [get_bd_pins rst_ps7_0_125M/ext_reset_in]
  connect_bd_net -net rst_ps7_0_125M_peripheral_aresetn  [get_bd_pins rst_ps7_0_125M/peripheral_aresetn] \
  [get_bd_pins axi_interconnect_0/ARESETN] \
  [get_bd_pins axi_interconnect_0/S00_ARESETN] \
  [get_bd_pins Intr_Pltfrm_0/s00_axi_aresetn] \
  [get_bd_pins axi_interconnect_0/M00_ARESETN] \
  [get_bd_pins axi_interconnect_0/M01_ARESETN] \
  [get_bd_pins RTCC_0/s00_axi_aresetn]
  connect_bd_net -net sw_in_0_1  [get_bd_ports sw_in_0] \
  [get_bd_pins LED_SW_0/sw_in]

  # Create address segments
  assign_bd_address -offset 0x43C00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs Intr_Pltfrm_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x43C10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs RTCC_0/S00_AXI/S00_AXI_reg] -force


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


