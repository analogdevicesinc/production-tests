#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh
FAIL_COUNT=0

TEST_NAME="TEST_UART_COMM"

TEST_ID="01"
SHORT_DESC="Connect MicroUSB cable to carrier UART. Check if USB-UART is detected"
CMD="wait_enter && test -e /dev/ttyUSB0 && test -e /dev/ttyUSB1"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Check UART communication"
CMD="TTY_PORT=\"/dev/\$(dmesg | grep tty | grep \"cp210x converter now attached to\" | awk '{print \$10}')\";"
CMD+="\$SCRIPT_DIR/test_uart.expect \$TTY_PORT"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

failed_no
answer=$?
exit $answer