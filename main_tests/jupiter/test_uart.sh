#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh
FAIL_COUNT=0

TEST_NAME="TEST_UART_COMM"

TEST_ID="01"
SHORT_DESC="Test if USB-UART is detected"
CMD="test -e /dev/ttyUSB0"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Check UART communication and test USB_DATA Voltage"
CMD="VIN=\$(\$SCRIPT_DIR/test_uart.expect | awk -F'[^0-9]*' '\$0=\$3');"
CMD+="echo \" \$VIN mV returned from expect\";"
CMD+="[[ \$VIN -ge 4500 ]] && [[ \$VIN -le 5060 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Check UART communication and test USB_DATA Current"
CMD="sleep 3;"
CMD+="CIN=\$(( \$(\$SCRIPT_DIR/test_uart_current.expect | awk -F'[^0-9]*' '\$0=\$3') / 20 ));"
CMD+="echo \" \$CIN mA returned from expect\";"
CMD+="[[ \$CIN -ge 1690 ]] && [[ \$CIN -le 2070 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
