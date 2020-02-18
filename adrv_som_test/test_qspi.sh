#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_FLASH_MEMORY"

TEST_ID="01"
SHORT_DESC="Check if QSPI chip was detected"
CMD="test -e /dev/mtd0"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Erase test on QSPI Flash - Erase 10 x 4Kibyte blocks"
CMD="timeout 3 flash_erase /dev/mtd0 0 10"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Write test on QSPI Flash"
CMD="dd if=/dev/urandom of=/tmp/foo.foo bs=4k count=10 &>/dev/null;"
CMD+="[ -e /dev/mtd0 ] && dd if=/tmp/foo.foo of=/dev/mtd0 &>/dev/null;"
CMD+="[ -e /dev/mtd0 ] && dd if=/dev/mtd0 of=/tmp/foo_rb.foo bs=4k count=10 &>/dev/null;"
CMD+="cmp -n40960 -s /tmp/foo.foo /tmp/foo_rb.foo"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

 : #if reached this point, ensure exito code 0
