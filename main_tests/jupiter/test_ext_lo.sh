#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh
FAIL_COUNT=0


TEST_NAME="TEST_CLK_OUT"

TEST_ID="01"
SHORT_DESC="Test CLK_OUT."
CMD="ssh_cmd \"sudo sh -c 'cp /home/analog/jupiter/ext_lo.dtb /boot/system.dtb'\";"
CMD="echo \"Rebooting board\" && ssh_cmd \"sudo reboot\";"
CMD+="sleep 30;"
CMD+="wait_for_board_online;"
CMD+="ssh_cmd \"iio_info | grep adrv9002\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT