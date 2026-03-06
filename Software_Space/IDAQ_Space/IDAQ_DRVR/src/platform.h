/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#ifndef PLATFORM_H_
#define PLATFORM_H_

#include "xil_types.h"           // Always include this
#ifndef SDT
#include "platform_config.h"     // Only include this if SDT is not defined
#endif

void init_platform();
void cleanup_platform();
int slv_read(int slv_reg_addr);
int slv_wrt(int slv_reg_addr,u32 data);
void delay(int dly);
int hex2ascii(u8 rtc_val);
void UART_WRITE();
void Din_Read();
void ADC_Read();
void DAC_Write();
int rtcc_wrt(int slv_reg_addr, u32 data);
int rtcc_read(int slv_reg_addr);
void RTCC();
void RTCC_Write();
#endif
