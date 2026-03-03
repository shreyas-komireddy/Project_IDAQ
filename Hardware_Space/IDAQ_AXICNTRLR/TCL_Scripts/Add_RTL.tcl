puts "INFO: Adding RTL Files"

# Add all .vhd Files
set rtl_files [glob ../Sources/*.vhd]
foreach f $rtl_files {
    add_files -fileset sources_1 $f
}

# Update Compile Order
update_compile_order -fileset sources_1

# Set Top Module
set_property top IDAQ_AXISYS_wrapper [current_fileset]