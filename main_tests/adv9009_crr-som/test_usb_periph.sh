#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_USB_DEVICE_MODE"

TEST_ID="01"
SHORT_DESC="USB port testing - please plug USB Type C cable between Pi and DUT"
CMD="wait_enter && USB_DEV=\$(iio_info -S usb | grep \"0456:b671\" | cut -d '[' -f 2 | cut -d ']' -f 1);"
CMD+="[ ! -z \$USB_DEV ]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="USB type check - Detect USB class HighSpeed or SuperSpeed"
CMD="lsusb -t | grep \"CDC Data\" | grep -q \"480M\" && echo \"HighSpeed - USB2.0\" && false;"
CMD+="lsusb -t | grep \"CDC Data\" | grep -q \"5000M\" && echo \"SuperSpeed - USB3.0\" && true;"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_NAME="TEST_USB_SPEED"

TEST_ID="03"
SHORT_DESC="Test device access and speed - Read 50Mega Samples and compute average read speed"
CMD="iio_readdev -u \$USB_DEV -b 100000 -s 50000000 axi-adrv9009-rx-hpc | pv -af >/dev/null 2>/tmp/rate;"
CMD+="RATE=\$(cat /tmp/rate | grep -oP '^[^0-9]*\K[0-9]+'); echo \"Read rate \$RATE MB/s\";"
CMD+="[ \$RATE -gt 60 ]"
if lsusb -t | grep "CDC Data" | grep -q "480M"; then CMD="false"; fi
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="USB port testing - please replug cable but rotated 180 degrees"
CMD="wait_enter && lsusb -t | grep \"CDC Data\" | grep -q \"5000M\" && echo \"SuperSpeed\";"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

if [ -n "$GLOBAL_FAIL" ]; then
	exit 1
else
	exit 0
fi
