#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_GPIO"

TEST_ID="01"
SHORT_DESC="Test GPIO Loopback."
CMD="echo \"GPIO Test N/A yet.\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"