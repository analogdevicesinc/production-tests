#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_UART_COMM"

TEST_ID="01"
SHORT_DESC="Connect MicroUSB cable to carrier UART. Check if USB-UART is detected"
CMD="wait_enter && test -e /dev/ttyUSB0"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Check UART communication and test POE Voltage"
CMD="VIN=\$(\$SCRIPT_DIR/test_uart.expect | awk -F'[^0-9]*' '\$0=\$3');"
CMD+="echo \" \$VIN returned from expect\";"
CMD+="[[ \$VIN -ge 5500 ]] && [[ \$VIN -le 6100 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

 : #if reached this point, ensure exito code 0
