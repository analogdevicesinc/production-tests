#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_FLASH_MEMORY"

TEST_ID="01"
SHORT_DESC="Check if QSPI chip was detected"
CMD="test -e /dev/mtd0"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="01"
SHORT_DESC="Erase test on QSPI Flash"
CMD="flash_erase /dev/mtd0 0 0"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Write test on QSPI Flash"
CMD="dd if=/dev/urandom of=/tmp/foo.foo bs=1k count=1000 &>/dev/null;"
CMD+="[ -e /dev/mtd0 ] && cp /tmp/foo.foo /dev/mtd0;"
CMD+="[ -e /dev/mtd0 ] && dd if=/dev/mtd0 of=/tmp/foo_rb.foo bs=1k count=1000 &>/dev/null;"
CMD+="cmp -n10750 -s /tmp/foo.foo /tmp/foo_rb.foo"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

 : #if reached this point, ensure exito code 0
