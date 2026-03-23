--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
--Date        : Sat Mar 21 17:10:24 2026
--Host        : DSPL-LAB-2-TEF running 64-bit major release  (build 9200)
--Command     : generate_target IDAQ_AXISYS_wrapper.bd
--Design      : IDAQ_AXISYS_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity IDAQ_AXISYS_wrapper is
  port (
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    IIC_0_0_scl_io : inout STD_LOGIC;
    IIC_0_0_sda_io : inout STD_LOGIC;
    UART_0_0_rxd : in STD_LOGIC;
    UART_0_0_txd : out STD_LOGIC;
    ad3542_cs_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_ldac_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_rst_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sclk_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sdi_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sdo_0 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    ad7328_cs_0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ad7328_sclk_0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ad7328_sdi_0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ad7328_sdo_0 : in STD_LOGIC_VECTOR ( 1 downto 0 );
    cs_0 : out STD_LOGIC;
    digi_in_0 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    digi_out_0 : out STD_LOGIC_VECTOR ( 15 downto 0 );
    led_out_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    miso_0 : in STD_LOGIC;
    mosi_0 : out STD_LOGIC;
    sclk_0 : out STD_LOGIC;
    sw_in_0 : in STD_LOGIC
  );
end IDAQ_AXISYS_wrapper;

architecture STRUCTURE of IDAQ_AXISYS_wrapper is
  component IDAQ_AXISYS is
  port (
    ad3542_cs_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_ldac_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_rst_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sclk_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sdi_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ad3542_sdo_0 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    ad7328_cs_0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ad7328_sclk_0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ad7328_sdi_0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ad7328_sdo_0 : in STD_LOGIC_VECTOR ( 1 downto 0 );
    digi_in_0 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    digi_out_0 : out STD_LOGIC_VECTOR ( 15 downto 0 );
    cs_0 : out STD_LOGIC;
    miso_0 : in STD_LOGIC;
    mosi_0 : out STD_LOGIC;
    sclk_0 : out STD_LOGIC;
    led_out_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    sw_in_0 : in STD_LOGIC;
    DDR_cas_n : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    IIC_0_0_sda_i : in STD_LOGIC;
    IIC_0_0_sda_o : out STD_LOGIC;
    IIC_0_0_sda_t : out STD_LOGIC;
    IIC_0_0_scl_i : in STD_LOGIC;
    IIC_0_0_scl_o : out STD_LOGIC;
    IIC_0_0_scl_t : out STD_LOGIC;
    UART_0_0_txd : out STD_LOGIC;
    UART_0_0_rxd : in STD_LOGIC
  );
  end component IDAQ_AXISYS;
  component IOBUF is
  port (
    I : in STD_LOGIC;
    O : out STD_LOGIC;
    T : in STD_LOGIC;
    IO : inout STD_LOGIC
  );
  end component IOBUF;
  signal IIC_0_0_scl_i : STD_LOGIC;
  signal IIC_0_0_scl_o : STD_LOGIC;
  signal IIC_0_0_scl_t : STD_LOGIC;
  signal IIC_0_0_sda_i : STD_LOGIC;
  signal IIC_0_0_sda_o : STD_LOGIC;
  signal IIC_0_0_sda_t : STD_LOGIC;
begin
IDAQ_AXISYS_i: component IDAQ_AXISYS
     port map (
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      IIC_0_0_scl_i => IIC_0_0_scl_i,
      IIC_0_0_scl_o => IIC_0_0_scl_o,
      IIC_0_0_scl_t => IIC_0_0_scl_t,
      IIC_0_0_sda_i => IIC_0_0_sda_i,
      IIC_0_0_sda_o => IIC_0_0_sda_o,
      IIC_0_0_sda_t => IIC_0_0_sda_t,
      UART_0_0_rxd => UART_0_0_rxd,
      UART_0_0_txd => UART_0_0_txd,
      ad3542_cs_0(3 downto 0) => ad3542_cs_0(3 downto 0),
      ad3542_ldac_0(3 downto 0) => ad3542_ldac_0(3 downto 0),
      ad3542_rst_0(3 downto 0) => ad3542_rst_0(3 downto 0),
      ad3542_sclk_0(3 downto 0) => ad3542_sclk_0(3 downto 0),
      ad3542_sdi_0(3 downto 0) => ad3542_sdi_0(3 downto 0),
      ad3542_sdo_0(3 downto 0) => ad3542_sdo_0(3 downto 0),
      ad7328_cs_0(1 downto 0) => ad7328_cs_0(1 downto 0),
      ad7328_sclk_0(1 downto 0) => ad7328_sclk_0(1 downto 0),
      ad7328_sdi_0(1 downto 0) => ad7328_sdi_0(1 downto 0),
      ad7328_sdo_0(1 downto 0) => ad7328_sdo_0(1 downto 0),
      cs_0 => cs_0,
      digi_in_0(15 downto 0) => digi_in_0(15 downto 0),
      digi_out_0(15 downto 0) => digi_out_0(15 downto 0),
      led_out_0(7 downto 0) => led_out_0(7 downto 0),
      miso_0 => miso_0,
      mosi_0 => mosi_0,
      sclk_0 => sclk_0,
      sw_in_0 => sw_in_0
    );
IIC_0_0_scl_iobuf: component IOBUF
     port map (
      I => IIC_0_0_scl_o,
      IO => IIC_0_0_scl_io,
      O => IIC_0_0_scl_i,
      T => IIC_0_0_scl_t
    );
IIC_0_0_sda_iobuf: component IOBUF
     port map (
      I => IIC_0_0_sda_o,
      IO => IIC_0_0_sda_io,
      O => IIC_0_0_sda_i,
      T => IIC_0_0_sda_t
    );
end STRUCTURE;
