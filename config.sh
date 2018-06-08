#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

COMMON_RELEASE_FILES="boot.dfu u-boot.elf uboot-env.dfu ps7_init.tcl"
LD_LIBRARY_PATH=./work/libiio/build
PATH="./work/openocd-0.10.0/installed/bin:./work/libiio/build/tests:./work/plutosdr_scripts:$PATH"

# HOST x86 Config
TTYUSB=ttyTest-A1

# RPI Config
#havegpio=1
#GDB=gdb
#TTYUSB=ttyS0

POWER_CYCLE_DELAY=2

FT4232H_SERIAL="Test-Slot-A"

# This can be increased to a higher value, and then multiple measurements
# will be made and averaged
NUM_SAMPLES=1

# These need to be tuned per board
REFINOUT=2.4989
VOLTAGE_OFFSET=0
VOLTAGE_GAIN=1

IIO_URI_MODE="-u ip:192.168.2.1"
BOARD_ONLINE_TIMEOUT=10	# seconds

#----------------------------------#
# Utils                            #
#----------------------------------#
source lib/utils.sh

check_system_requirements

enforce_root
