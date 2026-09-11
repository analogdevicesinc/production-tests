// Copyright(c) 2019 Analog Devices, Inc.
// All Rights Reserved.
// This software is proprietary to Analog Devices, Inc. and its licensors.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "library/adm1266.h"

//Change this based on the number of ADM1266
#define ADM1266_NUM 2

int main(int argc, char *argv[])
{	
	i2c_init(); // Uncomment for Linux System
	//int aardvark_id = 1845961448; // Uncomment when using Aardvark
	//aardvark_open(aardvark_id); // Uncomment when using Aardvark

	__u8 ADM1266_Address[ADM1266_NUM] = { 0x40, 0x42 }; // Specify the hex PMBus address for each ADM1266 in your system

	// Include following Variables in your code
	__u8 exit_input = 1;
	__u8 margin_type = 0xFF;
	__u8 ADM1266_margin_update = 0xFF;
	__u8 ADM1266_margin_level = 0xFF;
	__u8 index;
	__u8 ADM1266_DAC_Number = 0;
	float margin_percent = 0.0;
	struct ADM1266_dac_data ADM1266_dac_mapping_data[9 * ADM1266_NUM];
	const char rail_input_name[18][5] = { "OPEN", "VH1", "VH2", "VH3", "VH4", "VP1", "VP2", "VP3", "VP4", "VP5", "VP6", "VP7", "VP8", "VP9", "VP10",
		"VP11", "VP12", "VP13" };		
	int temp = 1;
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
	__u8 ADM1266_PDIO_GPIO_Pad[26] = { 0,22,30,31,32,33,34,35,36,37,23,24,25,26,27,28,29,14,15,16,44,45,46,43,18,19 };
	__u8 ADM1266_VX_Pad[18] = { 0,47,48,49,50,51,56,57,58,59,60,61,62,63,52,53,54,55 };	

	while (exit_input == 1)
	{
		// Check if Refresh Memory feature is running and all the devices are present
		printf("1 - Margin all rails\n2 - Margin single rail\n3 - Update margining thresholds\nSelect margining option: ");
		scanf("%hhi", &margin_type);

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
			// Margin all rails
			if (margin_type == 1)
			{
				printf("\n1 - High\n2 - Low\n3 - Vout\n4 - Disable\nSelect margin level:");
				scanf("%hhi", &ADM1266_margin_level);
				// This function margins all the rails that are closed loop margined
				// Valid ADM1266_margin_level are 1 for high, 2 for low, 3 for vout, 4 disable
				ADM1266_Margin_All(ADM1266_Address, ADM1266_NUM, ADM1266_margin_level);
			}
			// Margin a single rail
			else if (margin_type == 2)
			{
				// This function takes in the Number of ADM1266 and their PMBus address, and reads back all the system information
				// like Rail,Signal and State names and returns the raw data back to the 'ADM1266_System_Data' Array
				ADM1266_System_Read(ADM1266_NUM, ADM1266_Address, ADM1266_System_Data);
				// This function takes in the raw system data 'ADM1266_System_Data' Array, and parses it to return various arrays
				// 'ADM1266_State_Name' Array has all the state names,  'ADM1266_Rail_Name' array has all the rail names
				// 'ADM1266_Signal_Name' Array has all the signal names, 'ADM1266_VH_Data' has the VH status and PDIO and Rails mapping
				// 'ADM1266_VP_Data' has the VP status and PDIO and Rails mapping, 'ADM1266_Signals_Data' has the Signals status and PDIO/GPIO mapping
				ADM1266_System_Parse(ADM1266_System_Data, (__u16 *)ADM1266_State_Name, (__u16 *)ADM1266_Rail_Name, (__u16 *)ADM1266_Signal_Name, (__u8 *)ADM1266_VH_Data, (__u8 *)ADM1266_VP_Data, (__u8 *)ADM1266_Signals_Data, ADM1266_PDIO_GPIO_Pad, ADM1266_VX_Pad);
				
				printf("\n");

				// This function checks if a DAC is used for closed loop margining, if so which input channel the DAC is mapped to
				// It added information for all the 9 DAC per device to ADM_dac_mapping_data struct
				ADM1266_DAC_Mapping(ADM1266_Address, ADM1266_NUM, ADM1266_dac_mapping_data);

				for (__u8 dac_counter = 0; dac_counter < (9 * ADM1266_NUM); dac_counter++)
				{

					if (ADM1266_dac_mapping_data[dac_counter].input_channel < 4)
					{
						// Prints the physical address and input channel name (VH1 - VH4) of the rails that are closed loop margined 
						printf("%d - %s@0x%hhx: ", dac_counter, rail_input_name[ADM1266_dac_mapping_data[dac_counter].input_channel], ADM1266_dac_mapping_data[dac_counter].ADM1266_Address);
						// Prints the user name of the rail that are closed loop margined
						ADM1266_Get_Name(ADM1266_System_Data, (__u16*)ADM1266_Rail_Name, ADM1266_VH_Data[ADM1266_dac_mapping_data[dac_counter].device_index][ADM1266_dac_mapping_data[dac_counter].input_channel + 1][0]);
						printf("\n");
					}
					else
					{
						// Prints the physical address and input channel name (VP1 - VP13) of the rails that are closed loop margined 
						printf("%d - %s@0x%hhx: ", dac_counter, rail_input_name[ADM1266_dac_mapping_data[dac_counter].input_channel], ADM1266_dac_mapping_data[dac_counter].ADM1266_Address);
						// Prints the user name of the rail that are closed loop margined
						ADM1266_Get_Name(ADM1266_System_Data, (__u16*)ADM1266_Rail_Name, ADM1266_VP_Data[ADM1266_dac_mapping_data[dac_counter].device_index][ADM1266_dac_mapping_data[dac_counter].input_channel - 4][0]);
						printf("\n");
					}
				}

				printf("\nSelect a rail index number to margin:");
				scanf("%hhi", &index);

				printf("\n1 - High\n2 - Low\n3 - Vout\n4 - Disable\nSelect margin level:");
				scanf("%hhi", &ADM1266_margin_level);

				if (index < (9 * ADM1266_NUM))
					// This function margins a single rail based on the i2c address of the ADM1266, input channel to be margined (valid input 1 - 17), and the margin level (valid input 1 for high, 2 for low, 3 for vout, 4 disable)
					ADM1266_Margin_Single_Input(ADM1266_dac_mapping_data[index].ADM1266_Address, ADM1266_dac_mapping_data[index].input_channel, ADM1266_margin_level);
				else
					printf("Please select a valid index.\n");
			}
			// Update margining thresholds
			else if (margin_type == 3)
			{
				// This function checks if a DAC is used for closed loop margining, if so which input channel the DAC is mapped to
				// It added information for all the 9 DAC per device to ADM_dac_mapping_data struct
				ADM1266_DAC_Mapping(ADM1266_Address, ADM1266_NUM, ADM1266_dac_mapping_data);
				printf("\n1 - Update thresholds for all rails\n2 - Update thresholds for single rail\nSelect option:");
				scanf("%hhi", &ADM1266_margin_update);
				// Update margining thresholds for a single rail
				if (ADM1266_margin_update == 1)
				{
					printf("\nEnter margin percentage:+/-");
					scanf("%f", &margin_percent);
					// This function updates the margin high and low thresholds for all the input channels that are margined closed loop
					// based on number of ADM1266, ADM1266_dac_mapping_data which contains DAC mapping information, margin_percent
					ADM1266_Margin_All_Percent(ADM1266_NUM, ADM1266_dac_mapping_data, margin_percent);

				}
				// Update margining thresholds for all rails
				else if (ADM1266_margin_update == 2)
				{
					ADM1266_System_Read(ADM1266_NUM, ADM1266_Address, ADM1266_System_Data);
					ADM1266_System_Parse(ADM1266_System_Data, (__u16 *)ADM1266_State_Name, (__u16 *)ADM1266_Rail_Name, (__u16 *)ADM1266_Signal_Name, (__u8 *)ADM1266_VH_Data, (__u8 *)ADM1266_VP_Data, (__u8 *)ADM1266_Signals_Data, ADM1266_PDIO_GPIO_Pad, ADM1266_VX_Pad);

					printf("\n");

					for (__u8 dac_counter = 0; dac_counter < (9 * ADM1266_NUM); dac_counter++)
					{
						if (ADM1266_dac_mapping_data[dac_counter].input_channel < 4)
						{
							printf("%d - %s@0x%hhx: ", dac_counter, rail_input_name[ADM1266_dac_mapping_data[dac_counter].input_channel], ADM1266_dac_mapping_data[dac_counter].ADM1266_Address);
							ADM1266_Get_Name(ADM1266_System_Data, (__u16*)ADM1266_Rail_Name, ADM1266_VH_Data[ADM1266_dac_mapping_data[dac_counter].device_index][ADM1266_dac_mapping_data[dac_counter].input_channel + 1][0]);
							printf("\n");
						}
						else
						{
							printf("%d - %s@0x%hhx: ", dac_counter, rail_input_name[ADM1266_dac_mapping_data[dac_counter].input_channel], ADM1266_dac_mapping_data[dac_counter].ADM1266_Address);
							ADM1266_Get_Name(ADM1266_System_Data, (__u16*)ADM1266_Rail_Name, ADM1266_VP_Data[ADM1266_dac_mapping_data[dac_counter].device_index][ADM1266_dac_mapping_data[dac_counter].input_channel - 4][0]);
							printf("\n");
						}
					}

					printf("\nSelect a rail index number to update threshold:");
					scanf("%hhi", &index);

					printf("\nEnter margin percentage:+/-");
					scanf("%f", &margin_percent);

					if (index < (9 * ADM1266_NUM))
					{
						// This function updates the margin high and low thresholds for a specific the input channel that is margined closed loop
						// based on the i2c address, input channel index and margin percentage
						ADM1266_Margin_Single_Percent(ADM1266_dac_mapping_data[index].ADM1266_Address, ADM1266_dac_mapping_data[index].input_channel - 1, margin_percent);
					}
					else
						printf("Please select a valid index.\n");
				}
				else
				{
					printf("Please select a valid input.");
				}

			}
			else
				printf("Please select a valid input.");
		}

		printf("\n\nEnter 1 to go to margining menu, any other key to exit:");
		scanf("%hhi", &exit_input);
	}

	return 0;
}