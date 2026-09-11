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
CMD="flashcp -v /boot/qspi_boot/BOOT.BIN /dev/mtd0"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Write uImage on QSPI Flash"
CMD="flashcp -v /boot/qspi_boot/uImage /dev/mtd2"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="Write devicetree on QSPI Flash"
CMD="flashcp -v /boot/qspi_boot/devicetree.dtb /dev/mtd3"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="05"
SHORT_DESC="Write uramdisk.image.gz on QSPI Flash"
CMD="flashcp -v /boot/qspi_boot/uramdisk.image.gz /dev/mtd4"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="06"
SHORT_DESC="Write system.bit on QSPI Flash"
CMD="flashcp -v /boot/qspi_boot/system.bit /dev/mtd5"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="07"
SHORT_DESC="Write MAC addresses on ENV partition"
CMD="write_mac"
run_test $TEST_ID "$SHORT_DESC" "$CMD"
: