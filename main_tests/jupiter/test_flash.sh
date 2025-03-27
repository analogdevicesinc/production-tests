#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh
source $SCRIPT_DIR/mac_get.sh

BOARD_S=$1

TEST_NAME="TEST_FLASH_WRITE"

TEST_ID="01"
SHORT_DESC="Write I2C Flash "
CMD="get_mac; ETH_ADDR=\$(cat mac_file.txt);"
CMD+="echo \"$BOARD_S\";"
CMD+="MANDATE=\"\$(date -d ${BOARD_S:0:8} --rfc-3339=date)\";"
CMD+="MANDATE+=\"T15:12:30-05:00\";"
CMD+="fru-dump -i /boot/eeprom/eeprom.bin -o /sys/bus/i2c/devices/0-0050/eeprom -d \"\$MANDATE\" -m \"\$ETH_ADDR\" -s \"$BOARD_S\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
