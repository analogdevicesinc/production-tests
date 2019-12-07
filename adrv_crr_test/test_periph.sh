#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_PREIPHERALS"

TEST_ID="01"
SHORT_DESC="Test QSFP. QSFP Loopback should be inserted!"
CMD="sudo $SCRIPT_DIR/test_periph QSFP"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test SFP. SFP Loopback should be inserted!"
CMD="sudo $SCRIPT_DIR/test_periph SFP"
run_test $TEST_ID "$SHORT_DESC" "$CMD"


TEST_ID="03"
SHORT_DESC="Test FMC GTX. FMC Loopback should be inserted!"
CMD="sudo $SCRIPT_DIR/test_periph FMC"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="Test FMC GPIO0. FMC Loopback should be inserted!"
CMD="sudo $SCRIPT_DIR/test_gpio FMC_GPIO0 loopback"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="05"
SHORT_DESC="Test FMC GPIO1. FMC Loopback should be inserted!"
CMD="sudo $SCRIPT_DIR/test_gpio FMC_GPIO1 loopback"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="06"
SHORT_DESC="Test PCI Express. PCI Express Loopback should be inserted and powered!"
CMD="sudo $SCRIPT_DIR/test_periph PCIE"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

 : #if reached this point, ensure exito code 0
