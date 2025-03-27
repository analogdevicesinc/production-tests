#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_PERIPHERALS"

TEST_ID="01"
SHORT_DESC="Test SATA Link. Make sure SSD is connected to power."
CMD="lsblk | grep 'sda1';"
CMD+="dmesg | grep -i \"SATA link up 6.0 Gbps\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test SATA Transfer."
CMD="sudo mount /dev/sda1 /media/S870 &&"
CMD+="echo \"Analog\" > /media/S870/file.txt;"
CMD+="cat /media/S870/file.txt | grep \"Analog\";"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Test Display Port video interface."
CMD="YES_no 'Is image visible on monitor?'"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

return $FAIL_COUNT
