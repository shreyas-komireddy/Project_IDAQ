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
#include <xil_types.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xuartps.h"
#include <stdlib.h>
#include "sleep.h"

#ifndef XPAR_XUARTPS_0_DEVICE_ID
#define XPAR_XUARTPS_0_DEVICE_ID 0
#endif

#define UART_DEVICE_ID XPAR_XUARTPS_0_DEVICE_ID
#define ADC_BUFFER 200                              // Circular Buffer for ADC samples averaging
#define UART_BUFFER 50                               // UART Buffer Size 

//IP address Pointer Variable Declaration
u32 *ip_read_addr;
u32 *ip_read_rtcc;

u8 recv_buffer[UART_BUFFER];
int Slave_Addr;
u16 digi_in;

// Global Variables related to RTCC
u8 sec_l_val, sec_u_val, min_l_val, min_u_val,hr_l_val, hr_u_val,w_l_val,w_u_val,d_l_val,d_u_val,m_l_val, m_u_val,y_l_val, y_u_val;
const char* week ;

int main()
{   
    u32 rtc_val;   
    
    const char* weekday_names[7] = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" };

    init_platform();
    
    ip_read_addr = (u32*)XPAR_INTR_PLTFRM_0_BASEADDR;
    ip_read_rtcc = (u32*)XPAR_RTCC_0_BASEADDR;

    //************uart configuration *********************
    XUartPs uart;
    XUartPs_Config *config;    
    
    int uart_index = 0;

    // Initialize UART
    config = XUartPs_LookupConfig(UART_DEVICE_ID);
    if (config == NULL) {
        //xil_printf("UART config lookup failed.\r\n");
        return -1;
    }

    if (XUartPs_CfgInitialize(&uart, config, config->BaseAddress) != XST_SUCCESS) {
        //xil_printf("UART initialization failed.\r\n");
        return -1;
    }

    XUartPs_SetBaudRate(&uart, 115200);

    // Writes to INTR_PLTFRM IP
    slv_wrt(1, 0x5555FF13);   // AD7328 Configuration Data 
    delay(10000);
    slv_wrt(6, 0x22222222);   // AD3542 Configuration Data 
    delay(10000);    
    slv_wrt(0, 0x00008080);
    delay(100000);
    slv_wrt(0, 0x14004040);
    delay(100000);

    // Writes to RTCC IP
   // rtcc_wrt(1,0x01030600);  
   // rtcc_wrt(2,0x00260209);  
   // rtcc_wrt(0,0x00000001);  // allowing data to be written by selecting the state WRTC
    //sleep(1);    
    //rtcc_wrt(0,0x00000000);

    while(1)
    {
        
         
        u8 ch;
        // Try to receive one character
        if (XUartPs_Recv(&uart, &ch, 1) == 1) {
            // Store character
           
            recv_buffer[uart_index++] = ch;  
           /*
            if(uart_index==10) {

                Slave_Addr = (recv_buffer[0]*10)+ recv_buffer[1];
                
                if(Slave_Addr==540){                    //ASCII 12 = 540 Decimal
                    Din_Read();
                }
                else if(Slave_Addr==530){
                                                   
                    ADC_Read();                     
                }
                else if(Slave_Addr==544){
                    RTCC();
                }
                else if(Slave_Addr==548){
                    RTCC_Write();
                }                    
                else {
                    UART_WRITE();                         
                }
               
                //XUartPs_Send(&uart, recv_buffer, uart_index);           
                uart_index = 0; // Reset buffer
                // memset(recv_buffer, 0, sizeof(recv_buffer));
            } */



            if(uart_index >=2 && uart_index<=18) {
                // Echo the full line
                
                Slave_Addr = (recv_buffer[0]*10)+ recv_buffer[1];
               // xil_printf("-----%d---\n",Slave_Addr);                
                if(Slave_Addr==540 & uart_index==10 ){                    //540==12 reg
                    Din_Read();
                     uart_index = 0;
                     memset(recv_buffer, 0, sizeof(recv_buffer));
                 }


                else if(Slave_Addr==530 & uart_index==10){
                                                   
                    ADC_Read(); 
                     uart_index = 0;    
                    memset(recv_buffer, 0, sizeof(recv_buffer));                                     
                 }
                // else if(Slave_Addr==534){
                                                   
                //     DAC_Write();                     
                //  }
                else if(Slave_Addr== 544 & uart_index==10){
                    RTCC();
                        uart_index = 0;   
                     
                        memset(recv_buffer, 0, sizeof(recv_buffer));                 
                 }
                else if(Slave_Addr==548  && uart_index==18){
                    RTCC_Write();
                    uart_index = 0; 
                                           
                    memset(recv_buffer, 0, sizeof(recv_buffer));
                                                                  
                 }
                else if(Slave_Addr != 548  && uart_index==10) {
                    UART_WRITE();    
                     uart_index = 0;  
                    
                     
                     memset(recv_buffer, 0, sizeof(recv_buffer));                   
                 }
               
                //XUartPs_Send(&uart, recv_buffer, index_1);           
               // index_1 = 0; // Reset buffer
            //  memset(recv_buffer, 0, sizeof(recv_buffer));
            }             

            // Prevent buffer overflow
            if (uart_index >= UART_BUFFER) {
                uart_index = 0;
                xil_printf("\r\nBuffer overflow. Resetting.\r\n");
            }
        }  




        rtc_val = rtcc_read(3);
        // val_1 = rtc_val/1000000;
        //xil_printf("val_1 = %x\n",val_1);        
        //xil_printf("RTCC VALUE : 0x%08x\r", rtc_val);
        //reading seconds
        sec_l_val =  hex2ascii(rtc_val);               // Lower Nibble
        sec_u_val =  hex2ascii((rtc_val>>4) & 0x07);   // Upper Nibble with mask Oscillator Bit
        
        //reading minutes
         min_l_val =  hex2ascii(rtc_val>>8);
         min_u_val =  hex2ascii(rtc_val>>12);

        //reading hours
         hr_l_val =  hex2ascii(rtc_val>>16);
         hr_u_val =  hex2ascii(rtc_val>>20);
         
        //reading weekdays
        w_l_val =  hex2ascii(rtc_val>>24) ;              
        w_u_val =  hex2ascii(rtc_val>>28);

        int weekday_index =(int) w_l_val;  
        weekday_index = weekday_index-48;
        week = weekday_names[weekday_index]; 
        
        rtc_val = rtcc_read(4);
        //reading date
        d_l_val =  hex2ascii(rtc_val);               
        d_u_val =  hex2ascii((rtc_val>>4) & 0x07); 
        //reading month
        m_l_val =  hex2ascii(rtc_val>>8);
        m_u_val =  hex2ascii(rtc_val>>12);                
        //reading year
        y_l_val =  hex2ascii(rtc_val>>16);
        y_u_val =  hex2ascii(rtc_val>>20);        


        // xil_printf("%c%c:%c%c:%c%c %s %c%c/%c%c/20%c%c", hr_u_val,hr_l_val,min_u_val,min_l_val,sec_u_val,sec_l_val,week,d_u_val,d_l_val, m_u_val,m_l_val,y_u_val,y_l_val);
        //  delay(1000);  
          

    }
    
    cleanup_platform();
    return 0;
}

// Conversion Hexa to ASCII
int hex2ascii(u8 rtc_val)
{      
        int low_nib;
        low_nib = rtc_val & 0x0f;
        low_nib = low_nib + 0x30;
        return(low_nib);
        
}

// Read Registers from RTCC IP
int rtcc_read(int slv_reg_addr)
{ 
    return *(ip_read_rtcc + slv_reg_addr);
} 

// Write Registers to RTCC IP
int rtcc_wrt(int slv_reg_addr, u32 data)
{
    *(ip_read_rtcc + slv_reg_addr) = data;
    return *(ip_read_rtcc + slv_reg_addr) ;
}

// Read Registers from INTR_PLTFRM IP
int slv_read(int slv_reg_addr)
{ 
    return *(ip_read_addr + slv_reg_addr);
}

// Write Registers to INTR_PLTFRM IP
int slv_wrt(int slv_reg_addr, u32 data)
{
    *(ip_read_addr + slv_reg_addr) = data;
    return *(ip_read_addr + slv_reg_addr);
}

// DELAY FUNCTION
void delay(int dly)
{
    for (int i = 0; i < dly; i++);
}

// UART WRITE Function:  FROM UART to Registers 
void UART_WRITE(){
     
    u32  Slave_value = (u32)strtoul((char *)&recv_buffer[2], NULL, 16);
    slv_wrt(Slave_Addr,Slave_value);
    xil_printf("%c%c:%c%c:%c%c %s %c%c/%c%c/20%c%c\r\n", hr_u_val,hr_l_val,min_u_val,min_l_val,sec_u_val,sec_l_val,week,d_u_val,d_l_val, m_u_val,m_l_val,y_u_val,y_l_val);    

}

void ADC_Read(){
    

    u16 out1_chnl0, out1_chnl2, out1_chnl4, out1_chnl6, out2_chnl0, out2_chnl2, out2_chnl4, out2_chnl6;
    uint16_t adc3_avg0 = 0, adc3_avg2 = 0, adc3_avg4 = 0, adc3_avg6 = 0, adc5_avg0 = 0, adc5_avg2 = 0, adc5_avg4 = 0, adc5_avg6 = 0; 
    int volts_mV_3ch0, volts_mV_3ch2, volts_mV_3ch4, volts_mV_3ch6, volts_mV_5ch0, volts_mV_5ch2, volts_mV_5ch4, volts_mV_5ch6;
    uint16_t buffer1[ADC_BUFFER] = {0}, buffer2[ADC_BUFFER] = {0}, buffer3[ADC_BUFFER] = {0}, buffer4[ADC_BUFFER] = {0};  // circular buffer
    uint16_t buffer5[ADC_BUFFER] = {0}, buffer6[ADC_BUFFER] = {0}, buffer7[ADC_BUFFER] = {0}, buffer8[ADC_BUFFER] = {0};  // circular buffer
    uint32_t sum1 = 0, sum2 = 0, sum3 = 0, sum4 = 0, sum5 = 0, sum6 = 0, sum7 = 0, sum8 = 0;                    // running sum (use 32-bit to avoid overflow)
    int index = 0;                       // current position in buffer
    int count = 0;                       // number of samples received 

    for(int i=0;i<2;i++){
        
        out1_chnl0 = slv_read(2) & 0xffc;
        out1_chnl2 = ( slv_read(2) >> 16 ) & 0xffc;

        out1_chnl4 = slv_read(3) & 0xffc;
        out1_chnl6 = ( slv_read(3) >> 16 ) & 0xffc;

        out2_chnl0 = slv_read(4) & 0xffc;
        out2_chnl2 = ( slv_read(4) >> 16 ) & 0xffc;

        out2_chnl4 = slv_read(5) & 0xffc;
        out2_chnl6 = ( slv_read(5) >> 16 ) & 0xffc;                                                       
  


        volts_mV_3ch0 = (out1_chnl0) * 1.22;
        volts_mV_3ch2 = (out1_chnl2) * 1.22;
        volts_mV_3ch4 = (out1_chnl4) * 1.22;
        volts_mV_3ch6 = (out1_chnl6) * 1.22;

        volts_mV_5ch0 = (out2_chnl0) * 1.22;
        volts_mV_5ch2 = (out2_chnl2) * 1.22;
        volts_mV_5ch4 = (out2_chnl4) * 1.22;
        volts_mV_5ch6 = (out2_chnl6) * 1.22;

        for (int i = 0; i < 100; i++) {

             // ADC_3 Channel 0 
            sum1 -= buffer1[index];
            buffer1[index] = volts_mV_3ch0;
            sum1 += volts_mV_3ch0;

            //ADC_3 Channel 2 
            sum2 -= buffer2[index];
            buffer2[index] = volts_mV_3ch2;
            sum2 += volts_mV_3ch2;

            // ADC_3 Channel 4 
            sum3 -= buffer3[index];
            buffer3[index] = volts_mV_3ch4;
            sum3 += volts_mV_3ch4;

            // ADC_3 Channel 6 
            sum4 -= buffer4[index];
            buffer4[index] = volts_mV_3ch6;
            sum4 += volts_mV_3ch6;

            // ADC_5 Channel 0 
            sum5 -= buffer5[index];
            buffer5[index] = volts_mV_5ch0;
            sum5 += volts_mV_5ch0;

            // ADC_5 Channel 2 
            sum6 -= buffer6[index];
            buffer6[index] = volts_mV_5ch2;
            sum6 += volts_mV_5ch2;

            // ADC_5 Channel 4 
            sum7 -= buffer7[index];
            buffer7[index] = volts_mV_5ch4;
            sum7 += volts_mV_5ch4;

            // ADC_5 Channel 6 
            sum8 -= buffer8[index];
            buffer8[index] = volts_mV_5ch6;
            sum8 += volts_mV_5ch6;

            index = (index + 1) % ADC_BUFFER;

            // keep track of how many samples we have
            if (count < ADC_BUFFER) {
                count++;
            }

            // compute average only when buffer is full
            if (count == ADC_BUFFER) { 

                 
                adc3_avg0 = (uint16_t)(sum1 / ADC_BUFFER);
                adc3_avg2 = (uint16_t)(sum2 / ADC_BUFFER);
                adc3_avg4 = (uint16_t)(sum3 / ADC_BUFFER);
                adc3_avg6 = (uint16_t)(sum4 / ADC_BUFFER);

                adc5_avg0 = (uint16_t)(sum5 / ADC_BUFFER);
                adc5_avg2 = (uint16_t)(sum6 / ADC_BUFFER);
                adc5_avg4 = (uint16_t)(sum7 / ADC_BUFFER);
                adc5_avg6 = (uint16_t)(sum8 / ADC_BUFFER);
    
            
               xil_printf("%u:%u:%u:%u:%u:%u:%u:%u$%c%c:%c%c:%c%c %s %c%c/%c%c/20%c%c\r\n",adc3_avg0, adc3_avg2, adc3_avg4, adc3_avg6, adc5_avg0, adc5_avg2, adc5_avg4, adc5_avg6,hr_u_val,hr_l_val,min_u_val,min_l_val,sec_u_val,sec_l_val,week,d_u_val,d_l_val, m_u_val,m_l_val,y_u_val,y_l_val);
            
               delay(1000);
               


            }
         }
         

    }
}

// Digital IN Read Function
void Din_Read(){
    
    digi_in = slv_read(12) & 0xffff;//12 reister
    xil_printf("%x$%c%c:%c%c:%c%c %s %c%c/%c%c/20%c%c\r\n",digi_in,hr_u_val,hr_l_val,min_u_val,min_l_val,sec_u_val,sec_l_val,week,d_u_val,d_l_val, m_u_val,m_l_val,y_u_val,y_l_val);
   
}
  
// 
void RTCC(){
    xil_printf("%c%c:%c%c:%c%c %s %c%c/%c%c/20%c%c\r", hr_u_val,hr_l_val,min_u_val,min_l_val,sec_u_val,sec_l_val,week,d_u_val,d_l_val, m_u_val,m_l_val,y_u_val,y_l_val);    
}

void RTCC_Write(){

    uint32_t rtc_value_1 = 0,rtc_value_2 = 0;      
      
    for (int i = 2; i < 10; i++) {
        rtc_value_1 = (rtc_value_1 << 4) | (recv_buffer[i] - '0');
    }                
    rtcc_wrt(1,rtc_value_1);  
    for (int i = 10; i < 18; i++) {
        rtc_value_2 = (rtc_value_2 << 4) | (recv_buffer[i] - '0');
    }                
    rtcc_wrt(2,rtc_value_2); 
   // rtcc_wrt(2,0x00260209);                
    rtcc_wrt(0,0x00000001);                
    sleep(1); 
    rtcc_wrt(0,0x00000000);
                                           
}
