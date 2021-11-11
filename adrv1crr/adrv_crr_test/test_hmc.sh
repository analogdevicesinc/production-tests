#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_CRR_HMC_LOCK"

TEST_ID="01"
SHORT_DESC="Check if CRR HMC7044 is detected"
CMD="cat /sys/bus/iio/devices/iio*/name | grep -xq \"hmc7044-car\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Check lock state of HMC7044"
CMD="cat /sys/kernel/debug/iio/iio\:device1/status | grep -q \"PLL1 & PLL2 Locked\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"

 : #if reached this point, ensure exito code 0
