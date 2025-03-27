#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_LED"

TEST_ID="01"
SHORT_DESC="Test Status LED"
CMD="ssh_cmd \"sudo sh -c 'sudo /home/analog/jupiter/blink_status.sh '\" &"
CMD+="YES_no 'Is STATUS LED blinking?' ;"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
