#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_USB_HOST_MODE"

TEST_ID="01"
SHORT_DESC="USB port testing - please plug OTG cable with a connected USB2 flash device"
CMD="wait_enter ;"
CMD+="echo ci_hdrc.0 | sudo tee /sys/bus/platform/devices/ci_hdrc.0/driver/unbind ;"
CMD+="echo ci_hdrc.0 | sudo tee /sys/bus/platform/devices/ci_hdrc.0/driver/bind ;"
CMD+="lsusb -t | grep -q \"Class=Mass Storage, Driver=usb-storage\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_NAME="TEST_USB_DRIVE_MOUNTED"

TEST_ID="02"
SHORT_DESC="Test if sda1 partition is mounted"
CMD="[ ! -f /dev/sda1 ]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_NAME="TEST_USB_HOST_MODE_SPEED"

TEST_ID="03"
SHORT_DESC="USB port speed test. Should be greater than 90MB/s"
CMD="drive_path=\$(lsblk | grep 'sda1' | awk -F'part ' '{ print \$2 }');"
CMD+="read_speed=\$(hdparm -T /dev/sda1 | grep \"MB/sec\" | cut -d '=' -f 2 | cut -d 'M' -f 1); echo \"Speed: \$read_speed\";"
CMD+="(( \$(echo \"\$read_speed > 90\" | bc -l -q) ))"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_NAME="TEST_USB_HOST_MODE"

: #if reached this point, ensure exit code 0
