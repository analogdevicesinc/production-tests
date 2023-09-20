#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_FLASHPD"

TEST_ID="01"
SHORT_DESC="Program USBPD spi flash"
CMD="flashcp /home/analog/flashpd/Jupiter_TPS65988_revC.bin /dev/mtd0"
run_test $TEST_ID "$SHORT_DESC" "$CMD"
