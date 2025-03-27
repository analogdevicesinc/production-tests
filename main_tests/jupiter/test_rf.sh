#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_ID="01"
SHORT_DESC="Testing RF"
CMD="ssh_cmd \"sudo sh -c 'cat /home/analog/jupiter/lte_10_lvds_nco_api_68_8_1.json > /sys/bus/iio/devices/iio\:device1/profile_config'\";"
CMD+="sleep 4;"
CMD+="ssh_cmd \"sudo iio_info &> /dev/null\";"
CMD+="python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_jupiter_prod.py --uri=\"ip:analogdut.local\" --adi-hw-map --hw=adrv9002 | tee rf_log.txt;"
CMD+="cat rf_log.txt | grep -q \"FAILED\"; TEST_RES=\$?; "
CMD+="[[ \$TEST_RES -ne 0 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
