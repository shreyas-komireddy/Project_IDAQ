puts "INFO: Adding Constraint File"

# Add XDC File
set xdc_file "../Constraints/IDAQ_AXIPinout.xdc"
add_files -fileset constrs_1 $xdc_file
