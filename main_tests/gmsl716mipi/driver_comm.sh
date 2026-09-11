#!/bin/bash
SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

RESULT=$?
echo_blue "[2] Testing max9296a driver"
echo_blue "-------------------------------------"

if sudo dmesg | grep "max9296a" | grep -q "rp1-cfe 1f00110000.csi: Using source max9296a 10-002a for capture"; then
    RESULT=0
    echo_green "PASSED"
else
    RESULT=1
    echo_red "FAILED"
    echo_red "MAX9296a Driver not found"
fi

#if [ $RESULT -ne 0 ]; then
    #exit 1;
#fi

echo_blue "[3] Testing max96717 driver"
echo_blue "-------------------------------------"


if media-ctl -p -d "platform:1f00110000.csi" | grep "max96717" | grep -q "max96717 15-0040"; then
    RESULT=0
    echo_green "PASSED"
else
    RESULT=1
    echo_red "FAILED"
    echo_red "MAX96717 Driver not found"
    exit 1;
fi