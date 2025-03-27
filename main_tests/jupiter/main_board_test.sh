#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

FAIL_COUNT=0

BOARD_S=$1

echo
source $SCRIPT_DIR/test_power_usb2.sh
answer=$?
proceed_if_ok $answer;

echo
source $SCRIPT_DIR/test_periph.sh
answer=$?
proceed_if_ok $answer;

echo
source $SCRIPT_DIR/test_eth.sh
answer=$?
proceed_if_ok $answer;

echo
source $SCRIPT_DIR/test_addon_connect.sh
answer=$?
proceed_if_ok $answer;

echo
source $SCRIPT_DIR/test_gpio.sh
answer=$?
proceed_if_ok $answer;

echo
source $SCRIPT_DIR/test_flash_empty.sh 
answer=$?
proceed_if_ok $answer;

echo
source $SCRIPT_DIR/test_usb.sh
answer=$?
proceed_if_ok $answer;

exit $FAIL_COUNT
