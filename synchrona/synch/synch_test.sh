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


sudo fru-dump -i $SCRIPT_DIR/pieeprom-2021-07-06.bin -o $SCRIPT_DIR/pieeprom-2021-07-06.bin -d now -s $BOARD_SERIAL
rpi-eeprom-update -d -f $SCRIPT_DIR/pieeprom-2021-07-06.bin