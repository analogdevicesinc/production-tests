#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_USB_DEVICE_MODE"

TEST_ID="01"
SHORT_DESC="USB port testing - please plug USB Type C cable between Pi and DUT"
CMD="wait_enter && USB_DEV=\$(iio_info -s | grep \"0456:b671\" | cut -d '[' -f 2 | cut -d ']' -f 1);"
CMD+="[ ! -z \$USB_DEV ]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_NAME="TEST_USB_DRIVE_SPEED"

TEST_ID="02"
SHORT_DESC="Test device access and speed - Read 500Mega Samples and compute average read speed"
CMD="iio_readdev -u \$USB_DEV -b 100000 -s 50000000 axi-adrv9009-rx-hpc | pv -a -f >/dev/null;"
CMD+="YES_no 'Was read speed over 60MB/s ? ';"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

: #if reached this point, ensure exit code 0
