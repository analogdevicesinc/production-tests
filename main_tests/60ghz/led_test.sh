#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh


RESULT=$?

check_leds() {
    check_4_leds_on() {
        echo_blue "[1] Testing the 4 LEDs status"
        read -n 1 -p "Are the 4 green LEDs on/blinking? (y/n): " answer
        echo ""

        if [[ "$answer" =~ [yY] ]]; then
            echo_green "PASSED"
        else
            echo_red "FAILED"
            RESULT=1;
        fi

        sleep 1
    }

    check_power_led() {
        echo_blue "[2] Testing the Power LED status"
        read -n 1 -p "Is the blue LED on? (y/n): " answer
        echo ""

        if [[ "$answer" =~ [yY] ]]; then
            echo_green "PASSED"
        else
            echo_red "FAILED"
            RESULT=1;
        fi

        sleep 2
    }

    check_eth_led() {
        echo_blue "[3] Testing the Raspberry Ethernet LED status"
        read -n 1 -p "Is the DUT Ethernet LED on? (y/n): " answer
        echo ""

        if [[ "$answer" =~ [yY] ]]; then
            echo_green "PASSED"
        else
            echo_red "FAILED"
            RESULT=1;
            
        fi
          
        sleep 2
    }

    check_4_leds_on
    check_power_led
    check_eth_led
}

check_leds
    if [ $RESULT -ne 0 ]; then
        exit 1;
    fi

