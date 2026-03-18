/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"     // Hardware definitions
#include "xiicps.h"          // I2C driver


/*int main()
{
    init_platform();

    print("Hello World\n\r");
    print("Successfully ran Hello World application");
    cleanup_platform();
    return 0;
}
*/

#define I2C_DEVICE_ID   XPAR_XIICPS_0_BASEADDR    // Adjust if using I2C1
#define TMP451_ADDR     0x4C                      // Default 7-bit address

XIicPs Iic;   // I2C instance

int main(void)
{
    int Status;
    XIicPs_Config *Config;
    u8 WriteBuffer[1];
    u8 ReadBuffer[1];

    xil_printf("TMP451 Test Application Started...\n\r");

    // -----------------------------
    // Step 1: Initialize I2C driver
    // -----------------------------
    Config = XIicPs_LookupConfig(I2C_DEVICE_ID);
    if (Config == NULL) {
        xil_printf("I2C LookupConfig failed!\n\r");
        return XST_FAILURE;
    }

    Status = XIicPs_CfgInitialize(&Iic, Config, Config->BaseAddress);
    if (Status != XST_SUCCESS) {
        xil_printf("I2C CfgInitialize failed!\n\r");
        return XST_FAILURE;
    }

    // -----------------------------
    // Step 2: Set I2C clock speed
    // -----------------------------
    Status = XIicPs_SetSClk(&Iic, 100000); // 100 kHz safe start
    if (Status != XST_SUCCESS) {
        xil_printf("I2C SetSClk failed!\n\r");
        return XST_FAILURE;
    }
    xil_printf("I2C initialized at 100 kHz.\n\r");

    // -----------------------------
    // Step 3: Read Manufacturer ID
    // -----------------------------
    WriteBuffer[0] = 0xFE; // Register address for Manufacturer ID
    Status = XIicPs_MasterSendPolled(&Iic, WriteBuffer, 1, TMP451_ADDR);
    if (Status != XST_SUCCESS) {
        xil_printf("I2C Write failed!\n\r");
        return XST_FAILURE;
    }

    Status = XIicPs_MasterRecvPolled(&Iic, ReadBuffer, 1, TMP451_ADDR);
    if (Status != XST_SUCCESS) {
        xil_printf("I2C Read failed!\n\r");
        return XST_FAILURE;
    }

    xil_printf("Manufacturer ID: 0x%02X \n\r", ReadBuffer[0]);

    // -----------------------------
    // Step 4: Read Local Temperature (High + Low)
    // -----------------------------
    WriteBuffer[0] = 0x00; // Local Temp High Byte
    Status = XIicPs_MasterSendPolled(&Iic, WriteBuffer, 1, TMP451_ADDR);
    Status = XIicPs_MasterRecvPolled(&Iic, ReadBuffer, 1, TMP451_ADDR);
    int local_high = ReadBuffer[0];

    WriteBuffer[0] = 0x15; // Local Temp Low Byte
    Status = XIicPs_MasterSendPolled(&Iic, WriteBuffer, 1, TMP451_ADDR);
    Status = XIicPs_MasterRecvPolled(&Iic, ReadBuffer, 1, TMP451_ADDR);
    int local_low = ReadBuffer[0] >> 4; // upper nibble only
    
    float local_temp = local_high + (local_low * 0.0625);
    xil_printf("Local Temperature: %d.%04d C\n\r", local_high, local_low * 625);

    // -----------------------------
    // Step 5: Read Remote Temperature
    // -----------------------------
    WriteBuffer[0] = 0x15; // Register address for Remote Temp
    Status = XIicPs_MasterSendPolled(&Iic, WriteBuffer, 1, TMP451_ADDR);
    if (Status != XST_SUCCESS) {
        xil_printf("I2C Write failed!\n\r");
        return XST_FAILURE;
    }

    Status = XIicPs_MasterRecvPolled(&Iic, ReadBuffer, 1, TMP451_ADDR);
    if (Status != XST_SUCCESS) {
        xil_printf("I2C Read failed!\n\r");
        return XST_FAILURE;
    }

    xil_printf("Remote Temperature: %d C\n\r", ReadBuffer[0]);

    

    xil_printf("TMP451 Test Completed.\n\r");

    return XST_SUCCESS;
}

