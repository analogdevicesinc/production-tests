#!/bin/bash
SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

python3 $SCRIPT_DIR/../../work/helpkit-waveform-test/waveform_test.py
TEST_RESULT=$?
if [ $TEST_RESULT -ne 0 ]; then
    handle_error_state "$BOARD_SERIAL"
    exit 1;
fi      