// Copyright(c) 2019 Analog Devices, Inc.
// All Rights Reserved.
// This software is proprietary to Analog Devices, Inc. and its licensors.

#include <sys/types.h>
#include <fcntl.h>
#include <errno.h>
#include <err.h>
#include <linux/types.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include "adm1266_pmbus_interface.h"
#include "adi_pmbus.h"

int file;

void i2c_init()
{

    const char *path = "/dev/i2c-1";
    int rc;
    file = open(path, O_RDWR);
	if (file < 0)
    {
		err(errno, "Tried to open '%s'", path);
    }   
}

__u32 i2c_block_write(__u8 device_addr,__u8 dataout_length, __u8 *dataout)
{
    __u32 bytes_written = 0;
    __u8 command;
    __u8 length;
    __u8 i;    
    __u8 datawrite[255];


    //set_i2c_addr(device_addr);

    command = dataout[0];
    length = dataout_length - 1;


    for (i = 1; i <= dataout_length; i++)
    {
        datawrite[i-1] = dataout[i];   
    } 

    // If ioctrl system call in Linux is not used for communicating with i2c devices 
    // i2c_smbus_block_write_big should be replaced with i2c master api used in the system

    // Parameters passed to i2c_smbus_block_write_big function
    //---------------------------------------------------------------------------
    // file is a pointer for the i2c master in a system
    // device_addr is the i2c address of the slave device
    // command is the register address for which the data will be sent
    // length is the number of bytes of data which will be sent to the i2c slave device
    // datawrite is the data which will be written to the i2c slave device

    bytes_written = i2c_smbus_block_write_big(file, device_addr, command, length, datawrite);
 
   return bytes_written;
}


__u32 i2c_block_write_block_read(__u8 device_addr, __u8 dataout_length, __u8 *dataout, __u8 read_no_bytes, __u8 *datain)
{
	
    __u8 write_length = 0;
	__u32 bytes_read = 0;
	__u8 actual_data_written = 0;
	__u8 actual_data_read = 0;
    __u8 command;
    __u8 length;
    __u8 i; 
    __u8 datawrite[255];  

    command = dataout[0];
    length = dataout_length - 1;
    for (i = 1; i <= dataout_length; i++)
    {
        datawrite[i-1] = dataout[i];   
    }


    // If ioctrl system call in Linux is not used for communicating with i2c devices 
    // i2c_smbus_block_write_block_read should be replaced with i2c master api used in the system

    // Parameters passed to i2c_smbus_block_write_block_read function
    //---------------------------------------------------------------------------
    // file is a pointer for the i2c master in a system
    // device_addr is the i2c address of the slave device
    // command is the register address for which the data will be sent
    // length is the number of bytes of data which will be sent to the i2c slave device
    // datawrite is the data which will be written to the i2c slave device
    // read_no_bytes is the number of bytes of data which will be read back from the i2c slave device
    // datain is the data which is read back from the i2c slave device

	    
	bytes_read = i2c_smbus_block_write_block_read(file, device_addr, command, length, datawrite, read_no_bytes, datain);

    return bytes_read;
}

void set_i2c_addr(__u8 addr)
{
    int rc;
    rc = ioctl(file, I2C_SLAVE, addr);
    if (rc < 0)
    {
		err(errno, "Tried to set device address '0x%02x'", addr);       
    }   

}
