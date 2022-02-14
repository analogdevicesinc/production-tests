#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh
FAIL_COUNT=0

TEST_NAME="TEST_USB_DEVICE_MODE"

TEST_ID="01"
SHORT_DESC="USB port testing - please plug Mini USB cable between Pi and DUT"
CMD="lsusb -t | grep \"cdc_eem\" | grep -q \"480M\" && echo \"HighSpeed - USB2.0\" && true;"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

failed_no
answer=$?
exit $answer
