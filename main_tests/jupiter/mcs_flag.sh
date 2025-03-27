#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

#drive gpios high
echo 476 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio476/direction
echo 1 > /sys/class/gpio/gpio476/value

echo 477 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio477/direction
echo 1 > /sys/class/gpio/gpio477/value

#load profile for mcs
cat $SCRIPT_DIR/lte_10_lvds_nco_api_68_8_1_sync.json > /sys/bus/iio/devices/iio\:device1/profile_config
sleep 3
