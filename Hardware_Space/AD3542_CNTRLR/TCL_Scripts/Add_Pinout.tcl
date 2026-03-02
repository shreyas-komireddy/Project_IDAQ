puts "INFO: Adding Constraint File"

# Add XDC File
set xdc_file "../Constraints/AD3542_Pinout.xdc"
add_files -fileset constrs_1 $xdc_file

# Update Compile Order
update_compile_order -fileset constrs_1