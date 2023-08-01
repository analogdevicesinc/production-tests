#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_POWER_USB1"

TEST_ID="01"
SHORT_DESC="Test USB1 boot. Please press the button and wait for board to boot"
CMD="wait_enter &&"
CMD+="YES_no 'Is Power LED Blue?'"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test POE input voltage."
CMD="POE_VIN=\$(cat /sys/bus/i2c/devices/0-006a/hwmon/hwmon0/in1_input);"
CMD+="echo $POE_VIN"
CMD+="[[ \$POE_VIN -ge 4700 ]] && [[ \$POE_VIN -le 5250 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Write AD9542 Flash"
CMD="/root/ad9542/ad9542"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="Powering down board for next test."
CMD="reboot"
run_test $TEST_ID "$SHORT_DESC" "$CMD"
