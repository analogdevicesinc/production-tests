#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

FAIL_COUNT=0

TEST_NAME="TEST_MCS"

TEST_ID="01"
SHORT_DESC="Test MCS. Sending impulse from Rpi"
CMD="ssh_cmd \"sudo /home/analog/jupiter/mcs_flag.sh\";"
CMD+="echo \"sending impulse from RPI\";"
CMD+="RES=\$(ssh_cmd \"sudo sh -c 'echo 1 > /sys/bus/iio/devices/iio\:device1/multi_chip_sync'\") &"
CMD+="python3 \$SCRIPT_DIR/rpi_pulse.py ;"
CMD+="[[ \$RES -eq 0 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
