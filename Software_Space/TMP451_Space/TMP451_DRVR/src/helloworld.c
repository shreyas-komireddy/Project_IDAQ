#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xiicps.h"
#include "sleep.h"

#define I2C_DEVICE_ID   XPAR_XIICPS_0_BASEADDR
#define TMP451_ADDR     0x4C

XIicPs Iic;

int main(void)
{
    int Status;
    XIicPs_Config *Config;
    u8 WriteBuffer[1];
    u8 ReadBuffer[1];

    init_platform();
    xil_printf("TMP451 Continuous Temperature Monitor Started...\n\r");

    Config = XIicPs_LookupConfig(I2C_DEVICE_ID);
    Status = XIicPs_CfgInitialize(&Iic, Config, Config->BaseAddress);

    

    
    XIicPs_SetSClk(&Iic, 100000);

    WriteBuffer[0] = 0xFE;
    XIicPs_MasterSendPolled(&Iic, WriteBuffer, 1, TMP451_ADDR);
    XIicPs_MasterRecvPolled(&Iic, ReadBuffer, 1, TMP451_ADDR);
    int Manufacturer_ID = ReadBuffer[0];
    xil_printf("Manufacturer ID: 0x%02X \n\r", ReadBuffer[0]);



    // Print two blank lines initially
    xil_printf("\n\n");

    while(1) {
        // Local Temp High Byte
        WriteBuffer[0] = 0x00;
        XIicPs_MasterSendPolled(&Iic, WriteBuffer, 1, TMP451_ADDR);
        XIicPs_MasterRecvPolled(&Iic, ReadBuffer, 1, TMP451_ADDR);
        int local_high = ReadBuffer[0];

        // Local Temp Low Byte
        WriteBuffer[0] = 0x15;
        XIicPs_MasterSendPolled(&Iic, WriteBuffer, 1, TMP451_ADDR);
        XIicPs_MasterRecvPolled(&Iic, ReadBuffer, 1, TMP451_ADDR);
        int local_low = ReadBuffer[0] >> 4;

        // Remote Temp High Byte
        WriteBuffer[0] = 0x01;
        XIicPs_MasterSendPolled(&Iic, WriteBuffer, 1, TMP451_ADDR);
        XIicPs_MasterRecvPolled(&Iic, ReadBuffer, 1, TMP451_ADDR);
        int remote_high = ReadBuffer[0];

        // Remote Temp Low Byte
        WriteBuffer[0] = 0x10;
        XIicPs_MasterSendPolled(&Iic, WriteBuffer, 1, TMP451_ADDR);
        XIicPs_MasterRecvPolled(&Iic, ReadBuffer, 1, TMP451_ADDR);
        int remote_low = ReadBuffer[0] >> 4;

        // Move cursor up 2 lines and overwrite
        xil_printf("\033[2A");  // ANSI escape: move cursor up 2 lines
        xil_printf("Local Temperature : %d.%04d C\n\r", local_high, local_low * 625);
        xil_printf("Remote Temperature: %d.%04d C\n\r", remote_high, remote_low * 625);

        usleep(1000000); // 1 second delay
    }

    cleanup_platform();
    return 0;
}