#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_POWER_ADDON"

TEST_ID="01"
SHORT_DESC="Test USB_POWER voltage."
CMD="USB_POWER_VIN=\$(cat /sys/bus/i2c/devices/0-006a/hwmon/hwmon0/in1_input);"
CMD+="echo \"\$USB_POWER_VIN mV\";"
CMD+="[[ \$USB_POWER_VIN -ge 8300 ]] && [[ \$USB_POWER_VIN -le 9440 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test USB_POWER current."
CMD="USB_POWER_CIN=\$(( \$(cat /sys/bus/i2c/devices/0-006a/hwmon/hwmon0/curr1_input) / 20 ));"
CMD+="echo \"\$USB_POWER_CIN mA\";"
CMD+="[[ \$USB_POWER_CIN -ge 910 ]] && [[ \$USB_POWER_CIN -le 1320 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
