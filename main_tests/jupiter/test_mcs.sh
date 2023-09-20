#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_MCS"

TEST_ID="01"
SHORT_DESC="Test MCS. Sending impulse from Rpi"
CMD="echo \"sending impulse from rpi\""
CMD+="echo\"checking mcs flag\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"