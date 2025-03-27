#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_EEPROM_VALS"

TEST_ID="01"
SHORT_DESC="Test EEPROM date & serial number"
CMD="echo \"$BOARD_S\""
CMD="ssh_cmd \"sudo sh -c 'fru-dump -i /sys/bus/i2c/devices/0-0050/eeprom -b -u | grep $BOARD_S'\";"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT