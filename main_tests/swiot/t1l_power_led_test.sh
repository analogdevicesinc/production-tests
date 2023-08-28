#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh


RESULT=$?

check_leds() {
    check_powergood_leds() {
        echo_blue "[1] Testing the power good LEDs status"
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

    check_powergood_leds
}

check_leds
    if [ $RESULT -ne 0 ]; then
        exit 1;
    fi
