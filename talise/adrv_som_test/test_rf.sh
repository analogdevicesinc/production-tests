#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_RF"

TEST_ID="01"
SHORT_DESC="TEST RF RX Mode - Please connect the loopback cables to each RX"
CMD="wait_enter && python3 -m pytest --color yes $SCRIPT_DIR/../work/pyadi-iio/test/test_adrv9009_zu11eg.py -vs --uri=\"ip:analogdut.local\" --hw=\"adrv9009-dual\";"
run_test $TEST_ID "$SHORT_DESC" "$CMD"


TEST_ID="02"
SHORT_DESC="TEST RF OBS RX Mode - Please switch the cable from each RX to ORX accordingly! (RX1_A -> ORX1_A, RX2_A -> ORX2_A, etc)"
CMD="wait_enter && python3 -m pytest --color yes $SCRIPT_DIR/../work/pyadi-iio/test/test_adrv9009_zu11eg_obs.py -vs --uri=\"ip:analogdut.local\" --hw=\"adrv9009-dual\";"
run_test $TEST_ID "$SHORT_DESC" "$CMD"
