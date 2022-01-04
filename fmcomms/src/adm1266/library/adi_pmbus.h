// Copyright(c) 2019 Analog Devices, Inc.
// All Rights Reserved.
// This software is proprietary to Analog Devices, Inc. and its licensors.

#ifndef LIB_I2C_SMBUS_H
#define LIB_I2C_SMBUS_H

/* These are not included in the standard SMBus library
Maximum number of bytes is increased to 255*/

extern __s32 i2c_smbus_block_write_block_read(int file, __u8 device_addr, __u8 command, __u8 write_length, __u8 *write_values, __u8 read_length, __u8 *read_values);
extern __s32 i2c_smbus_block_write_big(int file, __u8 device_addr, __u8 command, __u8 write_length, __u8 *write_values);

#endif /* LIB_I2C_SMBUS_H */
