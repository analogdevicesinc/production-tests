#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_CLOCK"

TEST_ID="01"
SHORT_DESC="Test FMC CLK0 out"
CMD="sudo $SCRIPT_DIR/i2c_ad9545 &> /dev/null;"
CMD+="CLK_FREQ=\$(sudo $SCRIPT_DIR/test_clk CLK0 verbose);"
CMD+="[[ \$CLK_FREQ -ge 154 ]] && [[ \$CLK_FREQ -le 158 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test FMC CLK1 out"
CMD="CLK_FREQ=\$(sudo $SCRIPT_DIR/test_clk CLK1 verbose);"
CMD+="[[ \$CLK_FREQ -ge 154 ]] && [[ \$CLK_FREQ -le 158 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Test FMC CLK2 out"
CMD="CLK_FREQ=\$(sudo $SCRIPT_DIR/test_clk CLK2 verbose);"
CMD+="[[ \$CLK_FREQ -ge 154 ]] && [[ \$CLK_FREQ -le 158 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="Test AD9517-3ABCPZ out"
CMD="CLK_FREQ=\$(sudo $SCRIPT_DIR/test_clk CLK3 verbose);"
CMD+="[[ \$CLK_FREQ -ge 123 ]] && [[ \$CLK_FREQ -le 127 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

 : #if reached this point, ensure exito code 0
