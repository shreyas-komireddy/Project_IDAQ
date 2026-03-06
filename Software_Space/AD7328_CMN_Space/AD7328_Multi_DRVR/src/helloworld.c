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
    u16 out1_chnl0, out1_chnl2, out1_chnl4, out1_chnl6, out2_chnl0, out2_chnl2, out2_chnl4, out2_chnl6;
    
    uint16_t buffer1[BUFFER_SIZE] = {0}, buffer2[BUFFER_SIZE] = {0}, buffer3[BUFFER_SIZE] = {0}, buffer4[BUFFER_SIZE] = {0};  // circular buffer
    uint16_t buffer5[BUFFER_SIZE] = {0}, buffer6[BUFFER_SIZE] = {0}, buffer7[BUFFER_SIZE] = {0}, buffer8[BUFFER_SIZE] = {0};  // circular buffer
    uint32_t sum1 = 0, sum2 = 0, sum3 = 0, sum4 = 0, sum5 = 0, sum6 = 0, sum7 = 0, sum8 = 0;                    // running sum (use 32-bit to avoid overflow)
    int index = 0;                       // current position in buffer
    int count = 0;                       // number of samples received
    uint16_t adc3_avg0 = 0, adc3_avg2 = 0, adc3_avg4 = 0, adc3_avg6 = 0, adc5_avg0 = 0, adc5_avg2 = 0, adc5_avg4 = 0, adc5_avg6 = 0; 
    int volts_mV_3ch0, volts_mV_3ch2, volts_mV_3ch4, volts_mV_3ch6, volts_mV_5ch0, volts_mV_5ch2, volts_mV_5ch4, volts_mV_5ch6;

    init_platform();

    ip_read_addr = (u32*)XPAR_AD7328_CMNAXI_0_BASEADDR;

    xil_printf("**Temperature Monitoring**\n\r\n\r");

    slv_wrt(1, 0x5555FF13);   // AD7328 Configuration Data 
    delay(10000);
    slv_wrt(0, 0x00000080);
    delay(100000);
    slv_wrt(0, 0x00000040);
    //delay(100000);
    //slv_wrt(5, 0x00000050);

    while(1)
    {
         out1_chnl0 = slv_read(2) & 0xfff;
         out1_chnl2 = ( slv_read(2) >> 16 ) & 0xfff;

         out1_chnl4 = slv_read(3) & 0xfff;
         out1_chnl6 = ( slv_read(3) >> 16 ) & 0xfff;

         out2_chnl0 = slv_read(4) & 0xfff;
         out2_chnl2 = ( slv_read(4) >> 16 ) & 0xfff;

         out2_chnl4 = slv_read(5) & 0xfff;
         out2_chnl6 = ( slv_read(5) >> 16 ) & 0xfff;
  


         volts_mV_3ch0 = (out1_chnl0) * 1.22;
         volts_mV_3ch2 = (out1_chnl2) * 1.22;
         volts_mV_3ch4 = (out1_chnl4) * 1.22;
         volts_mV_3ch6 = (out1_chnl6) * 1.22;

         volts_mV_5ch0 = (out2_chnl0) * 1.22;
         volts_mV_5ch2 = (out2_chnl2) * 1.22;
         volts_mV_5ch4 = (out2_chnl4) * 1.22;
         volts_mV_5ch6 = (out2_chnl6) * 1.22;

         for (int i = 0; i < 30; i++) {

             /* ADC_3 Channel 0 */
            sum1 -= buffer1[index];
            buffer1[index] = volts_mV_3ch0;
            sum1 += volts_mV_3ch0;

            /* ADC_3 Channel 2 */
            sum2 -= buffer2[index];
            buffer2[index] = volts_mV_3ch2;
            sum2 += volts_mV_3ch2;

            /* ADC_3 Channel 4 */
            sum3 -= buffer3[index];
            buffer3[index] = volts_mV_3ch4;
            sum3 += volts_mV_3ch4;

            /* ADC_3 Channel 6 */
            sum4 -= buffer4[index];
            buffer4[index] = volts_mV_3ch6;
            sum4 += volts_mV_3ch6;

            /* ADC_5 Channel 0 */
            sum5 -= buffer5[index];
            buffer5[index] = volts_mV_5ch0;
            sum5 += volts_mV_5ch0;

            /* ADC_5 Channel 2 */
            sum6 -= buffer6[index];
            buffer6[index] = volts_mV_5ch2;
            sum6 += volts_mV_5ch2;

            /* ADC_5 Channel 4 */
            sum7 -= buffer7[index];
            buffer7[index] = volts_mV_5ch4;
            sum7 += volts_mV_5ch4;

            /* ADC_5 Channel 6 */
            sum8 -= buffer8[index];
            buffer8[index] = volts_mV_5ch6;
            sum8 += volts_mV_5ch6;

            index = (index + 1) % BUFFER_SIZE;

             // keep track of how many samples we have
             if (count < BUFFER_SIZE) {
                 count++;
             }

             // compute average only when buffer is full
             if (count == BUFFER_SIZE) {
                adc3_avg0 = (uint16_t)(sum1 / BUFFER_SIZE);
                adc3_avg2 = (uint16_t)(sum2 / BUFFER_SIZE);
                adc3_avg4 = (uint16_t)(sum3 / BUFFER_SIZE);
                adc3_avg6 = (uint16_t)(sum4 / BUFFER_SIZE);

                adc5_avg0 = (uint16_t)(sum5 / BUFFER_SIZE);
                adc5_avg2 = (uint16_t)(sum6 / BUFFER_SIZE);
                adc5_avg4 = (uint16_t)(sum7 / BUFFER_SIZE);
                adc5_avg6 = (uint16_t)(sum8 / BUFFER_SIZE);
 

                //xil_printf("Analog Voltage : %u mV           \r", average);
                xil_printf("%u:%u:%u:%u:%u:%u:%u:%u\r\n",adc3_avg0, adc3_avg2, adc3_avg4, adc3_avg6, adc5_avg0, adc5_avg2, adc5_avg4, adc5_avg6);
                delay(100000);
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