#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh

RESULT=$?

check_voltage_led() {
    echo_blue "[1] Testing the voltage supply LED"
    echo_blue "-------------------------------------"
    read -n 1 -p "Is the DS1 LED on? (y/n): " answer
    echo ""

    if [[ "$answer" =~ [yY] ]]; then
        echo_green "PASSED"
    else
        echo_red "FAILED"
        RESULT=1;
    fi

    sleep 2
}

check_voltage_led
    if [ $RESULT -ne 0 ]; then
        exit 1;
    fi