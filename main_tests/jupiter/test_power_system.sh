#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_POWER_SYSTEM"

TEST_ID="01"
SHORT_DESC="Test POE voltage before addon enable."
CMD="POE_VIN=\$(cat /sys/bus/i2c/devices/0-006a/hwmon/hwmon0/in1_input);"
CMD+="echo \"\$POE_VIN mV\";"
CMD+="[[ \$POE_VIN -ge 5070 ]] && [[ \$POE_VIN -le 5750 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test POE current before addon enable."
CMD="echo 475 > /sys/class/gpio/export;"
CMD+="echo out > /sys/class/gpio/gpio475/direction;"
CMD+="echo 0 > /sys/class/gpio/gpio475/value;"
CMD+="sleep 3;"
CMD+="POE_CIN_B=\$(( \$(cat /sys/bus/i2c/devices/0-006a/hwmon/hwmon0/curr1_input) / 20 ));"
CMD+="echo \"\$POE_CIN_B mA\";"
CMD+="[[ \$POE_CIN_B -ge 1570 ]] && [[ \$POE_CIN_B -le 1930 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Test POE current after addon enable."
CMD="echo 1 > /sys/class/gpio/gpio475/value;"
CMD+="sleep 3;"
CMD+="POE_CIN=\$(( \$(cat /sys/bus/i2c/devices/0-006a/hwmon/hwmon0/curr1_input) / 20 ));"
CMD+="echo \"\$POE_CIN mA\";"
CMD+="[[ \$POE_CIN -ge 1500 ]] && [[ \$POE_CIN -le 2030 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="Test POE addon consumption difference."
CMD="CONS=\$((\$POE_CIN - \$POE_CIN_B));"
CMD+="echo \"\$CONS mA \";"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="05"
SHORT_DESC="Test Fan LowSpeed Enabled consumption."
CMD+="echo 479 > /sys/class/gpio/export;"
CMD+="echo out > /sys/class/gpio/gpio479/direction;"
CMD+="echo 0 > /sys/class/gpio/gpio479/value;"
CMD+="sleep 5;"
CMD+="FANLOW=\$(( \$(cat /sys/bus/i2c/devices/0-006a/hwmon/hwmon0/curr1_input) / 20 ));"
CMD+="echo \"\$FANLOW mA \";"
#CMD+="[[ \$FANLOW -ge 1237 ]] && [[ \$FANLOW -le 1283 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="06"
SHORT_DESC="Test Fan highspeed consumption."
CMD="echo 1 > /sys/class/gpio/gpio479/value;"
CMD+="sleep 5;"
CMD+="FANHIGH=\$(( \$(cat /sys/bus/i2c/devices/0-006a/hwmon/hwmon0/curr1_input) / 20 ));"
CMD+="echo \"\$FANHIGH mA \";"
#CMD+="[[ \$FANHIGH -ge 1266 ]] && [[ \$FANHIGH -le 1290 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="07"
SHORT_DESC="Test fan consumption difference."
CMD="CONS=\$((\$FANHIGH - \$FANLOW));"
CMD+="echo \"\$CONS mA \";"
CMD+="echo 0 > /sys/class/gpio/gpio479/value;"
CMD+="[[ \$CONS -ge 27 ]] && [[ \$CONS -le 70 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
