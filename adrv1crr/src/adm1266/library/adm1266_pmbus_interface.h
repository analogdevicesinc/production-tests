// Copyright(c) 2019 Analog Devices, Inc.
// All Rights Reserved.
// This software is proprietary to Analog Devices, Inc. and its licensors.


#pragma once

extern int file;
extern void i2c_init();
extern __u32 i2c_block_write(__u8 device_addr,__u8 dataout_length, __u8 *dataout);
extern __u32 i2c_block_write_block_read(__u8 device_addr, __u8 dataout_length, __u8 *dataout, __u8 read_no_bytes, __u8 *datain);
extern __u32 i2c_byte_read(__u8 device_addr,__u8 command);
extern void set_i2c_addr(__u8 addr);
