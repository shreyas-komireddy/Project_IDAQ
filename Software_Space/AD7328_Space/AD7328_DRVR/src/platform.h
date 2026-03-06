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
int slv_wrt(int slv_reg_addr, u32 data);
void delay(int dly);

#endif