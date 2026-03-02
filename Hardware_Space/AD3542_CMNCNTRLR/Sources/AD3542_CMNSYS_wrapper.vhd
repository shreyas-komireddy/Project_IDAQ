--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
--Date        : Mon Mar  2 19:05:08 2026
--Host        : DSPL-LAB-2-TEF running 64-bit major release  (build 9200)
--Command     : generate_target AD3542_CMNSYS_wrapper.bd
--Design      : AD3542_CMNSYS_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity AD3542_CMNSYS_wrapper is
  port (
    CLK_IN1_D_0_clk_n : in STD_LOGIC;
    CLK_IN1_D_0_clk_p : in STD_LOGIC;
    ad3542_cs_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_ldac_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_rst_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sclk_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sdi_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sdo_0 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    ctrlr_reg_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    led_out_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    sys_rst_0 : in STD_LOGIC
  );
end AD3542_CMNSYS_wrapper;

architecture STRUCTURE of AD3542_CMNSYS_wrapper is
  component AD3542_CMNSYS is
  port (
    CLK_IN1_D_0_clk_n : in STD_LOGIC;
    CLK_IN1_D_0_clk_p : in STD_LOGIC;
    ad3542_cs_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_ldac_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_rst_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sclk_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sdi_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sdo_0 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    ctrlr_reg_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    led_out_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    sys_rst_0 : in STD_LOGIC
  );
  end component AD3542_CMNSYS;
begin
AD3542_CMNSYS_i: component AD3542_CMNSYS
     port map (
      CLK_IN1_D_0_clk_n => CLK_IN1_D_0_clk_n,
      CLK_IN1_D_0_clk_p => CLK_IN1_D_0_clk_p,
      ad3542_cs_0(3 downto 0) => ad3542_cs_0(3 downto 0),
      ad3542_ldac_0(3 downto 0) => ad3542_ldac_0(3 downto 0),
      ad3542_rst_0(3 downto 0) => ad3542_rst_0(3 downto 0),
      ad3542_sclk_0(3 downto 0) => ad3542_sclk_0(3 downto 0),
      ad3542_sdi_0(3 downto 0) => ad3542_sdi_0(3 downto 0),
      ad3542_sdo_0(3 downto 0) => ad3542_sdo_0(3 downto 0),
      ctrlr_reg_0(7 downto 0) => ctrlr_reg_0(7 downto 0),
      led_out_0(7 downto 0) => led_out_0(7 downto 0),
      sys_rst_0 => sys_rst_0
    );
end STRUCTURE;
