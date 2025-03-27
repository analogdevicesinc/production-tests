#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_ISOLATION"

TEST_ID="01"
SHORT_DESC="Testing RF Isolation LNA ON"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio4_direction'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio6_direction'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio4_value'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio6_value'\";"
CMD+="ssh_cmd \"sudo sh -c 'cat /home/analog/jupiter/lte_10_lvds_nco_api_68_8_1.json > /sys/bus/iio/devices/iio\:device1/profile_config'\";"
CMD+="sleep 2;"
CMD+="python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_jupiter_isolation.py --uri=\"ip:analogdut.local\" --adi-hw-map --hw=adrv9002 | tee rf_log.txt;"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio4_direction'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio6_direction'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 0 > /sys/kernel/debug/iio/iio\:device1/agpio4_value'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo 0 > /sys/kernel/debug/iio/iio\:device1/agpio6_value'\";"
CMD+="cat rf_log.txt | grep -q FAIL; TEST_RES=\$?; "
CMD+="[[ \$TEST_RES -ne 0 ]];"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
