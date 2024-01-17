#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
FAIL_COUNT=0
source $SCRIPT_DIR/test_util.sh

source $SCRIPT_DIR/test_ethernet.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_usb.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_gpio.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_qspi.sh
answer=$?
proceed_if_ok $answer

failed_no
answer=$?
exit $answer