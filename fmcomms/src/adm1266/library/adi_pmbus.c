// Copyright(c) 2019 Analog Devices, Inc.
// All Rights Reserved.
// This software is proprietary to Analog Devices, Inc. and its licensors.

#include <errno.h>
#include <stddef.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include "adi_pmbus.h"

/* Compatibility defines */
/*
#ifndef I2C_SMBUS_I2C_BLOCK_BROKEN
#define I2C_SMBUS_I2C_BLOCK_BROKEN I2C_SMBUS_I2C_BLOCK_DATA
#endif
#ifndef I2C_FUNC_SMBUS_PEC
#define I2C_FUNC_SMBUS_PEC I2C_FUNC_SMBUS_HWPEC_CALC
#endif
*/

#define I2C_SMBUS_BLOCK_MAX_BIG 250


__s32 i2c_smbus_block_write_block_read(int file, __u8 device_addr, __u8 command, __u8 write_length, __u8 *write_values, __u8 read_length, __u8 *read_values)
{
    struct i2c_rdwr_ioctl_data args;
    struct i2c_msg msg[2];
    __u8 data[32];
    __s32 err;
    __u8 i;
    
    data[0] = command;   
     

    if ((write_length + 1) > I2C_SMBUS_BLOCK_MAX_BIG)
    {
        data[1] = (I2C_SMBUS_BLOCK_MAX_BIG - 1);
        write_length = I2C_SMBUS_BLOCK_MAX_BIG + 1;
    }
    else
    {
        write_length++;
    }

    
    if (read_length > I2C_SMBUS_BLOCK_MAX_BIG)
        read_length = I2C_SMBUS_BLOCK_MAX_BIG;
    

    for (i = 1; i <= write_length; i++)
    {
        data[i] = write_values[i-1];
    } 

    args.nmsgs = 2;
    args.msgs = msg;
    args.msgs[0].addr = device_addr;
    args.msgs[0].flags = 0;
    args.msgs[0].len = write_length;
    args.msgs[0].buf = data;
    // Load up receive msg
    args.msgs[1].addr = device_addr;
    args.msgs[1].flags = I2C_M_RD;
    args.msgs[1].len = read_length;
    args.msgs[1].buf = read_values;
    // Load up i2c_rdwr_ioctl_data
    
    err = ioctl(file, I2C_RDWR, &args);

   
    if (err == -1)
        err = -errno;
    

    if (err < 0)
        return err;
    
    return read_values[0];    

}

__s32 i2c_smbus_block_write_big(int file, __u8 device_addr, __u8 command, __u8 write_length, __u8 *write_values)
{
    struct i2c_rdwr_ioctl_data args;
    struct i2c_msg msg[1];
    __u8 data[255];
    __s32 err;
    __u8 i;

    data[0] = command;   
     
    if ((write_length + 1) > I2C_SMBUS_BLOCK_MAX_BIG)
    {
        data[1] = (I2C_SMBUS_BLOCK_MAX_BIG - 1);
        write_length = I2C_SMBUS_BLOCK_MAX_BIG + 1;
    }
    else
    {
        write_length++;
    }   
 
    for (i = 1; i <= write_length; i++)
    {
        data[i] = write_values[i-1];
    } 

    args.nmsgs = 1;
    args.msgs = msg;
    args.msgs[0].addr = device_addr;
    args.msgs[0].flags = 0;
    args.msgs[0].len = write_length;
    args.msgs[0].buf = data;
    
    err = ioctl(file, I2C_RDWR, &args);

     
    if (err == -1)
        err = -errno;
    

    if (err < 0)
        return err;
    
    return data[0]; 
}









