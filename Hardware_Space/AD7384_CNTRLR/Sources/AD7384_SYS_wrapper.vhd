--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
--Date        : Tue Mar  3 17:49:36 2026
--Host        : DSPL-LAB-2-TEF running 64-bit major release  (build 9200)
--Command     : generate_target AD7384_SYS_wrapper.bd
--Design      : AD7384_SYS_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity AD7384_SYS_wrapper is
  port (
    CLK_IN1_D_0_clk_n : in STD_LOGIC;
    CLK_IN1_D_0_clk_p : in STD_LOGIC;
    ad7384_cs_0 : out STD_LOGIC;
    ad7384_sclk_0 : out STD_LOGIC;
    ad7384_sdi_0 : out STD_LOGIC;
    ad7384_sdo_a_0 : in STD_LOGIC;
    ad7384_sdo_b_0 : in STD_LOGIC;
    ad7384_sdo_c_0 : in STD_LOGIC;
    ad7384_sdo_d_0 : in STD_LOGIC;
    ctrlr_reg_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    led_out_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    sys_rst_0 : in STD_LOGIC
  );
end AD7384_SYS_wrapper;

architecture STRUCTURE of AD7384_SYS_wrapper is
  component AD7384_SYS is
  port (
    ad7384_cs_0 : out STD_LOGIC;
    ad7384_sclk_0 : out STD_LOGIC;
    ad7384_sdi_0 : out STD_LOGIC;
    ad7384_sdo_a_0 : in STD_LOGIC;
    ad7384_sdo_b_0 : in STD_LOGIC;
    ad7384_sdo_c_0 : in STD_LOGIC;
    ad7384_sdo_d_0 : in STD_LOGIC;
    ctrlr_reg_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    led_out_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    sys_rst_0 : in STD_LOGIC;
    CLK_IN1_D_0_clk_n : in STD_LOGIC;
    CLK_IN1_D_0_clk_p : in STD_LOGIC
  );
  end component AD7384_SYS;
begin
AD7384_SYS_i: component AD7384_SYS
     port map (
      CLK_IN1_D_0_clk_n => CLK_IN1_D_0_clk_n,
      CLK_IN1_D_0_clk_p => CLK_IN1_D_0_clk_p,
      ad7384_cs_0 => ad7384_cs_0,
      ad7384_sclk_0 => ad7384_sclk_0,
      ad7384_sdi_0 => ad7384_sdi_0,
      ad7384_sdo_a_0 => ad7384_sdo_a_0,
      ad7384_sdo_b_0 => ad7384_sdo_b_0,
      ad7384_sdo_c_0 => ad7384_sdo_c_0,
      ad7384_sdo_d_0 => ad7384_sdo_d_0,
      ctrlr_reg_0(7 downto 0) => ctrlr_reg_0(7 downto 0),
      led_out_0(7 downto 0) => led_out_0(7 downto 0),
      sys_rst_0 => sys_rst_0
    );
end STRUCTURE;
