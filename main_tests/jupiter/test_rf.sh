#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_ID="01"
SHORT_DESC="Testing RF"
CMD="python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_jupiter_prod.py --uri=\"ip:analogdut.local\" --adi-hw-map --hw=adrv9002"
run_test $TEST_ID "$SHORT_DESC" "$CMD"
