#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_POWER_SUPPLY"

TEST_ID="01"
SHORT_DESC="Voltage VDDA1P3_ANLG_C is in range?"
CMD="python \$SCRIPT_DIR/test_powersupply.py voltage0 1235 1365"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Voltage VDDA1P3_ANLG_D is in range?"
CMD="python \$SCRIPT_DIR/test_powersupply.py voltage1 1235 1365"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Voltage VDDA1P8_C is in range?"
CMD="python \$SCRIPT_DIR/test_powersupply.py voltage2 1710 1890"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="Voltage VDDA1P8_D is in range?"
CMD="python \$SCRIPT_DIR/test_powersupply.py voltage3 1710 1890"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="05"
SHORT_DESC="Voltage VDDA3P3_CLK is in range?"
CMD="python \$SCRIPT_DIR/test_powersupply.py voltage4 1567 1732"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="06"
SHORT_DESC="Voltage VDDA3P3_VCO is in range?"
CMD="python \$SCRIPT_DIR/test_powersupply.py voltage5 1567 1732"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="07"
SHORT_DESC="Voltage VDDA3P3_VCXO is in range?"
CMD="python \$SCRIPT_DIR/test_powersupply.py voltage6 1567 1732"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="08"
SHORT_DESC="Voltage VDDA3P3 is in range?"
CMD="python \$SCRIPT_DIR/test_powersupply.py voltage7 1567 1732"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

 : #if reached this point, ensure exit code 0
