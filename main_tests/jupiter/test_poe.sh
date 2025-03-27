#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_POE"

TEST_ID="01"
SHORT_DESC="Test POE boot."
CMD="YES_no 'Is Power LED Blue?'"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test POE input voltage."
CMD="POE_VIN=\$(cat /sys/bus/i2c/devices/0-006a/hwmon/hwmon0/in1_input);"
CMD+="echo \"\$POE_VIN mV\";"
CMD+="[[ \$POE_VIN -ge 5070 ]] && [[ \$POE_VIN -le 5750 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Test POE input current."
CMD="POE_CIN=\$(( \$(cat /sys/bus/i2c/devices/0-006a/hwmon/hwmon0/curr1_input) / 20 ));"
CMD+="echo \"\$POE_CIN mA\";"
CMD+="[[ \$POE_CIN -ge 1570 ]] && [[ \$POE_CIN -le 1930 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
