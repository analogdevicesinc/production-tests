// Copyright(c) 2019 Analog Devices, Inc.
// All Rights Reserved.
// This software is proprietary to Analog Devices, Inc. and its licensors.

#include <stdio.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include <ctype.h>
#include "adm1266.h"

void ADM1266_Print_Current_State(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_System_Data, __u16 *ADM1266_State_Name)
{
	__u8 ADM1266_datain[2];
	__u8 dataout[1] = { 0xD9 };
	__u8 temp = 0;

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 1, ADM1266_datain);
		temp = ADM1266_datain[0] + (ADM1266_datain[1] * 256)-1;
		printf("ADM1266 at Address %#02x is in '", ADM1266_Address[i]);
		ADM1266_Get_Name(ADM1266_System_Data, ADM1266_State_Name,temp);
		printf("' State\n");
	}
}

void ADM1266_Get_Current_State(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_Current_State)
{
	__u8 ADM1266_datain[2];
	__u8 dataout[1] = { 0xD9 };
	__u8 temp = 0;

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 1, ADM1266_datain);
		ADM1266_Current_State[i] = ADM1266_datain[0] + (ADM1266_datain[1]*256);
	}
}

__u8 ADM1266_PDIOGPIO_Telemetry(__u8 ADM1266_Dev, __u8 ADM1266_Pin, __u8 *ADM1266_Signals_Data)
{
	__u8 temp = 0;
	if (ADM1266_Pin < 17)
	{
		for (__u8 j = 0; j < 25; j++)
		{
			if ((ADM1266_Signals_Data[n21(ADM1266_Dev, j, 2, 25, 7)] == 0) && (ADM1266_Signals_Data[n21(ADM1266_Dev, j, 1, 25, 7)] == ADM1266_Pin))
			{
				temp = ADM1266_Signals_Data[n21(ADM1266_Dev, j, 6, 25, 7)];
			}
		}
	}
	else
	{
		for (__u8 j = 0; j < 25; j++)
		{
			if ((ADM1266_Signals_Data[n21(ADM1266_Dev, j, 2, 25, 7)] == 1) && (ADM1266_Signals_Data[n21(ADM1266_Dev, j, 1, 25, 7)] == ADM1266_Pin-16))
			{
				temp = ADM1266_Signals_Data[n21(ADM1266_Dev, j, 6, 25, 7)];
			}
		}
	}
	return temp;
}

void ADM1266_VX_Telemetry(__u8 ADM1266_Dev, __u8 ADM1266_Pin, __u8 *ADM1266_VX_Status, float *ADM1266_VX_Value, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u16 *ADM1266_Voltages, __u8 *ADM1266_Status)
{

	if (ADM1266_Pin < 5)
	{
		*ADM1266_VX_Status = ADM1266_Status[ADM1266_VH_Data[n21(ADM1266_Dev, ADM1266_Pin, 9, 5, 15)]];
		*ADM1266_VX_Value = ADM1266_Voltages[ADM1266_VH_Data[n21(ADM1266_Dev, ADM1266_Pin, 9, 5, 15)]] * pow(2, ADM1266_Expo(ADM1266_VH_Data[n21(ADM1266_Dev, ADM1266_Pin, 8, 5, 15)]));
	}
	else
	{
		*ADM1266_VX_Status = ADM1266_Status[ADM1266_VP_Data[n21(ADM1266_Dev, ADM1266_Pin-4, 9, 14, 15)]];
		*ADM1266_VX_Value = ADM1266_Voltages[ADM1266_VP_Data[n21(ADM1266_Dev, ADM1266_Pin-4, 9, 14, 15)]] * pow(2, ADM1266_Expo(ADM1266_VP_Data[n21(ADM1266_Dev, ADM1266_Pin-4, 8, 14, 15)]));
	}
	
}

void ADM1266_Print_CRC(__u8 ADM1266_NUM, __u8 *ADM1266_Address)
{
	__u8 ADM1266_datain[2];
	__u8 dataout[1] = { 0xED };
	__u8 temp = 0;

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 2, ADM1266_datain);
		for (__u8 j = 4; j < 8; j++)
		{
			temp = pow(2, j);
			temp = (ADM1266_datain[0] & temp) >> j;
			if (temp == 1)
			{
				switch (temp)
				{
				case 4:
					printf("ADM1266 at Address %#02x has Main Mini-Bootloader CRC Fault\n", ADM1266_Address[i]);
					break;
				case 5:
					printf("ADM1266 at Address %#02x has Main Bootloader CRC Fault\n", ADM1266_Address[i]);
					break;
				case 6:
					printf("ADM1266 at Address %#02x has Back-up Mini-Bootloader CRC Fault\n", ADM1266_Address[i]);
					break;
				case 7:
					printf("ADM1266 at Address %#02x has Back-up Bootloader CRC Fault\n", ADM1266_Address[i]);
					break;
				}
			}
		}
		for (__u8 j = 0; j < 8; j++)
		{
			temp = pow(2, j);
			temp = (ADM1266_datain[1] & temp) >> j;
			if (temp == 1)
			{
				switch (temp)
				{
				case 0:
					printf("ADM1266 at Address %#02x has Main ABConfig CRC Fault\n", ADM1266_Address[i]);
					break;
				case 1:
					printf("ADM1266 at Address %#02x has Main User Configuration CRC Fault\n", ADM1266_Address[i]);
					break;
				case 2:
					printf("ADM1266 at Address %#02x has Main Firmware CRC Fault\n", ADM1266_Address[i]);
					break;
				case 3:
					printf("ADM1266 at Address %#02x has Main Password CRC Fault\n", ADM1266_Address[i]);
					break;
				case 4:
					printf("ADM1266 at Address %#02x has Back-up ABConfig CRC Fault\n", ADM1266_Address[i]);
					break;
				case 5:
					printf("ADM1266 at Address %#02x has Back-up User Configuration CRC Fault\n", ADM1266_Address[i]);
					break;
				case 6:
					printf("ADM1266 at Address %#02x has Back-up Firmware CRC Fault\n", ADM1266_Address[i]);
					break;
				case 7:
					printf("ADM1266 at Address %#02x has Back-up Password CRC Fault\n", ADM1266_Address[i]);
					break;
				}
			}
		}
		
	}
}

void ADM1266_Get_Main_Backup(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_Main_Backup)
{
	__u8 ADM1266_datain[2];
	__u8 dataout[1] = { 0xED };

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 2, ADM1266_datain);
		ADM1266_Main_Backup[i] = (ADM1266_datain[0] & 1);
	}
}

__u8 ADM1266_Get_Part_Locked(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_Part_Locked)
{
	__u8 ADM1266_datain[1];
	__u8 dataout[1] = { 0x80 };
	__u8 temp = 0;

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 1, ADM1266_datain);
		ADM1266_Part_Locked[i] = (ADM1266_datain[0]&4)>>2 ;
		temp = temp | ADM1266_Part_Locked[i];
	}
	return temp;
}

__u8 ADM1266_Get_Sys_CRC(__u8 ADM1266_NUM, __u8 *ADM1266_Address)
{
	__u8 ADM1266_datain[1];
	__u8 dataout[1] = { 0x80 };
	__u8 temp = 0;

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 1, ADM1266_datain);
		if (ADM1266_datain[0] > 31)
		{
			temp = 1;
		}
	}
	return temp;
}

void ADM1266_Print_MFR_ID(__u8 ADM1266_NUM, __u8 *ADM1266_Address)
{
	__u8 ADM1266_datain[33];
	__u8 dataout[1] = { 0x99 };

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		printf("MFR_ID for ADM1266 at Address %#02x is : ", ADM1266_Address[i]);
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 33, ADM1266_datain);
		for (__u8 j = 1; j < 33; j++)
		{
			printf("%c", ADM1266_datain[j]);
		}
		printf("\n");
	}
}

void ADM1266_Print_MFR_MODEL(__u8 ADM1266_NUM, __u8 *ADM1266_Address)
{
	__u8 ADM1266_datain[33];
	__u8 dataout[1] = { 0x9A };

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		printf("MFR_MODEL for ADM1266 at Address %#02x is : ", ADM1266_Address[i]);
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 33, ADM1266_datain);
		for (__u8 j = 1; j < 33; j++)
		{
			printf("%c", ADM1266_datain[j]);
		}
		printf("\n");
	}
}

void ADM1266_Print_MFR_REVISION(__u8 ADM1266_NUM, __u8 *ADM1266_Address)
{
	__u8 ADM1266_datain[9];
	__u8 dataout[1] = { 0x9B };

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		printf("MFR_REVISION for ADM1266 at Address %#02x is : ", ADM1266_Address[i]);
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 9, ADM1266_datain);
		for (__u8 j = 1; j < 9; j++)
		{
			printf("%c", ADM1266_datain[j]);
		}
		printf("\n");
	}
}

void ADM1266_Print_MFR_LOCATION(__u8 ADM1266_NUM, __u8 *ADM1266_Address)
{
	__u8 ADM1266_datain[49];
	__u8 dataout[1] = { 0x9C };

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		printf("MFR_LOCATION for ADM1266 at Address %#02x is : ", ADM1266_Address[i]);
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 49, ADM1266_datain);
		for (__u8 j = 1; j < 49; j++)
		{
			printf("%c", ADM1266_datain[j]);
		}
		printf("\n");
	}
}

void ADM1266_Print_MFR_DATE(__u8 ADM1266_NUM, __u8 *ADM1266_Address)
{
	__u8 ADM1266_datain[17];
	__u8 dataout[1] = { 0x9D };

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		printf("MFR_DATE for ADM1266 at Address %#02x is : ", ADM1266_Address[i]);
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 17, ADM1266_datain);
		for (__u8 j = 1; j < 17; j++)
		{
			printf("%c", ADM1266_datain[j]);
		}
		printf("\n");
	}
}

void ADM1266_Print_MFR_SERIAL(__u8 ADM1266_NUM, __u8 *ADM1266_Address)
{
	__u8 ADM1266_datain[33];
	__u8 dataout[1] = { 0x9E };

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		printf("MFR_SERIAL for ADM1266 at Address %#02x is : ", ADM1266_Address[i]);
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 33, ADM1266_datain);
		for (__u8 j = 1; j < 33; j++)
		{
			printf("%c", ADM1266_datain[j]);
		}
		printf("\n");
	}
}

void ADM1266_Print_User_Data(__u8 ADM1266_NUM, __u8 *ADM1266_Address)
{
	__u8 ADM1266_datain[253];
	__u8 dataout[5] = { 0xE3, 0x03, 252, 0x00, 0x00 };
	__u16 temp = 0;

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		printf("User_Data for ADM1266 at Address %#02x is : ", ADM1266_Address[i]);
		i2c_block_write_block_read(ADM1266_Address[i], 5, dataout,253, ADM1266_datain);
		temp = ADM1266_datain[1] + (ADM1266_datain[2] * 256);
		for (__u8 j = 3; j < temp; j++)
		{
			printf("%c", ADM1266_datain[j]);
		}
		printf("\n");
	}
}

void ADM1266_Get_IC_Device_ID(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_IC_Device_ID)
{
	__u8 ADM1266_datain[4];
	__u8 dataout[1] = { 0xAD };

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 4, ADM1266_datain);
		for (__u8 j = 1; j < 4; j++)
		{
			ADM1266_IC_Device_ID[n21(0, i, (j-1), ADM1266_NUM, 3)] = ADM1266_datain[j];
		}
	}
}

void ADM1266_Get_IC_Device_Rev(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_Firmware_Rev, __u8 *ADM1266_Bootloader_Rev)
{
	__u8 ADM1266_datain[9];
	__u8 dataout[1] = { 0xAE };
	__u8 mode = 0;

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		mode = 0;
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 9, ADM1266_datain);
		for (__u8 j = 4; j < 7; j++)
		{
			ADM1266_Bootloader_Rev[n21(0, i, (j - 4), ADM1266_NUM, 3)] = ADM1266_datain[j];
			if (ADM1266_datain[j] > 0)
				mode = 1;			
		}
		if (mode == 0)
		{
			for (__u8 j = 1; j < 4; j++)
			{
				ADM1266_Bootloader_Rev[n21(0, i, (j - 1), ADM1266_NUM, 3)] = ADM1266_datain[j];
				ADM1266_Firmware_Rev[n21(0, i, (j - 1), ADM1266_NUM, 3)] = 0;
			}
		}
		else
		{
			for (__u8 j = 1; j < 4; j++)
			{
				ADM1266_Firmware_Rev[n21(0, i, (j - 1), ADM1266_NUM, 3)] = ADM1266_datain[j];
			}
		}
		
	}
}



void ADM1266_Get_Refresh_Counter(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u16 *ADM1266_Refresh_Counter)
{
	__u8 ADM1266_datain[10];
	__u8 dataout[1] = { 0xF4 };

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 9, ADM1266_datain);
		ADM1266_Refresh_Counter[i] = ADM1266_datain[3] + (ADM1266_datain[4] * 256);
	}
}

void ADM1266_Print_Refresh_Counter(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u16 *ADM1266_Refresh_Counter)
{
	ADM1266_Get_Refresh_Counter(ADM1266_NUM, ADM1266_Address, ADM1266_Refresh_Counter);
	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		printf("ADM1266 at Address %#02x is refreshed %d time(s) since power-up\n", ADM1266_Address[i], ADM1266_Refresh_Counter[i]);
	}
}

void ADM1266_Get_CRC_Error_Counter(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u16 *ADM1266_CRC_Error_Counter)
{
	__u8 ADM1266_datain[10];
	__u8 dataout[1] = { 0xF4 };

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 9, ADM1266_datain);
		ADM1266_CRC_Error_Counter[i] = ADM1266_datain[5] + (ADM1266_datain[6] * 256);
	}
}

void ADM1266_Print_CRC_Error_Counter(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u16 *ADM1266_CRC_Error_Counter)
{
	ADM1266_Get_CRC_Error_Counter(ADM1266_NUM, ADM1266_Address, ADM1266_CRC_Error_Counter);
	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		printf("ADM1266 at Address %#02x saw CRC Error %d time(s) since power-up\n", ADM1266_Address[i], ADM1266_CRC_Error_Counter[i]);
	}
}

__u8 ADM1266_Get_Sys_Status(__u8 ADM1266_NUM, __u8 *ADM1266_Status)
{
	__u8 temp = 0;
	for (__u8 i = 1; i < ((ADM1266_NUM * 17) + 1); i++)
	{
		if (ADM1266_Status[i] > temp)
			temp = ADM1266_Status[i];
	}
	if (temp == 1)
		temp = 0;
	return temp;
}

void ADM1266_Print_Sys_Status(__u8 ADM1266_NUM, __u8 *ADM1266_Status)
{
	__u8 temp = 0;
	temp = ADM1266_Get_Sys_Status(ADM1266_NUM, ADM1266_Status);
	switch (temp)
	{
	case 5:
		printf("Over Voltage Fault in System\n");
		break;
	case 4:
		printf("Under Voltage Fault in System\n");
		break;
	case 3:
		printf("Over Voltage Warning in System\n");
		break;
	case 2:
		printf("Under Voltage Warning in System\n");
		break;
	case 0:
		printf("No Faults or Warnings in System\n");
		break;
	default:
		printf("Error, invalid value\n");
	}
}

__u8 ADM1266_Status_Decode(__u8 *Data, __u8 type, __u8 index, __u8 id)
{
	__u8 temp = 0;
	__u8 result = 0;
	__u8 temp2 = 1;
	if (type == 0)
		temp = 5;
	else
		temp = 14;
	if (Data[n21(id, index, 1, temp, 15)] == 0)
	{
		if (Data[n21(id, index, 10, temp, 15)] == 1 & temp2 != 0)
		{
			result = 5;
			temp2 = 0;
		}
		if (Data[n21(id, index, 11, temp, 15)] == 1 & temp2 != 0)
		{
			result = 4;
			temp2 = 0;
		}
		if (Data[n21(id, index, 12, temp, 15)] == 1 & temp2 != 0)
		{
			result = 3;
			temp2 = 0;
		}
		if (Data[n21(id, index, 13, temp, 15)] == 1 & temp2 != 0)
		{
			result = 2;
			temp2 = 0;
		}
		if ((Data[n21(id, index, 10, temp, 15)] == 0) & (Data[n21(id, index, 11, temp, 15)] == 0) & (Data[n21(id, index, 12, temp, 15)] == 0) & (Data[n21(id, index, 13, temp, 15)] == 0))
			result = 0;
	}
	else
	{
		if ((Data[n21(id, index, 10, temp, 15)] == 1) & (Data[n21(id, index, 3, temp, 15)] == Data[n21(id, index, 14, temp, 15)]) & temp2 != 0)
		{
			result = 5;
			temp2 = 0;
		}
		if ((Data[n21(id, index, 11, temp, 15)] == 1) & (Data[n21(id, index, 3, temp, 15)] == Data[n21(id, index, 14, temp, 15)]) & temp2 != 0)
		{
			result = 4;
			temp2 = 0;
		}
		if ((Data[n21(id, index, 12, temp, 15)] == 1) & (Data[n21(id, index, 3, temp, 15)] == Data[n21(id, index, 14, temp, 15)]) & temp2 != 0)
		{
			result = 3;
			temp2 = 0;
		}
		if ((Data[n21(id, index, 13, temp, 15)] == 1) & (Data[n21(id, index, 3, temp, 15)] == Data[n21(id, index, 14, temp, 15)]) & temp2 != 0)
		{
			result = 2;
			temp2 = 0;
		}
		if (Data[n21(id, index, 3, temp, 15)] != Data[n21(id, index, 14, temp, 15)])
			result = 1;
		if ((Data[n21(id, index, 10, temp, 15)] == 0) & (Data[n21(id, index, 11, temp, 15)] == 0) & (Data[n21(id, index, 12, temp, 15)] == 0) & (Data[n21(id, index, 13, temp, 15)] == 0) & (Data[n21(id, index, 3, temp, 15)] == Data[n21(id, index, 14, temp, 15)]))
			result = 0;
	}
	return result;
}

void ADM1266_Get_All_Data(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u8 *ADM1266_Signals_Data, __u16 *ADM1266_Voltages, __u8 *ADM1266_Status)
{
	__u8 ADM1266_datain[64];
	__u8 j = 0;
	__u8 dataout[1] = { 0xE8 };
	__u8 k = 0;
	__u8 l = 1;
	__u8 m = 0;
	__u8 p = 1;
	__u16 temp = 0;
	__u16 temp2 = 0;


	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		k = 1;
		dataout[0] = 0xE8;
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 52, ADM1266_datain);
		for (j = 1; j < 5; j++) 
		{
			ADM1266_VH_Data[n21(i, j, 9, 5, 15)] = p;
			ADM1266_Voltages[p] = ADM1266_datain[k] + (ADM1266_datain[k + 1] * 256);
			ADM1266_VH_Data[n21(i, j, 8, 5, 15)] = ADM1266_datain[j+34];
			k += 2;
			p += 1;
		}
		for (j = 1; j < 14; j++)
		{
			ADM1266_VP_Data[n21(i, j, 9, 14, 15)] = p;
			ADM1266_Voltages[p] = ADM1266_datain[k] + (ADM1266_datain[k + 1] * 256);
			ADM1266_VP_Data[n21(i, j, 8, 14, 15)] = ADM1266_datain[j + 38];
			k += 2;
			p += 1;
		}
		k = 1;
		dataout[0] = 0xE7;
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 18, ADM1266_datain);
		for (j = 1; j < 5; j++)
		{
			ADM1266_VH_Data[n21(i, j, 10, 5, 15)] = (ADM1266_datain[k] & 128)/128; //ovf
			ADM1266_VH_Data[n21(i, j, 11, 5, 15)] = (ADM1266_datain[k] & 16) / 16; //uvf
			ADM1266_VH_Data[n21(i, j, 12, 5, 15)] = (ADM1266_datain[k] & 64) / 64; //ovw
			ADM1266_VH_Data[n21(i, j, 13, 5, 15)] = (ADM1266_datain[k] & 32) / 32; //uvw
			k += 1;
		}
		for (j = 1; j < 14; j++)
		{
			ADM1266_VP_Data[n21(i, j, 10, 14, 15)] = (ADM1266_datain[k] & 128) / 128; //ovf
			ADM1266_VP_Data[n21(i, j, 11, 14, 15)] = (ADM1266_datain[k] & 16) / 16; //uvf
			ADM1266_VP_Data[n21(i, j, 12, 14, 15)] = (ADM1266_datain[k] & 64) / 64; //ovw
			ADM1266_VP_Data[n21(i, j, 13, 14, 15)] = (ADM1266_datain[k] & 32) / 32; //uvw
			k += 1;
		}
		dataout[0] = 0xE9;
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 3, ADM1266_datain);
		temp = (ADM1266_datain[2] * 256) + ADM1266_datain[1];
		dataout[0] = 0xEA;
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 3, ADM1266_datain);
		temp2 = (ADM1266_datain[2] * 256) + ADM1266_datain[1];
		temp2 = ADM1266_GPIO_Map(temp2);
		for (k = 0; k < 16; k++)
		{
			for (l = 0; l < ADM1266_NUM; l++)
			{
				for (m = 1; m < 5; m++)
				{
					if ((ADM1266_VH_Data[n21(l, m, 1, 5, 15)] == k + 1) && (ADM1266_VH_Data[n21(l, m, 2, 5, 15)] == i))
					{
						ADM1266_VH_Data[n21(l, m, 14, 5, 15)] = ADM1266_Get_Bit(temp, k);
					}
				}
				for (m = 1; m < 14; m++)
				{
					if ((ADM1266_VP_Data[n21(l, m, 1, 14, 15)] == k + 1) && (ADM1266_VP_Data[n21(l, m, 2, 14, 15)] == i))
					{
						ADM1266_VP_Data[n21(l, m, 14, 14, 15)] = ADM1266_Get_Bit(temp, k);
					}
				}
			}
			for (m = 0; m < 25; m++)
			{
				if ((ADM1266_Signals_Data[n21(i, m, 2, 25, 7)] == 0) && (ADM1266_Signals_Data[n21(i, m, 1, 25, 7)] == k + 1))
				{
					ADM1266_Signals_Data[n21(i, m, 6, 25, 7)] = ADM1266_Get_Bit(temp, k);
				}
			}
		}
		for (k = 0; k < 10; k++)
		{
			for (m = 0; m < 25; m++)
			{
				if ((ADM1266_Signals_Data[n21(i, m, 2, 25, 7)] == 1) && (ADM1266_Signals_Data[n21(i, m, 1, 25, 7)] == k + 1))
				{
					ADM1266_Signals_Data[n21(i, m, 6, 25, 7)] = ADM1266_Get_Bit(temp2, k);
				}
			}
		}
	}
	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		for (j = 1; j < 5; j++)
		{
			ADM1266_Status[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] = ADM1266_Status_Decode(ADM1266_VH_Data, 0, j, i);
		}
		for (j = 1; j < 14; j++)
		{
			ADM1266_Status[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] = ADM1266_Status_Decode(ADM1266_VP_Data, 1, j, i);
		}
	}
}

void ADM1266_Print_Telemetry(__u8 ADM1266_NUM, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u8 *ADM1266_Signals_Data, __u16 *ADM1266_Voltages, __u8 *ADM1266_Status, __u16 *ADM1266_Rail_Name, __u16 *ADM1266_Signal_Name, __u8 *ADM1266_System_Data)
{
	__u8 i = 0;
	__u8 j = 0;
	float calc_val = 0;

	printf("Telemetry\n------------------------------------------------------------------------------------------------\n");
	printf("Rails\n------------------------------------------------------------------------------------------------\n");
	for (i = 0; i < ADM1266_NUM; i++)
	{
		for (j = 1; j < 5; j++)
		{
			if (ADM1266_Status[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] == 5 & ADM1266_VH_Data[n21(i, j, 0, 5, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(i, j, 0, 5, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] * pow(2, ADM1266_Expo(ADM1266_VH_Data[n21(i, j, 8, 5, 15)]));
				printf(" - %.3f V - Over Voltage Fault\n", calc_val);
			}
		}
		for (j = 1; j < 14; j++)
		{
			if (ADM1266_Status[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] == 5 & ADM1266_VP_Data[n21(i, j, 0, 14, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(i, j, 0, 14, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] * pow(2, ADM1266_Expo(ADM1266_VP_Data[n21(i, j, 8, 14, 15)]));
				printf(" - %.3f V - Over Voltage Fault\n", calc_val);
			}
		}
	}
	for (i = 0; i < ADM1266_NUM; i++)
	{
		for (j = 1; j < 5; j++)
		{
			if (ADM1266_Status[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] == 4 & ADM1266_VH_Data[n21(i, j, 0, 5, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(i, j, 0, 5, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] * pow(2, ADM1266_Expo(ADM1266_VH_Data[n21(i, j, 8, 5, 15)]));
				printf(" - %.3f V - Under Voltage Fault\n", calc_val);
			}
		}
		for (j = 1; j < 14; j++)
		{
			if (ADM1266_Status[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] == 4 & ADM1266_VP_Data[n21(i, j, 0, 14, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(i, j, 0, 14, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] * pow(2, ADM1266_Expo(ADM1266_VP_Data[n21(i, j, 8, 14, 15)]));
				printf(" - %.3f V - Under Voltage Fault\n", calc_val);
			}
		}
	}
	for (i = 0; i < ADM1266_NUM; i++)
	{
		for (j = 1; j < 5; j++)
		{
			if (ADM1266_Status[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] == 3 & ADM1266_VH_Data[n21(i, j, 0, 5, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(i, j, 0, 5, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] * pow(2, ADM1266_Expo(ADM1266_VH_Data[n21(i, j, 8, 5, 15)]));
				printf(" - %.3f V - Over Voltage Warning\n", calc_val);
			}
		}
		for (j = 1; j < 14; j++)
		{
			if (ADM1266_Status[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] == 3 & ADM1266_VP_Data[n21(i, j, 0, 14, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(i, j, 0, 14, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] * pow(2, ADM1266_Expo(ADM1266_VP_Data[n21(i, j, 8, 14, 15)]));
				printf(" - %.3f V - Over Voltage Warning\n", calc_val);
			}
		}
	}
	for (i = 0; i < ADM1266_NUM; i++)
	{
		for (j = 1; j < 5; j++)
		{
			if (ADM1266_Status[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] == 2 & ADM1266_VH_Data[n21(i, j, 0, 5, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(i, j, 0, 5, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] * pow(2, ADM1266_Expo(ADM1266_VH_Data[n21(i, j, 8, 5, 15)]));
				printf(" - %.3f V - Under Voltage Warning\n", calc_val);
			}
		}
		for (j = 1; j < 14; j++)
		{
			if (ADM1266_Status[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] == 2 & ADM1266_VP_Data[n21(i, j, 0, 14, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(i, j, 0, 14, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] * pow(2, ADM1266_Expo(ADM1266_VP_Data[n21(i, j, 8, 14, 15)]));
				printf(" - %.3f V - Under Voltage Warning\n", calc_val);
			}
		}
	}
	for (i = 0; i < ADM1266_NUM; i++)
	{
		for (j = 1; j < 5; j++)
		{
			if (ADM1266_Status[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] == 0 & ADM1266_VH_Data[n21(i, j, 0, 5, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(i, j, 0, 5, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] * pow(2, ADM1266_Expo(ADM1266_VH_Data[n21(i, j, 8, 5, 15)]));
				printf(" - %.3f V \n", calc_val);
			}
		}
		for (j = 1; j < 14; j++)
		{
			if (ADM1266_Status[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] == 0 & ADM1266_VP_Data[n21(i, j, 0, 14, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(i, j, 0, 14, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] * pow(2, ADM1266_Expo(ADM1266_VP_Data[n21(i, j, 8, 14, 15)]));
				printf(" - %.3f V \n", calc_val);
			}
		}
	}
	for (i = 0; i < ADM1266_NUM; i++)
	{
		for (j = 1; j < 5; j++)
		{
			if (ADM1266_Status[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] == 1 & ADM1266_VH_Data[n21(i, j, 0, 5, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(i, j, 0, 5, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VH_Data[n21(i, j, 9, 5, 15)]] * pow(2, ADM1266_Expo(ADM1266_VH_Data[n21(i, j, 8, 5, 15)]));
				printf(" - %.3f V - Disabled\n", calc_val);
			}
		}
		for (j = 1; j < 14; j++)
		{
			if (ADM1266_Status[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] == 1 & ADM1266_VP_Data[n21(i, j, 0, 14, 15)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(i, j, 0, 14, 15)]);
				calc_val = ADM1266_Voltages[ADM1266_VP_Data[n21(i, j, 9, 14, 15)]] * pow(2, ADM1266_Expo(ADM1266_VP_Data[n21(i, j, 8, 14, 15)]));
				printf(" - %.3f V - Disabled\n", calc_val);
			}
		}
	}
	printf("------------------------------------------------------------------------------------------------\n");
	printf("Signals\n------------------------------------------------------------------------------------------------\n");
	for (i = 0; i < ADM1266_NUM; i++)
	{
		for (j = 0; j < 25; j++)
		{
			if (ADM1266_Signals_Data[n21(i, j, 0, 25, 7)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Signal_Name, ADM1266_Signals_Data[n21(i, j, 0, 25, 7)] - 1);
				printf(" - %d \n", ADM1266_Signals_Data[n21(i, j, 6, 25, 7)]);
			}
		}
	}
	printf("\n------------------------------------------------------------------------------------------------\n");
}

int ADM1266_Expo(__u8 num)
{
	int temp = 0;
	if (num < 16)
		temp = num;
	else
		temp = num - 32;
	return(temp);
}


int n21(int x, int y, int z, int my, int mz)
{
	int val;
	val = (mz*my*x) + (mz*y) + z;
	return val;
}

int ADM1266_Srch_Array(__u8 *ADM1266_datain, __u16 data_length, __u8 srch_element)
{
	__u16 i = 0;
	for (i = 0; i < data_length; i++)
	{
		if (ADM1266_datain[i] == srch_element)
		{
			break;
		}
	}
	return i;
}

void ADM1266_BB_Clear(__u8 ADM1266_Num, __u8 *ADM1266_Address)
{
	for (int i = 0; i < ADM1266_Num; i++)
	{
		__u8 dataout[5] = { 0xDE, 0x02, 0xFE, 0x00 };
		i2c_block_write(ADM1266_Address[i], 4, dataout);
	}

}

void ADM1266_System_Read(__u8 ADM1266_Num, __u8 *ADM1266_Address, __u8 *ADM1266_System_Data)
{
	__u8 ADM1266_datain[129];
	__u16 j, l, k, n, m, sdPtr;

	sdPtr = 0;
	__u8 dataout[5] = { 0xD7, 0x03, 0x80, 0x00, 0x00 };
	i2c_block_write_block_read(ADM1266_Address[0], 5, dataout, 128, ADM1266_datain);

	for (m = 0; m < ADM1266_datain[29] + 1; m++) {
		ADM1266_System_Data[m + sdPtr] = ADM1266_datain[m + 29];
	}
	sdPtr = ADM1266_datain[29] + 2;


	for (int i = 0; i < ADM1266_Num; i++)
	{
		__u16 Data_Length;
		l = 0;
		j = 0;
		k = 0;
		n = 0;
		__u8 dataout[5] = { 0xD7, 0x03, 0x03, 0x00, 0x00 };
		i2c_block_write_block_read(ADM1266_Address[i], 5, dataout, 3, ADM1266_datain);
		Data_Length = ADM1266_datain[1] + (ADM1266_datain[2] * 256);
		j = 128;
		while (j < Data_Length)
		{
			l = j & 0xFF;
			k = (j & 0xFF00) / 256;
			n = Data_Length - j;
			if (n > 128)
			{
				n = 128;
			}
			dataout[0] = 0xD7;
			dataout[1] = 0x03;
			dataout[2] = n;
			dataout[3] = l;
			dataout[4] = k;


			i2c_block_write_block_read(ADM1266_Address[i], 5, dataout, n + 1, ADM1266_datain);
			if (k == 0 && l == 128 && n == 128)
			{
				ADM1266_System_Data[sdPtr] = ADM1266_datain[128];
				sdPtr++;
			}
			else
			{
				for (m = 0; m < 128; m++) {
					ADM1266_System_Data[m + sdPtr] = ADM1266_datain[m + 1];
				}
				if (k == 7 && l == 128 && n == 128)
				{
					sdPtr--;
				}
				sdPtr = sdPtr + 128;
			}
			j = j + 128;
		}


	}
}

void ADM1266_Configuration_Name(__u8 *ADM1266_System_Data)
{
	__u8 i = 0;
	printf("------------------------------------------------------------------------------------------------\nConfiguration Name : ");

	for (i = 0; i < ADM1266_System_Data[0] + 1; i++) {
		printf("%c", ADM1266_System_Data[i + 1]);
	}
	printf("\n------------------------------------------------------------------------------------------------\n");
}

void ADM1266_VLQ_Decode(__u16 index, __u8 *ADM1266_System_Data, __u16 *value, __u16 *Next_Pointer)
{
	__u16 j = 0;
	__u16 i;
	__u16 val;
	i = index;
	val = 0;
	while (ADM1266_System_Data[i] > 127)
	{
		if (j == 0)
		{
			val += (ADM1266_System_Data[i] & 127);
		}
		else
		{
			val += (ADM1266_System_Data[i] & 127) * 128 * j;
		}
		i += 1;
		j += 1;
	}
	if (j == 0)
	{
		val += (ADM1266_System_Data[i] & 127);
	}
	else
	{
		val += (ADM1266_System_Data[i] & 127) * 128 * j;
	}
	*Next_Pointer = i + 1;
	*value = val;

}

void ADM1266_System_Parse(__u8 *ADM1266_System_Data, __u16 *ADM1266_State_Name, __u16 *ADM1266_Rail_Name, __u16 *ADM1266_Signal_Name, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u8 *ADM1266_Signals_Data, __u8 *ADM1266_ADM1266_PDIO_GPIO_Pad, __u8 *ADM1266_ADM1266_VX_Pad)
{
	__u16 next_pointer = 0;
	__u16 segment_length = 0;
	__u16 segment_pointer = 0;
	next_pointer = ADM1266_System_Data[0] + 44;
	// Pad Info
	ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &segment_length, &segment_pointer);

	next_pointer = segment_length + segment_pointer + 1;
	// Rail Info
	ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &segment_length, &segment_pointer);
	ADM1266_Rail_Parse(ADM1266_System_Data, ADM1266_Rail_Name, segment_pointer, segment_length, ADM1266_VH_Data, ADM1266_VP_Data, ADM1266_ADM1266_PDIO_GPIO_Pad, ADM1266_ADM1266_VX_Pad);

	next_pointer = segment_length + segment_pointer + 1;
	// State Info
	ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &segment_length, &segment_pointer);
	ADM1266_State_Parse(ADM1266_System_Data, ADM1266_State_Name, segment_pointer, segment_length);

	next_pointer = segment_length + segment_pointer + 1;
	// Signal Info
	ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &segment_length, &segment_pointer);
	ADM1266_Signal_Parse(ADM1266_System_Data, ADM1266_Signal_Name, segment_pointer, segment_length, ADM1266_Signals_Data, ADM1266_ADM1266_PDIO_GPIO_Pad, ADM1266_ADM1266_VX_Pad);

}

void ADM1266_Rail_Parse(__u8 *ADM1266_System_Data, __u16 *ADM1266_Rail_Name, __u16 Start_Pointer, __u16 Section_Length, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u8 *ADM1266_ADM1266_PDIO_GPIO_Pad, __u8 *ADM1266_ADM1266_VX_Pad)
{
	__u16 next_pointer = 0;
	__u16 rail_length = 0;
	__u16 rail_pointer = 0;
	__u8 PDIO_GPIO_Num = 0;
	__u8 PDIO_GPIO_Type = 0;
	__u8 PDIO_GPIO_Polarity = 0;
	__u8 Dev_id = 0;
	__u8 VX_Num = 0;
	__u8 VX_Type = 0;
	__u8 VX_Dev_id = 0;
	__u8 i = 1;
	next_pointer = Start_Pointer;
	ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &rail_length, &rail_pointer);
	next_pointer = rail_pointer;

	while (next_pointer < (Start_Pointer + Section_Length))
	{
		ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &rail_length, &rail_pointer);
		next_pointer = rail_pointer + rail_length;
		ADM1266_Rail_Name[n21(0, i, 0, 0, 2)] = rail_pointer;
		ADM1266_Rail_Name[n21(0, i, 1, 0, 2)] = next_pointer;
		i++;

		ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &rail_length, &rail_pointer);
		ADM1266_PDIO_GPIO_Global_Index(rail_length, ADM1266_ADM1266_PDIO_GPIO_Pad, &PDIO_GPIO_Num, &PDIO_GPIO_Type, &Dev_id);

		next_pointer = rail_pointer;

		ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &rail_length, &rail_pointer);
		ADM1266_VX_Global_Index(rail_length, ADM1266_ADM1266_VX_Pad, &VX_Num, &VX_Type, &VX_Dev_id);
		next_pointer = rail_pointer;

		ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &rail_length, &rail_pointer);
		next_pointer = rail_pointer;

		ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &rail_length, &rail_pointer);
		next_pointer = rail_pointer;

		ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &rail_length, &rail_pointer);
		next_pointer = rail_pointer;
		PDIO_GPIO_Polarity = rail_length & 0x01;

		if (PDIO_GPIO_Type == 0)
		{
			if (VX_Type == 0)
			{
				ADM1266_VH_Data[n21(VX_Dev_id, VX_Num, 0, 5, 15)] = i - 1;
				ADM1266_VH_Data[n21(VX_Dev_id, VX_Num, 1, 5, 15)] = PDIO_GPIO_Num;
				ADM1266_VH_Data[n21(VX_Dev_id, VX_Num, 2, 5, 15)] = Dev_id;
				ADM1266_VH_Data[n21(VX_Dev_id, VX_Num, 3, 5, 15)] = PDIO_GPIO_Polarity;
			}
			else
			{
				ADM1266_VP_Data[n21(VX_Dev_id, VX_Num, 0, 14, 15)] = i - 1;
				ADM1266_VP_Data[n21(VX_Dev_id, VX_Num, 1, 14, 15)] = PDIO_GPIO_Num;
				ADM1266_VP_Data[n21(VX_Dev_id, VX_Num, 2, 14, 15)] = Dev_id;
				ADM1266_VP_Data[n21(VX_Dev_id, VX_Num, 3, 14, 15)] = PDIO_GPIO_Polarity;
			}
		}

	}

}

void ADM1266_Signal_Parse(__u8 *ADM1266_System_Data, __u16 *ADM1266_Signal_Name, __u16 Start_Pointer, __u16 Section_Length, __u8 *ADM1266_Signals_Data, __u8 *ADM1266_ADM1266_PDIO_GPIO_Pad, __u8 *ADM1266_ADM1266_VX_Pad)
{
	__u16 next_pointer = 0;
	__u16 signal_length = 0;
	__u16 signal_pointer = 0;
	__u8 PDIO_GPIO_Num = 0;
	__u8 PDIO_GPIO_Type = 0;
	__u8 Signal_Direction = 0;
	__u8 Dev_id = 0;
	__u8 i = 0;
	next_pointer = Start_Pointer;
	ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &signal_length, &signal_pointer);
	next_pointer = signal_pointer;

	while (next_pointer < (Start_Pointer + Section_Length))
	{
		ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &signal_length, &signal_pointer);
		next_pointer = signal_pointer + signal_length;
		ADM1266_Signal_Name[n21(0, i, 0, 0, 2)] = signal_pointer;
		ADM1266_Signal_Name[n21(0, i, 1, 0, 2)] = next_pointer;

		ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &signal_length, &signal_pointer);
		ADM1266_PDIO_GPIO_Global_Index(signal_length, ADM1266_ADM1266_PDIO_GPIO_Pad, &PDIO_GPIO_Num, &PDIO_GPIO_Type, &Dev_id);
		next_pointer = signal_pointer;


		ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &signal_length, &signal_pointer);
		Signal_Direction = signal_length;
		next_pointer = signal_pointer;

		ADM1266_Signals_Data[n21(Dev_id, i, 0, 25, 7)] = i + 1;
		ADM1266_Signals_Data[n21(Dev_id, i, 1, 25, 7)] = PDIO_GPIO_Num;
		ADM1266_Signals_Data[n21(Dev_id, i, 2, 25, 7)] = PDIO_GPIO_Type;
		ADM1266_Signals_Data[n21(Dev_id, i, 3, 25, 7)] = Signal_Direction;
		i++;
	}

}

void ADM1266_PDIO_GPIO_Global_Index(__u16 ADM1266_datain, __u8 *ADM1266_ADM1266_PDIO_GPIO_Pad, __u8 *PDIO_GPIO_Num, __u8 *PDIO_GPIO_Type, __u8 *Dev_id)
{
	__u8 temp;
	__u8 temp2 = 0;
	__u8 temp3 = 0;

	temp = *PDIO_GPIO_Num;

	if (ADM1266_datain < 256)
	{
		temp = ADM1266_Srch_Array(ADM1266_ADM1266_PDIO_GPIO_Pad, 26, ADM1266_datain);
		temp2 = 0;
	}
	else
	{
		temp = ADM1266_Srch_Array(ADM1266_ADM1266_PDIO_GPIO_Pad, 26, (ADM1266_datain & 0xFF));
		temp2 = (ADM1266_datain & 0xFF00) / 256;
	}
	temp3 = 0;
	if (temp > 16)
	{
		temp = temp - 16;
		temp3 = 1;
	}
	*PDIO_GPIO_Num = temp;
	*Dev_id = temp2;
	*PDIO_GPIO_Type = temp3;
}

void ADM1266_VX_Global_Index(__u16 ADM1266_datain, __u8 *ADM1266_ADM1266_VX_Pad, __u8 *VX_Num, __u8 *VX_Type, __u8 *Dev_id)
{
	__u8 temp;
	__u8 temp2 = 0;
	__u8 temp3 = 0;
	temp = *VX_Num;

	if (ADM1266_datain < 256)
	{
		temp = ADM1266_Srch_Array(ADM1266_ADM1266_VX_Pad, 18, ADM1266_datain);
		temp2 = 0;
	}
	else
	{
		temp = ADM1266_Srch_Array(ADM1266_ADM1266_VX_Pad, 18, (ADM1266_datain & 0xFF));
		temp2 = (ADM1266_datain & 0xFF00) / 256;
	}
	temp3 = 0;
	if (temp > 4)
	{
		temp = temp - 4;
		temp3 = 1;
	}
	*VX_Num = temp;
	*Dev_id = temp2;
	*VX_Type = temp3;
}

void ADM1266_State_Parse(__u8 *ADM1266_System_Data, __u16 *ADM1266_State_Name, __u16 Start_Pointer, __u16 Section_Length)
{
	__u16 next_pointer = 0;
	__u16 name_length = 0;
	__u16 name_pointer = 0;
	__u8 i = 0;

	next_pointer = Start_Pointer;
	ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &name_length, &name_pointer);
	next_pointer = name_pointer;

	while (next_pointer < (Start_Pointer + Section_Length))
	{
		ADM1266_VLQ_Decode(next_pointer, ADM1266_System_Data, &name_length, &name_pointer);
		next_pointer = name_pointer + name_length;

		ADM1266_State_Name[n21(0, i, 0, 100, 2)] = name_pointer;
		ADM1266_State_Name[n21(0, i, 1, 100, 2)] = next_pointer;

		//printf("%d,%d\n", ADM1266_State_Name[n21(0, i, 0, 100, 2)], ADM1266_State_Name[n21(0, i, 1, 100, 2)]);
		//printf("%d,%d\n", ADM1266_State_Name[0], ADM1266_State_Name[1]);

		i++;
	}
}

void ADM1266_Get_Name(__u8 *ADM1266_System_Data, __u16 *Name, __u16 index)
{
	__u16 i = 0;
	__u16 start = 0;
	__u16 end = 0;

	start = Name[n21(0, index, 0, 100, 2)];
	end = Name[n21(0, index, 1, 100, 2)];


	for (i = start; i < end; i++) {
		printf("%c", ADM1266_System_Data[i]);
	}

}

void ADM1266_Get_Num_Records(__u8 *ADM1266_Address, __u16 *ADM1266_Record_Index, __u16 *ADM1266_Num_Records)
{
	__u8 ADM1266_datain[5];
	__u8 dataout[1] = { 0xE6 };
	i2c_block_write_block_read(ADM1266_Address[0], 1, dataout, 5, ADM1266_datain);
	*ADM1266_Record_Index = ADM1266_datain[3];
	*ADM1266_Num_Records = ADM1266_datain[4];
}

void ADM1266_Get_BB_Raw_Data(__u8 ADM1266_Num, __u8 *ADM1266_Address, __u8 index, __u16 ADM1266_Record_Index, __u16 ADM1266_Num_Records, __u8 *ADM1266_BB_Data)
{
	__u8 ADM1266_datain[64];
	__s8 temp = 0;
	__u8 dataout[3] = { 0xDE , 0x01, 0x00 };
	__u8 m = 0;
	temp = ADM1266_Record_Index + index - ADM1266_Num_Records;
	if (temp < 0)
	{
		temp += 32;
	}

	for (__u8 i = 0; i < ADM1266_Num; i++)
	{
		dataout[2] = temp;
		i2c_block_write_block_read(ADM1266_Address[i], 3, dataout, 64, ADM1266_datain);
		for (m = 0; m < 64; m++) {
			ADM1266_BB_Data[n21(0, i, m, ADM1266_Num, 64)] = ADM1266_datain[m];
			//printf("%d - %d , ",m-1, ADM1266_BB_Data[n21(0, i, m, ADM1266_Num, 64)]);
		}

	}
}

void ADM1266_BB_Parse(__u8 ADM1266_Num, __u8 *ADM1266_BB_Data, __u8 *ADM1266_System_Data, __u16 *ADM1266_State_Name, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u8 *ADM1266_Signals_Data, __u16 *ADM1266_Rail_Name, __u16 *ADM1266_Signal_Name)
{
	__u8 j = 0;
	__u8 k = 0;
	__u8 l = 0;
	__u8 m = 0;
	__u8 time_data[6] = { "" };
	__u16 temp = 0;
	__u16 temp2 = 0;
	__u16 temp3 = 0;
	__u16 temp4 = 0;
	printf("Summary\n------------------------------------------------------------------------------------------------\n");
	printf("Record ID : %d\n", ADM1266_BB_Data[n21(0, 0, 1, ADM1266_Num, 64)] + (ADM1266_BB_Data[n21(0, 0, 2, ADM1266_Num, 64)] * 256));
	printf("Power-up Counter : %d\n", ADM1266_BB_Data[n21(0, 0, 23, ADM1266_Num, 64)] + (ADM1266_BB_Data[n21(0, 0, 24, ADM1266_Num, 64)] * 256));
	printf("Trigger Source : Enable Blackbox[%d] in '", ADM1266_BB_Data[n21(0, 0, 4, ADM1266_Num, 64)]);
	ADM1266_Get_Name(ADM1266_System_Data, ADM1266_State_Name, ADM1266_BB_Data[n21(0, 0, 7, ADM1266_Num, 64)] + (ADM1266_BB_Data[n21(0, 0, 8, ADM1266_Num, 64)] * 256) - 1);
	printf("' state \nPrevious State : ");
	ADM1266_Get_Name(ADM1266_System_Data, ADM1266_State_Name, ADM1266_BB_Data[n21(0, 0, 9, ADM1266_Num, 64)] + (ADM1266_BB_Data[n21(0, 0, 10, ADM1266_Num, 64)] * 256) - 1);
	printf("\n");
	for (j = 0; j < 6; j++)
	{
		time_data[j] = ADM1266_BB_Data[n21(0, 0, j + 25, ADM1266_Num, 64)];
	}
	ADM1266_RTS(time_data);
	printf("------------------------------------------------------------------------------------------------\n");

	for (j = 0; j < ADM1266_Num; j++)
	{

		for (k = 0; k < 4; k++)
		{
			ADM1266_VH_Data[n21(j, k + 1, 4, 5, 15)] = ADM1266_Get_Bit(ADM1266_BB_Data[n21(0, j, 6, ADM1266_Num, 64)], k);
			ADM1266_VH_Data[n21(j, k + 1, 5, 5, 15)] = ADM1266_Get_Bit(ADM1266_BB_Data[n21(0, j, 6, ADM1266_Num, 64)], k + 4);
		}
		for (k = 0; k < 8; k++)
		{
			ADM1266_VP_Data[n21(j, k + 1, 4, 14, 15)] = ADM1266_Get_Bit(ADM1266_BB_Data[n21(0, j, 11, ADM1266_Num, 64)], k);
			ADM1266_VP_Data[n21(j, k + 1, 5, 14, 15)] = ADM1266_Get_Bit(ADM1266_BB_Data[n21(0, j, 13, ADM1266_Num, 64)], k);
		}
		for (k = 0; k < 6; k++)
		{
			ADM1266_VP_Data[n21(j, k + 9, 4, 14, 15)] = ADM1266_Get_Bit(ADM1266_BB_Data[n21(0, j, 12, ADM1266_Num, 64)], k);
			ADM1266_VP_Data[n21(j, k + 9, 5, 14, 15)] = ADM1266_Get_Bit(ADM1266_BB_Data[n21(0, j, 14, ADM1266_Num, 64)], k);
		}
		temp = (ADM1266_BB_Data[n21(0, j, 22, ADM1266_Num, 64)] * 256) + ADM1266_BB_Data[n21(0, j, 21, ADM1266_Num, 64)];
		temp2 = (ADM1266_BB_Data[n21(0, j, 20, ADM1266_Num, 64)] * 256) + ADM1266_BB_Data[n21(0, j, 19, ADM1266_Num, 64)];
		temp3 = (ADM1266_BB_Data[n21(0, j, 16, ADM1266_Num, 64)] * 256) + ADM1266_BB_Data[n21(0, j, 15, ADM1266_Num, 64)];
		temp3 = ADM1266_GPIO_Map(temp3);
		temp4 = (ADM1266_BB_Data[n21(0, j, 18, ADM1266_Num, 64)] * 256) + ADM1266_BB_Data[n21(0, j, 17, ADM1266_Num, 64)];
		temp4 = ADM1266_GPIO_Map(temp4);
		for (k = 0; k < 16; k++)
		{
			for (l = 0; l < ADM1266_Num; l++)
			{
				for (m = 1; m < 5; m++)
				{
					if ((ADM1266_VH_Data[n21(l, m, 1, 5, 15)] == k + 1) && (ADM1266_VH_Data[n21(l, m, 2, 5, 15)] == j))
					{
						ADM1266_VH_Data[n21(l, m, 6, 5, 15)] = ADM1266_Get_Bit(temp, k);
					}
				}
				for (m = 1; m < 14; m++)
				{
					if ((ADM1266_VP_Data[n21(l, m, 1, 14, 15)] == k + 1) && (ADM1266_VP_Data[n21(l, m, 2, 14, 15)] == j))
					{
						ADM1266_VP_Data[n21(l, m, 6, 14, 15)] = ADM1266_Get_Bit(temp, k);

					}
				}
			}
			for (m = 0; m < 25; m++)
			{
				if ((ADM1266_Signals_Data[n21(j, m, 2, 25, 7)] == 1) && (ADM1266_Signals_Data[n21(j, m, 1, 25, 7)] == k + 1))
				{
					ADM1266_Signals_Data[n21(j, m, 5, 25, 7)] = ADM1266_Get_Bit(temp, k);
					ADM1266_Signals_Data[n21(j, m, 4, 25, 7)] = ADM1266_Get_Bit(temp2, k);
				}
			}
		}
		for (k = 0; k < 10; k++)
		{
			for (m = 0; m < 25; m++)
			{
				if ((ADM1266_Signals_Data[n21(j, m, 2, 25, 7)] == 1) && (ADM1266_Signals_Data[n21(j, m, 1, 25, 7)] == k + 1))
				{
					ADM1266_Signals_Data[n21(j, m, 4, 25, 7)] = ADM1266_Get_Bit(temp3, k);
					ADM1266_Signals_Data[n21(j, m, 5, 25, 7)] = ADM1266_Get_Bit(temp4, k);
				}
			}
		}

	}
	printf("Rails\n------------------------------------------------------------------------------------------------\n");
	ADM1266_Print_OV(ADM1266_Num, ADM1266_System_Data, ADM1266_VH_Data, ADM1266_VP_Data, ADM1266_Rail_Name);
	printf("\n");
	ADM1266_Print_UV(ADM1266_Num, ADM1266_System_Data, ADM1266_VH_Data, ADM1266_VP_Data, ADM1266_Rail_Name);
	printf("\n");
	ADM1266_Print_Normal(ADM1266_Num, ADM1266_System_Data, ADM1266_VH_Data, ADM1266_VP_Data, ADM1266_Rail_Name);
	printf("\n");
	ADM1266_Print_Disabled(ADM1266_Num, ADM1266_System_Data, ADM1266_VH_Data, ADM1266_VP_Data, ADM1266_Rail_Name);
	printf("------------------------------------------------------------------------------------------------\n");
	printf("Signals\n------------------------------------------------------------------------------------------------\n");
	for (j = 0; j < ADM1266_Num; j++)
	{
		for (k = 0; k < 25; k++)
		{
			if (ADM1266_Signals_Data[n21(j, k, 0, 25, 7)] != 0)
			{
				ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Signal_Name, ADM1266_Signals_Data[n21(j, k, 0, 25, 7)] - 1);
				printf(" - Input Value : %d - Output Value : %d\n", ADM1266_Signals_Data[n21(j, k, 4, 25, 7)], ADM1266_Signals_Data[n21(j, k, 5, 25, 7)]);
			}
		}
	}
	printf("------------------------------------------------------------------------------------------------\n");

}

void ADM1266_Print_UV(__u8 ADM1266_Num, __u8 *ADM1266_System_Data, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u16 *ADM1266_Rail_Name)
{
	__u8 j = 0;
	__u8 k = 0;

	for (j = 0; j < ADM1266_Num; j++)
	{
		for (k = 1; k < 5; k++)
		{
			if (ADM1266_VH_Data[n21(j, k, 0, 5, 15)] != 0)
			{
				if (ADM1266_VH_Data[n21(j, k, 1, 5, 15)] == 0)
				{
					if (ADM1266_VH_Data[n21(j, k, 5, 5, 15)] == 1)
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(j, k, 0, 5, 15)]);
						printf(" - UV\n");
					}
				}
				else
				{
					if ((ADM1266_VH_Data[n21(j, k, 5, 5, 15)] == 1) && (ADM1266_VH_Data[n21(j, k, 3, 5, 15)] == ADM1266_VH_Data[n21(j, k, 6, 5, 15)]))
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(j, k, 0, 5, 15)]);
						printf(" - UV\n");
					}
				}

			}
		}
		for (k = 1; k < 14; k++)
		{
			if (ADM1266_VP_Data[n21(j, k, 0, 14, 15)] != 0)
			{
				if (ADM1266_VP_Data[n21(j, k, 1, 14, 15)] == 0)
				{
					if (ADM1266_VP_Data[n21(j, k, 5, 14, 15)] == 1)
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(j, k, 0, 14, 15)]);
						printf(" - UV\n");
					}
				}
				else
				{
					if ((ADM1266_VP_Data[n21(j, k, 5, 14, 15)] == 1) && (ADM1266_VP_Data[n21(j, k, 3, 14, 15)] == ADM1266_VP_Data[n21(j, k, 6, 14, 15)]))
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(j, k, 0, 14, 15)]);
						printf(" - UV\n");
					}
				}

			}
		}
	}
}

void ADM1266_Print_OV(__u8 ADM1266_Num, __u8 *ADM1266_System_Data, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u16 *ADM1266_Rail_Name)
{
	__u8 j = 0;
	__u8 k = 0;

	for (j = 0; j < ADM1266_Num; j++)
	{
		for (k = 1; k < 5; k++)
		{
			if (ADM1266_VH_Data[n21(j, k, 0, 5, 15)] != 0)
			{
				if (ADM1266_VH_Data[n21(j, k, 1, 5, 15)] == 0)
				{
					if (ADM1266_VH_Data[n21(j, k, 4, 5, 15)] == 1)
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(j, k, 0, 5, 15)]);
						printf(" - OV\n");
					}
				}
				else
				{
					if ((ADM1266_VH_Data[n21(j, k, 4, 5, 15)] == 1) && (ADM1266_VH_Data[n21(j, k, 3, 5, 15)] == ADM1266_VH_Data[n21(j, k, 6, 5, 15)]))
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(j, k, 0, 5, 15)]);
						printf(" - OV\n");
					}
				}

			}
		}
		for (k = 1; k < 14; k++)
		{
			if (ADM1266_VP_Data[n21(j, k, 0, 14, 15)] != 0)
			{
				if (ADM1266_VP_Data[n21(j, k, 1, 14, 15)] == 0)
				{
					if (ADM1266_VP_Data[n21(j, k, 4, 14, 15)] == 1)
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(j, k, 0, 14, 15)]);
						printf(" - OV\n");
					}
				}
				else
				{
					if ((ADM1266_VP_Data[n21(j, k, 4, 14, 15)] == 1) && (ADM1266_VP_Data[n21(j, k, 3, 14, 15)] == ADM1266_VP_Data[n21(j, k, 6, 14, 15)]))
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(j, k, 0, 14, 15)]);
						printf(" - OV\n");
					}
				}

			}
		}
	}
}

void ADM1266_Print_Normal(__u8 ADM1266_Num, __u8 *ADM1266_System_Data, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u16 *ADM1266_Rail_Name)
{
	__u8 j = 0;
	__u8 k = 0;

	for (j = 0; j < ADM1266_Num; j++)
	{
		for (k = 1; k < 5; k++)
		{
			if (ADM1266_VH_Data[n21(j, k, 0, 5, 15)] != 0)
			{
				if (ADM1266_VH_Data[n21(j, k, 1, 5, 15)] == 0)
				{
					if ((ADM1266_VH_Data[n21(j, k, 4, 5, 15)] == 0) && (ADM1266_VH_Data[n21(j, k, 5, 5, 15)] == 0))
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(j, k, 0, 5, 15)]);
						printf(" - Normal\n");
					}
				}
				else
				{
					if (((ADM1266_VH_Data[n21(j, k, 4, 5, 15)] == 0) && (ADM1266_VH_Data[n21(j, k, 5, 5, 15)] == 0)) && (ADM1266_VH_Data[n21(j, k, 3, 5, 15)] == ADM1266_VH_Data[n21(j, k, 6, 5, 15)]))
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(j, k, 0, 5, 15)]);
						printf(" - Normal\n");
					}
				}

			}
		}
		for (k = 1; k < 14; k++)
		{
			if (ADM1266_VP_Data[n21(j, k, 0, 14, 15)] != 0)
			{
				if (ADM1266_VP_Data[n21(j, k, 1, 14, 15)] == 0)
				{
					if ((ADM1266_VP_Data[n21(j, k, 4, 14, 15)] == 0) && (ADM1266_VP_Data[n21(j, k, 5, 14, 15)] == 0))
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(j, k, 0, 14, 15)]);
						printf(" - Normal\n");
					}
				}
				else
				{
					if (((ADM1266_VP_Data[n21(j, k, 4, 14, 15)] == 0) && (ADM1266_VP_Data[n21(j, k, 5, 14, 15)] == 0)) && (ADM1266_VP_Data[n21(j, k, 3, 14, 15)] == ADM1266_VP_Data[n21(j, k, 6, 14, 15)]))
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(j, k, 0, 14, 15)]);
						printf(" - Normal\n");
					}
				}

			}
		}
	}
}

void ADM1266_Print_Disabled(__u8 ADM1266_Num, __u8 *ADM1266_System_Data, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u16 *ADM1266_Rail_Name)
{
	__u8 j = 0;
	__u8 k = 0;

	for (j = 0; j < ADM1266_Num; j++)
	{
		for (k = 1; k < 5; k++)
		{
			if (ADM1266_VH_Data[n21(j, k, 0, 5, 15)] != 0)
			{
				if (ADM1266_VH_Data[n21(j, k, 1, 5, 15)] != 0)
				{
					if (ADM1266_VH_Data[n21(j, k, 3, 5, 15)] != ADM1266_VH_Data[n21(j, k, 6, 5, 15)])
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VH_Data[n21(j, k, 0, 5, 15)]);
						printf(" - Disabled\n");
					}
				}
			}
		}
		for (k = 1; k < 14; k++)
		{
			if (ADM1266_VP_Data[n21(j, k, 0, 14, 15)] != 0)
			{
				if (ADM1266_VP_Data[n21(j, k, 1, 14, 15)] != 0)
				{
					if (ADM1266_VP_Data[n21(j, k, 3, 14, 15)] != ADM1266_VP_Data[n21(j, k, 6, 14, 15)])
					{
						ADM1266_Get_Name(ADM1266_System_Data, ADM1266_Rail_Name, ADM1266_VP_Data[n21(j, k, 0, 14, 15)]);
						printf(" - Disabled\n");
					}
				}

			}
		}
	}
}

int ADM1266_GPIO_Map(__u16 ADM1266_datain)
{
	int temp = 0;
	temp = temp + ADM1266_Get_Bit(ADM1266_datain, 0);
	temp = temp + (ADM1266_Get_Bit(ADM1266_datain, 1) * 2);
	temp = temp + (ADM1266_Get_Bit(ADM1266_datain, 2) * 4);
	temp = temp + (ADM1266_Get_Bit(ADM1266_datain, 8) * 8);
	temp = temp + (ADM1266_Get_Bit(ADM1266_datain, 9) * 16);
	temp = temp + (ADM1266_Get_Bit(ADM1266_datain, 10) * 32);
	temp = temp + (ADM1266_Get_Bit(ADM1266_datain, 11) * 64);
	temp = temp + (ADM1266_Get_Bit(ADM1266_datain, 6) * 128);
	temp = temp + (ADM1266_Get_Bit(ADM1266_datain, 7) * 256);
	return temp;
}

__u16 ADM1266_Get_Bit(__u16 data, __u8 bit)
{
	__u16 val;
	val = pow(2, bit);
	val = (data & val) / val;
	return val;
}

void ADM1266_RTS(__u8 *ADM1266_datain)
{
	time_t calc_time = 0;
	long temp = 0;

	for (__u8 i = 0; i < 4; i++)
	{
		temp = pow(2, 8 * i);
		calc_time = calc_time + (ADM1266_datain[i + 2] * temp);
	}


	if (calc_time > 315360000)
	{
		struct tm *ptm;
		ptm = localtime(&calc_time);
		printf("Time(GMT) : %s", asctime(ptm));
	}
	else
	{
		__u16 days = 0;
		__u8 hours = 0;
		__u8 mins = 0;
		__u8 secs = 0;

		days = calc_time / (24 * 60 * 60);
		calc_time = calc_time - (days * 24 * 60 * 60);
		hours = calc_time / (60 * 60);
		calc_time = calc_time - (hours * 60 * 60);
		mins = calc_time / (60);
		secs = calc_time - (mins * 60);

		printf("Time : %d Day(s) %d Hour(s) %d Minute(s) %d Second(s)\n", days, hours, mins, secs);

	}

}


void ADM1266_Delay(__u32 ADM1266_milli_seconds)
{
        
    ADM1266_milli_seconds = ADM1266_milli_seconds*1000;
    // storing start time
    clock_t start_time = clock();
     
    // looping till required time is not acheived
    while (clock() < start_time + ADM1266_milli_seconds);
 
}

void ADM1266_FW_Boot_Rev(__u8 ADM1266_Address, __u8 *ADM1266_datain)
{   
    __u8 dataout[1];
    dataout[0] = 0xAE;
    i2c_block_write_block_read(ADM1266_Address, 0x01, dataout, 9, ADM1266_datain);  
}

void ADM1266_Pause_Sequence(__u8 ADM1266_Address, __u8 ADM1266_Reset_Sequence)
{
    __u8 dataout[3] = { 0xD8, 0x03, 0x00 };
    if (ADM1266_Reset_Sequence == 1)
    {
        dataout[0] = 0xD8;
        dataout[1] = 0x11;
        dataout[2] = 0x00;
    }
 
    i2c_block_write(ADM1266_Address, 0x03, dataout);
}
 
void ADM1266_Unlock(__u8 ADM1266_Address)
{
    __u8 dataout[19] = { 0xFD, 0x11, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x02};
    i2c_block_write(ADM1266_Address, 19, dataout);
    ADM1266_Delay(10);
    i2c_block_write(ADM1266_Address, 19, dataout);    
    ADM1266_Delay(10);
}

void ADM1266_Jump_to_IAP(__u8 ADM1266_Address)
{
    __u8 dataout[4] = { 0xFC, 0x02, 0x00 , 0x00};
    i2c_block_write(ADM1266_Address, 4, dataout);
    ADM1266_Delay(1000);    
}
 
void ADM1266_System_Reset(__u8 ADM1266_Address)
{
    __u8 dataout[3] = { 0xD8, 0x04, 0x00};
    i2c_block_write(ADM1266_Address, 3, dataout);
    ADM1266_Delay(1000);
}
 
void ADM1266_Memory_Pointer_Main(__u8 ADM1266_Address)
{
    __u8 dataout[3] = { 0xFA, 0x01, 0x00 };
    i2c_block_write(ADM1266_Address, 3, dataout);
}
 
void ADM1266_Start_Sequence(__u8 ADM1266_Address)
{
    __u8 dataout[3] = { 0xD8, 0x00, 0x00 };
    i2c_block_write(ADM1266_Address, 3, dataout);
    ADM1266_Delay(500);
}
 
void ADM1266_Refresh_Flash(__u8 ADM1266_Address)
{
    __u8 dataout[3] = { 0xF5, 0x01, 0x02 };
    i2c_block_write(ADM1266_Address, 3, dataout);
    ADM1266_Delay(10000);
}

void ADM1266_Refresh_Flash_no_Delay(__u8 ADM1266_Address)
{
    __u8 dataout[3] = { 0xF5, 0x01, 0x02 };
    i2c_block_write(ADM1266_Address, 3, dataout);
}
 
void ADM1266_Recalculate_CRC(__u8 ADM1266_Address)
{
    __u8 dataout[3] = { 0xF9, 0x01, 0x00 };
    i2c_block_write(ADM1266_Address, 3, dataout);
    ADM1266_Delay(600);
}
 

void ADM1266_Margin_All_Percent(__u8 ADM1266_NUM, struct ADM1266_dac_data *ADM1266_DAC_data, float ADM1266_Margin_Percent)
{
	for (__u8 dac_counter = 0; dac_counter < (9 * ADM1266_NUM); dac_counter++)
	{
		if (ADM1266_DAC_data[dac_counter].input_channel > 0)
		{
			ADM1266_Margin_Single_Percent(ADM1266_DAC_data[dac_counter].ADM1266_Address, ADM1266_DAC_data[dac_counter].input_channel - 1, ADM1266_Margin_Percent);
		}		
	}
}


void ADM1266_Margin_Single_Percent(__u8 ADM1266_Address, __u8 ADM1266_Pin, float ADM1266_Margin_Percent)
{
	//Set page to respective input channel
	__u8 dataout[3] = {0x00};
	__u8 ADM1266_datain[2];
	dataout[1] = ADM1266_Pin;
	i2c_block_write(ADM1266_Address, 2, dataout);

	//Read back exp and ment
	dataout[0] = 0x20;
	i2c_block_write_block_read(ADM1266_Address, 1, dataout, 1, ADM1266_datain);
	__u8 exp = ADM1266_datain[0];
	dataout[0] = 0x21;
	i2c_block_write_block_read(ADM1266_Address, 1, dataout, 2, ADM1266_datain);

	//Calculate nominal Value
	__u16 ment = ADM1266_datain[0] + (ADM1266_datain[1]<<8);
	float nominal_value = ADM1266_Ment_Exp_to_Val(exp, ment);

	//Calculate ment for margin high
	float margin_high = nominal_value*((100 + ADM1266_Margin_Percent) / 100);
	ment = ADM1266_Val_to_Ment(margin_high, exp);
	dataout[1] = ment & 0xff;
	dataout[2] = ment >> 8;
	dataout[0] = 0x25;
	i2c_block_write(ADM1266_Address, 3, dataout);

	//Calculate ment for margin low
	float margin_low = nominal_value*((100 - ADM1266_Margin_Percent) / 100);
	ment = ADM1266_Val_to_Ment(margin_low, exp);
	dataout[1] = ment & 0xff;
	dataout[2] = ment >> 8;
	dataout[0] = 0x26;
	i2c_block_write(ADM1266_Address, 3, dataout);

}

float ADM1266_Ment_Exp_to_Val(__u8 ADM1266_exp, __u16 ADM1266_ment)
{
	float value;
	
	value = ADM1266_Expo(ADM1266_exp);
	value = ADM1266_ment * pow(2, value);
	
	return value;
}

__u16 ADM1266_Val_to_Ment(float ADM1266_val, __u8 ADM1266_exp)
{
	__u16 value;
	value = ADM1266_val / pow(2, ADM1266_Expo(ADM1266_exp));
	
	return value;
}

void ADM1266_Margin_All(__u8 *ADM1266_Address, __u8 ADM1266_NUM, __u8 ADM1266_Margin_Type)
{
    __u8 dataout[2] = {0x00, 0xFF};

    for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
    {
        i2c_block_write(ADM1266_Address[loop], 2, dataout);
    }

    dataout[0] = 0x01;

    if (ADM1266_Margin_Type == 1)
        dataout[1] = 0xA4;
    else if (ADM1266_Margin_Type == 2)
        dataout[1] = 0x94;
    else if (ADM1266_Margin_Type == 3)
        dataout[1] = 0x84;
    else if (ADM1266_Margin_Type == 4)
        dataout[1] = 0x44;

    for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
    {
        i2c_block_write(ADM1266_Address[loop], 2, dataout);
    }

    printf("Margined all rails.");        
}

void ADM1266_Margin_Single_Input(__u8 ADM1266_Address, __u8 ADM1266_Pin_Index, __u8 ADM1266_Margin_Type){
    __u8 dataout[3];

    dataout[0] = 0x00;
    dataout[1] = ADM1266_Pin_Index-1; //Because DAC config input index is +1, exmaple VH1 is 1 instead of 0.

    i2c_block_write(ADM1266_Address, 2, dataout);

    dataout[0] = 0x01;

    if (ADM1266_Margin_Type == 1)
    {
        dataout[1] = 0xA4;
        printf("Rail is margined high.\n");
    }
    else if (ADM1266_Margin_Type == 2)
    {
        dataout[1] = 0x94;
        printf("Rail is margined low.\n");
    }
    else if (ADM1266_Margin_Type == 3)
    {
        dataout[1] = 0x84;
        printf("Rail is margined Vout.\n");
    }
    else if (ADM1266_Margin_Type == 4)
    {
        dataout[1] = 0x44;            
        printf("Margining is disabled.\n");
    }

    i2c_block_write(ADM1266_Address, 2, dataout);

}

void ADM1266_Margin_Single(__u8 ADM1266_Address, char *ADM1266_Pin_Name, __u8 ADM1266_Margin_Type){
    __u8 pin_number = 0xff;
    __u8 i = 0;
    __u8 ADM1266_datain[3];
    __u8 dataout[3];
    __u16 ADM1266_DAC_Mapping;
    __u8 dac_check = 0;


    while(ADM1266_Pin_Name[i]) {
        ADM1266_Pin_Name[i] = toupper(ADM1266_Pin_Name[i]);        
        i++;
    }    

    if (strcmp(ADM1266_Pin_Name,"VH1") == 0)
        pin_number = 0x00;
    else if (strcmp(ADM1266_Pin_Name,"VH2") == 0)
        pin_number = 0x01;
    else if (strcmp(ADM1266_Pin_Name,"VH3") == 0)
        pin_number = 0x02;
    else if (strcmp(ADM1266_Pin_Name,"VH4") == 0)
        pin_number = 0x03;
    else if (strcmp(ADM1266_Pin_Name,"VP1") == 0)
        pin_number = 0x04;
    else if (strcmp(ADM1266_Pin_Name,"VP2") == 0)
        pin_number = 0x05;
    else if (strcmp(ADM1266_Pin_Name,"VP3") == 0)
        pin_number = 0x06;
    else if (strcmp(ADM1266_Pin_Name,"VP4") == 0)
        pin_number = 0x07;
    else if (strcmp(ADM1266_Pin_Name,"VP5") == 0)
        pin_number = 0x08;
    else if (strcmp(ADM1266_Pin_Name,"VP6") == 0)
        pin_number = 0x09;
    else if (strcmp(ADM1266_Pin_Name,"VP7") == 0)
        pin_number = 0xa;
    else if (strcmp(ADM1266_Pin_Name,"VP8") == 0)
        pin_number = 0x0b;
    else if (strcmp(ADM1266_Pin_Name,"VP9") == 0)
        pin_number = 0x0c;
    else if (strcmp(ADM1266_Pin_Name,"VP10") == 0)
        pin_number = 0x0d;
    else if (strcmp(ADM1266_Pin_Name,"VP11") == 0)
        pin_number = 0x0e;
    else if (strcmp(ADM1266_Pin_Name,"VP12") == 0)
        pin_number = 0x0f;
    else if (strcmp(ADM1266_Pin_Name,"VP13") == 0)
        pin_number = 0x10;
    else
        pin_number = 0xFF;


    if (pin_number == 0xFF)
        printf("\nPlease enter a valid pin number.");
    else
    {
        dataout[0] = 0xD5;
        dataout[1] = 0x01;
        for (__u8 dac_index = 0; dac_index < 9; dac_index++)
        {
            dataout[2] = dac_index;
            i2c_block_write_block_read(ADM1266_Address, 3, dataout, 3, ADM1266_datain);

            ADM1266_DAC_Mapping = ADM1266_datain[1] + (ADM1266_datain[2] << 8);
            ADM1266_DAC_Mapping = (ADM1266_DAC_Mapping >> 6) & 0x1F;


            if (ADM1266_DAC_Mapping == (pin_number+1))
            {
                dac_check = 1;
                break;
            }
            else
                dac_check = 0;
        }

    if (dac_check == 1)
    {
        dataout[0] = 0x00;
        dataout[1] = pin_number;

        i2c_block_write(ADM1266_Address, 2, dataout);

        dataout[0] = 0x01;

        if (ADM1266_Margin_Type == 1)
            dataout[1] = 0xA4;
        else if (ADM1266_Margin_Type == 2)
            dataout[1] = 0x94;
        else if (ADM1266_Margin_Type == 3)
            dataout[1] = 0x84;
        else if (ADM1266_Margin_Type == 4)
            dataout[1] = 0x44;            
        

        i2c_block_write(ADM1266_Address, 2, dataout);

        printf("\n%s is margined.", ADM1266_Pin_Name);
    }
    
    else
        printf("Input channel is not closed loop margined by any DAC");  

    }         
               
}


void ADM1266_DAC_Mapping(__u8 *ADM1266_Address, __u8 ADM1266_NUM, struct ADM1266_dac_data *ADM1266_DAC_data)
{
    __u8 ADM1266_datain[3];
    __u8 dataout[3];
    __u16 ADM1266_DAC_Mapping;
    __u8 counter_multi = 1;

    dataout[0] = 0xD5;
    dataout[1] = 0x01;

    for (__u8 device_counter = 0; device_counter < ADM1266_NUM; device_counter++)
    {
        counter_multi = 9*device_counter;
        
        for (__u8 dac_counter = 0; dac_counter < 9; dac_counter++)
        {
            dataout[2] = dac_counter;
            i2c_block_write_block_read(ADM1266_Address[device_counter], 3, dataout, 3, ADM1266_datain);
            ADM1266_DAC_Mapping = ADM1266_datain[1] + (ADM1266_datain[2] << 8);         
            ADM1266_DAC_data[(dac_counter+counter_multi)].input_channel = (ADM1266_DAC_Mapping >> 6) & 0x1F;
            ADM1266_DAC_data[(dac_counter+counter_multi)].ADM1266_Address = ADM1266_Address[device_counter];            
			ADM1266_DAC_data[(dac_counter + counter_multi)].device_index = device_counter;
        }        
    }
}


void ADM1266_Program_Firmware(__u8 *ADM1266_Address, __u8 ADM1266_NUM, FILE *ADM1266_Ptr_File)
{
	
    for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
    {        
        ADM1266_Pause_Sequence(ADM1266_Address[loop],1);
        ADM1266_Unlock(ADM1266_Address[loop]);
        ADM1266_Jump_to_IAP(ADM1266_Address[loop]);        
    }

	if (ADM1266_Get_Part_Locked_System(ADM1266_NUM, ADM1266_Address) == 0)
	{
		for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
		{
			printf("Loading Firmware to ADM1266 @ 0x%x\n", ADM1266_Address[loop]);
			ADM1266_Parse_Load_Firmware(ADM1266_Address[loop], ADM1266_Ptr_File);
		}


		for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
		{
			ADM1266_System_Reset(ADM1266_Address[loop]);
		}
	}
	else
		printf("ADM1266 is locked, please verify the unlock password");
	    
 
    fclose(ADM1266_Ptr_File);
}
 
__u8 ADM1266_Refresh_Status(__u8 *ADM1266_Address, __u8 ADM1266_NUM)
{
    __u8 refresh_running = 0;
    __u8 dataout[1];
    __u8 ADM1266_datain[1];
    dataout[0] = 0x80;
 
    for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
    {
        i2c_block_write_block_read(ADM1266_Address[loop], 0x01, dataout, 1, ADM1266_datain);
        ADM1266_datain[0] = (ADM1266_datain[0] & 0x08) >> 3;

        if (ADM1266_datain[0] == 1)
        {
            refresh_running = 1;
        }
    }
    return refresh_running;
}
 
void ADM1266_Program_Config(__u8 *ADM1266_Address, __u8 ADM1266_NUM, FILE *ADM1266_Ptr_File[], __u8 ADM1266_Reset_Sequence)
{
    for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
    {        
        ADM1266_Pause_Sequence(ADM1266_Address[loop], ADM1266_Reset_Sequence);
        ADM1266_Unlock(ADM1266_Address[loop]);              
    }

	if (ADM1266_Get_Part_Locked_System(ADM1266_NUM, ADM1266_Address) == 0)
	{
		for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
		{
			printf("Loading Configuration to ADM1266 @ 0x%x\n", ADM1266_Address[loop]);
			ADM1266_Parse_Load_Config(ADM1266_Address[loop], &ADM1266_Ptr_File[loop]);
		}

		for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
		{
			ADM1266_Start_Sequence(ADM1266_Address[loop]);
		}

		for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
		{
			ADM1266_Unlock(ADM1266_Address[loop]);
			ADM1266_Refresh_Flash_no_Delay(ADM1266_Address[loop]);
		}
		printf("Running memory refresh.\n");
		ADM1266_Delay(10000);
	}
	else
		printf("ADM1266 is locked, please verify the unlock password");    
}
 
void ADM1266_CRC_Summary(__u8 *ADM1266_Address, __u8 ADM1266_NUM)
{
    __u16 crc_result;
    __u8 ADM1266_datain[9];
    for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
    {       
        ADM1266_FW_Boot_Rev(ADM1266_Address[loop], ADM1266_datain);
        ADM1266_Recalculate_CRC(ADM1266_Address[loop]);
        crc_result = ADM1266_All_CRC_Status(ADM1266_Address[loop]);
        printf("\nFirmware Version in device 0x%x is v%d.%d.%d", ADM1266_Address[loop], ADM1266_datain[1], ADM1266_datain[2], ADM1266_datain[3]);
 
        if (crc_result > 0)
        {
            printf("\nThere is CRC error in device 0x%x.", ADM1266_Address[loop]);
        }
        else
        {
            printf("\nAll CRC passed in device device 0x%x.", ADM1266_Address[loop]);
        }
    }
}
 
__u8 ADM1266_DAC_Config(__u8 ADM1266_Address, __u8 ADM1266_DAC_Number)
{
    __u8 data_buffer[5];
    __u8 margin_mode=0;
    __u8 open_dac_input;
    __u8 open_loop = 0;
 
    if (ADM1266_DAC_Number < 10)
    {
        data_buffer[0] = 0xD5;
        data_buffer[1] = 0x01;
        data_buffer[2] = ADM1266_DAC_Number;
 
        i2c_block_write_block_read(ADM1266_Address, 0x03, data_buffer, 0x03, data_buffer);
        margin_mode = data_buffer[1] & 0x03;
 
        if (margin_mode != 1)
        {
            printf("\nSelected DAC is not configured as open loop, would you like to configure the DAC as open loop?");
            printf("\nEnter '1' for yes or press enter to exit: ");
            scanf("%hhx", &open_dac_input);
            if (open_dac_input == 1)
            {
                data_buffer[0] = 0xD5;
                data_buffer[1] = 0x03;
                data_buffer[2] = ADM1266_DAC_Number;
                data_buffer[3] = 0x01;
                data_buffer[4] = 0x00;
                i2c_block_write(ADM1266_Address, 0x05, data_buffer);
                open_loop = 1;
            }
            else
            {
                printf("\nDAC is not configured as open loop, output voltage could not be set.");
                open_loop = 0;
            }
        }
        else
        {
            open_loop = 1;
        }
    }
     
    return open_loop;
}


void ADM1266_Margin_Open_Loop(__u8 ADM1266_Address, __u8 ADM1266_DAC_Number, float ADM1266_DAC_Output)
{
    __u8 i = 0;
	__u8 dac_index;
	__u8 mid_code = 0;
	__u8 dac_code;
	dac_index = 0;
	__u8 dac_config_data[5];
    

	if (ADM1266_DAC_Number < 10)
	{
		if (ADM1266_DAC_Output >= 0.202 && ADM1266_DAC_Output <= 0.808)
		{
			mid_code = 0;
			dac_code = ADM1266_DAC_Code_Calc(ADM1266_DAC_Output, 0.506);
		}
		else if (ADM1266_DAC_Output >= 0.707 && ADM1266_DAC_Output <= 1.313)
		{
			mid_code = 3;
			dac_code = ADM1266_DAC_Code_Calc(ADM1266_DAC_Output, 1.011);
		}
		else if (ADM1266_DAC_Output >= 0.959 && ADM1266_DAC_Output <= 1.565)
		{
			mid_code = 4;
			dac_code = ADM1266_DAC_Code_Calc(ADM1266_DAC_Output, 1.263);
		}
		else 
		{
			mid_code = 5;
		}
	}
	
    //printf("%i", mid_code);

	if (mid_code < 5) 
	{
		dac_config_data[0] = 0xEB;
		dac_config_data[1] = 0x03;
		dac_config_data[2] = ADM1266_DAC_Number;
		dac_config_data[3] = 0x01 + (mid_code<<1);
		dac_config_data[4] = dac_code;
		i2c_block_write(ADM1266_Address, 0x05, dac_config_data);
	}

}

__u8 ADM1266_DAC_Code_Calc(float ADM1266_DAC_Voltage, float ADM1266_Mid_Code_Volt)
{
	__u8 dac_code = ((ADM1266_Mid_Code_Volt - ADM1266_DAC_Voltage) / (0.606 / 256)) + 127;
	return dac_code;
}

__u8 ADM1266_Parse_Load_Firmware(__u8 ADM1266_Address, FILE *ADM1266_Ptr_File)
{
    char buf[1000];
    char size_char[4];
    char reg_addr_char[4];
    __u8 size;
    __u8 reg_addr;
    __u8 loop_counter;
    __u8 counter;
    __u32 delay_ms;
    char temp_char[2];
    __u8 temp;
     
    if (!ADM1266_Ptr_File)
        return 1;
 
    loop_counter = 0;
    rewind(ADM1266_Ptr_File);
     
 
    while (fgets(buf, 1000, ADM1266_Ptr_File) != NULL)
    {               
        //printf("%s\n", buf);
 
        if ((strcmp(buf, ":00000001FF\r\n")) == 0)
            break;
 
        //parse size and register ADM1266_Address
        strncpy(size_char, buf + 1, sizeof 1);
        strncpy(reg_addr_char, buf + 5, sizeof 2);
 
        //Convert from hex char to integer
        sscanf(size_char, "%02hhX", &size);
        sscanf(reg_addr_char, "%02hhX", &reg_addr);
                         
        //Stores the output data file
        __u8 dataout[256];
        dataout[0] = (__u8)reg_addr;     
         
                 
        for (counter = 0; counter < size; counter = counter + 1) {
            strncpy(temp_char, buf + counter * 2 + 9, 2);
            sscanf(temp_char, "%02hhX", &temp);
            dataout[counter + 1] = temp;            
        }
 
        i2c_block_write(ADM1266_Address, size + 1 , dataout);
         
        if (loop_counter == 0x00)
        {
            delay_ms = 2200;
        }
        else
        {
            delay_ms = 10;
        }
         
        ADM1266_Delay(delay_ms);
        loop_counter++;     
    }
     
    return 0;
} 


__u8 ADM1266_Parse_Load_Config(__u8 ADM1266_Address, FILE **ADM1266_Ptr_File)
{
 
    char buf[1000];
    char size_char[4];
    char reg_addr_char[4];
    __u8 size;
    __u8 reg_addr;
    __u8 counter;
    __u32 delay_ms;
    char temp_char[2];
    __u8 temp;
    __u8 offset = 0;

    __u8 break_counter = 0;
             
    if (!*ADM1266_Ptr_File)
        return 1;
    
    while (fgets(buf, 1000, *ADM1266_Ptr_File) != NULL)
    {         


        //the string contains a crraige return

        if ((strcmp(buf, ":00000001FF\r\n")) == 0)
        {            
            break;
        }             

        //parse size and register ADM1266_Address
        strncpy(size_char, buf + 1, sizeof 1);
        strncpy(reg_addr_char, buf + 5, sizeof 2);
 
        //Convert from hex char to integer
        sscanf(size_char, "%02hhX", &size);
        sscanf(reg_addr_char, "%02hhX", &reg_addr);
 
        //Stores the output data file
        __u8 dataout[256];
        dataout[0] = (__u8)reg_addr;     

        //printf("%s", buf);
        //printf("%x\n", dataout[0]);
 
        for (counter = 0; counter < size; counter = counter + 1) {
            strncpy(temp_char, buf + counter * 2 + 9, 2);
            sscanf(temp_char, "%02hhX", &temp);
            dataout[counter + 1] = temp;            
        }

 
        i2c_block_write(ADM1266_Address, size + 1, dataout);     
 
        if (dataout[0] == 0xD8)
        {
            delay_ms = 100;
        }
        else if (dataout[0] == 0x15)
        {
            delay_ms = 300;
        }
        else if (dataout[0] == 0xD7)
        {
            offset = ((dataout[2] | (dataout[3] << 8)));
            if (offset == 0) delay_ms = 400; else delay_ms = 40;
        }
        else if (dataout[0] == 0xE3)
        {
            offset = ((dataout[2] | (dataout[3] << 8)));
            if (offset == 0) delay_ms = 100; else delay_ms = 40;
        }
        else if (dataout[0] == 0xE0)
        {
            offset = ((dataout[2] | (dataout[3] << 8)));
            if (offset == 0) delay_ms = 200; else delay_ms = 40;
        }
        else if (dataout[0] == 0xD6)
        {
            if ((dataout[2] == 0xFF) & (dataout[3] == 0xFF))
            {
                delay_ms = 100 + (dataout[4] - 1) * 30;
            }
            else
            {
                delay_ms = 40;
            }
        }
        else
        {
            delay_ms = 40;
        }
 
        ADM1266_Delay(delay_ms);        
     
    }
    
    fclose(*ADM1266_Ptr_File);
 
    return 0;
}

__u16 ADM1266_All_CRC_Status(__u8 ADM1266_Address)
{
    __u8 dataout[1];
    dataout[0] = 0xED;
    __u8 ADM1266_datain[2];
    i2c_block_write_block_read(ADM1266_Address, 0x01, dataout, 0x02, ADM1266_datain);
    return ((ADM1266_datain[0] + (ADM1266_datain[1] << 8)) >> 4);
}


__u8 ADM1266_Device_Present(__u8 *ADM1266_Address, __u8 ADM1266_NUM)
{
    __u8 dataout[1];
    dataout[0] = 0xAD;
    __u8 ADM1266_datain[4];
 
    for (__u8 loop = 0; loop < ADM1266_NUM; loop++)
    {        
        i2c_block_write_block_read(ADM1266_Address[loop], 0x01, dataout, 0x04, ADM1266_datain);
        if (((ADM1266_datain[1] == 0x42) || (ADM1266_datain[1] == 0x41)) && (ADM1266_datain[2] == 0x12) && (ADM1266_datain[2] = 0x66))
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
}


__u8 ADM1266_Get_Part_Locked_System(__u8 ADM1266_NUM, __u8 *ADM1266_Address)
{
	__u8 ADM1266_datain[1];
	__u8 dataout[1] = { 0x80 };
	__u8 temp = 0;

	for (__u8 i = 0; i < ADM1266_NUM; i++)
	{
		i2c_block_write_block_read(ADM1266_Address[i], 1, dataout, 1, ADM1266_datain);		
		temp = temp | ((ADM1266_datain[0] & 4) >> 2);
	}
	return temp;
}