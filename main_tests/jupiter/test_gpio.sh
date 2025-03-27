#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_GPIO"

TEST_ID="01"
SHORT_DESC="Test GPIO Loopback IO_L1P_AD11P <-> IO_L1N_AD11N."
# CMD="sudo \$SCRIPT_DIR/export_gpios.sh;"
CMD="echo 1 > /sys/class/gpio/gpio428/value ;"
CMD+="LOOP=\$(cat /sys/class/gpio/gpio429/value) ;"
CMD+="echo 0 > /sys/class/gpio/gpio428/value;"
CMD+="[[ \$LOOP -eq 1 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test GPIO Loopback IO_L2P_AD10P <-> IO_L2N_AD10N."
CMD="echo 1 > /sys/class/gpio/gpio430/value ;"
CMD+="LOOP=\$(cat /sys/class/gpio/gpio431/value) ;"
CMD+="echo 0 > /sys/class/gpio/gpio430/value;"
CMD+="[[ \$LOOP -eq 1 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Test GPIO Loopback IO_L3P_AD9P <-> IO_L3N_AD9N."
CMD="echo 1 > /sys/class/gpio/gpio432/value ;"
CMD+="LOOP=\$(cat /sys/class/gpio/gpio433/value) ;"
CMD+="echo 0 > /sys/class/gpio/gpio432/value;"
CMD+="[[ \$LOOP -eq 1 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="Test GPIO Loopback IO_L4P_AD8P <-> IO_L4N_AD8N."
CMD="echo 1 > /sys/class/gpio/gpio434/value ;"
CMD+="LOOP=\$(cat /sys/class/gpio/gpio435/value) ;"
CMD+="echo 0 > /sys/class/gpio/gpio434/value;"
CMD+="[[ \$LOOP -eq 1 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="05"
SHORT_DESC="Test GPIO Loopback IO_L5P_AD7P <-> IO_L5N_AD7N."
CMD="echo 1 > /sys/class/gpio/gpio436/value ;"
CMD+="LOOP=\$(cat /sys/class/gpio/gpio437/value) ;"
CMD+="echo 0 > /sys/class/gpio/gpio436/value;"
CMD+="[[ \$LOOP -eq 1 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="06"
SHORT_DESC="Test GPIO Loopback IO_L6P_AD6P <-> IO_L6N_AD6N."
CMD="echo 1 > /sys/class/gpio/gpio438/value ;"
CMD+="LOOP=\$(cat /sys/class/gpio/gpio439/value) ;"
CMD+="echo 0 > /sys/class/gpio/gpio438/value;"
CMD+="[[ \$LOOP -eq 1 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="07"
SHORT_DESC="Test GPIO Loopback IO_L7P_AD5P <-> IO_L7N_AD5N."
CMD="echo 1 > /sys/class/gpio/gpio440/value ;"
CMD+="LOOP=\$(cat /sys/class/gpio/gpio441/value) ;"
CMD+="echo 0 > /sys/class/gpio/gpio440/value;"
CMD+="[[ \$LOOP -eq 1 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="08"
SHORT_DESC="Test GPIO Loopback IO_L8P_AD4P <-> IO_L8N_AD4N."
CMD="echo 1 > /sys/class/gpio/gpio442/value ;"
CMD+="LOOP=\$(cat /sys/class/gpio/gpio443/value) ;"
CMD+="echo 0 > /sys/class/gpio/gpio442/value;"
CMD+="[[ \$LOOP -eq 1 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

return $FAIL_COUNT
