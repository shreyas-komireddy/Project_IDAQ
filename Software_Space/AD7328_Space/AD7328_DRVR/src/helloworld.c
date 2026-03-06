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
#include "xparameters.h"

#define BUFFER_SIZE 100   // number of samples for averaging

u32 *ip_read_addr;

int main()
{
    u16 out_regA;
    
    uint16_t buffer[BUFFER_SIZE] = {0};  // circular buffer
    uint32_t sum = 0;                    // running sum (use 32-bit to avoid overflow)
    int index = 0;                       // current position in buffer
    int count = 0;                       // number of samples received
    uint16_t average = 0; 
    int volts_mV;

    init_platform();

    ip_read_addr = (u32*)XPAR_AD7328_IP_0_BASEADDR;

    xil_printf("**Temperature Monitoring**\n\r\n\r");

    slv_wrt(0, 0x5555FF11);   // AD7328 Configuration Data 
    delay(10000);
    slv_wrt(5, 0x00000080);
    delay(100000);
    slv_wrt(5, 0x00000040);
    //delay(100000);
    //slv_wrt(5, 0x00000050);

    while(1)
    {
         out_regA = slv_read(4) & 0xfff;
         volts_mV = (out_regA) * 1.22;

         for (int i = 0; i < 30; i++) {
             uint16_t newData = volts_mV;  // example incoming data

             // subtract the value being overwritten from sum
             sum -= buffer[index];

             // insert new data into buffer
             buffer[index] = newData;

             // add new data to sum
             sum += newData;

             // move index forward (wrap around with modulo)
             index = (index + 1) % BUFFER_SIZE;

             // keep track of how many samples we have
             if (count < BUFFER_SIZE) {
                 count++;
             }

             // compute average only when buffer is full
             if (count == BUFFER_SIZE) {
                average = (uint16_t)(sum / BUFFER_SIZE);
                //xil_printf("Analog Voltage : %u mV           \r", average);
                xil_printf("%u\r",average);
             }
         }
    
    }

    cleanup_platform();
    return 0;
}

int slv_read(int slv_reg_addr)
{ 
    return *(ip_read_addr + slv_reg_addr);
}

int slv_wrt(int slv_reg_addr, u32 data)
{
    *(ip_read_addr + slv_reg_addr) = data;
    return *(ip_read_addr + slv_reg_addr);
}

void delay(int dly)
{
    for (int i = 0; i < dly; i++);
}