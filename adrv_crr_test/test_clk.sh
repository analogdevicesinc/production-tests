#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_PREIPHERALS"

TEST_ID="01"
SHORT_DESC="Test AD9545 ETH_REFCLK1 out"
CMD="sudo $SCRIPT_DIR/i2c_ad9545 &> /dev/null;"
CMD+="CLK_FREQ=\$(sudo $SCRIPT_DIR/test_clk CLK0 verbose);"
CMD+="[[ \$CLK_FREQ -ge 311 ]] && [[ \$CLK_FREQ -le 315 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test AD9545 ETH_REFCLK2 out"
CMD="CLK_FREQ=\$(sudo $SCRIPT_DIR/test_clk CLK1 verbose);"
CMD+="[[ \$CLK_FREQ -ge 154 ]] && [[ \$CLK_FREQ -le 158 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

#TEST_ID="03"
#SHORT_DESC="Test HMC7044 QSFP_REFCLK out"
#CMD="CLK_FREQ=\$(sudo $SCRIPT_DIR/test_clk CLK2 verbose);"
#CMD+="[[ \"\$CLK_FREQ\" -eq 23 ]]"
#run_test $TEST_ID "$SHORT_DESC" "$CMD"

#TEST_ID="04"
#SHORT_DESC="Test HMC7044 SFP_REFCLK out"
#CMD="CLK_FREQ=\$(sudo $SCRIPT_DIR/test_clk CLK3 verbose);"
#CMD+="[[ \"\$CLK_FREQ\" -eq 23 ]]"
#run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="05"
SHORT_DESC="Test FMC_CLK_0 out"
CMD="CLK_FREQ=\$(sudo $SCRIPT_DIR/test_clk CLK4 verbose);"
CMD+="[[ \$CLK_FREQ -ge 311 ]] && [[ \$CLK_FREQ -le 315 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"



 : #if reached this point, ensure exito code 0
