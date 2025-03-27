#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_ID="01"
SHORT_DESC="Testing RF LNA ON"
CMD="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio4_direction'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio6_direction'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio4_value'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio6_value'\";"
CMD+="python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_jupiter_lna_on.py --uri=\"ip:analogdut.local\" --adi-hw-map --hw=adrv9002 | tee rf_log.txt;"
CMD+="cat rf_log.txt | grep -q \"FAILED\"; TEST_RES=\$?; "
CMD+="[[ \$TEST_RES -ne 0 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
