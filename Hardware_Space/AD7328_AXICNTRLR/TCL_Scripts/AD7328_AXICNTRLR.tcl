#Specify FPGA Part Number
set fpga_prt "xc7z030ffg676-2"

#Name a Project
set Proj_Nme "AD7328_AXIPRTYPE"

#Specify the Project Creation Directory
set Proj_Dir "../Project"

# Delete Old Project to regenerate the Project with new content
if {[file exists $Proj_Dir]} {
    puts "Info: Old Project Deleted."
    file delete -force $Proj_Dir
} else {
    puts "Info: No existing project found"
}

# Regenerate Project 
create_project $Proj_Nme $Proj_Dir -part $fpga_prt

set_property target_language VHDL [current_project]

# Add IPs Repository
set_property ip_repo_paths "f:/Project_IDAQclone/Project_IDAQ/Hardware_Space/AD7328_AXICNTRLR/IPs_Repo" [current_project]
update_ip_catalog

# Execute RTL TCL file
# source "../TCL_Scripts/Add_RTL.tcl"

# Execute Constraint TCL File
source "../TCL_Scripts/Add_Pinout.tcl"

# Execute Block Design TCL File
source "../TCL_Scripts/BD_Des.tcl"
