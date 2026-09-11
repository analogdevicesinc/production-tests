#!/bin/bash
# File that needs to be on the board

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh
source $SCRIPT_DIR/../lib/utils.sh

GLOBAL_FAIL=0

TEST_NAME="TEST_PERIPHERALS"

TEST_ID="01"
SHORT_DESC="Testing the GPIO pins. Loopback should be inserted"
CMD="sudo $SCRIPT_DIR/test_gpio-aarch64 FMC_GPIO0 loopback"
run_test $TEST_ID "$SHORT_DESC" "$CMD"


if [ -n "$GLOBAL_FAIL" ]; then
	exit 1
else
	exit 0
fi