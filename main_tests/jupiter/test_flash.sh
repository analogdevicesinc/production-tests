#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh
source $SCRIPT_DIR/mac_get.sh

TEST_NAME="TEST_FLASH_WRITE"

TEST_ID="01"
SHORT_DESC="Write BOOT.BIN to qspi."
#TODO: probably flashcp or some cmd to flash qspi
CMD="echo \"QSPI N/A\";"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Write I2C Flash & ."
CMD="get_mac; ETH_ADDR=\$(cat mac_file.txt);"
CMD+="fru-dump -i /boot/eeprom/eeprom.bin -o /sys/bus/i2c/devices/0-0050/eeprom -m \"\$ETH_ADDR\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"
