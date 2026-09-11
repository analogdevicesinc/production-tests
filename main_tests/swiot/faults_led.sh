#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh


RESULT=$?

check_leds() {
    check_status_led() {
        echo_blue "[1] Testing the 4 green status LEDs"
        read -n 1 -p "Are the DS1, DS3, DS5 and DS7 LEDs on? (y/n): " answer
        echo ""

        if [[ "$answer" =~ [yY] ]]; then
            echo_green "PASSED"
        else
            echo_red "FAILED"
            RESULT=1;
        fi

        sleep 1
    }

    check_fault_led() {
        echo_blue "[2] Testing the 4 red fault LEDs"
        read -n 1 -p "Are the DS2, DS4, DS6 and DS8 LEDs on? (y/n): " answer
        echo ""

        if [[ "$answer" =~ [yY] ]]; then
            echo_green "PASSED"
        else
            echo_red "FAILED"
            RESULT=1;
        fi

        sleep 2
    }


    check_status_led
    check_fault_led

}

check_leds
    if [ $RESULT -ne 0 ]; then
        exit 1;
    fi
