#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_GPIO"

TEST_ID="01"
SHORT_DESC="Test P2"
CMD="sudo $SCRIPT_DIR/test_fpga_loopback P2"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test P13"
CMD="sudo $SCRIPT_DIR/test_fpga_loopback P13"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="Test P4_P5"
CMD="sudo $SCRIPT_DIR/test_fpga_loopback P4_P5"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="05"
SHORT_DESC="Test P6_P7"
CMD="sudo $SCRIPT_DIR/test_fpga_loopback P6_P7"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

: