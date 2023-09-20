#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_EXTERNAL_LO"

TEST_ID="01"
SHORT_DESC="Test ext_lo"
CMD="echo \"testing ext lo, rquires re-load profile\""
CMD+="echo\"check navassa loaded\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"
