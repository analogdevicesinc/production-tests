#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh


RESULT=$?

check_leds() {
    echo_blue "[1] Testing the resistor board LED status"
    echo "Powering the LED...it might take a while"
    sleep 8
    read -n 1 -p "CHECK: Is the red LED on the resistor board ON? (y/n): " answer
    echo ""

    if [[ "$answer" =~ ^[yY]$ ]]; then
        echo_green "PASSED"
    else
        echo_red "FAILED"
        RESULT=1
    fi

    sleep 1
}

check_display(){
        echo_blue "[2] Testing the current"
        read -n 1 -p "Do you read on the display C : approximately 500 mA? (y/n): " answer
        echo ""

        if [[ "$answer" =~ ^[yY]$ ]]; then
                echo_green "PASSED"
        else
                echo_red "FAILED"
                RESULT=1
        fi
}

check_leds
check_display

    if [ $RESULT -ne 0 ]; then
        exit 1;
    f