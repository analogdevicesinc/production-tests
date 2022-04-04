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

#define ADM1266_NUM 1 // Specify number of ADM1266 in your system


int main(int argc, char *argv[])
{
	i2c_init(); // Uncomment for Linux System
	//int aardvark_id = 1845961448; // Uncomment when using Aardvark
	//aardvark_open(aardvark_id); // Uncomment when using Aardvark


	__u8 ADM1266_Address[ADM1266_NUM] = { 0x48 }; // Specify the hex PMBus address for each ADM1266 in your system

	// Include following Variables in your code
	__s32 temp = 1;
	float calc_val = 0;
	__u8 i = 0;
	__u8 k = 0;
	__u8 ADM1266_VH_Data[ADM1266_NUM][5][15] = { "" };
	__u8 ADM1266_VP_Data[ADM1266_NUM][14][15] = { "" };
	__u8 ADM1266_Signals_Data[ADM1266_NUM][25][7] = { "" };
	__u8 ADM1266_BB_Data[ADM1266_NUM][64] = { "" };
	__u8 ADM1266_System_Data[ADM1266_NUM * 2048] = { "" };
	__u16 ADM1266_State_Name[100][2];
	__u16 ADM1266_Rail_Name[(ADM1266_NUM * 17) + 10][2];
	__u16 ADM1266_Signal_Name[ADM1266_NUM * 25][2];
	__u16 ADM1266_Record_Index = 0;
	__u16 ADM1266_Num_Records = 0;
	__u16 ADM1266_Voltages[(ADM1266_NUM * 17)+1];
	__u8 ADM1266_Status[(ADM1266_NUM * 17) + 1];
	__u16 ADM1266_Refresh_Counter[ADM1266_NUM];
	__u16 ADM1266_CRC_Error_Counter[ADM1266_NUM];
	__u8 ADM1266_IC_Device_ID[ADM1266_NUM][3];
	__u8 ADM1266_Firmware_Rev[ADM1266_NUM][3];
	__u8 ADM1266_Bootloader_Rev[ADM1266_NUM][3];
	__u8 ADM1266_Part_Locked[ADM1266_NUM];
	__u8 ADM1266_Main_Backup[ADM1266_NUM];
	__u8 ADM1266_VX_Status;
	float ADM1266_VX_Value;
	__u8 ADM1266_Current_State[ADM1266_NUM];
	__u8 ADM1266_PDIO_GPIO_Pad[26] = { 0,22,30,31,32,33,34,35,36,37,23,24,25,26,27,28,29,14,15,16,44,45,46,43,18,19 };
	__u8 ADM1266_VX_Pad[18] = { 0,47,48,49,50,51,56,57,58,59,60,61,62,63,52,53,54,55 };

	// Check if Refresh Memory feature is running
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
		// This function takes in the Number of ADM1266 and their PMBus address, and reads back all the system information
		// like Rail,Signal and State names and returns the raw data back to the 'ADM1266_System_Data' Array
		ADM1266_System_Read(ADM1266_NUM, ADM1266_Address, ADM1266_System_Data);

		// This function takes in the raw system data 'ADM1266_System_Data' Array, and parses it to return various arrays
		// 'ADM1266_State_Name' Array has all the state names,  'ADM1266_Rail_Name' array has all the rail names
		// 'ADM1266_Signal_Name' Array has all the signal names, 'ADM1266_VH_Data' has the VH status and PDIO and Rails mapping
		// 'ADM1266_VP_Data' has the VP status and PDIO and Rails mapping, 'ADM1266_Signals_Data' has the Signals status and PDIO/GPIO mapping
		ADM1266_System_Parse(ADM1266_System_Data, (__u16 *)ADM1266_State_Name, (__u16 *)ADM1266_Rail_Name, (__u16 *)ADM1266_Signal_Name, (__u8 *)ADM1266_VH_Data, (__u8 *)ADM1266_VP_Data, (__u8 *)ADM1266_Signals_Data, ADM1266_PDIO_GPIO_Pad, ADM1266_VX_Pad);

		// The above two functions should be called atleast once, the information readback does not change during the operation of the ADM1266
		// The information is fixed for a system, and only needs to be readback again, if a new configuration is loaded into the ADM1266

		//---------------------------------------------------------------------------------------------------------------------------------------------------------------

		// This function is used to read back all the voltages and their corresponding status for all VH and VP pins, Along with PDIO and GPIO status
		// This function takes in the Number of ADM1266 and their PMBus address, Reads back from all the parts and parses the information to fill the following arrays
		// ADM1266_VH_Data, ADM1266_VP_Data, ADM1266_Signals_Data, ADM1266_Voltages, ADM1266_Status
		ADM1266_Get_All_Data(ADM1266_NUM, ADM1266_Address, (__u8 *)ADM1266_VH_Data, (__u8 *)ADM1266_VP_Data, (__u8 *)ADM1266_Signals_Data, ADM1266_Voltages, ADM1266_Status);

		// This function takes in the Number of ADM1266 and their PMBus address, and returns the status of the entire system
		// 5 = OV Fault, 4 = UV Fault, 3 = OV Warning, 2 = UV Warning, 0 = No faults or Warnings
		ADM1266_Get_Sys_Status(ADM1266_NUM, ADM1266_Status);

		// This function is similar to the above function, but instead of returning a value, it prints the status
		// You dont need to call the above function to run this function
		ADM1266_Print_Sys_Status(ADM1266_NUM, ADM1266_Status);

		// This function takes in the Number of ADM1266 and their PMBus address, and returns the number of times Refresh Feature is run since power-up
		// The counter value can be read back from the following Array 'ADM1266_Refresh_Counter' where the index of the array stands for each ADM1266
		// ADM1266_Refresh_Counter[0] - Refresh Counter Value for first ADM1266, ADM1266_Refresh_Counter[1] - Refresh Counter Value for second ADM1266
		ADM1266_Get_Refresh_Counter(ADM1266_NUM, ADM1266_Address, ADM1266_Refresh_Counter);
		
		// This function is similar to the above function, but instead of returning a value, it prints the Refresh Counters
		// You dont need to call the above function to run this function
		ADM1266_Print_Refresh_Counter(ADM1266_NUM, ADM1266_Address, ADM1266_Refresh_Counter);

		// This function takes in the Number of ADM1266 and their PMBus address, and returns the number of times the ADM1266 has seen a Memory CRC Error since power-up
		// The counter value can be read back from the following Array 'ADM1266_CRC_Error_Counter' where the index of the array stands for each ADM1266
		// ADM1266_CRC_Error_Counter[0] - CRC Error Counter Value for first ADM1266, ADM1266_CRC_Error_Counter[1] - CRC Error Counter Value for second ADM1266
		ADM1266_Get_CRC_Error_Counter(ADM1266_NUM, ADM1266_Address, ADM1266_CRC_Error_Counter);

		// This function is similar to the above function, but instead of returning a value, it prints the Memory CRC Error Counters
		// You dont need to call the above function to run this function
		ADM1266_Print_CRC_Error_Counter(ADM1266_NUM, ADM1266_Address, ADM1266_CRC_Error_Counter);

		// This function takes in the Number of ADM1266 and their PMBus address, and prints the PMBus MFR_ID for each ADM1266 in the system
		ADM1266_Print_MFR_ID(ADM1266_NUM, ADM1266_Address);

		// This function takes in the Number of ADM1266 and their PMBus address, and prints the PMBus MFR_MODEL for each ADM1266 in the system
		ADM1266_Print_MFR_MODEL(ADM1266_NUM, ADM1266_Address);

		// This function takes in the Number of ADM1266 and their PMBus address, and prints the PMBus MFR_REVISON for each ADM1266 in the system
		ADM1266_Print_MFR_REVISION(ADM1266_NUM, ADM1266_Address);

		// This function takes in the Number of ADM1266 and their PMBus address, and prints the PMBus MFR_LOCATION for each ADM1266 in the system
		ADM1266_Print_MFR_LOCATION(ADM1266_NUM, ADM1266_Address);

		// This function takes in the Number of ADM1266 and their PMBus address, and prints the PMBus MFR_DATE for each ADM266 in the system
		ADM1266_Print_MFR_DATE(ADM1266_NUM, ADM1266_Address);

		// This function takes in the Number of ADM1266 and their PMBus address, and prints the PMBus MFR_SERIAL for each ADM1266 in the system
		ADM1266_Print_MFR_SERIAL(ADM1266_NUM, ADM1266_Address);

		// This function takes in the Number of ADM1266 and their PMBus address, and prints the USER_DATA for each ADM1266 in the system
		ADM1266_Print_User_Data(ADM1266_NUM, ADM1266_Address);

		// This function takes in the Number of ADM1266 and their PMBus address, and returns the IC_Device_ID for each ADM1266 in the system
		// The ID can be read back from the following Array 'ADM1266_IC_Device_ID' where the first index of the array stands for each ADM1266, second index stands for each byte
		// ADM1266_IC_Device_ID[0][n] - IC_Device_ID Value for first ADM1266, ADM1266_IC_Device_ID[1][n] - IC_Device_ID Value for second ADM1266
		// Right Values - ADM1266_IC_Device_ID[0][0] = 0x42, ADM1266_IC_Device_ID[0][1] = 0x12, ADM1266_IC_Device_ID[0][2] = 0x66
		ADM1266_Get_IC_Device_ID(ADM1266_NUM, ADM1266_Address, (__u8 *)ADM1266_IC_Device_ID);
		
		// This function takes in the Number of ADM1266 and their PMBus address, and returns the Firmware_Rev and Bootloader_Rev for each ADM1266 in the system
		// The Rev can be read back from the following Arrays 'ADM1266_Firmware_Rev' and 'ADM1266_Bootloader_Rev' where the first index of the array stands for each ADM1266, second index stands for each byte
		// ADM1266_Firmware_Rev[0][n] - Firmware_Rev Value for first ADM1266, ADM1266_Firmware_Rev[1][n] - Firmware_Rev Value for second ADM1266
		// ADM1266_Firmware_Rev[0][0].ADM1266_Firmware_Rev[0][1].ADM1266_Firmware_Rev[0][2] = 1.14.3
		// ADM1266_Bootloader_Rev[0][n] - Bootloader_Rev Value for first ADM1266, ADM1266_Bootloader_Rev[1][n] - Bootloader_Rev Value for second ADM1266
		// ADM1266_Bootloader_Rev[0][0].ADM1266_Bootloader_Rev[0][1].ADM1266_Bootloader_Rev[0][2] = 0.0.9
		ADM1266_Get_IC_Device_Rev(ADM1266_NUM, ADM1266_Address, (__u8 *)ADM1266_Firmware_Rev, (__u8 *)ADM1266_Bootloader_Rev);

		// This function takes in the Number of ADM1266 and their PMBus address, and returns the status of the Memory CRC for entire system
		// 1 = CRC Fault, 0 = No CRC fault
		ADM1266_Get_Sys_CRC(ADM1266_NUM, ADM1266_Address);

		// This function takes in the Number of ADM1266 and their PMBus address, and prints all the CRC errors present on each ADM1266
		ADM1266_Print_CRC(ADM1266_NUM, ADM1266_Address);

		// This function takes in the Number of ADM1266 and their PMBus address, and returns if the particular ADM1266 is Locked
		// It also returns back the locked system status, 1 = atleast one device is locked, 0 = all devices are unlocked
		// The locked individual status can be read back from the following Array 'ADM1266_Part_Locked' where the index of the array stands for each ADM1266
		// ADM1266_Part_Locked[0] - Locked Status for first ADM1266, ADM1266_Part_Locked[1] - Locked Status for second ADM1266
		// 1 = Locked, 0 = Unlocked
		ADM1266_Get_Part_Locked(ADM1266_NUM, ADM1266_Address, ADM1266_Part_Locked);

		// This function takes in the Number of ADM1266 and their PMBus address, and returns if the particular ADM1266 is running Main or Backup memory
		// The memory status can be read back from the following Array 'ADM1266_Main_Backup' where the index of the array stands for each ADM1266
		// ADM1266_Main_Backup[0] - Memory Status for first ADM1266, ADM1266_Main_Backup[1] - Memory Status for second ADM1266
		// 1 = Backup, 0 = Main
		ADM1266_Get_Main_Backup(ADM1266_NUM, ADM1266_Address, ADM1266_Main_Backup);

		// This function takes the device index, and the VX pin index, and returns the Status and Voltage for that pin
		// ADM1266_VX_Telemetry(ADM1266_Dev, ADM1266_Pin, ADM1266_VX_Status, ADM1266_VX_Value, ADM1266_VH_Data, ADM1266_VP_Data, ADM1266_Voltages, ADM1266_Status);
		// ADM1266_Dev = 0 means first ADM1266, 1 means second ADM1266, etc. 
		// ADM1266_Pin = 1:4 for VH1:VH4, 5:17 for VP1:VP13
		// The function returns this value, ADM1266_VX_Status = 5 = OV Fault, 4 = UV Fault, 3 = OV Warning, 2 = UV Warning, 1 = Rail Disabled, 0 = No faults or Warnings
		// The function returns this value, ADM1266_VX_Value = Rail Voltage
		ADM1266_VX_Telemetry(1, 5, &ADM1266_VX_Status, &ADM1266_VX_Value, (__u8 *)ADM1266_VH_Data, (__u8 *)ADM1266_VP_Data, ADM1266_Voltages, ADM1266_Status);
		printf("%d, %.3f\n", ADM1266_VX_Status, ADM1266_VX_Value);

		// This function takes the device index, and the PDIO GPIO pin index, and returns the Status for that pin
		// ADM1266_PDIOGPIO_Telemetry(ADM1266_Dev, ADM1266_Pin, ADM1266_Signals_Data);
		// ADM1266_Dev = 0 means first ADM1266, 1 means second ADM1266, etc. 
		// ADM1266_Pin = 1:16 for PDIO1:PDIO16, 17:25 for GPIO1:GPIO9
		// The function returns this value = 1 High, 0 Low
		i = ADM1266_PDIOGPIO_Telemetry(1, 22, (__u8 *)ADM1266_Signals_Data);
		printf("%d\n", i);

		// This function takes in the Number of ADM1266 and their PMBus address, and returns the current state of each ADM1266
		// The state can be read back from the following Array 'ADM1266_Current_State' where the index of the array stands for each ADM1266
		// ADM1266_Current_State[0] - State Number for first ADM1266, ADM1266_Current_State[1] - State Number for second ADM1266
		ADM1266_Get_Current_State(ADM1266_NUM, ADM1266_Address, ADM1266_Current_State);


		while (temp != 0)
		{
			// This function is used to read back all the voltages and their corresponding status for all VH and VP pins, Along with PDIO and GPIO status
			// This function takes in the Number of ADM1266 and their PMBus address, Reads back from all the parts and parses the information to fill the following arrays
			// ADM1266_VH_Data, ADM1266_VP_Data, ADM1266_Signals_Data, ADM1266_Voltages, ADM1266_Status
			ADM1266_Get_All_Data(ADM1266_NUM, ADM1266_Address, (__u8 *)ADM1266_VH_Data, (__u8 *)ADM1266_VP_Data, (__u8 *)ADM1266_Signals_Data, ADM1266_Voltages, ADM1266_Status);

			printf("\n");


			ADM1266_Print_Sys_Status(ADM1266_NUM, ADM1266_Status);
			printf("\n");

			// This function takes in the Number of ADM1266 and their PMBus address, and prints the current state of each ADM1266
			ADM1266_Print_Current_State(ADM1266_NUM, ADM1266_Address, ADM1266_System_Data, (__u16 *)ADM1266_State_Name);
			printf("\n");

			// This function prints the Voltage and Status of each Rail, it also prints the status of each Signal
			// It sorts the rail based on following order OV Fault, UV Fault, OV Warning, UV Warning, No Fault or Warning, Disabled
			ADM1266_Print_Telemetry(ADM1266_NUM, (__u8 *)ADM1266_VH_Data, (__u8 *)ADM1266_VP_Data, (__u8 *)ADM1266_Signals_Data, ADM1266_Voltages, ADM1266_Status, (__u16 *)ADM1266_Rail_Name, (__u16 *)ADM1266_Signal_Name, ADM1266_System_Data);

			printf("\nPress any number followed by Enter to read telemetry again, Press 0 followed by Enter to exit ");
			scanf("%d", &temp);
		}

	}


	printf("\nPress any number followed by Enter to exit the program ");
	scanf("%d", &temp);

	return 0;
}


