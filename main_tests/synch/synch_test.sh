#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

BOARD_SERIAL=$1
FAIL_COUNT=0

source $SCRIPT_DIR/test_util.sh

source $SCRIPT_DIR/clk_disable.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/clk_source.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/vcxo_test.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_i2c_temp.sh
answer=$?
proceed_if_ok $answer

dtoverlay -r
dtoverlay $SCRIPT_DIR/rpi-ad9545-hmc7044.dtbo
sudo fru-dump -i $SCRIPT_DIR/pieeprom-new.bin -o $SCRIPT_DIR/pieeprom-new.bin -I 524016 -O 524016 -d now -s $BOARD_SERIAL
rpi-eeprom-update -d -f $SCRIPT_DIR/pieeprom-new.bin

failed_no
answer=$?
exit $answer