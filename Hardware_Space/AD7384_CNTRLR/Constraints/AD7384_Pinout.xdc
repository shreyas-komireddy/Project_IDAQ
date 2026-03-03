### Clocking Wizard Ports
set_property PACKAGE_PIN J14 [get_ports CLK_IN1_D_0_clk_p]
set_property PACKAGE_PIN H14 [get_ports CLK_IN1_D_0_clk_n]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports CLK_IN1_D_0_clk_p]

### PL System Reset Port
set_property PACKAGE_PIN Y12 [get_ports sys_rst_0]
set_property IOSTANDARD LVCMOS33 [get_ports sys_rst_0]

### Slide Switches Ports
set_property PACKAGE_PIN F13 [get_ports {ctrlr_reg_0[0]}]
set_property PACKAGE_PIN E11 [get_ports {ctrlr_reg_0[1]}]
set_property PACKAGE_PIN E10 [get_ports {ctrlr_reg_0[2]}]
set_property PACKAGE_PIN G12 [get_ports {ctrlr_reg_0[3]}]
set_property PACKAGE_PIN G10 [get_ports {ctrlr_reg_0[4]}]
set_property PACKAGE_PIN H13 [get_ports {ctrlr_reg_0[5]}]
set_property PACKAGE_PIN K15 [get_ports {ctrlr_reg_0[6]}]
set_property PACKAGE_PIN K13 [get_ports {ctrlr_reg_0[7]}]

### Slide Switches IO Standards
set_property IOSTANDARD LVCMOS18 [get_ports {ctrlr_reg_0[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {ctrlr_reg_0[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {ctrlr_reg_0[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {ctrlr_reg_0[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {ctrlr_reg_0[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {ctrlr_reg_0[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {ctrlr_reg_0[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {ctrlr_reg_0[0]}]

### LED Ports
set_property PACKAGE_PIN B17 [get_ports {led_out_0[0]}]
set_property PACKAGE_PIN B16 [get_ports {led_out_0[1]}]
set_property PACKAGE_PIN A15 [get_ports {led_out_0[2]}]
set_property PACKAGE_PIN C14 [get_ports {led_out_0[3]}]
set_property PACKAGE_PIN A13 [get_ports {led_out_0[4]}]
set_property PACKAGE_PIN D13 [get_ports {led_out_0[5]}]
set_property PACKAGE_PIN C12 [get_ports {led_out_0[6]}]
set_property PACKAGE_PIN C11 [get_ports {led_out_0[7]}]

### LED IO Standards
set_property IOSTANDARD LVCMOS18 [get_ports {led_out_0[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_out_0[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_out_0[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_out_0[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_out_0[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_out_0[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_out_0[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_out_0[0]}]

### ADC - 1 (AD7384) Ports
set_property PACKAGE_PIN AB26 [get_ports ad7384_cs_0]
set_property PACKAGE_PIN AE25 [get_ports ad7384_sclk_0]
set_property PACKAGE_PIN AF25 [get_ports ad7384_sdi_0]
set_property PACKAGE_PIN AC26 [get_ports ad7384_sdo_a_0]
set_property PACKAGE_PIN AE26 [get_ports ad7384_sdo_b_0]
set_property PACKAGE_PIN AB25 [get_ports ad7384_sdo_c_0]
set_property PACKAGE_PIN AF24 [get_ports ad7384_sdo_d_0]

#### ADC - 2 (AD7384) Ports
#set_property PACKAGE_PIN AF23 [get_ports ad7384_cs_0]
#set_property PACKAGE_PIN AE22 [get_ports ad7384_sclk_0]
#set_property PACKAGE_PIN AF22 [get_ports ad7384_sdi_0]
#set_property PACKAGE_PIN AE23 [get_ports ad7384_sdo_a_0]
#set_property PACKAGE_PIN AD23 [get_ports ad7384_sdo_b_0]
#set_property PACKAGE_PIN AA25 [get_ports ad7384_sdo_c_0]
#set_property PACKAGE_PIN AA24 [get_ports ad7384_sdo_d_0]

### ADC IO Standards
set_property IOSTANDARD LVCMOS33 [get_ports ad7384_cs_0]
set_property IOSTANDARD LVCMOS33 [get_ports ad7384_sclk_0]
set_property IOSTANDARD LVCMOS33 [get_ports ad7384_sdi_0]
set_property IOSTANDARD LVCMOS33 [get_ports ad7384_sdo_a_0]
set_property IOSTANDARD LVCMOS33 [get_ports ad7384_sdo_b_0]
set_property IOSTANDARD LVCMOS33 [get_ports ad7384_sdo_c_0]
set_property IOSTANDARD LVCMOS33 [get_ports ad7384_sdo_d_0]
