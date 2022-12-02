#!/bin/bash

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
CMD="flashcp -v /boot/bootbin_qspi/BOOT.BIN /dev/mtd0"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Write MAC addresses on ENV partition"
CMD="write_mac"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

 : #if reached this point, ensure exito code 0
