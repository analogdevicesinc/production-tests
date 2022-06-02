#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_CLK_OUTPUTS"

TEST_ID="01"
SHORT_DESC="TEST VCXO SWITCH"
CMD="dtoverlay -r;"
CMD+="dtoverlay $SCRIPT_DIR/rpi-ad9545-hmc7044-vcxo2.dtbo;"
CMD+="cat /sys/kernel/debug/iio/iio\:device0/status | grep \"PLL1 & PLL2 Locked\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"