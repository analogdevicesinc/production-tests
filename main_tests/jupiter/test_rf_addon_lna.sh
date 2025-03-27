#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_RF_ADDON_LNA_ON"

TEST_ID="01"
SHORT_DESC="Testing RF ADD-ON LNA ON"
CMD="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio5_direction'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio7_direction'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio5_value'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio7_value'\";"
CMD+="python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_jupiter_addon_lna_on.py --uri=\"ip:analogdut.local\" --adi-hw-map --hw=adrv9002 | tee rf_log.txt;"
CMD+="cat rf_log.txt | grep -q \"FAILED\"; TEST_RES=\$?; "
CMD+="[[ \$TEST_RES -ne 0 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
