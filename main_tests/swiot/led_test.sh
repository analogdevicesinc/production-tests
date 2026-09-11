#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh


RESULT=$?

check_leds() {
    check_yellow_led() {
        echo_blue "[1] Testing the link-up LED status"
        read -n 1 -p "Is DS11 LED on? (y/n): " answer
        echo ""

        if [[ "$answer" =~ [yY] ]]; then
            echo_green "PASSED"
        else
            echo_red "FAILED"
            RESULT=1;
        fi

        sleep 1
    }

    check_daplink_led() {
        echo_blue "[2] Testing the power on LED status"
        read -n 1 -p "Is the DS17 LED on? (y/n): " answer
        echo ""

        if [[ "$answer" =~ [yY] ]]; then
            echo_green "PASSED"
        else
            echo_red "FAILED"
            RESULT=1;
        fi

        sleep 2
    }

    check_powergod_leds() {
        echo_blue "[3] Testing the power good LEDs status"
        read -n 1 -p "Are the DS12 and DS9 LEDs on? (y/n): " answer
        echo ""

        if [[ "$answer" =~ [yY] ]]; then
            echo_green "PASSED"
        else
            echo_red "FAILED"
            RESULT=1;
            
        fi
          
        sleep 2
    }

    check_yellow_led
    check_daplink_led
    check_powergod_leds
}

check_leds
    if [ $RESULT -ne 0 ]; then
        exit 1;
    fi
