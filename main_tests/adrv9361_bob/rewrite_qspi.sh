#!/bin/bash

####################### This script is for re-writing the flashes that contain mistakes!! ###########################

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh
source $SCRIPT_DIR/mac_write.sh

TEST_NAME="TEST_FLASH_MEMORY"

TEST_ID="01"
SHORT_DESC="Check if QSPI chip was detected"
CMD="test -e /dev/mtd0"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Write BOOT.BIN on QSPI Flash"
CMD="flashcp -v /boot/qspi_boot/BOOT.BIN /dev/mtd0"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

: