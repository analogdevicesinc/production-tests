#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

BOARD_SERIAL=$1

source $SCRIPT_DIR/test_util.sh

source $SCRIPT_DIR/clk_disable.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/clk_source.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_i2c_temp.sh
answer=$?
proceed_if_ok $answer


python3 $SCRIPT_DIR/bin_write.py $BOARD_SERIAL
rpi-eeprom-update -d -f $SCRIPT_DIR/pieeprom-2021-04-29.bin