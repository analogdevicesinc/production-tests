#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_nav.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_audio.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_periph.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_clk.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_eth.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_usb.sh
answer=$?
proceed_if_ok $answer
