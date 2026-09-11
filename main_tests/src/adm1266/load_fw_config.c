// Copyright(c) 2019 Analog Devices, Inc.
// All Rights Reserved.
// This software is proprietary to Analog Devices, Inc. and its licensors.


//=========================================================================
// INCLUDES
//=========================================================================
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "library/adm1266.h"
#ifndef _MSC_VER
#include <linux/types.h>
#endif /* __MSC_VER */

#define ADM1266_NUM 1 // Specify number of ADM1266 in your system

//=========================================================================
// MAIN PROGRAM ENTRY POINT
//=========================================================================
int main(int argc, char *argv[])
{
	i2c_init(); // Uncomment for Linux System
	//int aardvark_id = 1845961448; // Uncomment when using Aardvark
	//aardvark_open(aardvark_id); // Uncomment when using Aardvark

	// Pointer to the variable for storing the path to ADM1266 firmware .*hex file
	FILE *ADM1266_ptr_file_fw;
	// Pointer to the variable for storing the path to ADM1266 configuration files .*hex file
	FILE *ADM1266_ptr_file_cfg[ADM1266_NUM];

	// Address of all the ADM1266 in the system
	__u8 ADM1266_Address[ADM1266_NUM] = { 0x48 };

	// For storing user input for update type: configuration, firmware or both
	__u8 ADM1266_update_type;

	// For storing user input for reset type: seamless or restart
	__u8 ADM1266_reset_type;

	// For storing the password
	//__u8 ADM1266_password;

	// Path of the firmware file
	//ADM1266_ptr_file_fw = fopen("C:\\Users\\hopal\\ADM126x_SW\\trunk\\Applications\\C Library\\Firmware Configuration Files\\adm1266_v1.14.2_b0.hex", "r");
	ADM1266_ptr_file_fw = fopen("./config_files/adm1266_v1.14.3.hex", "r");

	// Path of the configuration file for windows
	// The configuration path order should be in the same order as the device address listed in address array above
	//ADM1266_ptr_file_cfg[0] = fopen("C:\\Users\\hopal\\ADM126x_SW\\trunk\\Applications\\C Library\\Firmware Configuration Files\\EVAL-ADM1266 - Two Boards Config-device@40.hex", "r");

	// Path of the configuration file for linux
	ADM1266_ptr_file_cfg[0] = fopen("./config_files/TaliseSOM_Sequencing_ADM1266@48.hex", "r");

	// Check for if refresh is running and all the devices are present
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
		printf("Enter '1' to update both firmware and configuration, '2' to update firmware only, '3' to update configuration only: ");
		scanf("%hhd", &ADM1266_update_type);
		// Update firmware and then configuration
		if (ADM1266_update_type == 1)
		{
			// Call the function to program firmware
			// This function requires the ADM1266 address array, number of ADM1266 and pointer to firmware file
			ADM1266_Program_Firmware(ADM1266_Address, ADM1266_NUM, ADM1266_ptr_file_fw);
			// Call the function to program configuration
			// This function requires the ADM1266 address array, number of ADM1266 and pointer to config files
			ADM1266_Program_Config(ADM1266_Address, ADM1266_NUM, ADM1266_ptr_file_cfg, 0);
			// Check CRC to confirm firmware and config were updated correctly
			// This function requires ADM1266 address array, number of ADM1266
			ADM1266_CRC_Summary(ADM1266_Address, ADM1266_NUM);
		}
		// Update firmware only
		else if (ADM1266_update_type == 2)
		{
			ADM1266_Program_Firmware(ADM1266_Address, ADM1266_NUM, ADM1266_ptr_file_fw);
			ADM1266_CRC_Summary(ADM1266_Address, ADM1266_NUM);
		}
		// Update configuration only
		else if (ADM1266_update_type == 3)
		{
			// When seamless reset is performed the sequence jumps directly to power good state
			printf("Enter '1' to do seamless reset or any other input for a sequence reset after update : ");
			scanf("%hhd", &ADM1266_reset_type);
			if (ADM1266_reset_type == 1)
			{
				ADM1266_Program_Config(ADM1266_Address, ADM1266_NUM, ADM1266_ptr_file_cfg, 1);
			}
			else
			{
				ADM1266_Program_Config(ADM1266_Address, ADM1266_NUM, ADM1266_ptr_file_cfg, 0);
			}
			ADM1266_CRC_Summary(ADM1266_Address, ADM1266_NUM);
		}
		else
		{
			printf("Not a valid input selected.");
		}
	}

	return 0;
}