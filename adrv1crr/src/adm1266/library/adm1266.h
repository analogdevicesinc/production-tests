// Copyright(c) 2019 Analog Devices, Inc.
// All Rights Reserved.
// This software is proprietary to Analog Devices, Inc. and its licensors.

#include <stdio.h>
#pragma once

#ifndef _MSC_VER
/* C99-compliant compilers (GCC) */
#include <stdint.h>
typedef uint8_t   __u8;
typedef uint16_t  __u16;
typedef uint32_t  __u32;
typedef uint64_t  __u64;
typedef int8_t    __s8;
typedef int16_t   __s16;
typedef int32_t   __s32;
typedef int64_t   __s64;
#include "adm1266_pmbus_interface.h"

#else
/* Microsoft compilers (Visual C++) */
#include "aardvark.h"
typedef unsigned __int8   __u8;
typedef unsigned __int16  __u16;
typedef unsigned __int32  __u32;
typedef unsigned __int64  __u64;
typedef signed   __int8   __s8;
typedef signed   __int16  __s16;
typedef signed   __int32  __s32;
typedef signed   __int64  __s64;
extern Aardvark aardvark_handle;
#include "aardvark_i2c_interface.h"
#endif /* __MSC_VER */


void ADM1266_Get_All_Data(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u8 *ADM1266_Signals_Data, __u16 *ADM1266_Voltages, __u8 *ADM1266_Status);
void ADM1266_Print_Telemetry(__u8 ADM1266_NUM, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u8 *ADM1266_Signals_Data, __u16 *ADM1266_Voltages, __u8 *ADM1266_Status, __u16 *ADM1266_Rail_Name, __u16 *ADM1266_Signal_Name, __u8 *ADM1266_System_Data);
int ADM1266_Expo(__u8 num);
__u8 ADM1266_Get_Sys_Status(__u8 ADM1266_NUM, __u8 *ADM1266_Status);
void ADM1266_Print_Sys_Status(__u8 ADM1266_NUM, __u8 *ADM1266_Status);
void ADM1266_Get_Refresh_Counter(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u16 *ADM1266_Refresh_Counter);
void ADM1266_Print_Refresh_Counter(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u16 *ADM1266_Refresh_Counter);
void ADM1266_Get_CRC_Error_Counter(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u16 *ADM1266_CRC_Error_Counter);
void ADM1266_Print_CRC_Error_Counter(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u16 *ADM1266_CRC_Error_Counter);
void ADM1266_Print_MFR_ID(__u8 ADM1266_NUM, __u8 *ADM1266_Address);
void ADM1266_Print_MFR_MODEL(__u8 ADM1266_NUM, __u8 *ADM1266_Address);
void ADM1266_Print_MFR_REVISION(__u8 ADM1266_NUM, __u8 *ADM1266_Address);
void ADM1266_Print_MFR_LOCATION(__u8 ADM1266_NUM, __u8 *ADM1266_Address);
void ADM1266_Print_MFR_DATE(__u8 ADM1266_NUM, __u8 *ADM1266_Address);
void ADM1266_Print_MFR_SERIAL(__u8 ADM1266_NUM, __u8 *ADM1266_Address);
void ADM1266_Print_User_Data(__u8 ADM1266_NUM, __u8 *ADM1266_Address);
void ADM1266_Get_IC_Device_ID(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_IC_Device_ID);
void ADM1266_Get_IC_Device_Rev(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_Firmware_Rev, __u8 *ADM1266_Bootloader_Rev);
__u8 ADM1266_Get_Sys_CRC(__u8 ADM1266_NUM, __u8 *ADM1266_Address);
__u8 ADM1266_Get_Part_Locked(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_Part_Locked);
void ADM1266_Get_Main_Backup(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_Main_Backup);
void ADM1266_Print_CRC(__u8 ADM1266_NUM, __u8 *ADM1266_Address);
void ADM1266_VX_Telemetry(__u8 ADM1266_Dev, __u8 ADM1266_Pin, __u8 *ADM1266_VX_Status, float *ADM1266_VX_Value, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u16 *ADM1266_Voltages, __u8 *ADM1266_Status);
__u8 ADM1266_PDIOGPIO_Telemetry(__u8 ADM1266_Dev, __u8 ADM1266_Pin, __u8 *ADM1266_Signals_Data);
void ADM1266_Get_Current_State(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_Current_State);
void ADM1266_Print_Current_State(__u8 ADM1266_NUM, __u8 *ADM1266_Address, __u8 *ADM1266_System_Data, __u16 *ADM1266_State_Name);

int n21(int x, int y, int z, int my, int mz);
int ADM1266_Srch_Array(__u8 *ADM1266_datain, __u16 data_length, __u8 srch_element);
void ADM1266_System_Read(__u8 ADM1266_Num, __u8 *ADM1266_Address, __u8 *ADM1266_System_Data);
void ADM1266_Configuration_Name(__u8 *ADM1266_System_Data);
void ADM1266_System_Parse(__u8 *ADM1266_System_Data, __u16 *ADM1266_State_Name, __u16 *ADM1266_Rail_Name, __u16 *ADM1266_Signal_Name, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u8 *ADM1266_Signals_Data, __u8 *ADM1266_ADM1266_PDIO_GPIO_Pad, __u8 *ADM1266_ADM1266_VX_Pad);
void ADM1266_State_Parse(__u8 *ADM1266_System_Data, __u16 *ADM1266_State_Name, __u16 Start_Pointer, __u16 Section_Length);
void ADM1266_Rail_Parse(__u8 *ADM1266_System_Data, __u16 *ADM1266_Rail_Name, __u16 Start_Pointer, __u16 Section_Length, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u8 *ADM1266_ADM1266_PDIO_GPIO_Pad, __u8 *ADM1266_ADM1266_VX_Pad);
void ADM1266_Signal_Parse(__u8 *ADM1266_System_Data, __u16 *ADM1266_Signal_Name, __u16 Start_Pointer, __u16 Section_Length, __u8 *ADM1266_Signals_Data, __u8 *ADM1266_ADM1266_PDIO_GPIO_Pad, __u8 *ADM1266_ADM1266_VX_Pad);
void ADM1266_Get_Name(__u8 *ADM1266_System_Data, __u16 *Name, __u16 index);
void ADM1266_VLQ_Decode(__u16 index, __u8 *ADM1266_System_Data, __u16 *value, __u16 *Next_Pointer);
void ADM1266_PDIO_GPIO_Global_Index(__u16 ADM1266_datain, __u8 *ADM1266_ADM1266_PDIO_GPIO_Pad, __u8 *PDIO_GPIO_Num, __u8 *PDIO_GPIO_Type, __u8 *Dev_id);
void ADM1266_VX_Global_Index(__u16 ADM1266_datain, __u8 *ADM1266_ADM1266_VX_Pad, __u8 *VX_Num, __u8 *VX_Type, __u8 *Dev_id);
void ADM1266_Get_Num_Records(__u8 *ADM1266_Address, __u16 *ADM1266_Record_Index, __u16 *ADM1266_Num_Records);
void ADM1266_Get_BB_Raw_Data(__u8 ADM1266_Num, __u8 *ADM1266_Address, __u8 index, __u16 ADM1266_Record_Index, __u16 ADM1266_Num_Records, __u8 *ADM1266_BB_Data);
void ADM1266_BB_Parse(__u8 ADM1266_Num, __u8 *ADM1266_BB_Data, __u8 *ADM1266_System_Data, __u16 *ADM1266_State_Name, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u8 *ADM1266_Signals_Data, __u16 *ADM1266_Rail_Name, __u16 *ADM1266_Signal_Name);
void ADM1266_RTS(__u8 *ADM1266_datain);
int ADM1266_GPIO_Map(__u16 ADM1266_datain);
void ADM1266_Print_UV(__u8 ADM1266_Num, __u8 *ADM1266_System_Data, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u16 *ADM1266_Rail_Name);
void ADM1266_Print_OV(__u8 ADM1266_Num, __u8 *ADM1266_System_Data, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u16 *ADM1266_Rail_Name);
void ADM1266_Print_Normal(__u8 ADM1266_Num, __u8 *ADM1266_System_Data, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u16 *ADM1266_Rail_Name);
void ADM1266_Print_Disabled(__u8 ADM1266_Num, __u8 *ADM1266_System_Data, __u8 *ADM1266_VH_Data, __u8 *ADM1266_VP_Data, __u16 *ADM1266_Rail_Name);
void ADM1266_BB_Clear(__u8 ADM1266_Num, __u8 *ADM1266_Address);
__u16 ADM1266_Get_Bit(__u16 data, __u8 bit);

struct ADM1266_dac_data
{
    __u8 ADM1266_Address;
	__u8 device_index;
    __u8 input_channel;
};


// Functions for open loop margining
void ADM1266_Margin_Open_Loop(__u8 ADM1266_Address, __u8 ADM1266_DAC_Number, float ADM1266_DAC_Output);
__u8 ADM1266_DAC_Code_Calc(float ADM1266_DAC_Voltage, float ADM1266_Mid_Code_Volt);
__u8 ADM1266_DAC_Config(__u8 ADM1266_Address, __u8 ADM1266_DAC_Number);
void ADM1266_DAC_Mapping(__u8 *ADM1266_Address, __u8 ADM1266_NUM, struct ADM1266_dac_data *ADM1266_DAC_data);

// Functions for open loop margining
void ADM1266_Margin_All(__u8 *ADM1266_Address, __u8 ADM1266_NUM, __u8 ADM1266_Margin_Type);
void ADM1266_Margin_Single(__u8 ADM1266_Address, char *ADM1266_Pin_Name, __u8 ADM1266_Margin_Type);
void ADM1266_Margin_Single_Input(__u8 ADM1266_Address, __u8 ADM1266_Pin_Index, __u8 ADM1266_Margin_Type);

// Functions for loading configuration and firmware
void ADM1266_Jump_to_IAP(__u8 ADM1266_Address);
void ADM1266_Program_Firmware(__u8 *ADM1266_Address, __u8 ADM1266_NUM, FILE *ADM1266_Ptr_File);
void ADM1266_Program_Config(__u8 *ADM1266_Address, __u8 ADM1266_NUM, FILE *ADM1266_Ptr_File[], __u8 ADM1266_Reset_Sequence);
void ADM1266_Memory_Pointer_Main(__u8 ADM1266_Address);
__u8 ADM1266_Parse_Load_Config(__u8 ADM1266_Address, FILE **ADM1266_Ptr_File);
__u8 ADM1266_Parse_Load_Firmware(__u8 ADM1266_Address, FILE *ADM1266_Ptr_File);

// Generic Functions
void ADM1266_Delay(__u32 ADM1266_milli_seconds);
__u8 ADM1266_Device_Present(__u8 *ADM1266_Address, __u8 ADM1266_NUM);
void ADM1266_Refresh_Flash(__u8 ADM1266_Address);
void ADM1266_Refresh_Flash_no_Delay(__u8 ADM1266_Address);
__u8 ADM1266_Refresh_Status(__u8 *ADM1266_Address, __u8 ADM1266_NUM);
__u16 ADM1266_All_CRC_Status(__u8 ADM1266_Address);
void ADM1266_Recalculate_CRC(__u8 ADM1266_Address);
void ADM1266_CRC_Summary(__u8 *ADM1266_Address, __u8 ADM1266_NUM);
void ADM1266_Start_Sequence(__u8 ADM1266_Address);
void ADM1266_Pause_Sequence(__u8 ADM1266_Address, __u8 ADM1266_Reset_Sequence);
void ADM1266_System_Reset(__u8 ADM1266_Address);
void ADM1266_Unlock(__u8 ADM1266_Address);
void ADM1266_FW_Boot_Rev(__u8 ADM1266_Address, __u8 *ADM1266_datain);
void ADM1266_Margin_Single_Percent(__u8 ADM1266_Address, __u8 ADM1266_Pin, float ADM1266_Margin_Percent);
void ADM1266_Margin_All_Percent(__u8 ADM1266_NUM, struct ADM1266_dac_data *ADM1266_DAC_data, float ADM1266_Margin_Percent);
float ADM1266_Ment_Exp_to_Val(__u8 ADM1266_exp, __u16 ADM1266_ment);
__u16 ADM1266_Val_to_Ment(float ADM1266_val, __u8 ADM1266_exp);
__u8 ADM1266_Get_Part_Locked_System(__u8 ADM1266_NUM, __u8 *ADM1266_Address);