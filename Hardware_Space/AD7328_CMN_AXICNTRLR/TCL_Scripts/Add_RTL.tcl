puts "INFO: Adding Source File"

# Add Source File
set rtl_file "../Sources/AD7328_CMN_AXISYS_wrapper.vhd"
add_files -fileset sources_1 $rtl_file

# Set Top Module
set_property top AD7328_CMN_AXISYS_wrapper [current_fileset]
