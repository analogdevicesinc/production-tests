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
	//ADM1266_ptr_file_fw = fopen("./config_files/adm1266_v1.14.2.hex", "r");
	ADM1266_ptr_file_fw = fopen("./config_files/adm1266_v1.14.3.hex", "r");

	if(!ADM1266_ptr_file_fw) {
		printf("Input file \"adm1266_v1.14.3.hex\" could not be open!\n");
		exit(1);
	}

	// Path of the configuration file for linux
	ADM1266_ptr_file_cfg[0] = fopen("./config_files/TaliseSOM_Sequencing_ADM1266@48.hex", "r");
	
	if(!ADM1266_ptr_file_cfg[0]) {
		printf("Input file \"TaliseSOM_Sequencing_ADM1266@48.hex\" could not be open!\n");
		exit(1);
	}

	if(!ADM1266_ptr_file_cfg[0]) {
		printf("Input file \"TaliseSOM_Sequencing_ADM1266@48.hex\" could not be open!\n");
		exit(1);
	}

	// Check if all the devices are present
	if (ADM1266_Device_Present(ADM1266_Address, ADM1266_NUM) == 0)
	{
		printf("ADM1266 Power Sequencer not detected. Please check connection\n");
		return -1;
	}
	else
	{
		// Update firmware and then configuration
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

	return 0;
}
