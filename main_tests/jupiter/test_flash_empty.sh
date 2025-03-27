#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh
source $SCRIPT_DIR/mac_get.sh

BOARD_S=$1

TEST_NAME="TEST_FLASH_WRITE_1"

TEST_ID="01"
SHORT_DESC="Write BOOT.BIN to qspi."
CMD="flashcp /boot/qspi_boot/BOOT.BIN /dev/mtd1"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Write I2C Flash "
CMD="fru-dump -i /boot/eeprom/eeprom.bin -o /sys/bus/i2c/devices/0-0050/eeprom"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

return $FAIL_COUNT
