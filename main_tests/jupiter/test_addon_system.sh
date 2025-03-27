#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_RF_ADDON"

TEST_ID="01"
SHORT_DESC="Testing RF ADD-ON."
CMD="ssh_cmd \"sudo sh -c 'cat /home/analog/jupiter/my_profile_RXB_9MHz_NCO.json > /sys/bus/iio/devices/iio\:device1/profile_config'\";"
CMD+="sleep 4;"
CMD+="ssh_cmd \"sudo sh -c 'echo tx_b > /sys/bus/iio/devices/iio\:device1/out_voltage0_port_select'\";"
CMD+="ssh_cmd \"sudo sh -c 'echo tx_b > /sys/bus/iio/devices/iio\:device1/out_voltage1_port_select'\";"
CMD+="ssh_cmd \"sudo iio_info &> /dev/null\";"
CMD+="python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_jupiter_addon.py --uri=\"ip:analogdut.local\" --adi-hw-map --hw=adrv9002;"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
