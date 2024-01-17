#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

RESULT=$?
tty=/dev/ttyACM0
stty -F $tty 115200
exec 4<$tty 5>$tty

read -p "Press the reset button on the board then press ENTER"

if timeout 5 cat $tty | tee output.txt | grep -q -A2 "2.4.0"; then
    echo_green "PASSED"
else
    echo_red "FAILED"
    RESULT=1
fi

if [ "$RESULT" -ne 0 ]; then
    exit 1
fi


# rm -rf output.txt
