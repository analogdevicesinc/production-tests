#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_power_usb2.sh
answer=$?
proceed_if_ok $answer

source $SCRIPT_DIR/test_measure_pr.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_eth.sh
answer=$?
proceed_if_ok $answer

source $SCRIPT_DIR/test_periph.sh
answer=$?
proceed_if_ok $answer

source $SCRIPT_DIR/test_gpio.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_usb.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_flash.sh
answer=$?
proceed_if_ok $answer
###### maybe directly python command
# source $SCRIPT_DIR/test_rf.sh
# answer=$?
# proceed_if_ok $answer
