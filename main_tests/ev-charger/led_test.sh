#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh
RESULT=$?
echo_blue "[1] Testing the power LED status"
read -n 1 -p "Is the DS3_2 LED on? (y/n): " answer
        echo ""

        if [[ "$answer" =~ [yY] ]]; then
            echo_green "PASSED"
        else
            echo_red "FAILED"
            RESULT=1;
        fi

        sleep 1

if [ $RESULT -ne 0 ]; then
    handle_error_state "BOARD_SERIAL"
    exit 1;
fi
