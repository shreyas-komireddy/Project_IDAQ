puts "INFO: Adding Constraint File"

# Add XDC File
set xdc_file "../Constraints/AD7328_CMNPinout.xdc"
add_files -fileset constrs_1 $xdc_file
