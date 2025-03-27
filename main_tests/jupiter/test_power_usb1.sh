#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_POWER_USB_DATA"

TEST_ID="01"
SHORT_DESC="Test USB_DATA boot."
CMD="wait_enter &&"
CMD+="YES_no 'Is Power LED Blue?'"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
