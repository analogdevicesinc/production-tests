#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

LD_LIBRARY_PATH="$SCRIPT_DIR/work/scopy/deps/staging/lib:$SCRIPT_DIR/work/libiio/build"
PATH="$SCRIPT_DIR/work/libiio/build/tests:$PATH"
PATH="$SCRIPT_DIR/work/:$PATH"

export LD_LIBRARY_PATH
export PATH

# HOST x86 Config
TTYUSB=ttyTest-A1

POWER_CYCLE_DELAY=2

# This can be increased to a higher value, and then multiple measurements
# will be made and averaged
NUM_SAMPLES=1

M2K_URI_MODE="ip:192.168.2.1"
IIO_URI_MODE="-u $M2K_URI_MODE"
BOARD_ONLINE_TIMEOUT=20	# seconds


