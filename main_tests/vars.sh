#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

LD_LIBRARY_PATH="$SCRIPT_DIR/work/libiio/build:$LD_LIBRARY_PATH"
PATH="$SCRIPT_DIR/work/libiio/build/tests:$PATH"

export LD_LIBRARY_PATH
export PATH

# This can be increased to a higher value, and then multiple measurements
# will be made and averaged
NUM_SAMPLES=1

IIO_URI_MODE="-u ip:192.168.2.1"
BOARD_ONLINE_TIMEOUT=20	# seconds
