#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

COMMON_RELEASE_FILES="boot.dfu u-boot.elf uboot-env.dfu ps7_init.tcl"
LD_LIBRARY_PATH="$SCRIPT_DIR/work/scopy/deps/staging/lib:$SCRIPT_DIR/work/libiio/build"
PATH="$SCRIPT_DIR/work/openocd-0.10.0/installed/bin:$SCRIPT_DIR/work/libiio/build/tests:$SCRIPT_DIR/work/plutosdr_scripts:$PATH"
PATH="$SCRIPT_DIR/work/scopy/build:$SCRIPT_DIR/work/:$PATH"

export LD_LIBRARY_PATH
export PATH

# HOST x86 Config
TTYUSB=ttyTest-A1

POWER_CYCLE_DELAY=2

FT4232H_SERIAL="Test-Slot-A"

# This can be increased to a higher value, and then multiple measurements
# will be made and averaged
NUM_SAMPLES=1

IIO_URI_MODE="-u ip:192.168.2.1"
BOARD_ONLINE_TIMEOUT=20	# seconds

EEPROM_VARS="VGAIN VOFF VREF"

