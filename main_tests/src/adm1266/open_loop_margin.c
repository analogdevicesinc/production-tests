// Copyright(c) 2019 Analog Devices, Inc.
// All Rights Reserved.
// This software is proprietary to Analog Devices, Inc. and its licensors.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "library/adm1266.h"
#ifndef _MSC_VER
#include <linux/types.h>
#endif /* __MSC_VER */

#define ADM1266_NUM 2 // Specify number of ADM1266 in your system


int main(int argc, char *argv[])
{
	i2c_init(); // Uncomment for Linux System
	//int aardvark_id = 1845961448; // Uncomment when using Aardvark
	//aardvark_open(aardvark_id); // Uncomment when using Aardvark

	// Specify the hex PMBus address for each ADM1266 in your system
	__u8 ADM1266_Address[ADM1266_NUM] = { 0x40, 0x42 };

	// Include following Variables in your code
	float ADM1266_DAC_Output = 0;
	__u8 ADM1266_Device_Margin_Addr;
	__u8 ADM1266_DAC_Number = 0;
	
	
	// Check if Refresh Memory feature is running and all the devices are present
	if ((ADM1266_Refresh_Status(ADM1266_Address, ADM1266_NUM) == 1) || (ADM1266_Device_Present(ADM1266_Address, ADM1266_NUM) == 0))
	{
		if ((ADM1266_Refresh_Status(ADM1266_Address, ADM1266_NUM) == 1))
		{
			printf("Memory refresh is currently running, please try after 10 secounds.");
		}
		else
		{
			printf("Not all the devices defined are present.");
		}
	}
	else
	{
		printf("Enter device address (e.g. 0x40): ");
		scanf("%hhx", &ADM1266_Device_Margin_Addr);

		printf("Enter DAC  between number 1 - 9 (e.g. 5): ");
		scanf("%hhx", &ADM1266_DAC_Number);
		ADM1266_DAC_Number = ADM1266_DAC_Number - 1;

		printf("Enter DAC output voltage in between 0.202V - 1.565V (e.g. 1.223): ");
		scanf("%f", &ADM1266_DAC_Output);

		if (ADM1266_DAC_Number < 10 || ADM1266_DAC_Number > 0)
		{
			if (ADM1266_DAC_Config(ADM1266_Device_Margin_Addr, ADM1266_DAC_Number) == 1)
			{
				// This function sets open loop DAC to a user requested voltage in between 0.202V - 1.565
				// This function requires the ADM1266 i2c address, DAC number (1 - 9), voltage that requres to be outputed from the DAC
				ADM1266_Margin_Open_Loop(ADM1266_Device_Margin_Addr, ADM1266_DAC_Number, ADM1266_DAC_Output);
			}
		}
		else
		{
			printf("Enter a valid DAC name.");
		}

	}

	return 0;
}

