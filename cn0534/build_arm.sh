#!/bin/sh
ROOTFS=$(pwd)/pluto-0.30.sysroot
CC_DIR=/home/guest/linux_dev/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf/bin
make CC=$CC_DIR/arm-linux-gnueabihf-gcc CFLAGS="-mfloat-abi=hard  --sysroot=${ROOTFS} -I./include -L${ROOTFS}/lib"