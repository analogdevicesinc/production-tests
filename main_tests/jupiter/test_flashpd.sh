#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_FLASHPD"

TEST_ID="01"
SHORT_DESC="Program USBPD spi flash"
CMD="flashcp /home/analog/flashpd/Jupiter_TPS65988_revC.bin /dev/mtd0;"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Write AD9542 Flash"
CMD="sudo /home/analog/ad9542/prog_ad9542;"
CMD+="echo 358 > /sys/class/gpio/export;"
CMD+="echo out > /sys/class/gpio/gpio358/direction;"
CMD+="sleep 0.1;"
CMD+="echo 1 > /sys/class/gpio/gpio358/value;"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Load default dtb"
CMD="sudo cp /home/analog/jupiter/system.dtb /boot/system.dtb"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

exit $FAIL_COUNT
